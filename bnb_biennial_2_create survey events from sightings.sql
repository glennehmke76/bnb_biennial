-- create survey events from sightings

-- v2 change to cater for multiple surveys for given route years
  -- let's accept that this will happen and retain the primary data as is in sightings instead of combining survey events in sightings and summing counts in that table
  -- let's instead aggregate events in survey (making for a single route x survey year row in that table), and then populate survey.ids to many sighting rows as necessary.
  -- from here, let's do aggregation (sum counts etc) in as a final step when exporting data for analysis.

-- archive old table
alter table public.surveys
    rename to surveys_old;

-- create survey events table
  -- initially insert digitised routes with start and finish geometries as digitised route geometries
  -- reduces multiple surveys for given route years to zero
  DROP TABLE IF EXISTS surveys CASCADE;
  CREATE TABLE surveys
  (
      region_id             integer,
      region_name           varchar,
      surv_year             integer,
      route_id              varchar,
      route_name            text,
      start_name            text,
      start_x               double precision,
      start_y               double precision,
      finish_name           text,
      finish_x              double precision,
      finish_y              double precision,
      start_srid            integer,
      geom_start            geometry(Point,4283),
      finish_srid           integer,
      geom_finish           geometry(Point,4283)
  );

    INSERT INTO surveys (region_id, region_name, surv_year, route_id)
    SELECT DISTINCT
      sightings.region_id,
      sightings.region_name,
      sightings.surv_year,
      sightings.route_id
    FROM sightings
    WHERE surv_year >=2014
  ;


--               SELECT DISTINCT
--                 sightings.region_id,
--                 sightings.region_name,
--                 sightings.surv_year,
--                 sightings.route_id,
--                 NULL AS route_name, -- nullified to avoid event pollution
--                 NULL AS start_name, -- nullified to avoid event pollution
--                 ST_X
--                   (ST_Transform
--                     (ST_StartPoint(geom), 4283)) AS start_x,
--                 ST_Y
--                   (ST_Transform
--                     (ST_StartPoint(geom), 4283)) AS start_y,
--                 NULL AS finish_name, -- nullified to avoid event pollution
--                 ST_X
--                   (ST_Transform
--                     (ST_EndPoint(geom), 4283)) AS finish_x,
--                 ST_Y
--                   (ST_Transform
--                     (ST_EndPoint(geom), 4283)) AS finish_y,
--                 4283 AS start_srid,
--                 ST_StartPoint
--                   (ST_Transform(routes_provided_consistent.geom, 4283)) AS geom_start,
--                 4283 AS finish_srid,
--                 ST_EndPoint
--                   (ST_Transform(routes_provided_consistent.geom, 4283)) AS geom_finish
--               FROM sightings
--               LEFT JOIN routes_provided_consistent
--                 ON sightings.route_id = routes_provided_consistent.route_id
--                 AND sightings.surv_year = routes_provided_consistent.surv_year
--             ;

  -- then insert non-digitised routes
  -- these will still have multiple surveys for given route years
  INSERT INTO surveys (region_id, region_name, surv_year, route_id, route_name, start_name, start_x, start_y, finish_name,
                     finish_x, finish_y, start_srid, geom_start, finish_srid, geom_finish)
  SELECT DISTINCT
    region_id,
    region_name,
    surv_year,
    route_id,
    route_name,
    start_name,
    start_x,
    start_y,
    finish_name,
    finish_x,
    finish_y,
    start_srid,
    geom_start,
    finish_srid,
    geom_finish
  FROM sightings
  WHERE
    surv_year < 2014
  ;

  ALTER TABLE IF EXISTS public.surveys
      ADD COLUMN id integer NOT NULL GENERATED ALWAYS AS IDENTITY;
  ALTER TABLE IF EXISTS public.surveys
      ADD PRIMARY KEY (id);
  CREATE INDEX surveys_surv_year_index
    ON public.surveys (surv_year);
  CREATE INDEX idx_surv_geom_start ON surveys USING gist (geom_start);
  CREATE INDEX idx_surv_geom_finish ON surveys USING gist (geom_finish);

--   back-attribute survey.id to sightings
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS survey_id;
  ALTER TABLE IF EXISTS sightings
      ADD COLUMN survey_id integer DEFAULT NULL;

  UPDATE sightings
  SET survey_id = surveys.id
  FROM surveys
  WHERE
    CONCAT
      (
      sightings.region_name,
      sightings.region_name,
      sightings.surv_year,
      sightings.route_id,
      sightings.route_name,
      sightings.start_name,
      sightings.geom_start,
      sightings.finish_name,
      sightings.geom_finish
      ) = CONCAT
      (
      surveys.region_name,
      surveys.region_name,
      surveys.surv_year,
      surveys.route_id,
      surveys.route_name,
      surveys.start_name,
      surveys.geom_start,
      surveys.finish_name,
      surveys.geom_finish
      )
  ;

  -- identify routes with multiple surveys for given route years
    alter table public.surveys
        add multiple_surveys boolean default false;
    comment on column public.surveys.multiple_surveys is 'identifier for multiple survey events per route x survey year';

    UPDATE surveys
    SET multiple_surveys = true
    FROM
        (SELECT
          route_id,
          surv_year
        FROM surveys
        WHERE
          route_id IS NOT NULL
        GROUP BY
          route_id,
          surv_year
        HAVING
          COUNT(*) > 1
        )sub
    WHERE
      sub.route_id = surveys.route_id
      AND sub.surv_year = surveys.surv_year
    ;

  ALTER TABLE IF EXISTS sighting
      ADD CONSTRAINT sighting_ibfk_1 FOREIGN KEY (survey_id)
      REFERENCES survey (id) MATCH SIMPLE
      ON UPDATE RESTRICT
      ON DELETE CASCADE
      NOT VALID;
  CREATE INDEX IF NOT EXISTS fki_sighting_ibfk_1
      ON sighting(survey_id);

alter table sightings
    drop constraint sightings_surveys_id_fk;

alter table sightings
    drop constraint sightings_surveys_id_fk;
alter table sightings
  add constraint sightings_surveys_id_fk
    foreign key (survey_id) references surveys (id)
      match simple
      on update cascade
      on delete no action
;

-- after events have been created delete sightings with null counts by species
DELETE FROM sightings
WHERE COALESCE(num_adults,0) + COALESCE(num_juvs,0) = 0;
