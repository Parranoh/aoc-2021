CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

WITH RECURSIVE
edges(tail, head, "to_big?") AS (
    SELECT tail, head, upper(head) = head
    FROM input,
        LATERAL (VALUES (string_to_array(line, '-'))) AS _(e),
        LATERAL (VALUES (e[1], e[2]), (e[2], e[1])) AS __(tail, head)
    WHERE tail <> 'end' AND head <> 'start'
),
paths(p, "duplicate?") AS (
    SELECT ARRAY['start'], FALSE
UNION ALL
    SELECT p || head, "duplicate?" OR NOT ("to_big?" OR head <> ALL(p))
    FROM paths
        JOIN edges ON p[array_length(p, 1)] = tail
    WHERE "to_big?"
        OR NOT "duplicate?"
        OR head <> ALL(p)
)
SELECT count(*)
FROM paths
WHERE p[array_length(p, 1)] = 'end';
