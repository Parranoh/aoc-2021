CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
starting_pos(p1, p2) AS (
    SELECT substring(i1.line FROM '\d+$')::int, substring(i2.line FROM '\d+$')::int
    FROM input AS i1, input AS i2
    WHERE i1.id < i2.id
),
history(num_rolls, p1, p2, s1, s2, "next1?") AS (
    SELECT 0, p1, p2, 0, 0, TRUE
    FROM starting_pos
UNION ALL
    SELECT num_rolls + 3,
        CASE WHEN "next1?" THEN (p1 + 3 * num_rolls + 6 - 1) % 10 + 1 ELSE p1 END,
        CASE WHEN "next1?" THEN p2 ELSE (p2 + 3 * num_rolls + 6 - 1) % 10 + 1 END,
        CASE WHEN "next1?" THEN s1 + (p1 + 3 * num_rolls + 6 - 1) % 10 + 1 ELSE s1 END,
        CASE WHEN "next1?" THEN s2 ELSE s2 + (p2 + 3 * num_rolls + 6 - 1) % 10 + 1 END,
        NOT "next1?"
    FROM history
    WHERE greatest(s1, s2) < 1000
)
SELECT least(s1, s2) * num_rolls
FROM history
WHERE num_rolls = (SELECT max(num_rolls) FROM history);
