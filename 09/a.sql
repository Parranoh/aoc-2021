CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH
map(x,y,height) AS (
    SELECT x, id, c::int
    FROM input,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(c,x)
),
low_points(x,y,height) AS (
    SELECT x, y, height
    FROM map AS o
    WHERE height < ALL(SELECT height FROM map AS i WHERE (i.x,i.y) IN ((o.x,o.y+1),(o.x,o.y-1),(o.x+1,o.y),(o.x-1,o.y)))
)
SELECT sum(height + 1)
FROM low_points;
