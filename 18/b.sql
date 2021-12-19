DROP TYPE IF EXISTS explode_t CASCADE;
CREATE TYPE explode_t AS (to_left int, val jsonb, to_right int);

CREATE OR REPLACE FUNCTION
add_at(i int, diff int, x jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN CASE
        WHEN diff IS NULL THEN
            x
        WHEN jsonb_typeof(x) = 'number' THEN
            (x::int + diff)::text::jsonb
        WHEN i = 0 THEN
            jsonb_build_array(add_at(0, diff, x -> 0), x -> 1)
        ELSE
            jsonb_build_array(x -> 0, add_at(1, diff, x -> 1))
        END;
END;
$$;

CREATE OR REPLACE FUNCTION
explode(l int, x jsonb)
RETURNS explode_t
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    tmp explode_t;
BEGIN
    IF jsonb_typeof(x) = 'number' THEN
        RETURN NULL;
    ELSIF l = 4 THEN
        RETURN (x -> 0, '0', x -> 1)::explode_t;
    END IF;
    tmp := explode(l + 1, x -> 0);
    IF tmp IS DISTINCT FROM NULL THEN
        RETURN (tmp.to_left,
            jsonb_build_array(tmp.val, add_at(0, tmp.to_right, x -> 1)),
            NULL)::explode_t;
    END IF;
    tmp := explode(l + 1, x -> 1);
    IF tmp IS DISTINCT FROM NULL THEN
        RETURN (NULL,
            jsonb_build_array(add_at(1, tmp.to_left, x -> 0), tmp.val),
            tmp.to_right)::explode_t;
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION
split(x jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    tmp jsonb;
BEGIN
    IF jsonb_typeof(x) = 'number' THEN
        RETURN CASE
            WHEN x::int >= 10 THEN
                jsonb_build_array(x::int / 2, (x::int + 1) / 2)
            ELSE
                NULL
            END;
    END IF;
    tmp := split(x -> 0);
    IF tmp IS DISTINCT FROM NULL THEN
        RETURN jsonb_build_array(tmp, x -> 1);
    END IF;
    tmp := split(x -> 1);
    IF tmp IS DISTINCT FROM NULL THEN
        RETURN jsonb_build_array(x -> 0, tmp);
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION
reduce(x jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    tmp jsonb;
BEGIN
    tmp := (explode(0, x)).val;
    IF tmp IS DISTINCT FROM NULL THEN
        RETURN reduce(tmp);
    END IF;
    tmp := split(x);
    IF tmp IS DISTINCT FROM NULL THEN
        RETURN reduce(tmp);
    END IF;
    RETURN x;
END;
$$;

CREATE OR REPLACE FUNCTION
snailfish_add(x jsonb, y jsonb)
RETURNS jsonb
LANGUAGE sql IMMUTABLE STRICT
RETURN reduce(jsonb_build_array(x, y));

CREATE OR REPLACE FUNCTION
magnitude(x jsonb)
RETURNS int
LANGUAGE sql IMMUTABLE STRICT
AS $$
SELECT CASE
    WHEN jsonb_typeof(x) = 'number' THEN
        x::int
    ELSE
        3 * magnitude(x -> 0) + 2 * magnitude(x -> 1)
    END
$$;

CREATE TEMPORARY TABLE input(
    id   int   GENERATED ALWAYS AS IDENTITY,
    line jsonb NOT NULL
);
\copy input(line) from pstdin

SELECT max(magnitude(snailfish_add(i1.line, i2.line)))
FROM input AS i1, input AS i2;
