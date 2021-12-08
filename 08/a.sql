CREATE TEMPORARY TABLE input(
    line text NOT NULL
);
\copy input(line) from pstdin

WITH
digits(ps, vs) AS (
    SELECT string_to_array(l[1], ' '), string_to_array(l[2], ' ')
    FROM input, LATERAL string_to_array(line, ' | ') AS l
)
SELECT count(*)
FROM digits, LATERAL unnest(vs) as v
WHERE length(v) IN (2, 3, 4, 7);
