CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
map(x,y,height) AS (
    SELECT x, id, c::int
    FROM input,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(c,x)
),
low_points(x,y) AS (
    SELECT x, y
    FROM map AS o
    WHERE height < ALL(SELECT height FROM map AS i WHERE (i.x,i.y) IN ((o.x,o.y+1),(o.x,o.y-1),(o.x+1,o.y),(o.x-1,o.y)))
),
basin(x,y,low_x,low_y) AS (
    SELECT x, y, x, y
    FROM low_points
UNION
    SELECT m.x, m.y, b.low_x, b.low_y
    FROM map AS m, basin AS b
    WHERE (b.x,b.y) IN ((m.x,m.y+1),(m.x,m.y-1),(m.x+1,m.y),(m.x-1,m.y))
        AND m.height < 9
),
sizes(s) AS (
    SELECT count(*)
    FROM basin
    GROUP BY low_x, low_y
    ORDER BY count(*) DESC
    LIMIT 3
),
sizes_arr(a) AS (
    SELECT array_agg(s)
    FROM sizes
)
SELECT a[1] * a[2] * a[3] -- no product aggregate
FROM sizes_arr;
