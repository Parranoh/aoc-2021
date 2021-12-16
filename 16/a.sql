CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

DROP TYPE IF EXISTS state_t;
CREATE TYPE state_t AS ENUM (
    'VERSION',
    'LITERAL',
    'POP',
    'HALT'
);

DROP FUNCTION IF EXISTS bits_to_int(bit[]);
CREATE FUNCTION bits_to_int(b bit[]) RETURNS bigint AS
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
    ids, -- array of ints
    starts, -- stack of ints
    parents, -- array of ints
    versions, -- array of ints
    type_ids, -- array of ints
    value, -- array of ints nullable
    total_bits, -- stack of ints nullable
    total_packets, -- stack of ints nullable
    packets_read -- stack of ints nullable
) AS (
    -- base {{{
    SELECT 0           AS i,
        'VERSION'::state_t,
        1::int         AS next_int,
        ARRAY[]::int[] AS ids,
        ARRAY[]::int[] AS starts,
        ARRAY[]::int[] AS parents,
        ARRAY[]::bigint[] AS versions,
        ARRAY[]::bigint[] AS type_ids,
        ARRAY[]::bigint[] AS vals,
        ARRAY[]::bigint[] AS tbl,
        ARRAY[]::bigint[] AS tpl,
        ARRAY[]::int[] AS pr -- }}}
UNION ALL
    SELECT * FROM (
        WITH parse(i,state,next_in,ids,starts,parents,versions,type_ids,value,total_bits,total_packets,packets_read) AS (TABLE parse)
        -- case 'VERSION' {{{
        SELECT i + 1,
            CASE type_id WHEN 4 THEN 'LITERAL' ELSE 'POP' END::state_t AS state,
            next_in + CASE type_id
                WHEN 4 THEN 6
                ELSE 22 - length_type_id::int * 4
                END AS next_in,
            ids || next_in + CASE WHEN type_id = 4 THEN 6 WHEN length_type_id = 0::bit THEN 22 ELSE 18 END AS ids,
            next_in + CASE WHEN type_id = 4 THEN 6 WHEN length_type_id = 0::bit THEN 22 ELSE 18 END || starts AS starts, -- start of content
            parents || starts[1] AS parents,
            versions || version AS versions,
            type_ids || type_id AS type_ids,
            value || CASE type_id WHEN 4 THEN 0 END AS value,
            CASE WHEN type_id <> 4 AND length_type_id = 0::bit THEN bits_to_int(b[next_in + 7 : next_in + 21]) END || total_bits AS total_bits,
            CASE WHEN type_id <> 4 AND length_type_id = 1::bit THEN bits_to_int(b[next_in + 7 : next_in + 17]) END || total_packets AS total_packets,
            0 || packets_read AS packets_read
        FROM parse, bits, LATERAL (VALUES (
                bits_to_int(b[next_in : next_in + 2]), -- version
                bits_to_int(b[next_in + 3 : next_in + 5]), -- type_id
                b[next_in + 6] -- length_type_id, valid if type_id <> 4
            )) AS let(version, type_id, length_type_id)
        WHERE state = 'VERSION' -- }}}
    UNION ALL
        -- case 'LITERAL' {{{
        SELECT i + 1,
            CASE continuation WHEN 1::bit THEN 'LITERAL' ELSE 'POP' END::state_t AS state,
            next_in + 5 AS next_in,
            ids AS ids,
            starts AS starts,
            parents AS parents,
            versions AS versions,
            type_ids AS type_ids,
            trim_array(value, 1) || value[array_length(value, 1)] * 16 + bits_to_int(b[next_in + 1 : next_in + 4]) AS value,
            total_bits AS total_bits,
            total_packets AS total_packets,
            CASE continuation WHEN 0::bit THEN 1 || packets_read[2:] ELSE packets_read END AS packets_read
        FROM parse, bits, LATERAL (VALUES (
                b[next_in]
            )) AS let(continuation)
        WHERE state = 'LITERAL' -- }}}
    UNION ALL
        -- case 'POP' {{{
        SELECT i + 1,
            CASE
                WHEN pop AND array_length(starts, 1) = 1 THEN 'HALT'
                WHEN pop                                 THEN 'POP'
                ELSE                                          'VERSION'
                END::state_t AS state,
            next_in AS next_in,
            ids AS ids,
            CASE WHEN pop THEN starts[2:] ELSE starts END AS starts,
            parents AS parents,
            versions AS versions,
            type_ids AS type_ids,
            value AS value,
            CASE WHEN pop THEN total_bits[2:]                          ELSE total_bits    END AS total_bits,
            CASE WHEN pop THEN total_packets[2:]                       ELSE total_packets END AS total_packets,
            CASE WHEN pop THEN packets_read[2] + 1 || packets_read[3:] ELSE packets_read  END AS packets_read
        FROM parse, bits /* TODO */, LATERAL (VALUES (
                total_bits[1] IS NULL AND total_packets[1] IS NULL -- just read a literal
                    OR next_in - starts[1] = total_bits[1]
                    OR packets_read[1]     = total_packets[1]
            )) AS let(pop)
        WHERE state = 'POP' -- }}}
    ) AS rec
),
result(ids, parents, versions, type_ids, value) AS (
    SELECT ids, parents, versions, type_ids, value
    FROM parse
    ORDER BY i DESC
    LIMIT 1
)
SELECT sum(version)
FROM result, LATERAL unnest(versions) AS version;
