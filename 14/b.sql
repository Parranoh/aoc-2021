CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

\set N 40

WITH RECURSIVE
template(prev, element) AS (
    SELECT lag(e) OVER (ORDER BY ix), e
    FROM input,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(e, ix)
    WHERE length(line) > 0
        AND position('-' IN line) = 0
),
rules(prev, element, new) AS (
    SELECT m[1]::char(1), m[2]::char(1), m[3]::char(1)
    FROM input,
        LATERAL (VALUES (regexp_match(line, '(.)(.) -> (.)'))) AS let(m)
    WHERE position('-' IN line) <> 0
),
process(i, prev, element, count) AS (
    SELECT 0, prev, element, count(*)
    FROM template
    GROUP BY prev, element
UNION ALL SELECT * FROM (WITH process(i, prev, element, count) AS (TABLE process)
    SELECT i + 1, n.prev, n.element, sum(count)::bigint
    FROM process AS p NATURAL LEFT JOIN rules,
        LATERAL (VALUES (prev, new), (new, element)) AS n(prev, element)
    WHERE i < :N
        AND n.element IS NOT NULL
    GROUP BY i, n.prev, n.element
) AS rec),
counts(element, n) AS (
    SELECT element, sum(count)
    FROM process
    WHERE i = :N
    GROUP BY element
)
SELECT max(n) - min(n)
FROM counts;
