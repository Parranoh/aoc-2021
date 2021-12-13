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
first_fold(axis, coord) AS (
    SELECT axis, coord
    FROM folds
    ORDER BY id
    LIMIT 1
)
SELECT count(DISTINCT CASE axis WHEN 'x' THEN (@(coord - x), y) ELSE (x, @(coord -y )) END)
FROM dots, first_fold;
