CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

DROP FUNCTION IF EXISTS dijkstra(int[][]);
CREATE FUNCTION dijkstra(_risks int[][]) RETURNS int AS
$$
DECLARE
    _x int;
    _y int;
    _d int;
    _target_x CONSTANT int := array_length(_risks, 1);
    _target_y CONSTANT int := array_length(_risks, 2);
BEGIN
    CREATE TEMPORARY TABLE dist(x int, y int, d int, done bool, PRIMARY KEY (x,y));
    INSERT INTO dist
    VALUES (1, 1, 0, FALSE);

    LOOP
        SELECT x, y, d
        INTO _x, _y, _d
        FROM dist
        WHERE NOT done
        ORDER BY d;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'priority queue empty';
        END IF;

        IF (_x,_y) = (_target_x,_target_y) THEN
            RETURN _d;
        END IF;

        UPDATE dist
        SET done = TRUE
        WHERE (x,y) = (_x,_y);

        INSERT INTO dist
        SELECT *
        FROM (VALUES (_x+1, _y, _d + _risks[_x+1][_y], FALSE),
            (_x-1, _y, _d + _risks[_x-1][_y], FALSE),
            (_x, _y+1, _d + _risks[_x][_y+1], FALSE),
            (_x, _y-1, _d + _risks[_x][_y-1], FALSE)) AS new(a,b,d,b)
        WHERE d IS NOT NULL
        ON CONFLICT (x, y) DO UPDATE
        SET d = least(dist.d, _d + _risks[dist.x][dist.y])
        WHERE (dist.x,dist.y) IN ((_x+1, _y),
            (_x-1, _y),
            (_x, _y+1),
            (_x, _y-1));
    END LOOP;
END;
$$
LANGUAGE PLpgSQL
VOLATILE;

WITH
tile(x, y, v) AS (
    SELECT x + tile_x * max(x) OVER (),
        dense_rank() OVER (ORDER BY id) + tile_y * (SELECT count(*) FROM input),
        (c::int - 1 + tile_x + tile_y) % 9 + 1
    FROM input,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(c, x),
        LATERAL generate_series(0, 4) AS tile_x,
        LATERAL generate_series(0, 4) AS tile_y
),
lines(y, l) AS (
    SELECT y, array_agg(v ORDER BY x)
    FROM tile
    GROUP BY y
),
risks(r) AS (
    SELECT array_agg(l ORDER BY y)
    FROM lines
)
SELECT dijkstra(r)
FROM risks;
