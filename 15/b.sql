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
    _done bool[][] := (
        WITH
        lines(y, l) AS (
            SELECT y, array_agg(FALSE)
            FROM generate_series(1, _target_y) AS y,
                generate_series(1, _target_x) AS x
            GROUP BY y
        )
        SELECT array_agg(l)
    FROM lines
    );
BEGIN
    CREATE TEMPORARY TABLE pq(x int, y int, d int, PRIMARY KEY (x,y));
    CREATE INDEX ON pq(d) INCLUDE (x, y);
    INSERT INTO pq
    VALUES (1, 1, 0);

    LOOP
        SELECT x, y, d
        INTO _x, _y, _d
        FROM pq
        ORDER BY d
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'priority queue empty';
        END IF;

        IF (_x,_y) = (_target_x,_target_y) THEN
            RETURN _d;
        END IF;

        _done[_x][_y] := TRUE;
        DELETE FROM pq
        WHERE (x,y) = (_x,_y);

        INSERT INTO pq
        SELECT *
        FROM (VALUES
            (_x+1, _y, _d + _risks[_x+1][_y]),
            (_x-1, _y, _d + _risks[_x-1][_y]),
            (_x, _y+1, _d + _risks[_x][_y+1]),
            (_x, _y-1, _d + _risks[_x][_y-1])) AS new(x,y,d)
        WHERE NOT _done[x][y]
        ON CONFLICT (x, y) DO UPDATE
        SET d = least(pq.d, _d + _risks[pq.x][pq.y])
        WHERE (pq.x,pq.y) IN ((_x+1, _y),
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
