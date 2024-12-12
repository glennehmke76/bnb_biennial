
AcuGIS bnb_biennial







-- calculate route line lengths
-- to load as GIS take sub-query only
SELECT
  sub.id,
  sub.surv_year,
  sub.route_id,
  sub.route_name,
  sub.start_name,
  sub.finish_name,
  ST_Length(sub.geom_line_galcc) AS route_line
FROM
  (SELECT
    id,
    route_id,
    route_name,
    start_name,
    finish_name,
    surv_year,
    ST_MakeLine(geom_start_galcc, geom_finish_galcc) AS geom_line_galcc
  FROM sightings
  WHERE
    geom_start_galcc IS NOT NULL
    AND geom_finish_galcc IS NOT NULL
    AND start_end_same IS NULL
  GROUP BY
    id,
    route_id,
    route_name,
    start_name,
    finish_name,
    surv_year
  )sub

-- digitise routes_provided from coastal line




start with biennial_coast





when moving incorrect points in QGIS...

original coords are bivariate lat/long - move geom



-- attribute route_ids as nearest to route lines


-- calculate variance / residual of route_line by route_id

max-min


residual of digitised route against route line length


ALTER TABLE IF EXISTS public.sightings
    DROP COLUMN start_end_same;


-- QGIS
SELECT
  sightings.id,
  sightings.surv_year,
  ST_Transform(sightings.geom_start, 3112) AS geom_start
FROM
  sightings

SELECT
  sightings.id,
  sightings.surv_year,
  ST_Transform(sightings.geom_finish, 3112) AS geom_finish
FROM
  sightings

SELECT
  sightings.id,
  sightings.surv_year,
  ST_Transform(sightings.geom_sighting, 3112) AS geom_sighting
FROM
  sightings



[-- nearests
  -- do nearests max 10k
  id	surv_year	spatial_id	spatial_region_id	spatial_region_name	spatial_route_id	spatial_route_name	spatial_state	n	distance

  [-- site polys
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_start_region_id;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_start_region_name;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_start_route_id;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_start_route_name;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_start_dist;

    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_finish_region_id;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_finish_region_name;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_finish_route_id;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_finish_route_name;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_finish_dist;

    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_sighting_region_id;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_sighting_region_name;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_sighting_route_id;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_sighting_route_name;
    ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS sp_sighting_dist;


    ALTER TABLE IF EXISTS public.sightings
        ADD COLUMN sp_start_region_id integer,
        ADD COLUMN sp_start_region_name varchar,
        ADD COLUMN sp_start_route_id varchar,
        ADD COLUMN sp_start_route_name varchar,
        ADD COLUMN sp_start_dist integer,
        ADD COLUMN sp_finish_region_id integer,
        ADD COLUMN sp_finish_region_name varchar,
        ADD COLUMN sp_finish_route_id varchar,
        ADD COLUMN sp_finish_route_name varchar,
        ADD COLUMN sp_finish_dist integer,
        ADD COLUMN sp_sighting_region_id integer,
        ADD COLUMN sp_sighting_region_name varchar,
        ADD COLUMN sp_sighting_route_id varchar,
        ADD COLUMN sp_sighting_route_name varchar,
        ADD COLUMN sp_sighting_dist integer
    ;

    UPDATE sightings
    SET
      sp_start_region_id = sp_start.spatial_region_id,
      sp_start_region_name = sp_start.spatial_region_name,
      sp_start_route_id = sp_start.spatial_route_id,
      sp_start_route_name = sp_start.spatial_route_name,
      sp_start_dist = sp_start.distance
    FROM sp_start
    WHERE
      sightings.id = sp_start.id
      AND sightings.surv_year = sp_start.surv_year;

    UPDATE sightings
    SET
      sp_finish_region_id = sp_finish.spatial_region_id,
      sp_finish_region_name = sp_finish.spatial_region_name,
      sp_finish_route_id = sp_finish.spatial_route_id,
      sp_finish_route_name = sp_finish.spatial_route_name,
      sp_finish_dist = sp_finish.distance
    FROM sp_finish
    WHERE
      sightings.id = sp_finish.id
      AND sightings.surv_year = sp_finish.surv_year;

    UPDATE sightings
    SET
      sp_sighting_region_id = sp_sighting.spatial_region_id,
      sp_sighting_region_name = sp_sighting.spatial_region_name,
      sp_sighting_route_id = sp_sighting.spatial_route_id,
      sp_sighting_route_name = sp_sighting.spatial_route_name,
      sp_sighting_dist = sp_sighting.distance
    FROM sp_sighting
    WHERE
      sightings.id = sp_sighting.id
      AND sightings.surv_year = sp_sighting.surv_year;
  ]

  [-- site lines
    DROP TABLE IF EXISTS sp_start;
    CREATE TABLE sp_start (
      id int NOT NULL,
      surv_year int NOT NULL,
      spatial_route_id varchar DEFAULT NULL,
      spatial_region_id int DEFAULT NULL,
      n int DEFAULT NULL,
      distance double precision DEFAULT NULL
    );

    copy sp_start FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/sp_start.csv' DELIMITER ',' CSV HEADER;

    DROP TABLE IF EXISTS sp_finish;
    CREATE TABLE sp_finish (
      id int NOT NULL,
      surv_year int NOT NULL,
      spatial_route_id varchar DEFAULT NULL,
      spatial_region_id int DEFAULT NULL,
      n int DEFAULT NULL,
      distance double precision DEFAULT NULL
    );

    copy sp_finish FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/sp_finish.csv' DELIMITER ',' CSV HEADER;

    DROP TABLE IF EXISTS sp_sighting;
    CREATE TABLE sp_sighting (
      id int NOT NULL,
      surv_year int NOT NULL,
      spatial_route_id varchar DEFAULT NULL,
      spatial_region_id int DEFAULT NULL,
      n int DEFAULT NULL,
      distance double precision DEFAULT NULL
    );

    copy sp_sighting FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/sp_sighting.csv' DELIMITER ',' CSV HEADER;

    ALTER TABLE IF EXISTS public.sightings
        ADD COLUMN sp_line_start_region_id integer,
        ADD COLUMN sp_line_start_route_id varchar,
        ADD COLUMN sp_line_start_dist integer,
        ADD COLUMN sp_line_finish_region_id integer,
        ADD COLUMN sp_line_finish_route_id varchar,
        ADD COLUMN sp_line_finish_dist integer,
        ADD COLUMN sp_line_sighting_region_id integer,
        ADD COLUMN sp_line_sighting_route_id varchar,
        ADD COLUMN sp_line_sighting_dist integer
    ;

    UPDATE sightings
    SET
      sp_line_start_region_id = sp_line_start.spatial_region_id,
      sp_line_start_route_id = sp_line_start.spatial_route_id,
      sp_line_start_dist = sp_line_start.distance
    FROM sp_line_start
    WHERE
      sightings.id = sp_line_start.id
      AND sightings.surv_year = sp_line_start.surv_year;

    UPDATE sightings
    SET
      sp_line_finish_region_id = sp_line_finish.spatial_region_id,
      sp_line_finish_route_id = sp_line_finish.spatial_route_id,
      sp_line_finish_dist = sp_line_finish.distance
    FROM sp_line_finish
    WHERE
      sightings.id = sp_line_finish.id
      AND sightings.surv_year = sp_line_finish.surv_year;

    UPDATE sightings
    SET
      sp_line_sighting_region_id = sp_line_sighting.spatial_region_id,
      sp_line_sighting_route_id = sp_line_sighting.spatial_route_id,
      sp_line_sighting_dist = sp_line_sighting.distance
    FROM sp_line_sighting
    WHERE
      sightings.id = sp_line_sighting.id
      AND sightings.surv_year = sp_line_sighting.surv_year;
  ]

  -- add ST
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_start_region_id;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_start_region_name;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_start_route_id;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_start_route_name;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_start_dist;

  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_finish_region_id;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_finish_region_name;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_finish_route_id;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_finish_route_name;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_finish_dist;

  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_sighting_region_id;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_sighting_region_name;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_sighting_route_id;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_sighting_route_name;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS st_sighting_dist;

  ALTER TABLE IF EXISTS public.sightings
      ADD COLUMN st_start_region_id integer,
      ADD COLUMN st_start_region_name varchar,
      ADD COLUMN st_start_route_id varchar,
      ADD COLUMN st_start_route_name varchar,
      ADD COLUMN st_start_dist integer,
      ADD COLUMN st_finish_region_id integer,
      ADD COLUMN st_finish_region_name varchar,
      ADD COLUMN st_finish_route_id varchar,
      ADD COLUMN st_finish_route_name varchar,
      ADD COLUMN st_finish_dist integer,
      ADD COLUMN st_sighting_region_id integer,
      ADD COLUMN st_sighting_region_name varchar,
      ADD COLUMN st_sighting_route_id varchar,
      ADD COLUMN st_sighting_route_name varchar,
      ADD COLUMN st_sighting_dist integer
  ;

                  -- do select first...
                  --
                  -- UPDATE sightings
                  -- SET
                  --   sightings.st_sighting_region_id = site_bnb_biennial.spatial_region_id,
                  --   sightings.st_sighting_region_nme = site_bnb_biennial.spatial_region_name,
                  --   sightings.st_sighting_route_id = site_bnb_biennial.spatial_route_id,
                  --   sightings.st_sighting_route_nme = site_bnb_biennial.spatial_route_name
                  -- FROM sightings
                  -- INNER JOIN site_bnb_biennial
                  -- ON ST_DWithin
                  --
                  --
                  -- (sightings.geom_start::geography, site_bnb_biennial.geom::geography, 1000)
                  -- -- LEFT JOIN sp_sighting ON ST_Distance/Contains/DWithin(sightings.geom_start::geography, site_bnb_biennial.geom::geography)
                  -- ;
                  --
                  -- WHERE
                  --   sightings.id = sp_sighting.id
                  --   AND sightings.surv_year = sp_sighting.surv_year;
                  --
                  -- UPDATE sightings
                  -- SET
                  --   sightings.st_sighting_region_id =
                  --     (SELECT site_bnb_biennial.region_id
                  --       FROM sightings
                  --       INNER JOIN site_bnb_biennial
                  --       ON ST_Contains (site_bnb_biennial.geom, sightings.geom_start)
                  --     )
                  --
                  --
                  -- UPDATE sightings
                  -- INNER JOIN
                  --     (SELECT sightings.id, site_bnb_biennial.region_id
                  --       FROM sightings
                  --       INNER JOIN site_bnb_biennial
                  --       ON ST_Contains (site_bnb_biennial.geom, sightings.geom_start)
                  --     ) sub1
                  -- ON sub1 sightings.id = sub1.id
                  -- SET
                  --   sightings.st_sighting_region_id = sub1.region_id
                  --
                  -- UPDATE sightings
                  -- SET sightings.st_sighting_region_id = sub1.region_id
                  --   (SELECT sightings.id, site_bnb_biennial.region_id
                  --     FROM sightings
                  --     INNER JOIN site_bnb_biennial
                  --     ON ST_Contains (site_bnb_biennial.geom, sightings.geom_start)
                  --   ) sub1
                  -- WHERE sub1.id = sightings.id;
                  --
                  -- UPDATE sightings
                  -- SET st_sighting_region_id = site_bnb_biennial.region_id
                  -- FROM sightings
                  -- WHERE ST_Contains (site_bnb_biennial.geom, sightings.geom_start)
                  --
                  -- -- use geom?
                  -- SELECT site_bnb_biennial.region_id
                  --   FROM sightings
                  --   INNER JOIN site_bnb_biennial
                  --   ON ST_DWithin ((ST_transform(site_bnb_biennial.geom, 3112)), ((ST_transform(sightings.geom_start, 3112)), 3000)
                  --
                  --
                  --
                  --   sightings.st_sighting_region_nme = site_bnb_biennial.spatial_region_name,
                  --   sightings.st_sighting_route_id = site_bnb_biennial.spatial_route_id,
                  --   sightings.st_sighting_route_nme = site_bnb_biennial.spatial_route_name
                  --
                  -- ST_Distance(sightings.geom_finish::geography, site_bnb_biennial.geom::geography) AS poly_dist_finish,
                  -- ST_Distance(sightings.geom_sighting::geography, site_bnb_biennial.geom::geography) AS poly_dist_sighting,
                  --
                  -- LEFT JOIN sightings ON ST_DWithin(site_bnb_biennial.geom::geography, sightings.geom_start::geography, 3000)



  --
  UPDATE sightings
  SET
    st_start_dist = ST_Distance (site_bnb_biennial.geom_GALCC, sightings.geom_start_GALCC),
    st_start_region_id = site_bnb_biennial.region_id,
    st_start_region_name = site_bnb_biennial.region_name,
    st_start_route_id = site_bnb_biennial.route_id,
    st_start_route_name = site_bnb_biennial.route_name
  FROM site_bnb_biennial
  WHERE
    -- ST_Contains (site_bnb_biennial.geom_GALCC, sightings.geom_GALCC)
    ST_DWithin (site_bnb_biennial.geom_GALCC, sightings.geom_start_GALCC, 3000)
  ;

  UPDATE sightings
  SET
    st_finish_dist = ST_Distance (site_bnb_biennial.geom_GALCC, sightings.geom_finish_GALCC),
    st_finish_region_id = site_bnb_biennial.region_id,
    st_finish_region_name = site_bnb_biennial.region_name,
    st_finish_route_id = site_bnb_biennial.route_id,
    st_finish_route_name = site_bnb_biennial.route_name
  FROM site_bnb_biennial
  WHERE
    -- ST_Contains (site_bnb_biennial.geom_GALCC, sightings.geom_GALCC)
    ST_DWithin (site_bnb_biennial.geom_GALCC, sightings.geom_finish_GALCC, 3000)
  ;

  UPDATE sightings
  SET
    st_sighting_dist = ST_Distance (site_bnb_biennial.geom_GALCC, sightings.geom_sighting_GALCC),
    st_sighting_region_id = site_bnb_biennial.region_id,
    st_sighting_region_name = site_bnb_biennial.region_name,
    st_sighting_route_id = site_bnb_biennial.route_id,
    st_sighting_route_name = site_bnb_biennial.route_name
  FROM site_bnb_biennial
  WHERE
    -- ST_Contains (site_bnb_biennial.geom_GALCC, sightings.geom_GALCC)
    ST_DWithin (site_bnb_biennial.geom_GALCC, sightings.geom_sighting_GALCC, 3000)
  ;









  DROP VIEW IF EXISTS sightings_spatial;
  CREATE VIEW sightings_spatial AS
  SELECT
    -- sightings.geom_start,
    -- sightings.geom_finish,
    -- sightings.geom_sighting,
    sightings.id,
    sightings.surv_year,
    sightings.form_id,
    sightings.start_name,
    sightings.finish_name,
    sightings.start_lat,
    sightings.start_long,
    sightings.finish_lat,
    sightings.finish_long,
    sightings.lat,
    sightings.long,
    sightings.sp_id,
    sightings.num_adults,
    sightings.num_juvs,
    sightings.num_adults + sightings.num_juvs AS num_total,
    sightings.region_id AS db_region_id,
    sightings.region_name AS db_region_name,
    sightings.route_id AS db_route_id,
    sightings.route_name AS db_route_name,
    sightings.sp_line_start_region_id,
    sightings.sp_line_start_route_id,
    sightings.sp_line_start_dist,
    sightings.sp_line_finish_region_id,
    sightings.sp_line_finish_route_id,
    sightings.sp_line_finish_dist,
    sightings.sp_line_sighting_region_id,
    sightings.sp_line_sighting_route_id,
    sightings.sp_line_sighting_dist,
    sightings.sp_start_region_id,
    sightings.sp_start_region_name,
    sightings.sp_start_route_id,
    sightings.sp_start_route_name,
    sightings.sp_start_dist,
    sightings.sp_finish_region_id,
    sightings.sp_finish_region_name,
    sightings.sp_finish_route_id,
    sightings.sp_finish_route_name,
    sightings.sp_finish_dist,
    sightings.sp_sighting_region_id,
    sightings.sp_sighting_region_name,
    sightings.sp_sighting_route_id,
    sightings.sp_sighting_route_name,
    sightings.sp_sighting_dist
  FROM
    sightings
  ;

  -- add taxon name for export
  COPY
  (
  SELECT
    WLAB_sp.taxon_name,
    sightings_spatial.*
  FROM
    sightings_spatial
  JOIN WLAB_sp
  ON sightings_spatial.sp_id = WLAB_sp.sp_id
  )
  TO
  '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/biennial.csv'
  DELIMITER ','
  NULL AS ''
  QUOTE AS'"'
  CSV HEADER
  ;


  SELECT
    sightings.geom_start,
    -- sightings.geom_finish,
    -- sightings.geom_sighting,
    sightings.id,
    sightings.surv_year,
    sightings.route_id AS db_route_id,
    sightings.sp_start_route_id,
    sightings.sp_line_start_route_id,
    sightings.sp_start_dist,
    sightings.sp_line_start_dist,
  FROM
    sightings
  ;

    sightings.region_id AS db_region_id,
    sightings.sp_line_start_region_id,
    sightings.sp_start_route_id,
    sightings.route_id AS db_route_id,
    sightings.sp_line_start_route_id,
    sightings.sp_line_start_dist,


  -- 1508 rows
  SELECT
    *
  FROM
    Sightings
  WHERE sp_line_start_route_id <> sp_line_finish_route_id
  AND route_id is null
  ;

  But these have route names so populate route_id from route_name where is exists in either spatial layer (assuming they are equivilent)

  -- 4632 rows
  SELECT
    *
  FROM
    Sightings
  WHERE sp_line_start_route_id <> sp_line_finish_route_id
  ;

  -- 39 rows
  SELECT
    *
  FROM
    Sightings
  WHERE (sp_line_start_route_id = sp_line_finish_route_id) AND  sp_line_start_route_id <> sp_line_sighting_route_id
  ;

  These two spatial geometries differ and in 4632 instances sighting points intersect different route based on start and finish points (this may be due to spatial lines/polygons being on exactly the same point this returning 2 route_ids). For many of these we can revert to the database route ids, but in 1508 cases there is no route_id in the raw data and the route names in the database often differ from the route names in the master route file.
]


-- aggregation
SELECT
  region_id,
  region_name,
  route_id,
  route_name
  surv_year,
  SUM(adult + juv) AS total
FROM sightings
WHERE
  sp_id = 138
AND
  (SELECT
    route_id,
    COUNT DISTINCT (surv_year) AS num_years
  FROM sightings
  WHERE
    num_years > 3
  )
;


SELECT
  region_id,
  region_name,
  route_id,
  route_name,
  surv_year,
  SUM(num_adults + num_juvs) AS total
  -- (SELECT
  --   route_id,
  --   COUNT DISTINCT (surv_year) AS num_years
  -- FROM sightings
  -- GROUP BY route_id
  -- ) num_years
FROM sightings
WHERE
  sp_id = 138
-- AND
--   num_years > 3
GROUP BY
  region_id,
  region_name,
  route_id,
  route_name,
  surv_year
;









-- compare provided and digitised routes_provided (ie from surveys)
  -- need indexes etc?
          -- SELECT
          --   routes_provided.id,
          --   routes_provided.route_id,
          --   routes_provided.route_name,
          --   routes_provided.region_id,
          --   routes_provided.region_name,
          --   routes_provided.surveyed
          -- FROM
          --   routes_provided
          -- JOIN routes_digitised
          -- ON ST_Union(ST_Buffer(routes_provided.geom,100),ST_Buffer(routes_digitised.geom,100))
          -- WHERE
          --   routes_provided.surv_year = 2018
          --   -- AND routes_digitised.id IS NULL
          -- ;



  -- then initially just make route extents but do not attribute route_id or route_name.
  -- then do overlaps and decide from the master routes_provided file what is what.

  because there are route_ids with different start and finish points spatial route attribution requires an aggregate to sum num_adults within a



  -- provided route vs ge digitised
  -- route_ are start/end points digitised, routes_ are provided

  SELECT

  ST_Union(routes_digitised, routes_2018)
  HAVING NOT IN ???


  SELECT
    route.id,
    routes_provided.id,






-- Aug 2023

populate 2010-12 route lines with route_ids and link to raw data.

Add start-end lines to surveys

ALTER TABLE IF EXISTS surveys
  ADD COLUMN route_line geometry(linestring, 3112);

UPDATE surveys
SET route_line = sub.geom
FROM
    (SELECT
      id,
      ST_MakeLine(geom_start_galcc, geom_finish_galcc) AS geom
    FROM surveys
    WHERE
      geom_start_galcc IS NOT NULL
      AND geom_finish_galcc IS NOT NULL
      AND start_end_same IS NULL
    )sub
WHERE
  surveys.id = sub.id
;

then add to QGIS and enter route_ids manually via selection





 processing.run("native:intersection", {'INPUT':'postgres://dbname=\'bnb_biennial\' host=localhost port=5432 user=\'gehmke\' password=\'pf2x5n\' sslmode=disable key=\'id\' srid=3112 type=LineString checkPrimaryKeyUnicity=\'1\' table="public"."biennial_coast" (geom)','OVERLAY':'postgres://dbname=\'bnb_biennial\' host=localhost port=5432 user=\'gehmke\' password=\'pf2x5n\' sslmode=disable key=\'_uid_\' checkPrimaryKeyUnicity=\'1\' table="(SELECT row_number() over () AS _uid_,* FROM (SELECT     id,     route_id,     surv_year,     ST_Buffer(geom, 50, \'endcap=flat\') AS geom   FROM routes_provided\n) AS _subq_1_\n)" (geom)','INPUT_FIELDS':['id','line_source','habitat','length'],'OVERLAY_FIELDS':['id','route_id','surv_year'],'OVERLAY_FIELDS_PREFIX':'','OUTPUT':'TEMPORARY_OUTPUT','GRID_SIZE':None})


WITH unioned AS
(SELECT
  surv_year,
  route_id,
  ST_Union(geom) AS geom
FROM routes_provided_consistent
GROUP BY
  surv_year,
  route_id
)
SELECT
  ST_Union(geom) AS geom,
  COUNT(geom)
FROM unioned
GROUP BY
  route_id



DROP TABLE IF EXISTS routes_summary;
CREATE TABLE routes_summary (
  state varchar DEFAULT NULL,
  region_name varchar DEFAULT NULL,
  route_id varchar DEFAULT NULL,
  surv_year int DEFAULT NULL,
  route_length int DEFAULT NULL,
  route_inferred int DEFAULT NULL,
  description varchar DEFAULT NULL,
  needs_review int DEFAULT NULL,
  needs_aggregation varchar DEFAULT NULL,
  checked int DEFAULT NULL
);
copy routes_summary FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/routes_review.csv' DELIMITER ',' CSV HEADER;

UPDATE routes_summary
SET needs_review = 0
WHERE needs_review IS NULL;

-- to get route has years in need of attention
SELECT
  route_id
FROM routes_summary
WHERE
  needs_review <> needs_review
GROUP BY
  route_id
  ;

