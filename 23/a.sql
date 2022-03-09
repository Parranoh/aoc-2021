CREATE TEMPORARY TABLE input(
    nr   int  GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);
\copy input(line) from pstdin

WITH RECURSIVE
init(h1, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, db) AS (
    SELECT NULL::char, NULL::char, NULL::char, NULL::char, NULL::char, NULL::char, NULL::char,
        t.m[1]::char, b.m[1]::char, t.m[2]::char, b.m[2]::char, t.m[3]::char, b.m[3]::char, t.m[4]::char, b.m[4]::char
    FROM input AS i1, input AS i2,
        LATERAL (VALUES (regexp_match(i1.line, '##([A-D])#(.)#(.)#(.)##'))) AS t(m),
        LATERAL (VALUES (regexp_match(i2.line, '#(.)#(.)#(.)#(.)#'))) AS b(m)
    WHERE i1.nr + 1 = i2.nr
        AND t.m IS NOT NULL AND b.m IS NOT NULL
),
search(cost, h1, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, db) AS (
    SELECT 0, h1, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, db
    FROM init
UNION ALL
    SELECT cost + steps * (ARRAY[1,10,100,1000])[ascii(species) - 64],
        n.h1, n.h2, n.h3, n.h4, n.h5, n.h6, n.h7, n.at, n.ab, n.bt, n.bb, n.ct, n.cb, n.dt, n.db
    FROM search,
        LATERAL (VALUES
            -- move out from at                                                      if path is free                         and not already at destination{{{
            (3, at, at, h2, h3, h4, h5, h6, h7, NULL::char, ab, bt, bb, ct, cb, dt, db, coalesce(h1, h2)             IS NULL AND (at <> 'A' OR ab <> 'A')),
            (2, at, h1, at, h3, h4, h5, h6, h7, NULL::char, ab, bt, bb, ct, cb, dt, db, h2                           IS NULL AND (at <> 'A' OR ab <> 'A')),
            (2, at, h1, h2, at, h4, h5, h6, h7, NULL::char, ab, bt, bb, ct, cb, dt, db, h3                           IS NULL AND (at <> 'A' OR ab <> 'A')),
            (4, at, h1, h2, h3, at, h5, h6, h7, NULL::char, ab, bt, bb, ct, cb, dt, db, coalesce(h3, h4)             IS NULL AND (at <> 'A' OR ab <> 'A')),
            (6, at, h1, h2, h3, h4, at, h6, h7, NULL::char, ab, bt, bb, ct, cb, dt, db, coalesce(h3, h4, h5)         IS NULL AND (at <> 'A' OR ab <> 'A')),
            (8, at, h1, h2, h3, h4, h5, at, h7, NULL::char, ab, bt, bb, ct, cb, dt, db, coalesce(h3, h4, h5, h6)     IS NULL AND (at <> 'A' OR ab <> 'A')),
            (9, at, h1, h2, h3, h4, h5, h6, at, NULL::char, ab, bt, bb, ct, cb, dt, db, coalesce(h3, h4, h5, h6, h7) IS NULL AND (at <> 'A' OR ab <> 'A')),--}}}
            -- move out from ab{{{
            ( 4, ab, ab, h2, h3, h4, h5, h6, h7, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h1, h2)             IS NULL AND ab <> 'A'),
            ( 3, ab, h1, ab, h3, h4, h5, h6, h7, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h2)                 IS NULL AND ab <> 'A'),
            ( 3, ab, h1, h2, ab, h4, h5, h6, h7, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h3)                 IS NULL AND ab <> 'A'),
            ( 5, ab, h1, h2, h3, ab, h5, h6, h7, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4)             IS NULL AND ab <> 'A'),
            ( 7, ab, h1, h2, h3, h4, ab, h6, h7, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4, h5)         IS NULL AND ab <> 'A'),
            ( 9, ab, h1, h2, h3, h4, h5, ab, h7, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4, h5, h6)     IS NULL AND ab <> 'A'),
            (10, ab, h1, h2, h3, h4, h5, h6, ab, at, NULL::char, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4, h5, h6, h7) IS NULL AND ab <> 'A'),--}}}
            -- move out from bt{{{
            (5, bt, bt, h2, h3, h4, h5, h6, h7, at, ab, NULL::char, bb, ct, cb, dt, db, coalesce(h1, h2, h3)     IS NULL AND (bt <> 'B' OR bb <> 'B')),
            (4, bt, h1, bt, h3, h4, h5, h6, h7, at, ab, NULL::char, bb, ct, cb, dt, db, coalesce(h2, h3)         IS NULL AND (bt <> 'B' OR bb <> 'B')),
            (2, bt, h1, h2, bt, h4, h5, h6, h7, at, ab, NULL::char, bb, ct, cb, dt, db, h3                       IS NULL AND (bt <> 'B' OR bb <> 'B')),
            (2, bt, h1, h2, h3, bt, h5, h6, h7, at, ab, NULL::char, bb, ct, cb, dt, db, h4                       IS NULL AND (bt <> 'B' OR bb <> 'B')),
            (4, bt, h1, h2, h3, h4, bt, h6, h7, at, ab, NULL::char, bb, ct, cb, dt, db, coalesce(h4, h5)         IS NULL AND (bt <> 'B' OR bb <> 'B')),
            (6, bt, h1, h2, h3, h4, h5, bt, h7, at, ab, NULL::char, bb, ct, cb, dt, db, coalesce(h4, h5, h6)     IS NULL AND (bt <> 'B' OR bb <> 'B')),
            (7, bt, h1, h2, h3, h4, h5, h6, bt, at, ab, NULL::char, bb, ct, cb, dt, db, coalesce(h4, h5, h6, h7) IS NULL AND (bt <> 'B' OR bb <> 'B')),--}}}
            -- move out from bb{{{
            (6, bb, bb, h2, h3, h4, h5, h6, h7, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h1, h2, h3)     IS NULL AND bb <> 'B'),
            (5, bb, h1, bb, h3, h4, h5, h6, h7, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h2, h3)         IS NULL AND bb <> 'B'),
            (3, bb, h1, h2, bb, h4, h5, h6, h7, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h3)             IS NULL AND bb <> 'B'),
            (3, bb, h1, h2, h3, bb, h5, h6, h7, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h4)             IS NULL AND bb <> 'B'),
            (5, bb, h1, h2, h3, h4, bb, h6, h7, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h4, h5)         IS NULL AND bb <> 'B'),
            (7, bb, h1, h2, h3, h4, h5, bb, h7, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h4, h5, h6)     IS NULL AND bb <> 'B'),
            (8, bb, h1, h2, h3, h4, h5, h6, bb, at, ab, bt, NULL::char, ct, cb, dt, db, coalesce(bt, h4, h5, h6, h7) IS NULL AND bb <> 'B'),--}}}
            -- move out from ct{{{
            (7, ct, bt, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, NULL::char, cb, dt, db, coalesce(h1, h2, h3, h4) IS NULL AND (ct <> 'C' OR cb <> 'C')),
            (6, ct, h1, bt, h3, h4, h5, h6, h7, at, ab, bt, bb, NULL::char, cb, dt, db, coalesce(h2, h3, h4)     IS NULL AND (ct <> 'C' OR cb <> 'C')),
            (4, ct, h1, h2, bt, h4, h5, h6, h7, at, ab, bt, bb, NULL::char, cb, dt, db, coalesce(h3, h4)         IS NULL AND (ct <> 'C' OR cb <> 'C')),
            (2, ct, h1, h2, h3, bt, h5, h6, h7, at, ab, bt, bb, NULL::char, cb, dt, db, h4                       IS NULL AND (ct <> 'C' OR cb <> 'C')),
            (2, ct, h1, h2, h3, h4, bt, h6, h7, at, ab, bt, bb, NULL::char, cb, dt, db, h5                       IS NULL AND (ct <> 'C' OR cb <> 'C')),
            (4, ct, h1, h2, h3, h4, h5, bt, h7, at, ab, bt, bb, NULL::char, cb, dt, db, coalesce(h5, h6)         IS NULL AND (ct <> 'C' OR cb <> 'C')),
            (5, ct, h1, h2, h3, h4, h5, h6, bt, at, ab, bt, bb, NULL::char, cb, dt, db, coalesce(h5, h6, h7)     IS NULL AND (ct <> 'C' OR cb <> 'C')),--}}}
            -- move out from cb{{{
            (8, cb, bb, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h1, h2, h3, h4) IS NULL AND cb <> 'C'),
            (7, cb, h1, bb, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h2, h3, h4)     IS NULL AND cb <> 'C'),
            (5, cb, h1, h2, bb, h4, h5, h6, h7, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h3, h4)         IS NULL AND cb <> 'C'),
            (3, cb, h1, h2, h3, bb, h5, h6, h7, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h4)             IS NULL AND cb <> 'C'),
            (3, cb, h1, h2, h3, h4, bb, h6, h7, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h5)             IS NULL AND cb <> 'C'),
            (5, cb, h1, h2, h3, h4, h5, bb, h7, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h5, h6)         IS NULL AND cb <> 'C'),
            (6, cb, h1, h2, h3, h4, h5, h6, bb, at, ab, bt, bb, ct, NULL::char, dt, db, coalesce(ct, h5, h6, h7)     IS NULL AND cb <> 'C'),--}}}
            -- move out from dt{{{
            (9, dt, bt, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, NULL::char, db, coalesce(h1, h2, h3, h4, h5) IS NULL AND (dt <> 'D' OR db <> 'D')),
            (8, dt, h1, bt, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, NULL::char, db, coalesce(h2, h3, h4, h5)     IS NULL AND (dt <> 'D' OR db <> 'D')),
            (6, dt, h1, h2, bt, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, NULL::char, db, coalesce(h3, h4, h5)         IS NULL AND (dt <> 'D' OR db <> 'D')),
            (4, dt, h1, h2, h3, bt, h5, h6, h7, at, ab, bt, bb, ct, cb, NULL::char, db, coalesce(h4, h5)             IS NULL AND (dt <> 'D' OR db <> 'D')),
            (2, dt, h1, h2, h3, h4, bt, h6, h7, at, ab, bt, bb, ct, cb, NULL::char, db, h5                           IS NULL AND (dt <> 'D' OR db <> 'D')),
            (2, dt, h1, h2, h3, h4, h5, bt, h7, at, ab, bt, bb, ct, cb, NULL::char, db, h6                           IS NULL AND (dt <> 'D' OR db <> 'D')),
            (3, dt, h1, h2, h3, h4, h5, h6, bt, at, ab, bt, bb, ct, cb, NULL::char, db, coalesce(h6, h7)             IS NULL AND (dt <> 'D' OR db <> 'D')),--}}}
            -- move out from db{{{
            (10, db, bb, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h1, h2, h3, h4, h5) IS NULL AND db <> 'D'),
            ( 9, db, h1, bb, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h2, h3, h4, h5)     IS NULL AND db <> 'D'),
            ( 7, db, h1, h2, bb, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h3, h4, h5)         IS NULL AND db <> 'D'),
            ( 5, db, h1, h2, h3, bb, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h4, h5)             IS NULL AND db <> 'D'),
            ( 3, db, h1, h2, h3, h4, bb, h6, h7, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h5)                 IS NULL AND db <> 'D'),
            ( 3, db, h1, h2, h3, h4, h5, bb, h7, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h6)                 IS NULL AND db <> 'D'),
            ( 4, db, h1, h2, h3, h4, h5, h6, bb, at, ab, bt, bb, ct, cb, dt, NULL::char, coalesce(dt, h6, h7)             IS NULL AND db <> 'D'),--}}}
            -- move in to at                                                              if path is free                                   and can stay there{{{
            (3, 'A'::char, NULL::char, h2, h3, h4, h5, h6, h7, 'A'::char, ab, bt, bb, ct, cb, dt, db, coalesce(at, h2)             IS NULL AND h1 = 'A' AND ab = 'A'),
            (2, 'A'::char, h1, NULL::char, h3, h4, h5, h6, h7, 'A'::char, ab, bt, bb, ct, cb, dt, db, at                           IS NULL AND h2 = 'A' AND ab = 'A'),
            (2, 'A'::char, h1, h2, NULL::char, h4, h5, h6, h7, 'A'::char, ab, bt, bb, ct, cb, dt, db, at                           IS NULL AND h3 = 'A' AND ab = 'A'),
            (4, 'A'::char, h1, h2, h3, NULL::char, h5, h6, h7, 'A'::char, ab, bt, bb, ct, cb, dt, db, coalesce(at, h3)             IS NULL AND h4 = 'A' AND ab = 'A'),
            (6, 'A'::char, h1, h2, h3, h4, NULL::char, h6, h7, 'A'::char, ab, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4)         IS NULL AND h5 = 'A' AND ab = 'A'),
            (8, 'A'::char, h1, h2, h3, h4, h5, NULL::char, h7, 'A'::char, ab, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4, h5)     IS NULL AND h6 = 'A' AND ab = 'A'),
            (9, 'A'::char, h1, h2, h3, h4, h5, h6, NULL::char, 'A'::char, ab, bt, bb, ct, cb, dt, db, coalesce(at, h3, h4, h5, h6) IS NULL AND h7 = 'A' AND ab = 'A'),--}}}
            -- move in to ab{{{
            ( 4, 'A'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, 'A'::char, bt, bb, ct, cb, dt, db, coalesce(ab, h2)             IS NULL AND h1 = 'A'),
            ( 3, 'A'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, 'A'::char, bt, bb, ct, cb, dt, db, ab                           IS NULL AND h2 = 'A'),
            ( 3, 'A'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, 'A'::char, bt, bb, ct, cb, dt, db, ab                           IS NULL AND h3 = 'A'),
            ( 5, 'A'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, 'A'::char, bt, bb, ct, cb, dt, db, coalesce(ab, h3)             IS NULL AND h4 = 'A'),
            ( 7, 'A'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, 'A'::char, bt, bb, ct, cb, dt, db, coalesce(ab, h3, h4)         IS NULL AND h5 = 'A'),
            ( 9, 'A'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, 'A'::char, bt, bb, ct, cb, dt, db, coalesce(ab, h3, h4, h5)     IS NULL AND h6 = 'A'),
            (10, 'A'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, 'A'::char, bt, bb, ct, cb, dt, db, coalesce(ab, h3, h4, h5, h6) IS NULL AND h7 = 'A'),--}}}
            -- move in to bt{{{
            (5, 'B'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, ab, 'B'::char, bb, ct, cb, dt, db, coalesce(bt, h2, h3)     IS NULL AND h1 = 'B' AND bb = 'B'),
            (4, 'B'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, ab, 'B'::char, bb, ct, cb, dt, db, coalesce(bt, h3)         IS NULL AND h2 = 'B' AND bb = 'B'),
            (2, 'B'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, ab, 'B'::char, bb, ct, cb, dt, db, bt                       IS NULL AND h3 = 'B' AND bb = 'B'),
            (2, 'B'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, ab, 'B'::char, bb, ct, cb, dt, db, bt                       IS NULL AND h4 = 'B' AND bb = 'B'),
            (4, 'B'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, ab, 'B'::char, bb, ct, cb, dt, db, coalesce(bt, h4)         IS NULL AND h5 = 'B' AND bb = 'B'),
            (6, 'B'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, ab, 'B'::char, bb, ct, cb, dt, db, coalesce(bt, h4, h5)     IS NULL AND h6 = 'B' AND bb = 'B'),
            (7, 'B'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, ab, 'B'::char, bb, ct, cb, dt, db, coalesce(bt, h4, h5, h6) IS NULL AND h7 = 'B' AND bb = 'B'),--}}}
            -- move in to bb{{{
            (6, 'B'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, ab, bt, 'B'::char, ct, cb, dt, db, coalesce(bb, h2, h3)     IS NULL AND h1 = 'B'),
            (5, 'B'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, ab, bt, 'B'::char, ct, cb, dt, db, coalesce(bb, h3)         IS NULL AND h2 = 'B'),
            (3, 'B'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, ab, bt, 'B'::char, ct, cb, dt, db, bb                       IS NULL AND h3 = 'B'),
            (3, 'B'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, ab, bt, 'B'::char, ct, cb, dt, db, bb                       IS NULL AND h4 = 'B'),
            (5, 'B'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, ab, bt, 'B'::char, ct, cb, dt, db, coalesce(bb, h4)         IS NULL AND h5 = 'B'),
            (7, 'B'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, ab, bt, 'B'::char, ct, cb, dt, db, coalesce(bb, h4, h5)     IS NULL AND h6 = 'B'),
            (8, 'B'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, ab, bt, 'B'::char, ct, cb, dt, db, coalesce(bb, h4, h5, h6) IS NULL AND h7 = 'B'),--}}}
            -- move in to ct{{{
            (7, 'C'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, 'C'::char, cb, dt, db, coalesce(ct, h2, h3, h4) IS NULL AND h1 = 'C' AND cb = 'C'),
            (6, 'C'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, ab, bt, bb, 'C'::char, cb, dt, db, coalesce(ct, h3, h4)     IS NULL AND h2 = 'C' AND cb = 'C'),
            (4, 'C'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, ab, bt, bb, 'C'::char, cb, dt, db, coalesce(ct, h4)         IS NULL AND h3 = 'C' AND cb = 'C'),
            (2, 'C'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, ab, bt, bb, 'C'::char, cb, dt, db, ct                       IS NULL AND h4 = 'C' AND cb = 'C'),
            (2, 'C'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, ab, bt, bb, 'C'::char, cb, dt, db, ct                       IS NULL AND h5 = 'C' AND cb = 'C'),
            (4, 'C'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, ab, bt, bb, 'C'::char, cb, dt, db, coalesce(ct, h5)         IS NULL AND h6 = 'C' AND cb = 'C'),
            (5, 'C'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, ab, bt, bb, 'C'::char, cb, dt, db, coalesce(ct, h5, h6)     IS NULL AND h7 = 'C' AND cb = 'C'),--}}}
            -- move in to cb{{{
            (8, 'C'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, 'C'::char, dt, db, coalesce(cb, h2, h3, h4) IS NULL AND h1 = 'C'),
            (7, 'C'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, 'C'::char, dt, db, coalesce(cb, h3, h4)     IS NULL AND h2 = 'C'),
            (5, 'C'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, ab, bt, bb, ct, 'C'::char, dt, db, coalesce(cb, h4)         IS NULL AND h3 = 'C'),
            (3, 'C'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, ab, bt, bb, ct, 'C'::char, dt, db, cb                       IS NULL AND h4 = 'C'),
            (3, 'C'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, ab, bt, bb, ct, 'C'::char, dt, db, cb                       IS NULL AND h5 = 'C'),
            (5, 'C'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, ab, bt, bb, ct, 'C'::char, dt, db, coalesce(cb, h5)         IS NULL AND h6 = 'C'),
            (6, 'C'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, ab, bt, bb, ct, 'C'::char, dt, db, coalesce(cb, h5, h6)     IS NULL AND h7 = 'C'),--}}}
            -- move in to dt{{{
            (9, 'D'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, 'D'::char, db, coalesce(dt, h2, h3, h4, h5) IS NULL AND h1 = 'D' AND db = 'D'),
            (8, 'D'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, 'D'::char, db, coalesce(dt, h3, h4, h5)     IS NULL AND h2 = 'D' AND db = 'D'),
            (6, 'D'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, 'D'::char, db, coalesce(dt, h4, h5)         IS NULL AND h3 = 'D' AND db = 'D'),
            (4, 'D'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, ab, bt, bb, ct, cb, 'D'::char, db, coalesce(dt, h5)             IS NULL AND h4 = 'D' AND db = 'D'),
            (2, 'D'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, ab, bt, bb, ct, cb, 'D'::char, db, dt                           IS NULL AND h5 = 'D' AND db = 'D'),
            (2, 'D'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, ab, bt, bb, ct, cb, 'D'::char, db, dt                           IS NULL AND h6 = 'D' AND db = 'D'),
            (3, 'D'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, ab, bt, bb, ct, cb, 'D'::char, db, coalesce(dt, h6)             IS NULL AND h7 = 'D' AND db = 'D'),--}}}
            -- move in to db{{{
            (10, 'D'::char, NULL::char, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, 'D'::char, coalesce(db, h2, h3, h4, h5) IS NULL AND h1 = 'D'),
            ( 9, 'D'::char, h1, NULL::char, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, 'D'::char, coalesce(db, h3, h4, h5)     IS NULL AND h2 = 'D'),
            ( 7, 'D'::char, h1, h2, NULL::char, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, 'D'::char, coalesce(db, h4, h5)         IS NULL AND h3 = 'D'),
            ( 5, 'D'::char, h1, h2, h3, NULL::char, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, 'D'::char, coalesce(db, h5)             IS NULL AND h4 = 'D'),
            ( 3, 'D'::char, h1, h2, h3, h4, NULL::char, h6, h7, at, ab, bt, bb, ct, cb, dt, 'D'::char, db                           IS NULL AND h5 = 'D'),
            ( 3, 'D'::char, h1, h2, h3, h4, h5, NULL::char, h7, at, ab, bt, bb, ct, cb, dt, 'D'::char, db                           IS NULL AND h6 = 'D'),
            ( 4, 'D'::char, h1, h2, h3, h4, h5, h6, NULL::char, at, ab, bt, bb, ct, cb, dt, 'D'::char, coalesce(db, h6)             IS NULL AND h7 = 'D')--}}}
        ) AS n(steps, species, h1, h2, h3, h4, h5, h6, h7, at, ab, bt, bb, ct, cb, dt, db, "include?")
    WHERE "include?" AND species IS NOT NULL
)
SELECT min(cost)
FROM search
WHERE at = 'A' AND ab = 'A'
    AND bt = 'B' AND bb = 'B'
    AND ct = 'C' AND cb = 'C'
    AND dt = 'D' AND db = 'D';
