CREATE TEMPORARY TABLE input (
    nr   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

DROP FUNCTION IF EXISTS get_param;
CREATE FUNCTION get_param(_w int, _x int, _y int, _z int, _param text)
RETURNS int
IMMUTABLE STRICT LANGUAGE sql
AS $$
SELECT CASE _param
    WHEN 'w' THEN _w
    WHEN 'x' THEN _x
    WHEN 'y' THEN _y
    WHEN 'z' THEN _z
    ELSE _param::int
END;
$$;

DROP FUNCTION IF EXISTS exec;
CREATE FUNCTION exec(_w int, _x int, _y int, _z int, _prefix bigint, _cmd text)
RETURNS TABLE(w int, x int, y int, z int, prefix bigint)
IMMUTABLE STRICT LANGUAGE sql
AS $$
SELECT
    CASE cmd[2] WHEN 'w' THEN res ELSE _w END,
    CASE cmd[2] WHEN 'x' THEN res ELSE _x END,
    CASE cmd[2] WHEN 'y' THEN res ELSE _y END,
    CASE cmd[2] WHEN 'z' THEN res ELSE _z END,
    CASE cmd[1] WHEN 'inp' THEN 10 * _prefix + inp ELSE _prefix END
FROM (VALUES (string_to_array(_cmd, ' '))) AS let1(cmd),
    LATERAL generate_series(1, CASE WHEN cmd[1] = 'inp' THEN 9 ELSE 1 END) AS inp,
    LATERAL (VALUES (CASE cmd[1]
        WHEN 'inp' THEN inp
        WHEN 'add' THEN get_param(_w, _x, _y, _z, cmd[2]) + get_param(_w, _x, _y, _z, cmd[3])
        WHEN 'mul' THEN get_param(_w, _x, _y, _z, cmd[2]) * get_param(_w, _x, _y, _z, cmd[3])
        WHEN 'div' THEN get_param(_w, _x, _y, _z, cmd[2]) / get_param(_w, _x, _y, _z, cmd[3])
        WHEN 'mod' THEN get_param(_w, _x, _y, _z, cmd[2]) % get_param(_w, _x, _y, _z, cmd[3])
        WHEN 'eql' THEN (get_param(_w, _x, _y, _z, cmd[2]) = get_param(_w, _x, _y, _z, cmd[3]))::int
    END)) AS let2(res)
$$;

WITH RECURSIVE
states(i, w, x, y, z, prefix) AS (
    SELECT min(nr), 0, 0, 0, 0, 0::bigint
    FROM input
UNION ALL SELECT * FROM (
    SELECT DISTINCT ON (r.w, r.x, r.y, r.z)
        i + 1, r.w, r.x, r.y, r.z, r.prefix
    FROM states, input, exec(w, x, y, z, prefix, line) AS r
    WHERE nr = i
    ORDER BY r.w, r.x, r.y, r.z, r.prefix ASC
) AS rec)
SELECT max(prefix)
FROM states
WHERE z = 0
    AND i = (SELECT min(i) FROM states);
