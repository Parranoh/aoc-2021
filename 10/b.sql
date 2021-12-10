CREATE TEMPORARY TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

CREATE OR REPLACE FUNCTION score(str text[]) RETURNS bigint AS
$$
    SELECT sum(position(v IN '([{<') * 5 ^ (array_length(str, 1) - ix))
    FROM unnest(str) WITH ORDINALITY AS _(v, ix);
$$
LANGUAGE SQL
IMMUTABLE;

WITH RECURSIVE
parse(input, stack) AS (
    SELECT string_to_array(line, NULL)::text[], ARRAY[]::text[]
    FROM input
UNION ALL SELECT * FROM (WITH parse(input, stack) AS (TABLE parse)
    SELECT input[2:], input[1] || stack
    FROM parse
    WHERE input[1] IN ('(','[','{','<')
UNION ALL
    SELECT input[2:], stack[2:]
    FROM parse
    WHERE position(stack[1] IN '([{<') = position(input[1] IN ')]}>')
) AS rec),
scores(score) AS (
    SELECT score(stack)
    FROM parse
    WHERE cardinality(input) = 0
),
ranks(score, is_median) AS (
    SELECT score, row_number() OVER (ORDER BY score) - row_number() OVER (ORDER BY score DESC) = 0
    FROM scores
)
SELECT score
FROM ranks
WHERE is_median;
