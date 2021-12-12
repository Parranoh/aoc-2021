CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

CREATE OR REPLACE FUNCTION all_lower_distinct(a text[]) RETURNS bool AS
$$
    SELECT coalesce(bool_and(a1.v <> a2.v), TRUE)
    FROM unnest(a) WITH ORDINALITY AS a1(v,ix),
        LATERAL unnest(a) WITH ORDINALITY AS a2(v,ix)
    WHERE a1.ix <> a2.ix
        AND a1.v = lower(a1.v)
        AND a2.v = lower(a2.v)
$$
LANGUAGE SQL
IMMUTABLE;

WITH RECURSIVE
edges(tail, head, "to_big?") AS (
    SELECT tail, head, upper(head) = head
    FROM input,
        LATERAL (VALUES (string_to_array(line, '-'))) AS _(e),
        LATERAL (VALUES (e[1], e[2]), (e[2], e[1])) AS __(tail, head)
    WHERE tail <> 'end' AND head <> 'start'
),
paths(p) AS (
    SELECT ARRAY['start']
UNION ALL
    SELECT p || head
    FROM paths
        JOIN edges ON p[array_length(p, 1)] = tail
    WHERE "to_big?"
        OR head <> ALL(p)
        OR all_lower_distinct(p)
)
SELECT count(*)
FROM paths
WHERE p[array_length(p, 1)] = 'end';
