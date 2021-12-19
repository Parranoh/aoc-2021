CREATE TEMPORARY TABLE input(line text NOT NULL);
\copy input(line) from pstdin

SELECT y_min * (y_min + 1) / 2
FROM input,
    LATERAL (VALUES ((regexp_match(line, 'y=([0-9-]+)'))[1]::int)) AS let(y_min);
