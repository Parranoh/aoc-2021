CREATE TEMPORARY TABLE input(
    nr   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

CREATE OR REPLACE FUNCTION charge(x int, y int, energy int[][]) RETURNS int[][] AS
$$
BEGIN
    IF energy[x][y] = 10 THEN
        RETURN energy;
    END IF;
    energy[x][y] := energy[x][y] + 1;
    IF energy[x][y] = 10 THEN
        FOR i IN greatest(x - 1, array_lower(energy, 1)) .. least(x + 1, array_upper(energy, 1)) LOOP
            FOR j IN greatest(y - 1, array_lower(energy, 2)) .. least(y + 1, array_upper(energy, 2)) LOOP
                IF x <> i OR y <> j THEN
                    energy := charge(i, j, energy);
                END IF;
            END LOOP;
        END LOOP;
    END IF;
    RETURN energy;
END;
$$
LANGUAGE PLpgSQL
IMMUTABLE;

CREATE OR REPLACE FUNCTION step(energy int[][]) RETURNS int[][] AS
$$
BEGIN
    FOR x IN array_lower(energy, 1) .. array_upper(energy, 1) LOOP
        FOR y IN array_lower(energy, 2) .. array_upper(energy, 2) LOOP
            energy := charge(x, y, energy);
        END LOOP;
    END LOOP;
    FOR x IN array_lower(energy, 1) .. array_upper(energy, 1) LOOP
        FOR y IN array_lower(energy, 2) .. array_upper(energy, 2) LOOP
            energy[x][y] := energy[x][y] % 10;
        END LOOP;
    END LOOP;
    RETURN energy;
END;
$$
LANGUAGE PLpgSQL
IMMUTABLE;

CREATE OR REPLACE FUNCTION array_sum(int[][]) RETURNS int AS
$$
    SELECT sum(x)
    FROM unnest($1) AS x
$$
LANGUAGE SQL
IMMUTABLE;

WITH RECURSIVE
steps(i, energy) AS (
    SELECT 0, array_agg(string_to_array(line, NULL)::int[] ORDER BY nr)
    FROM input
UNION ALL
    SELECT i + 1, step(energy)
    FROM steps
    WHERE array_sum(energy) <> 0
)
SELECT max(i)
FROM steps;
