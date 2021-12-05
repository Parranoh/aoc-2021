DROP TABLE IF EXISTS input, lines;
CREATE TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

CREATE TABLE lines(
    x1 int NOT NULL,
    y1 int NOT NULL,
    x2 int NOT NULL,
    y2 int NOT NULL
);
INSERT INTO lines
SELECT coords[1]::int, coords[2]::int, coords[3]::int, coords[4]::int
FROM input,
    LATERAL (VALUES (regexp_match(line, '(\d+),(\d+) -> (\d+),(\d+)'))) AS let(coords);

CREATE OR REPLACE FUNCTION min(a int, b int) RETURNS int AS
$$ SELECT CASE WHEN a < b THEN a ELSE b END $$
LANGUAGE SQL IMMUTABLE;
CREATE OR REPLACE FUNCTION max(a int, b int) RETURNS int AS
$$ SELECT CASE WHEN a > b THEN a ELSE b END $$
LANGUAGE SQL IMMUTABLE;

WITH
points(x, y) AS (
    SELECT x1, y
    FROM lines,
        LATERAL generate_series(min(y1, y2), max(y1, y2)) AS _(y)
    WHERE x1 = x2
        UNION ALL
    SELECT x, y1
    FROM lines,
        LATERAL generate_series(min(x1, x2), max(x1, x2)) AS _(x)
    WHERE y1 = y2
),
overlap(x, y, n) AS (
    SELECT x, y, count(*)
    FROM points
    GROUP BY x, y
)
SELECT count(*)
FROM overlap
WHERE n >= 2;
