CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
dots(x, y) AS (
    SELECT m[1]::int, m[2]::int
    FROM input,
        LATERAL (VALUES (string_to_array(line, ','))) AS let(m)
    WHERE array_length(m, 1) = 2
),
folds(id, axis, coord) AS (
    SELECT row_number() OVER (ORDER BY id), m[1], m[2]::int
    FROM input,
        LATERAL (VALUES (regexp_match(line, '([xy])=(\d+)'))) AS let(m)
    WHERE starts_with(line, 'fold')
),
folded(i, x, y) AS (
    SELECT 1, x, y
    FROM dots
UNION ALL
    SELECT DISTINCT i + 1,
        CASE WHEN axis = 'x' THEN coord - @(coord - x) ELSE x END,
        CASE WHEN axis = 'y' THEN coord - @(coord - y) ELSE y END
    FROM folded JOIN folds ON i = id
),
last(i) AS (
    SELECT max(i)
    FROM folded
),
bound(x, y) AS (
    SELECT max(x), max(y)
    FROM last NATURAL JOIN folded
),
all_coords(x, y) AS (
    SELECT x.x, y.y
    FROM bound,
        LATERAL generate_series(0, y) AS y,
        LATERAL generate_series(0, x) AS x
)
SELECT string_agg(CASE WHEN i IS NULL THEN '.' ELSE '#' END, NULL ORDER BY x)
FROM last NATURAL JOIN folded NATURAL RIGHT JOIN all_coords
GROUP BY y
ORDER BY y;
