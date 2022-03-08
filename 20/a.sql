CREATE TEMPORARY TABLE input (
    nr   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

\set N 2

WITH RECURSIVE
rule(pattern, result) AS (
    SELECT ix - 1, c = '#'
    FROM input, LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(c, ix)
    WHERE nr = (SELECT min(nr) FROM input)
),
infinity_rule("toggles?") AS (
    SELECT result
    FROM rule
    WHERE pattern = 0
),
sep(nr) AS (
    SELECT nr
    FROM input
    WHERE line = ''
),
init(x, y, "alive?") AS (
    SELECT x, input.nr - sep.nr, c = '#'
    FROM input, sep,
        LATERAL unnest(string_to_array(line, NULL)) WITH ORDINALITY AS _(c, x)
    WHERE input.nr > sep.nr
),
bounds(x_max, y_max) AS (
    SELECT max(x), max(y)
    FROM init
),
history(i, x, y, "alive?") AS (
    SELECT 0, x, y, "alive?"
    FROM init
UNION ALL SELECT * FROM (
    WITH
    history(i, x, y, "alive?") AS (TABLE history),
    iter(i, pai) AS (
        SELECT i, "toggles?" AND i % 2 = 1
        FROM history, infinity_rule
        WHERE i < :N
        LIMIT 1
    ),
    prev(x, y, "alive?") AS (
        SELECT x, y, "alive?"
        FROM history
    UNION ALL
        SELECT x, tb, pai
        FROM bounds, iter,
            LATERAL generate_series(0 - i, x_max + i + 1) AS x,
            LATERAL (VALUES (0 - i), (y_max + i + 1)) AS let(tb)
    UNION ALL
        SELECT lr, y, pai
        FROM bounds, iter,
            LATERAL generate_series(1 - i, y_max + i) AS y,
            LATERAL (VALUES (0 - i), (x_max + i + 1)) AS let(lr)
    )
    SELECT i + 1, x, y, result
    FROM iter, rule NATURAL JOIN (
        SELECT x, y, lag("alive?", 1, pai) OVER nwse::int * 256
            + lag ("alive?", 1, pai) OVER   ns::int * 128
            + lead("alive?", 1, pai) OVER swne::int * 64
            + lag ("alive?", 1, pai) OVER   we::int * 32
            +                         "alive?"::int * 16
            + lead("alive?", 1, pai) OVER   we::int * 8
            + lag ("alive?", 1, pai) OVER swne::int * 4
            + lead("alive?", 1, pai) OVER   ns::int * 2
            + lead("alive?", 1, pai) OVER nwse::int * 1
        FROM prev, iter
        WINDOW
            ns   AS (PARTITION BY x ORDER BY y),
            we   AS (PARTITION BY y ORDER BY x),
            nwse AS (PARTITION BY x - y ORDER BY x),
            swne AS (PARTITION BY x + y ORDER BY x)
    ) AS prev(x, y, pattern)
) AS rec)
SELECT count(*)
FROM history
WHERE i = :N AND "alive?";
