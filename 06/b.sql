DROP TABLE IF EXISTS input CASCADE;
CREATE TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
init(days, n) AS (
    SELECT days, count(s)
    FROM input,
        LATERAL unnest(string_to_array(line, ',')) AS _(s)
        RIGHT OUTER JOIN LATERAL generate_series(0, 8) AS __(days) ON s::int = days
    GROUP BY days
),
pop(i, p) AS (
    SELECT 0, array_agg(n ORDER BY days)
    FROM init
        UNION ALL
    SELECT i + 1, p[2:7] || p[1] + p[8] || p[9] || p[1]
    FROM pop
    WHERE i < 256
)
SELECT sum(n)
FROM pop,
    LATERAL unnest(p) AS _(n)
GROUP BY i
ORDER BY i DESC
LIMIT 1;
