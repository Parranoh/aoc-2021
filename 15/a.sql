CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
lines(y, l) AS (
    SELECT id, array_agg(c::int ORDER BY x)
    FROM input,
        LATERAL unnest(string_to_array(line)) WITH ORDINALITY AS _(c, x)
    GROUP BY id
),
risks(r) AS (
    SELECT array_agg(l ORDER BY y)
    lines
),
bellman_ford(i, x, y, d) AS (
    SELECT 1, 1, 1, 0
UNION ALL SELECT * FROM (WITH bellman_ford(i, x, y, d) AS (TABLE bellman_ford)
    SELECT i + 1, c.x, c.y,
        d + CASE WHEN (b.x,b.y) = (c.x,c.y) THEN 0 ELSE r[x][y]
    FROM risks, bellman_ford AS b,
        LATERAL (VALUES (x,y), (x+1,y), (x-1,y), (x,y+1), (x,y-1)) AS c(x,y)
    WHERE i < cardinality(r)
) AS rec)
