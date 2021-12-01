DROP TABLE IF EXISTS input;
CREATE TABLE input (
    id int GENERATED ALWAYS AS IDENTITY,
    n  int NOT NULL
);
\copy input(n) FROM PSTDIN

WITH three AS (
    SELECT
        id,
        sum(n) OVER w AS sum,
        count(*) OVER w as count
    FROM input
    WINDOW w AS (ORDER BY id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
), inc AS (
    SELECT lag(sum) OVER (ORDER BY id) < sum AS increased
    FROM three
    WHERE count = 3
)
SELECT count (*)
FROM inc
WHERE increased;
