DROP TABLE IF EXISTS input CASCADE;
DROP FUNCTION IF EXISTS step, match CASCADE;
CREATE TABLE input(
    id  int  GENERATED ALWAYS AS IDENTITY,
    val text NOT NULL
);
\copy input(val) from pstdin

CREATE FUNCTION step(invert bool, ns int[], rs text[], OUT ns int[], OUT rs text[]) RETURNS record AS
$$
    WITH
    modus(m) AS (
        SELECT mode() WITHIN GROUP (ORDER BY left(r, 1) DESC)
        FROM unnest(rs) as _(r)
    )
    SELECT array_agg(n ORDER BY id), array_agg(right(r, -1) ORDER BY id)
    FROM modus, unnest(ns, rs) WITH ORDINALITY AS _(n, r, id)
    WHERE left(r, 1) = CASE WHEN invert THEN (~modus.m::bit)::text ELSE modus.m END
$$
LANGUAGE SQL
IMMUTABLE;

CREATE FUNCTION match(invert bool) RETURNS int AS
$$
    WITH RECURSIVE
    state(ns, rs) AS (
        SELECT
            array_agg(lpad(val, 32, '0')::bit(32)::int ORDER BY val, id),
            array_agg(val ORDER BY val, id)
        FROM input
            UNION ALL
        SELECT (step(invert, ns, rs)).*
        FROM state
        WHERE cardinality(ns) > 1
    )
    SELECT ns[1]
    FROM state
    WHERE cardinality(ns) = 1
$$
LANGUAGE SQL
IMMUTABLE;

SELECT match(true) * match(false);
