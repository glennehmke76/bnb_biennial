-- make lines from start/finish points and centroids from lines
-- make route lines
DROP TABLE IF EXISTS route_lines;
CREATE TABLE route_lines AS
  SELECT
    sub1.route_id,
    sub1.surv_year,
    sub1.route_name,
    sub1.start_name,
    sub1.finish_name,
    sub1.geom_line,
    ST_X(ST_Transform(sub1.geom_centroid, 4283)) AS route_centroid_lat,
    ST_Y(ST_Transform(sub1.geom_centroid, 4283)) AS route_centroid_long,
    ST_X(sub1.geom_centroid) AS route_centroid_X,
    ST_Y(sub1.geom_centroid) AS route_centroid_y
  FROM
     (SELECT
        sub.route_id,
        sub.surv_year,
        sub.route_name,
        sub.start_name,
        sub.finish_name,
        ST_Centroid(sub.geom_line) AS geom_centroid,
        sub.geom_line
      FROM
          (SELECT
            surveys.surv_year,
            surveys.route_id,
            surveys.route_name,
            surveys.start_name,
            surveys.finish_name,
            ST_Union
              (ST_MakeLine
                  (ST_Transform(geom_start, 3112),  ST_Transform(geom_finish, 3112))) AS geom_line
          FROM surveys, biennial_coast
          WHERE
            surveys.geom_start IS NOT NULL
            AND surveys.geom_finish IS NOT NULL
            AND surveys.start_end_same IS NULL
--             AND surveys.start_finish_null IS NOT true
            AND ST_DWithin
                  (ST_Transform(biennial_coast.geom, 3112), ST_Transform(geom_start, 3112), 5000)
            AND ST_DWithin
                  (ST_Transform(biennial_coast.geom, 3112), ST_Transform(geom_finish, 3112), 5000)
            AND surv_year BETWEEN 2008 AND 2012
          GROUP BY
            surveys.surv_year,
            surveys.route_id,
            surveys.route_name,
            surveys.start_name,
            surveys.finish_name
          )sub
    )sub1
;

ALTER TABLE IF EXISTS public.route_lines
    ADD COLUMN id integer NOT NULL GENERATED ALWAYS AS IDENTITY;
ALTER TABLE IF EXISTS public.route_lines
    ADD PRIMARY KEY (id);

-- check there are not >3 survey years per route name
SELECT
  route_lines.route_name,
  Count(DISTINCT surv_year)
FROM route_lines
GROUP BY
  route_name
;

-- make routes (to match routes consistent - based on biennial coast) from start/finish-point lines based on master coast layer
-- to add a buffer distance permutation...

  -- 500m buffer permutation
  DROP TABLE IF EXISTS routes_derived_500;
  CREATE TABLE routes_derived_500 AS
    WITH buffers AS
      (SELECT
        route_name,
        surv_year,
          ST_Buffer(geom_line, 500, 'quad_segs=2 endcap=flat join=mitre') AS geom
      FROM route_lines
      )
    SELECT
      buffers.route_name,
      buffers.surv_year,
      ST_Union
        (ST_Intersection(biennial_coast.geom, ST_Transform(buffers.geom, 3112))) AS geom
    FROM buffers
    JOIN biennial_coast ON ST_Intersects(biennial_coast.geom, ST_Transform(buffers.geom, 3112))
    GROUP BY
      buffers.route_name,
      buffers.surv_year
  ;

  ALTER TABLE IF EXISTS public.routes_derived_500
      ADD COLUMN id integer NOT NULL GENERATED ALWAYS AS IDENTITY;
  ALTER TABLE IF EXISTS public.routes_derived_500
      ADD PRIMARY KEY (id);

  ALTER TABLE IF EXISTS public.routes_derived_500
  ADD COLUMN route_length numeric;
  UPDATE routes_derived_500
  SET route_length = ST_Length(geom);

  ALTER TABLE IF EXISTS public.routes_derived_500
  ADD COLUMN centroid_x numeric;
  UPDATE routes_derived_500
  SET centroid_x = ST_X
                    (ST_Transform
                      (ST_Centroid(geom), 4283))
  ;

  -- 2500m buffer permutation
  DROP TABLE IF EXISTS routes_derived_2500;
  CREATE TABLE routes_derived_2500 AS
    WITH buffers AS
      (SELECT
        route_name,
        surv_year,
          ST_Buffer(geom_line, 2500, 'quad_segs=2 endcap=flat join=mitre') AS geom
      FROM route_lines
      )
    SELECT
      buffers.route_name,
      buffers.surv_year,
      ST_Union
        (ST_Intersection(biennial_coast.geom, ST_Transform(buffers.geom, 3112))) AS geom
    FROM buffers
    JOIN biennial_coast ON ST_Intersects(biennial_coast.geom, ST_Transform(buffers.geom, 3112))
    GROUP BY
      buffers.route_name,
      buffers.surv_year
  ;

  ALTER TABLE IF EXISTS public.routes_derived_2500
      ADD COLUMN id integer NOT NULL GENERATED ALWAYS AS IDENTITY;
  ALTER TABLE IF EXISTS public.routes_derived_2500
      ADD PRIMARY KEY (id);

  ALTER TABLE IF EXISTS public.routes_derived_2500
  ADD COLUMN route_length numeric;
  UPDATE routes_derived_2500
  SET route_length = ST_Length(geom);

  ALTER TABLE IF EXISTS public.routes_derived_2500
  ADD COLUMN centroid_x numeric;
  UPDATE routes_derived_2500
  SET centroid_x = ST_X
                    (ST_Transform
                      (ST_Centroid(geom), 4283))
  ;

-- assign nearest route_id from provided routes (although most pt_on_surfaces will be on a line vertex)
DROP VIEW IF EXISTS pt_on_surface_500;
CREATE VIEW pt_on_surface_500 AS
SELECT
  id,
  route_name,
  surv_year,
  ST_PointOnSurface(geom) AS geom_pt_on_surface
FROM routes_derived_500;

DROP VIEW IF EXISTS pt_on_surface_2500;
CREATE VIEW pt_on_surface_2500 AS
SELECT
  id,
  route_name,
  surv_year,
  ST_PointOnSurface(geom) AS geom_pt_on_surface
FROM routes_derived_2500;

-- only worked after saved as gpkg layers and run (perhaps because of undefined SRID?)
 processing.run("native:joinbynearest", {'INPUT':'/Users/glennehmke/Downloads/pt_on_surface_2500.gpkg|layername=pt_on_surface_2500','INPUT_2':'/Users/glennehmke/Downloads/prov.gpkg|layername=routes_provided_consistent','FIELDS_TO_COPY':[],'DISCARD_NONMATCHING':False,'PREFIX':'','NEIGHBORS':1,'MAX_DISTANCE':3000,'OUTPUT':'/Users/glennehmke/Downloads/nearest_2500.csv'})
 processing.run("native:joinbynearest", {'INPUT':'/Users/glennehmke/Downloads/pt_on_surface_500.gpkg|layername=pt_on_surface_500','INPUT_2':'/Users/glennehmke/Downloads/prov.gpkg|layername=routes_provided_consistent','FIELDS_TO_COPY':['route_id'],'DISCARD_NONMATCHING':False,'PREFIX':'','NEIGHBORS':1,'MAX_DISTANCE':3000,'OUTPUT':'/Users/glennehmke/Downloads/nearest_500.csv'})

-- import as is as route_line_nearests
  -- ingest



  -- update to route lines
  alter table routes_derived_500
      add route_id_nearest varchar;
  UPDATE routes_derived_500
  SET route_id_nearest = nearest_500.route_id
  FROM nearest_500
  WHERE
    routes_derived_500.id = nearest_500.id
  ;

  alter table routes_derived_2500
      add route_id_nearest varchar;
  UPDATE routes_derived_2500
  SET route_id_nearest = nearest_2500.route_id
  FROM nearest_2500
  WHERE
    routes_derived_2500.id = nearest_2500.id
  ;

-- add source for later filtering
alter table routes_derived_500
    add derived_route_perm varchar;
UPDATE routes_derived_500
SET derived_route_perm = '500m';

alter table routes_derived_2500
    add derived_route_perm varchar;
UPDATE routes_derived_2500
SET derived_route_perm = '32500m';


    -- comparison of ST_Centroid vs ST_PointOnSurface based route_ids
      -- n=6
      SELECT
        *
      FROM routes_derived_500
      WHERE routes_derived_500.route_id_nearest <> routes_derived_500.route_id_nearest_old;

      -- n=53
      SELECT
        *
      FROM routes_derived_2500
      WHERE routes_derived_2500.route_id_nearest <> routes_derived_2500.route_id_nearest_old;

-- show start/finish-points
    -- show start-points
    DROP VIEW IF EXISTS start_points;
    CREATE VIEW start_points AS
    SELECT
       row_number() over (),
       surveys.id,
       surveys.surv_year,
       surveys.route_id,
       surveys.route_name,
       surveys.start_name,
       ST_SetSRID(surveys.geom_start, 4283)  AS geom_start
    FROM
        surveys,
        biennial_coast
    WHERE
      surveys.geom_start IS NOT NULL
--       AND surveys.start_end_same IS NULL
      AND ST_DWithin(biennial_coast.geom, ST_Transform(geom_start, 3112), 5000)
      AND surv_year BETWEEN 2008 AND 2012
    ;

    -- show finish-points
    DROP VIEW IF EXISTS finish_points;
    CREATE VIEW finish_points AS
    SELECT
       row_number() over (),
       surveys.id,
       surveys.surv_year,
       surveys.route_id,
       surveys.route_name,
       surveys.start_name,
       surveys.geom_finish  AS geom_finish
    FROM
        surveys,
        biennial_coast
    WHERE
      surveys.geom_finish IS NOT NULL
      AND surveys.geom_finish IS NOT NULL
--       AND surveys.start_end_same IS NULL
      AND ST_DWithin(biennial_coast.geom, ST_Transform(geom_finish, 3112), 5000)
      AND surv_year BETWEEN 2008 AND 2012
    ;






-- are there multi-part lines (indicating pollution)
SELECT
  route_id_nearest,
  surv_year,
  COUNT(geom) AS num_lines
FROM routes_derived_500
GROUP BY
  route_id_nearest,
  surv_year
HAVING
  COUNT(geom) > 1
;

-- find multi-part geometries (there are many)
SELECT
  route_id_nearest,
  surv_year,
  ST_NumGeometries(geom)
FROM routes_derived_500
WHERE
  ST_NumGeometries(geom) > 1
;



THIS MEANS THERE ARE DIFFERENT SUB-ROUTES - I.E. A ROUTE_NAME START/FINISH POINT ETC AND THE JOIN TOM LENGTH ETC IN MASTER NEEDS FURTHER INFO... NRESRESTS ARE A PROBLEM!
SO CHANGE ROUTE- LeNGTH IN REOUTES PROVIDED AND DUPLICATE ROUTE_ID?


-- create view for QGIS connector buffers layer
DROP VIEW IF EXISTS buffers_500;
CREATE VIEW buffers_500 AS
SELECT
  row_number() over () AS id,
  route_name,
  surv_year,
  ST_Buffer(geom_line, 500, 'quad_segs=2 endcap=flat join=mitre') AS geom
FROM route_lines
;
DROP VIEW IF EXISTS buffers_2500;
CREATE VIEW buffers_2500 AS
SELECT
  row_number() over () AS id,
  route_name,
  surv_year,
  ST_SetSRID
    (ST_Buffer(geom_line, 2500, 'quad_segs=2 endcap=flat join=mitre'), 3112) AS geom
FROM route_lines
;

