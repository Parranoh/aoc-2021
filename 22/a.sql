CREATE TEMPORARY TABLE input(
    nr   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
cuboids(id, "on?", x, y, z) AS (
    SELECT nr, m[1] = 'on', int8range(m[2]::int, m[3]::int, '[]'), int8range(m[4]::int, m[5]::int, '[]'), int8range(m[6]::int, m[7]::int, '[]')
    FROM input,
        LATERAL (VALUES (regexp_match(line, '^(o..?) x=(.*)\.\.(.*),y=(.*)\.\.(.*),z=(.*)\.\.(.*)$'))) AS let(m)
),
process(i, x, y, z) AS (
    SELECT * FROM (
        SELECT id, x, y, z
        FROM cuboids
        ORDER BY id
        LIMIT 1
    ) AS init
UNION ALL SELECT * FROM (
    WITH
    process(i, x, y, z) AS (TABLE process),
    next(id, "on?", x, y, z) AS (
        SELECT id, "on?", c.x, c.y, c.z
        FROM cuboids AS c, process
        WHERE i < id
        ORDER BY id
        LIMIT 1
    ),
    new(i, x, y, z, "include?") AS (
        SELECT id, t.x, t.y, t.z, t.inc
        FROM process AS p, next AS n,
            LATERAL (VALUES (p.x && n.x AND p.y && n.y AND p.z && n.z)) AS let("intersect?"),
            LATERAL (VALUES
                (n.x, n.y, n.z, "on?"),
                (p.x, p.y, p.z, NOT "intersect?"),
                (int8range(lower(p.x), greatest(lower(p.x), lower(n.x))), p.y, p.z, "intersect?"),
                (int8range(upper(n.x), greatest(upper(n.x), upper(p.x))), p.y, p.z, "intersect?"),
                (p.x * n.x, int8range(lower(p.y), greatest(lower(p.y), lower(n.y))), p.z, "intersect?"),
                (p.x * n.x, int8range(upper(n.y), greatest(upper(n.y), upper(p.y))), p.z, "intersect?"),
                (p.x * n.x, p.y * n.y, int8range(lower(p.z), greatest(lower(p.z), lower(n.z))), "intersect?"),
                (p.x * n.x, p.y * n.y, int8range(upper(n.z), greatest(upper(n.z), upper(p.z))), "intersect?")
            ) AS t(x, y, z, inc)
    )
    SELECT DISTINCT i, x, y, z
    FROM new
    WHERE "include?"
        AND NOT isempty(x)
        AND NOT isempty(y)
        AND NOT isempty(z)
) AS rec),
small(i, x, y, z) AS (
    SELECT i, int8range(-50, 50, '[]') * x, int8range(-50, 50, '[]') * y, int8range(-50, 50, '[]') * z
    FROM process
)
SELECT sum((upper(x) - lower(x)) * (upper(y) - lower(y)) * (upper(z) - lower(z)))
FROM small
WHERE i = (SELECT max(id) FROM cuboids);
