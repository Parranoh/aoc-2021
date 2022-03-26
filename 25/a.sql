CREATE TEMPORARY TABLE input (
    nr   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
dims(x, y) AS (
    SELECT max(length(line)), count(*)
    FROM input
),
history(t, x, y, state, change) AS (
    SELECT 0, x, nr - min(nr) OVER () + 1, state::char, TRUE
    FROM input, string_to_table(line, NULL) WITH ORDINALITY AS _(state, x)
UNION ALL SELECT * FROM (WITH
    history(t, x, y, state) AS (TABLE history),
    change(change_agg) AS (SELECT bool_or(change) FROM history)
    SELECT h.t + 1, h.x, h.y, new.state, h.state <> new.state
    FROM history AS h, history AS t, history AS b, history AS l, history AS r,
        history AS bl, history AS br, dims AS d, change,
        LATERAL (VALUES (CASE
            WHEN l.state = '>' AND h.state = '.'
                THEN l.state
            WHEN h.state = '.' AND t.state = 'v' AND l.state <> '>'
                THEN t.state
            WHEN h.state = '>' AND t.state = 'v' AND r.state = '.'
                THEN t.state
            WHEN h.state = '>' AND r.state = '>'
                THEN h.state
            WHEN h.state = '>' AND r.state = 'v'
                THEN h.state
            WHEN h.state = 'v' AND b.state = 'v'
                THEN h.state
            WHEN h.state = 'v' AND b.state = '.' AND bl.state = '>'
                THEN h.state
            WHEN h.state = 'v' AND b.state = '>' AND br.state <> '.'
                THEN h.state
            ELSE '.'::char
        END)) AS new(state)
    WHERE change_agg
        AND h.x = t.x AND (h.y = t.y + 1 OR h.y = 1 AND t.y = d.y)
        AND h.x = b.x AND (h.y = b.y - 1 OR h.y = d.y AND b.y = 1)
        AND (h.x = l.x + 1 OR h.x = 1 AND l.x = d.x) AND h.y = l.y
        AND (h.x = r.x - 1 OR h.x = d.x AND r.x = 1) AND h.y = r.y
        AND bl.x = l.x AND bl.y = b.y
        AND br.x = r.x AND br.y = b.y
) AS rec)
SELECT max(t)
FROM history;
