-- identify problem geometries
  -- add start/finish_geom_incorrect fields

-- identify surveys with clearly incorrect start/finish points
  ALTER TABLE IF EXISTS public.surveys DROP COLUMN IF EXISTS start_end_same;
  ALTER TABLE IF EXISTS public.surveys
      ADD COLUMN start_end_same boolean;
  UPDATE surveys
  SET start_end_same = true
  WHERE geom_start = geom_finish
  ;

  -- in order to filter out non-constructable lines
  ALTER TABLE IF EXISTS public.surveys DROP COLUMN IF EXISTS start_finish_null;
  ALTER TABLE IF EXISTS public.surveys
      ADD COLUMN start_finish_null boolean;
  UPDATE surveys
  SET start_finish_null = true
  WHERE
    geom_start IS NULL
    OR geom_finish IS NULL
  ;

  alter table public.surveys
    drop column if exists start_geom_incorrect cascade;
  alter table public.surveys
    drop column if exists finish_geom_incorrect cascade;
  alter table surveys
      add start_geom_incorrect boolean;
  alter table surveys
      add finish_geom_incorrect boolean;

  WITH buffered_coast AS
    (SELECT
      ST_Union
        (ST_Buffer(geom, 5000, 'quad_segs=2')) AS geom
    FROM biennial_coast
    )
  UPDATE surveys
  SET start_geom_incorrect = true
  FROM
      (
      SELECT
        surveys.id,
        surveys.surv_year,
        surveys.route_id,
        surveys.route_name,
        surveys.start_name,
        surveys.geom_start
      FROM
        surveys
        JOIN buffered_coast ON ST_Disjoint(ST_Transform(surveys.geom_start, 3112), buffered_coast.geom)
      WHERE
        surveys.geom_start IS NOT NULL
        AND surveys.surv_year BETWEEN 2008 AND 2012
      )sub
  WHERE
    surveys.id = sub.id
  ;

  WITH buffered_coast AS
    (SELECT
      ST_Union
        (ST_Buffer(geom, 5000, 'quad_segs=2')) AS geom
    FROM biennial_coast
    )
  UPDATE surveys
  SET finish_geom_incorrect = true
  FROM
      (SELECT
        surveys.id,
        surveys.surv_year,
        surveys.route_id,
        surveys.route_name,
        surveys.start_name,
        surveys.geom_finish AS geom_start
      FROM
        surveys
        JOIN buffered_coast ON ST_Disjoint(ST_Transform(surveys.geom_finish, 3112), buffered_coast.geom)
      WHERE
        surveys.geom_finish IS NOT NULL
        AND surveys.surv_year BETWEEN 2008 AND 2012
      )sub
  WHERE
    surveys.id = sub.id
  ;

      -- display incorrect start and/or finish points
      SELECT
        surveys.id,
        surveys.surv_year,
        surveys.route_id,
        surveys.route_name,
        surveys.start_name,
        surveys.geom_start_galcc AS geom_start,
        surveys.geom_finish_galcc AS geom_finish
      FROM
        surveys
        JOIN buffered_coast
          ON ST_Disjoint(surveys.geom_start_galcc,buffered_coast.geom)
          OR ST_Disjoint(surveys.geom_finish_galcc,buffered_coast.geom)
--         JOIN buffered_coast ON NOT ST_Intersects(buffered_coast.geom, surveys.geom_start_galcc)
      WHERE
        surveys.geom_start_galcc IS NOT NULL
        AND surveys.geom_finish_galcc IS NOT NULL
        AND surveys.surv_year BETWEEN 2008 AND 2012

-- summarise and export incorrect start/finish geoms
SELECT
  surveys.surv_year,
  surveys.region_name,
  surveys.route_id,
  surveys.route_name,
  surveys.start_name,
  surveys.start_srid AS original_start_coord_srid,
  ST_Y(geom_start) AS start_lat,
  ST_X(geom_start) AS start_long,
  surveys.finish_name,
  surveys.finish_srid AS original_finish_coord_srid,
  ST_Y(geom_finish) AS finish_lat,
  ST_X(geom_finish) AS finish_long,
  start_geom_incorrect,
  finish_geom_incorrect,
  start_end_same,
  start_finish_null
FROM surveys
WHERE
  (start_geom_incorrect = true
  OR finish_geom_incorrect = true
  OR start_end_same = true
  OR start_finish_null = true)
  AND surv_year BETWEEN 2008 AND 2012
;

-- an export with feedback appended
SELECT DISTINCT
  surveys.surv_year,
  surveys.region_name,
  surveys.route_id,
  surveys.route_name,
  surveys.start_name,
  surveys.start_srid AS original_start_coord_srid,
  ST_Y(geom_start) AS start_lat,
  ST_X(geom_start) AS start_long,
  surveys.finish_name,
  surveys.finish_srid AS original_finish_coord_srid,
  ST_Y(geom_finish) AS finish_lat,
  ST_X(geom_finish) AS finish_long,
  start_geom_incorrect,
  finish_geom_incorrect,
  start_end_same,
  start_finish_null,
  sff.matched_route_name,
  sff.notes
FROM surveys
LEFT JOIN public.start_finish_feedback sff
  ON surveys.surv_year = sff.surv_year
  AND surveys.route_name = sff.route_name
WHERE
  (surveys.start_geom_incorrect = true
  OR surveys.finish_geom_incorrect = true
  OR surveys.start_end_same = true
  OR surveys.start_finish_null = true)
  AND surveys.surv_year BETWEEN 2008 AND 2012
;

-- plot incorrect start or finish geoms
DROP VIEW IF EXISTS incorrect_start;
CREATE VIEW incorrect_start AS
SELECT
  row_number() over (),
  surveys.surv_year,
  surveys.route_id,
  surveys.route_name,
  surveys.start_name,
  ST_Y(geom_start) AS start_lat,
  ST_X(geom_start) AS start_long,
  start_end_updated,
  geom_start AS geom_start
FROM surveys
WHERE
  start_geom_incorrect = true
  AND geom_start IS NOT NULL
  AND surv_year BETWEEN 2008 AND 2012
;

-->>>>>>>>>>>>>>>>>>>> LOOP-POINT <<<<<<<<<<<<<<<<<<<<<<<
-- import Kasun's 2008-2012 corrections as start_finish_feedback
  -- from /Users/glennehmke/MEGA/Hoodie biennial trends/workflow/incorrect start-finish points_KE feedback.xlsx filter to 2008-2012 (other routes were vetted but these are not included now as routes for post 2012 are from digitised lines and start/finish-points are not used
    -- had to ingest to local drive, then export as SQL inserts with a DDL the run those from an AcuGIS console to get the data in.

-- correct negative longitudes
UPDATE start_finish_feedback
SET start_long = ABS(start_long)
WHERE
  start_long < 0
;
UPDATE start_finish_feedback
SET finish_long = ABS(finish_long)
WHERE
  finish_long < 0
;

-- update coordinates
alter table public.surveys
    add start_end_updated boolean default false not null;

UPDATE surveys
SET
  geom_start = sub.updated,
  start_end_updated = true
FROM
  (SELECT
    surv_year,
    route_name,
    ST_MakePoint(start_long, start_lat) AS updated
  FROM start_finish_feedback
  )sub
WHERE
  sub.surv_year = surveys.surv_year
  AND sub.route_name = surveys.route_name
;

UPDATE surveys
SET
  geom_finish = sub.updated,
  start_end_updated = true
FROM
  (SELECT
    surv_year,
    route_name,
    ST_MakePoint(finish_long, finish_lat) AS updated
  FROM start_finish_feedback
  )sub
WHERE
  sub.surv_year = surveys.surv_year
  AND sub.route_name = surveys.route_name
;

-- add notes and assigned route_ids
alter table public.surveys
    add feedback text;
alter table public.surveys
    add assigned_route_id text;
UPDATE surveys
SET
  assigned_route_id = start_finish_feedback.route_id,
  feedback = start_finish_feedback.notes
FROM start_finish_feedback
WHERE
  surveys.surv_year = start_finish_feedback.surv_year
  AND surveys.route_name = start_finish_feedback.route_name
;

CHECK THIS does not need to be 2 updates...