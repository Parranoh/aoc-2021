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
            (_x, _y-1, _d + _risks[_x][_y-1], FALSE)) AS new(x,y,d,done)
        WHERE d IS NOT NULL
        ON CONFLICT DO NOTHING;

        UPDATE dist
        SET d = least(dist.d, _d + _risks[dist.x][dist.y])
        WHERE (x,y) IN ((_x+1, _y),
            (_x-1, _y),
            (_x, _y+1),
            (_x, _y-1));
    END LOOP;
END;
$$
LANGUAGE PLpgSQL
VOLATILE;

WITH
lines(y, l) AS (
    SELECT id, array_agg(c::int ORDER BY x)
    FROM input,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(c, x)
    GROUP BY id
),
risks(r) AS (
    SELECT array_agg(l ORDER BY y)
    FROM lines
)
SELECT dijkstra(r)
FROM risks;
