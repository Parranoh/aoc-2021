CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

WITH RECURSIVE
target(x_min, x_max, y_min, y_max) AS (
    SELECT m[1]::int, m[2]::int, m[3]::int, m[4]::int
    FROM input,
        LATERAL (VALUES (regexp_match(line, 'x=(\d+)..(\d+), y=(-\d+)..(-\d+)'))) AS let(m)
),
trajs(vx0, vy0, x, y, vx, vy) AS (
    SELECT vx0, vy0, 0, 0, vx0, vy0
    FROM target,
        LATERAL generate_series(floor(sqrt(x_min))::int, x_max) AS vx0,
        LATERAL generate_series(y_min, -y_min + 1) AS vy0
UNION ALL
    SELECT vx0, vy0, x + vx, y + vy, vx - sign(vx)::int, vy - 1
    FROM trajs, target
    WHERE y >= y_min OR vy > 0
),
reach_target(vx0, vy0) AS (
    SELECT vx0, vy0
    FROM trajs, target
    GROUP BY vx0, vy0
    HAVING bool_or(x BETWEEN x_min AND x_max AND y BETWEEN y_min AND y_max)
)
SELECT count(*)
FROM reach_target;
