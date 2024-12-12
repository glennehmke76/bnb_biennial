-- review and modify in GIS - see - bnb_biennial/process screenshots

-- union geoms and re-calc diagnostics
drop table if exists routes_integrated_;
create table public.routes_integrated_ (
  route_source character varying,
  route_id character varying(50),
  surv_year integer,
  super_route_id integer,
  delta double precision,
  abs_delta double precision,
  aggregate integer,
  notes character varying,
  exclude integer,
  needs_review integer,
  length integer,
  geom geometry(MultiLineString,3112)
);

insert into routes_integrated_ (route_source, route_id, surv_year, super_route_id, aggregate,
                               notes, exclude, needs_review, geom)
SELECT
  route_source,
  route_id,
  surv_year,
  super_route_id,
  aggregate,
  notes,
  exclude,
  needs_review,
  ST_Multi(ST_Union(geom)) AS geom
FROM routes_integrated
GROUP BY
  route_source,
  route_id,
  surv_year,
  super_route_id,
  aggregate,
  notes,
  exclude,
  needs_review
;

-- check for multiple field values across geometries and resolve then union
SELECT
  route_id, surv_year,
  Count((Concat(route_id, surv_year))) AS count
FROM
  (SELECT
    route_source,
    route_id,
    surv_year,
    super_route_id,
    aggregate,
    notes,
    exclude,
    needs_review,
    ST_Multi(ST_Union(geom)) AS geom
  FROM routes_integrated_
  GROUP BY
    route_source,
    route_id,
    surv_year,
    super_route_id,
    aggregate,
    notes,
    exclude,
    needs_review
  )sub
  GROUP BY
    route_id, surv_year
  HAVING
    Count((Concat(route_id, surv_year))) > 1;
  ;

TRUNCATE TABLE routes_integrated;
insert into routes_integrated (route_source, route_id, surv_year, super_route_id, aggregate,
                               notes, exclude, needs_review, geom)
SELECT
  route_source,
  route_id,
  surv_year,
  super_route_id,
  aggregate,
  notes,
  exclude,
  needs_review,
  geom
FROM routes_integrated_
;

-- re-run diagnostics
UPDATE routes_integrated
SET length = ST_Length(geom)
;

-- derived deltas are incorrect and will be changed anyway so draw from here
WITH mean_route_length AS
  (SELECT
  route_id,
  AVG(length) AS mean_length,
  COUNT(length) AS num_surv_years,
  STDDEV(length) AS sd_length
  FROM routes_integrated
  WHERE
    surv_year > 2012
  GROUP BY
    route_id
  )
UPDATE routes_integrated
SET delta = sub.delta
FROM
  (SELECT
    routes_integrated.route_id,
    routes_integrated.surv_year,
    mean_route_length.mean_length,
    routes_integrated.length,
    100 - (mean_route_length.mean_length / routes_integrated.length)::numeric * 100 AS delta
  FROM routes_integrated
  JOIN mean_route_length ON routes_integrated.route_id = mean_route_length.route_id
  WHERE
    surv_year < 2014
    AND routes_integrated.length > 0
  )sub
WHERE
  routes_integrated.route_id = sub.route_id
  AND routes_integrated.surv_year = sub.surv_year
  AND routes_integrated.surv_year < 2014
;

UPDATE routes_integrated
SET abs_delta = ABS(delta);

SELECT DISTINCT
  route_source
FROM routes_integrated;

drop table if exists routes_integrated_;

-- attribute super routes and notes
alter table routes_integrated
    add notes_super_routes text;

-- add super route diagnostics
