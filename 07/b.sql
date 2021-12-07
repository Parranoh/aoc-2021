DROP TABLE IF EXISTS input CASCADE;
CREATE TEMPORARY TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

EXPLAIN ANALYZE
WITH nums(n) AS (
    SELECT s::int
    FROM input,
        LATERAL unnest(string_to_array(line, ',')) AS s
),
extremes(minimum, maximum) AS (
    SELECT min(n), max(n)
    FROM nums
)
SELECT sum(dist * (dist + 1) / 2) AS cost
FROM nums, extremes,
    LATERAL generate_series(minimum, maximum) AS target,
    LATERAL (VALUES (@(n - target))) AS let(dist)
GROUP BY target
ORDER BY cost
LIMIT 1;
