CREATE OR REPLACE FUNCTION
unnest_2d(m int[][])
RETURNS TABLE (x int, r int, c int)
LANGUAGE sql IMMUTABLE STRICT
AS $$
    SELECT x, ((i - 1) / array_length(m, 2)) + 1, ((i - 1) % array_length(m, 2)) + 1
    FROM unnest(m) WITH ORDINALITY AS _(x, i)
$$;

CREATE OR REPLACE FUNCTION
mult(a int[][], b int[][])
RETURNS int[][]
LANGUAGE sql IMMUTABLE STRICT
AS $$
    WITH
    cells(x, r, c) AS (
        SELECT sum(x1 * x2), r1, c2
        FROM unnest_2d(a) AS ta(x1, r1, c1),
            unnest_2d(b) AS tb(x2, r2, c2)
        WHERE c1 = r2
        GROUP BY r1, c2
    ),
    rs(xs, r) AS (
        SELECT array_agg(x ORDER BY c), r
        FROM cells
        GROUP BY r
    )
    SELECT array_agg(xs ORDER BY r)
    FROM rs
$$;

CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
rel_beacons(scanner, x, y, z) AS (
    SELECT (id - row_number() OVER (ORDER BY id))::int / 2, m[1]::int, m[2]::int, m[3]::int
    FROM input,
        LATERAL (VALUES (regexp_match(line, '^(-?\d+),(-?\d+),(-?\d+)$'))) AS let(m)
    WHERE m IS NOT NULL
),
scanner_pos(scanner, transrot) AS (
    SELECT 0, ARRAY[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
UNION SELECT * FROM (WITH scanner_pos(scanner, transrot) AS (TABLE scanner_pos)
    SELECT new.scanner,
        mult(ARRAY[[1,0,0,dx],[0,1,0,dy],[0,0,1,dz],[0,0,0,1]], rotations.r)
    FROM scanner_pos AS s
        NATURAL JOIN rel_beacons AS known,
        rel_beacons AS new,
        (VALUES -- {{{
                (ARRAY[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]),
                (ARRAY[[-1,0,0,0],[0,-1,0,0],[0,0,1,0],[0,0,0,1]]),
                (ARRAY[[-1,0,0,0],[0,1,0,0],[0,0,-1,0],[0,0,0,1]]),
                (ARRAY[[1,0,0,0],[0,-1,0,0],[0,0,-1,0],[0,0,0,1]]),

                (ARRAY[[0,1,0,0],[0,0,1,0],[1,0,0,0],[0,0,0,1]]),
                (ARRAY[[0,-1,0,0],[0,0,-1,0],[1,0,0,0],[0,0,0,1]]),
                (ARRAY[[0,-1,0,0],[0,0,1,0],[-1,0,0,0],[0,0,0,1]]),
                (ARRAY[[0,1,0,0],[0,0,-1,0],[-1,0,0,0],[0,0,0,1]]),

                (ARRAY[[0,0,1,0],[1,0,0,0],[0,1,0,0],[0,0,0,1]]),
                (ARRAY[[0,0,-1,0],[-1,0,0,0],[0,1,0,0],[0,0,0,1]]),
                (ARRAY[[0,0,-1,0],[1,0,0,0],[0,-1,0,0],[0,0,0,1]]),
                (ARRAY[[0,0,1,0],[-1,0,0,0],[0,-1,0,0],[0,0,0,1]]),

                (ARRAY[[0,0,-1,0],[0,1,0,0],[1,0,0,0],[0,0,0,1]]),
                (ARRAY[[0,0,1,0],[0,-1,0,0],[1,0,0,0],[0,0,0,1]]),
                (ARRAY[[0,0,1,0],[0,1,0,0],[-1,0,0,0],[0,0,0,1]]),
                (ARRAY[[0,0,-1,0],[0,-1,0,0],[-1,0,0,0],[0,0,0,1]]),

                (ARRAY[[0,-1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]),
                (ARRAY[[0,1,0,0],[-1,0,0,0],[0,0,1,0],[0,0,0,1]]),
                (ARRAY[[0,1,0,0],[1,0,0,0],[0,0,-1,0],[0,0,0,1]]),
                (ARRAY[[0,-1,0,0],[-1,0,0,0],[0,0,-1,0],[0,0,0,1]]),

                (ARRAY[[-1,0,0,0],[0,0,1,0],[0,1,0,0],[0,0,0,1]]),
                (ARRAY[[1,0,0,0],[0,0,-1,0],[0,1,0,0],[0,0,0,1]]),
                (ARRAY[[1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1]]),
                (ARRAY[[-1,0,0,0],[0,0,-1,0],[0,-1,0,0],[0,0,0,1]])-- }}}
            ) AS rotations(r),
        LATERAL (VALUES (mult(r, ARRAY[[new.x],[new.y],[new.z],[1]]))) AS let1(rxyzw),
        LATERAL (VALUES (rxyzw[1][1] / rxyzw[4][1], rxyzw[2][1] / rxyzw[4][1], rxyzw[3][1] / rxyzw[4][1])) AS let2(rx, ry, rz),
        LATERAL (VALUES (mult(transrot, ARRAY[[known.x],[known.y],[known.z],[1]]))) AS let3(txyzw),
        LATERAL (VALUES (txyzw[1][1] / txyzw[4][1], txyzw[2][1] / txyzw[4][1], txyzw[3][1] / txyzw[4][1])) AS let4(tx, ty, tz),
        LATERAL (VALUES (tx - rx, ty - ry, tz - rz)) AS let5(dx, dy, dz)
    WHERE new.scanner NOT IN (SELECT scanner FROM scanner_pos)
    GROUP BY new.scanner, known.scanner, rotations.r, dx, dy, dz
    HAVING count(*) >= 12
) AS rec),
abs_beacons(x, y, z) AS (
    SELECT DISTINCT txyzw[1][1] / txyzw[4][1], txyzw[2][1] / txyzw[4][1], txyzw[3][1] / txyzw[4][1]
    FROM rel_beacons NATURAL JOIN scanner_pos,
        LATERAL (VALUES (mult(transrot, ARRAY[[x],[y],[z],[1]]))) AS let(txyzw)
)
SELECT count(*)
FROM abs_beacons;
