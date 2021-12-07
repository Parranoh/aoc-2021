DROP TABLE IF EXISTS input CASCADE;
CREATE TEMPORARY TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

WITH nums(n) AS (
    SELECT s::int
    FROM input,
        LATERAL unnest(string_to_array(line, ',')) AS s
),
median(m) AS (
    SELECT percentile_disc(0.5) WITHIN GROUP (ORDER BY n)
    FROM nums
)
SELECT sum(@(n - m))
FROM nums, median;
