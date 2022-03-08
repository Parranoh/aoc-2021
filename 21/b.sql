CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

\set SCORE_LIMIT 21

WITH RECURSIVE
starting_pos(p1, p2) AS (
    SELECT substring(i1.line FROM '\d+$')::int, substring(i2.line FROM '\d+$')::int
    FROM input AS i1, input AS i2
    WHERE i1.id < i2.id
),
history(p1, p2, s1, s2, "next1?", num) AS (
    SELECT p1, p2, 0, 0, TRUE, 1::numeric
    FROM starting_pos
UNION ALL SELECT * FROM (
    WITH
    expand(p1, p2, s1, s2, n, num) AS (
        SELECT
            CASE WHEN "next1?" THEN (p1 + r1 + r2 + r3 - 1) % 10 + 1 ELSE p1 END,
            CASE WHEN "next1?" THEN p2 ELSE (p2 + r1 + r2 + r3 - 1) % 10 + 1 END,
            CASE WHEN "next1?" THEN s1 + (p1 + r1 + r2 + r3 - 1) % 10 + 1 ELSE s1 END,
            CASE WHEN "next1?" THEN s2 ELSE s2 + (p2 + r1 + r2 + r3 - 1) % 10 + 1 END,
            NOT "next1?",
            num
        FROM history,
            (VALUES (1), (2), (3)) AS r1(r1),
            (VALUES (1), (2), (3)) AS r2(r2),
            (VALUES (1), (2), (3)) AS r3(r3)
        WHERE greatest(s1, s2) < :SCORE_LIMIT
    )
    SELECT p1, p2, s1, s2, n, sum(num)
    FROM expand
    GROUP BY p1, p2, s1, s2, n
) AS rec)
SELECT greatest(sum(num) FILTER (WHERE s1 >= :SCORE_LIMIT), sum(num) FILTER (WHERE s2 >= :SCORE_LIMIT))
FROM history;
