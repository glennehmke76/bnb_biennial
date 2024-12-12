-- 4/2/24 added geom to routes review to use as primary layer in GIS

-- begin table and add consistified routes (with geometries)
DROP TABLE IF EXISTS routes_master CASCADE;
CREATE TABLE routes_master AS
WITH mean_route_x AS
  (SELECT
  route_id,
  AVG(ST_X
    (ST_Transform
      (ST_Centroid(geom), 4283))) AS x
  FROM routes_provided_consistent
  GROUP BY
    route_id
  )
SELECT
  sub.region_name,
  sub.route_id,
  sub.surv_year,
  routes_provided_consistent.geom AS geom_provided,
  sub.route_length_provided,
  CASE
    WHEN provided_vs_consistent.delta BETWEEN -1 AND 1 THEN NULL
    ELSE provided_vs_consistent.delta
  END AS delta_provided_vs_consistent,
  mean_route_x.x AS centroid_x,
  'provided routes' AS route_source
FROM
    (SELECT
      routes_provided.region_name,
      routes_provided_consistent.route_id,
      routes_provided_consistent.surv_year,
      SUM(routes_provided_consistent.route_length) AS route_length_provided
      -- list of habitats in route possible with %'s in single field
    FROM routes_provided_consistent
    JOIN routes_provided
      ON routes_provided_consistent.route_id = routes_provided.route_id
      AND routes_provided_consistent.surv_year = routes_provided.surv_year
    GROUP BY
      routes_provided.region_name,
      routes_provided_consistent.route_id,
      routes_provided_consistent.surv_year
    )sub
JOIN mean_route_x ON sub.route_id = mean_route_x.route_id
JOIN provided_vs_consistent
  ON sub.route_id = provided_vs_consistent.route_id
  AND sub.surv_year = provided_vs_consistent.surv_year
JOIN routes_provided_consistent
  ON sub.route_id = routes_provided_consistent.route_id
  AND sub.surv_year = routes_provided_consistent.surv_year
ORDER BY
  mean_route_x.x DESC,
  sub.route_id,
  sub.surv_year DESC
;
alter table public.routes_master
    alter column surv_year type integer using surv_year::integer;
alter table public.routes_master
    add route_name_2500 varchar;
alter table public.routes_master
    add route_name_500 varchar;
create index routes_master_route_id_index
    on public.routes_master (route_id);
create index routes_master_surv_year_index
    on public.routes_master (surv_year);
alter table public.routes_master
    add route_length_derived_2500 integer,
    add route_length_derived_500 integer
;

-- add other geoms
alter table public.routes_master
  add geom_derived_2500 geometry,
  add geom_derived_500 geometry
;

-- add derived routes from start/finish-point lines by permutation
  -- do 500m buffer perm 1st as this is likely the best
  INSERT INTO routes_master (route_id, surv_year, route_length_derived_500, route_name_500, geom_derived_500, route_source)
  SELECT
    route_id_nearest,
    surv_year,
    route_length,
    route_name,
    geom AS geom_derived_500,
    'derived' AS route_source
  FROM routes_derived_500
  ;

  -- then update the larger derived routes based on joins to the larger derived routes now in the master table
--     this will only be workable for 2.5K routes where they have the same name/id???

-- initially set route_name to use in join for subsequent update
  UPDATE routes_master
  SET
    route_name_2500 = routes_derived_2500.route_name
  FROM routes_derived_2500
  WHERE
    routes_master.route_id = routes_derived_2500.route_id_nearest
    AND routes_master.surv_year = routes_derived_2500.surv_year

-- then...
  UPDATE routes_master
  SET
    route_length_derived_2500 = routes_derived_2500.route_length,
    geom_derived_2500 = routes_derived_2500.geom
  FROM routes_derived_2500
  WHERE
    routes_master.route_id = routes_derived_2500.route_id_nearest
    AND routes_master.surv_year = routes_derived_2500.surv_year
    AND routes_master.route_name_2500 = routes_derived_2500.route_name
  ;

  -- then add any larger buffer routes not in above derived permutation
  INSERT INTO routes_master (route_id, surv_year, route_length_derived_2500, route_name_2500, geom_derived_2500, route_source)
  SELECT
    routes_derived_2500.route_id_nearest,
    routes_derived_2500.surv_year,
    routes_derived_2500.route_length,
    routes_derived_2500.route_name,
    routes_derived_2500.geom,
    'derived' AS route_source
  FROM routes_derived_2500
  LEFT JOIN routes_derived_500
    ON routes_derived_2500.route_id_nearest = routes_derived_500.route_id_nearest
    AND routes_derived_2500.surv_year = routes_derived_500.surv_year
  WHERE
    routes_derived_500.route_id_nearest IS NULL
    AND routes_derived_500.surv_year IS NULL
  ;

-- add route line delta by permutation as mean of routes_provided_consistent across years against delta
-- delta positive = routes_provided_consistent is larger
  alter table routes_master
    add delta_derived_500 numeric;
  alter table routes_master
      add delta_derived_2500 numeric;

  -- 500m buffer permutation
  WITH mean_route_length AS
    (SELECT
    route_id,
    AVG(route_length_provided) AS mean_length,
    COUNT(route_length_provided) AS num_surv_years,
    STDDEV(route_length_provided) AS sd_length
    FROM routes_master
    WHERE
      surv_year > 2012
    GROUP BY
      route_id
    )
  UPDATE routes_master
  SET delta_derived_500 = sub.delta
  FROM
    (SELECT
      routes_master.route_id,
      routes_master.surv_year,
      100 - (mean_route_length.mean_length / routes_master.route_length_derived_500)::numeric * 100 AS delta
    FROM routes_master
    JOIN mean_route_length ON routes_master.route_id = mean_route_length.route_id
    WHERE
      surv_year < 2014
      AND route_source = 'derived'
      AND routes_master.route_length_derived_500 > 0
    )sub
  WHERE
    routes_master.route_id = sub.route_id
    AND routes_master.surv_year = sub.surv_year
    AND routes_master.surv_year < 2014
    AND route_source = 'derived'
  ;

  -- 2500m buffer permutation
  WITH mean_route_length AS
    (SELECT
    route_id,
    AVG(route_length_provided) AS mean_length,
    COUNT(route_length_provided) AS num_surv_years,
    STDDEV(route_length_provided) AS sd_length
    FROM routes_master
    WHERE
      surv_year > 2012
    GROUP BY
      route_id
    )
  UPDATE routes_master
  SET delta_derived_2500 = sub.delta
  FROM
    (SELECT
      routes_master.route_id,
      routes_master.surv_year,
      100 - (mean_route_length.mean_length / routes_master.route_length_derived_2500)::numeric * 100 AS delta
    FROM routes_master
    JOIN mean_route_length ON routes_master.route_id = mean_route_length.route_id
    WHERE
      surv_year < 2014
      AND route_source = 'derived'
    )sub
  WHERE
    routes_master.route_id = sub.route_id
    AND routes_master.surv_year = sub.surv_year
    AND routes_master.surv_year < 2014
    AND route_source = 'derived'
  ;

-- apply single-value centroid to all routes based on max of per route
UPDATE routes_master
SET centroid_x = sub.max_centroid_x
FROM
   (SELECT
       route_id,
       MAX(centroid_x) AS max_centroid_x
    FROM routes_master
    GROUP BY
      route_id
    )sub
WHERE
  routes_master.route_id = sub.route_id
;

-- add state
ALTER TABLE IF EXISTS routes_master
ADD COLUMN state_code varchar;
ALTER TABLE IF EXISTS routes_master
ADD COLUMN geom_centroid geometry;

UPDATE routes_master
SET geom_centroid = ST_Centroid
                      (coalesce(geom_provided, geom_derived_2500, geom_derived_500))
;
UPDATE routes_master
SET state_code = states_5kmbuffer.code
FROM states_5kmbuffer
WHERE
  ST_Intersects(ST_Transform(states_5kmbuffer.geom, 3112), routes_master.geom_centroid)
;

-- add region to missing rows
UPDATE routes_master
SET region_name = sub.region_name
FROM
  (SELECT DISTINCT
     route_id,
     region_name
   FROM routes_master
   WHERE region_name IS NOT NULL
  )sub
WHERE
  sub.route_id = routes_master.route_id
  AND routes_master.region_name IS NULL
;

-- add survey variables
-- alter table public.routes_master
--     drop column multiple_surveys;
alter table public.routes_master
    add multiple_surveys boolean default false;

UPDATE routes_master
SET multiple_surveys = surveys.multiple_surveys
FROM surveys
WHERE
  surveys.route_id = routes_master.route_id
  AND surveys.surv_year = routes_master.surv_year
  AND surveys.surv_year > 2013
;

-- this may be a slight issue in that we may be replacing trues iteratively across the derived route permutations?
UPDATE routes_master
SET multiple_surveys = surveys.multiple_surveys
FROM surveys
WHERE
  surveys.route_name = routes_master.route_name_2500
  AND surveys.surv_year = routes_master.surv_year
  AND surveys.surv_year < 2014
;
UPDATE routes_master
SET multiple_surveys = surveys.multiple_surveys
FROM surveys
WHERE
  surveys.route_name = routes_master.route_name_500
  AND surveys.surv_year = routes_master.surv_year
  AND surveys.surv_year < 2014
;

-- add assigned route_id from Kasun feedback AFTER PERMUTATIONS ARE CHOSEN
alter table public.routes_master
    add assigned_route_id_derived_500 varchar(20) default null;
alter table public.routes_master
    add assigned_route_id_derived_2500 varchar(20) default null;

-- this is somewhat convoluted for now as we are yet to decide which of the derived route permutations to use.
-- accordingly, Kasun's route_id feedback is attributed to both derived route permutations so that when one is chosen that carried through.
UPDATE routes_master
SET assigned_route_id_derived_500 = surveys.assigned_route_id
FROM surveys
WHERE
  surveys.route_name = routes_master.route_name_500
  AND surveys.surv_year = routes_master.surv_year
  AND surveys.surv_year < 2014
;
UPDATE routes_master
SET assigned_route_id_derived_2500 = surveys.assigned_route_id
FROM surveys
WHERE
  surveys.route_name = routes_master.route_name_2500
  AND surveys.surv_year = routes_master.surv_year
  AND surveys.surv_year < 2014
;

-- import routes old and integrate
  -- apply single-value centroid to all old routes based on max of per new routes
--   alter table routes_master_old
--         add max_centroid_x numeric;
--   UPDATE routes_master_old
--   SET max_centroid_x = sub.max_centroid_x
--   FROM
--      (SELECT
--          route_id,
--          MAX(centroid_x) AS max_centroid_x
--       FROM routes_master
--       GROUP BY
--         route_id
--       )sub
--   WHERE
--     routes_master_old.route_id = sub.route_id
--   ;

-- integrate fields with CASE WHENs and export with formatting with routes old as different columns where they exist?
SELECT
  row_number() OVER
    (ORDER BY
    sub.state_code,
    sub.route_id,
    sub.surv_year,
    sub.route_source,
    sub.centroid_x
    ) AS sort,
  sub.*
FROM
    (SELECT
      routes_master.state_code,
      COALESCE(routes_master.centroid_x, routes_master_old.max_centroid_x, NULL :: numeric, 6) AS centroid_x,
      routes_master.region_name,
     CASE
        WHEN routes_master.route_source IS NOT NULL
        THEN routes_master.route_source
        ELSE 'old'
      END AS route_source,
      CASE
        WHEN routes_master.route_id IS NOT NULL
        THEN routes_master.route_id
        ELSE routes_master_old.route_id
      END AS route_id,
--       routes_master.assigned_route_id_derived_500,
--       routes_master.assigned_route_id_derived_2500,
      routes_master.route_name_2500,
      routes_master.route_name_500,
      CASE
        WHEN routes_master.route_name_2500 <> routes_master.route_name_500
        THEN 1
        ELSE NULL
        END AS derived_route_ids_divergent,
      CASE
        WHEN routes_master.surv_year IS NOT NULL
        THEN routes_master.surv_year
        ELSE routes_master_old.surv_year
      END AS surv_year,
      routes_master.multiple_surveys,
      routes_master_old.route_length AS route_length_old,
      ROUND(routes_master.route_length_provided, 2) AS route_length_provided,
      ROUND(routes_master.delta_provided_vs_consistent, 2) AS delta_provided_vs_consistent,
      ROUND(routes_master.route_length_derived_2500, 2) AS route_length_derived_2500,
      ROUND(routes_master.route_length_derived_500, 2) AS route_length_derived_500,
      ROUND(routes_master.delta_derived_500, 2) AS delta_derived_500,
      ROUND(routes_master.delta_derived_2500, 2) AS delta_derived_2500,
      CASE
        WHEN routes_master.delta_derived_500 <> routes_master.delta_derived_2500
        THEN 1
        ELSE NULL
      END AS derived_deltas_differ,
      routes_master_old.route_inferred,
      routes_master_old.description,
      routes_master_old.needs_review,
      routes_master_old.action,
      routes_master_old.needs_aggregation
    FROM routes_master
    FULL OUTER JOIN routes_master_old
      ON routes_master.route_id = routes_master_old.route_id
      AND routes_master.surv_year = routes_master_old.surv_year
    )sub
ORDER BY
  sub.state_code,
  sub.route_id,
  sub.surv_year,
  sub.route_source,
  sub.centroid_x
;

-- need to integrate a few old routes into sort given missing state definitions - only a few dozen...

-- display routes
  -- routes_integrated_derived_500
  DROP VIEW IF EXISTS routes_integrated_derived_500;
  CREATE VIEW routes_integrated_derived_500 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
  FROM routes_master
  WHERE
    COALESCE(geom_derived_500, geom_provided) IS NOT NULL
  ;

  -- routes_integrated_derived_2500
  DROP VIEW IF EXISTS routes_integrated_derived_2500;
  CREATE VIEW routes_integrated_derived_2500 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    COALESCE(geom_provided, geom_derived_2500) AS geom_integrated_2500
  FROM routes_master;
  ;

-- individual year views to use in QGIS atlas
  -- routes_integrated_derived_500
  DROP VIEW IF EXISTS routes_integrated_derived_500_2022;
  CREATE VIEW routes_integrated_derived_500_2022 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2022
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2020;
  CREATE VIEW routes_integrated_derived_500_2020 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2020
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2018;
  CREATE VIEW routes_integrated_derived_500_2018 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2018
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2018;
  CREATE VIEW routes_integrated_derived_500_2018 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2018
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2016;
  CREATE VIEW routes_integrated_derived_500_2016 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2016
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2014;
  CREATE VIEW routes_integrated_derived_500_2014 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2014
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2012;
  CREATE VIEW routes_integrated_derived_500_2012 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2012
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2010;
  CREATE VIEW routes_integrated_derived_500_2010 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2010
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_500_2008;
  CREATE VIEW routes_integrated_derived_500_2008 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_500, geom_provided) IS NOT NULL
        AND surv_year = 2008
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  -- routes_integrated_derived_2500
  DROP VIEW IF EXISTS routes_integrated_derived_2500_2022;
  CREATE VIEW routes_integrated_derived_2500_2022 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2022
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2020;
  CREATE VIEW routes_integrated_derived_2500_2020 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2020
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2018;
  CREATE VIEW routes_integrated_derived_2500_2018 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2018
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2018;
  CREATE VIEW routes_integrated_derived_2500_2018 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2018
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2016;
  CREATE VIEW routes_integrated_derived_2500_2016 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2016
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2014;
  CREATE VIEW routes_integrated_derived_2500_2014 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2014
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2012;
  CREATE VIEW routes_integrated_derived_2500_2012 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2012
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2010;
  CREATE VIEW routes_integrated_derived_2500_2010 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2010
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

  DROP VIEW IF EXISTS routes_integrated_derived_2500_2008;
  CREATE VIEW routes_integrated_derived_2500_2008 AS
  SELECT
    row_number() over () AS id,
    route_id,
    surv_year,
    ST_SetSRID(ST_Union(geom_integrated_2500), 3112) AS geom
  FROM
      (SELECT
        route_id,
        surv_year,
        COALESCE(geom_derived_2500, geom_provided) AS geom_integrated_2500
      FROM routes_master
      WHERE
        COALESCE(geom_derived_2500, geom_provided) IS NOT NULL
        AND surv_year = 2008
      )sub
  GROUP BY
    route_id,
    surv_year
  ;

-- display 2500m but with 500m connector buffers to show where permutations differ

-- summarise extent of habitats by route year INCOMPLETE
-- SELECT
--   route_id,
--   surv_year,
-- --   COALESCE or CASE with CONCAT
--   CASE
--     WHEN
--     CONCAT
--       ('Sand beach (', sub."Sand beach", '), '
--       'Airfield (', sub."Airfield", '), '
--       )
-- FROM
--     (SELECT
--       route_id,
--       surv_year,
--       ROUND(SUM(routes_provided_consistent.route_length) FILTER (WHERE routes_provided_consistent.habitat = 1) :: numeric, 0) AS "Sand beach",
--       ROUND(SUM(routes_provided_consistent.route_length) FILTER (WHERE routes_provided_consistent.habitat = 2) :: numeric, 0) AS "Airfield",
--       ROUND(SUM(routes_provided_consistent.route_length) FILTER (WHERE routes_provided_consistent.habitat = 3) :: numeric, 0) AS "lake",
--       ROUND(SUM(routes_provided_consistent.route_length) FILTER (WHERE routes_provided_consistent.habitat = 4) :: numeric, 0) AS "Cliff",
--       ROUND(SUM(routes_provided_consistent.route_length) FILTER (WHERE routes_provided_consistent.habitat = 5) :: numeric, 0) AS "Inlet"
--     FROM routes_provided_consistent
--     JOIN lut_habitat ON routes_provided_consistent.habitat = lut_habitat.id
--     GROUP BY
--       route_id,
--       surv_year
--     )sub
-- ;