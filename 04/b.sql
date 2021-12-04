DROP TABLE IF EXISTS input, numbers, boards CASCADE;
CREATE TABLE input(
    nr   int  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

CREATE TABLE numbers(
    id int PRIMARY KEY,
    n  int NOT NULL
);
INSERT INTO numbers
SELECT id, n::int
FROM input, LATERAL string_to_table(line, ',') WITH ORDINALITY AS _(n, id)
WHERE nr = 1;

CREATE TABLE boards(
    id  int,
    row int,
    col int,
    n   int NOT NULL,
    PRIMARY KEY (id,row,col)
);
INSERT INTO boards
SELECT (nr + 3) / 6, (nr - 2) % 6, col, n::int
FROM input, LATERAL regexp_split_to_table(trim(line), '\s+') WITH ORDINALITY AS _(n, col)
WHERE nr <> 1
    AND nr % 6 <> 2;

WITH RECURSIVE
marked(i, board, row, col, n, "marked?") AS (
    SELECT 0, id, row, col, n, false
    FROM boards
        UNION ALL
    SELECT i + 1, board, row, col, m.n, "marked?" OR m.n = n.n
    FROM marked AS m, numbers AS n
    WHERE i + 1 = id
),
won(i, board) AS (
    SELECT i, board
    FROM marked
    GROUP BY i, board, GROUPING SETS ((row), (col))
    HAVING count(*) FILTER (WHERE "marked?") >= 5
),
loser(i, board) AS (
    SELECT min(i), board
    FROM won
    GROUP BY board
    ORDER BY min(i) DESC
    LIMIT 1
)
SELECT sum(m.n) * n.n
FROM loser AS l, marked AS m, numbers AS n
WHERE l.i = m.i
    AND l.i = n.id
    AND l.board = m.board
    AND NOT m."marked?"
GROUP BY n.n;
