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
mean(m) AS (
    SELECT avg(n)
    FROM nums
)
SELECT sum(dist * (dist + 1) / 2) AS cost
FROM nums, mean,
    LATERAL (VALUES (floor(m)::int), (ceil(m)::int)) AS t(target),
    LATERAL (VALUES (@(n - target))) AS let(dist)
GROUP BY target
ORDER BY cost
LIMIT 1;
