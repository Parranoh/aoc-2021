CREATE TEMPORARY TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
parse(input, stack) AS (
    SELECT string_to_array(line, NULL)::text[], ARRAY[]::text[]
    FROM input
UNION ALL SELECT * FROM (
    WITH parse(input, stack) AS (TABLE parse)
    SELECT input[2:], input[1] || stack
    FROM parse
    WHERE input[1] IN ('(','[','{','<')
UNION ALL
    SELECT input[2:], stack[2:]
    FROM parse
    WHERE position(stack[1] IN '([{<') = position(input[1] IN ')]}>')
) AS rec)
SELECT sum(CASE input[1] WHEN ')' THEN 3 WHEN ']' THEN 57 WHEN '}' THEN 1197 WHEN '>' THEN 25137 END)
FROM parse
WHERE position(stack[1] IN '([{<') <> nullif(position(input[1] IN ')]}>'), 0);
