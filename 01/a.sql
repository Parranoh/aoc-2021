DROP TABLE IF EXISTS input;
CREATE TABLE input (
    id int GENERATED ALWAYS AS IDENTITY,
    n  int NOT NULL
);
\copy input(n) FROM PSTDIN

WITH inc AS (
    SELECT lag(n) OVER (ORDER BY id) < n AS increased
    FROM input
)
SELECT count (*)
FROM inc
WHERE increased;
