CREATE TEMPORARY TABLE input(
    id   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH
patterns(id, ps) AS (
    SELECT id, string_to_array(l[1], ' ')
    FROM input,
        LATERAL string_to_array(line, ' | ') AS l
),
outputs(id, vs) AS (
    SELECT id, string_to_array(l[2], ' ')
    FROM input,
        LATERAL string_to_array(line, ' | ') AS l
),
count_segments(id, seg, count) AS (
    SELECT id, s, count(*)
    FROM patterns,
        LATERAL unnest(ps) AS p,
        LATERAL unnest(string_to_array(p, NULL)) AS s
    GROUP BY id, s
),
easy_segments(id, inseg, outseg) AS (
    SELECT id, seg, (ARRAY[NULL, NULL, NULL, 'e', NULL, 'b', NULL, NULL, 'f'])[count]
    FROM count_segments
    WHERE count IN (4, 6, 9)
),
easy_digits(id, instring, outdigit) AS (
    SELECT id, p, (ARRAY[NULL, 1, 7, 4, NULL, NULL, 8])[length(p)]
    FROM patterns,
        LATERAL unnest(ps) AS p
    WHERE length(p) IN (2, 3, 4, 7)
),
segments(id, inseg, outseg) AS (
    TABLE easy_segments
UNION ALL
    SELECT id, seg, CASE position(seg IN instring) WHEN 0 THEN 'a' ELSE 'c' END
    FROM count_segments NATURAL JOIN easy_digits
    WHERE outdigit = 1
        AND count = 8
UNION ALL
    SELECT id, seg, CASE position(seg IN instring) WHEN 0 THEN 'g' ELSE 'd' END
    FROM count_segments NATURAL JOIN easy_digits
    WHERE outdigit = 4
        AND count = 7
),
translated_outputs(id, place, outv) AS (
    SELECT id, array_length(vs, 1) - ix, string_agg(outseg, NULL ORDER BY outseg)
    FROM segments NATURAL JOIN outputs,
        LATERAL unnest(vs) WITH ORDINALITY AS _(v, ix),
        LATERAL unnest(string_to_array(v, NULL)) AS s
    WHERE inseg = s
    GROUP BY id, ix, vs
),
nums(id, n) AS (
    SELECT id,
                               -- 0        1    2       3       4      5       6       7      8         9
        sum(array_position(ARRAY['abcefg','cf','acdeg','acdfg','bcdf','abdfg','abdefg','acf','abcdefg','abcdfg'], outv) - 1 * 10^place)
    FROM digits
    GROUP BY id
)
SELECT sum(n)
FROM nums;
