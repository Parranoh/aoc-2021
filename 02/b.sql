DROP TABLE IF EXISTS input CASCADE;
CREATE TABLE input(
    id   int        GENERATED ALWAYS AS IDENTITY,
    dir  varchar(7) NOT NULL,
    dist int        NOT NULL
);
\copy input(dir, dist) from pstdin with (DELIMITER ' ')

WITH c(dist, aim, forward) AS(
    SELECT dist,
        sum(dist * CASE dir WHEN 'down' THEN 1 WHEN 'up' THEN -1 ELSE 0 END) OVER (ORDER BY id),
        dir = 'forward'
    FROM input
)
SELECT sum(dist) * sum(dist * aim)
FROM c
WHERE forward;
