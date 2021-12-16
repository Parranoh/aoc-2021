CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

DROP TYPE IF EXISTS state_t;
CREATE TYPE state_t AS ENUM (
    'VERSION',
    'LITERAL'
);

DROP FUNCTION IF EXISTS bits_to_int(bit[]);
CREATE FUNCTION bits_to_int(b bit[]) RETURNS int AS
$$
    SELECT sum(d::int * 2 ^ (array_length(b, 1) - p))
    FROM unnest(b) WITH ORDINALITY AS _(d, p)
$$
LANGUAGE SQL
IMMUTABLE;

WITH RECURSIVE
bits(b) AS (
    SELECT array_agg(bin.d::bit ORDER BY o, i)
    FROM input,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS hex(d, o),
        LATERAL unnest(string_to_array(('x' || d::text)::bit(4)::text, NULL)) WITH ORDINALITY AS bin(d, i)
),
parse(i,
    state,
    next_in, -- index of next input
    version, -- array
    "is_literal?", -- array of bools
    value, -- array of ints nullable
    operator, -- array of operator IDs nullable
    total_bit_length, -- stack of ints nullable
    remaining_bit_length, -- stack of ints nullable
    total_packet_length, -- stack of ints nullable
    remaining_packet_length -- stack of ints nullable
) AS (
    SELECT 0,
        'VERSION'::state_t,
        1,
        ARRAY[]::int[] AS version,
        ARRAY[]::bool[] AS is_lit,
        ARRAY[]::int[] AS val,
        ARRAY[]::int[] AS op,
        ARRAY[]::int[] AS tbl,
        ARRAY[]::int[] AS rbl,
        ARRAY[]::int[] AS tpl,
        ARRAY[]::int[] AS rpl
UNION ALL
    SELECT i + 1,
        CASE state
            WHEN 'VERSION'
                THEN CASE type_id WHEN 4 THEN 'LITERAL' ELSE 'VERSION' END
            WHEN 'LITERAL'
                THEN CASE b[next_in] WHEN 1 THEN 'LITERAL' ELSE 'VERSION' END
            END AS state,
        CASE state
            WHEN 'VERSION' THEN
                CASE type_id
                    WHEN 4 THEN next_in + next_in + 6
                    ELSE CASE length_type_id
                        WHEN 0 THEN next_in + 22
                        ELSE next_in + 18 END
            WHEN 'LITERAL' THEN
                ...
    FROM parse, bits,
        LATERAL (VALUES (
                bits_to_int(b[next_in : next_in + 2]) AS version_id, -- valid if state = 'VERSION'
                bits_to_int(b[next_in + 3 : next_in + 5]) AS type_id, -- valid if state = 'VERSION'
                b[next_in + 6] AS length_type_id, -- valid if state = 'VERSION' and type_id <> 4
                b[next_in] AS continuation -- valid if state = 'LITERAL'
            )) AS let
    WHERE next_in <= array_length(bits.b, 1)
)
TABLE bits;
