DROP TABLE IF EXISTS input CASCADE;
CREATE TABLE input(
    dir  varchar(7) NOT NULL,
    dist int        NOT NULL
);
\copy input(dir, dist) from pstdin with (DELIMITER ' ')

SELECT sum(dist) FILTER (WHERE dir = 'forward')
    * sum(dist * CASE dir WHEN 'down' THEN 1 WHEN 'up' THEN -1 ELSE 0 END)
FROM input;
