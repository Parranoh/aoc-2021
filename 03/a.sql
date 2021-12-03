DROP TABLE IF EXISTS input CASCADE;
CREATE TABLE input(
    val text NOT NULL
);
\copy input(val) from pstdin

CREATE OR REPLACE FUNCTION varbit_to_int(b varbit) RETURNS int AS
$$
    SELECT lpad(b::text, 32, '0')::bit(32)::int
$$
LANGUAGE SQL
IMMUTABLE;

WITH most_common(place, b) AS (
    SELECT place, mode() WITHIN GROUP (ORDER BY c)
    FROM input, string_to_table(val, NULL) WITH ORDINALITY AS _(c, place)
    GROUP BY place
), num(n) AS (
    SELECT string_agg(b, '' ORDER BY place)::varbit
    FROM most_common
)
SELECT varbit_to_int(n) * varbit_to_int(~n)
FROM num;
