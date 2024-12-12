-- now derive a unioned layer of unique route geoms under this - this is the FINAL layer 'routes_integrated'
DROP TABLE IF EXISTS routes_integrated;
create sequence routes_integrated_seq
  as integer;
create table public.routes_integrated (
  id integer primary key not null default nextval('routes_integrated_seq'::regclass),
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
create index sidx_routes_integrated_geom on routes_integrated using gist (geom);
alter sequence routes_integrated_seq owned by routes_integrated.id;

insert into routes_integrated (route_source, route_id, surv_year, super_route_id, delta, abs_delta, aggregate,
                               notes, exclude, needs_review, length, geom)
SELECT
  final_route_data_super_routes.route_source,
  final_route_data_super_routes.route_id,
  final_route_data_super_routes.surv_year,
  final_route_data_super_routes.super_route_id,
  routes_final_merged_aggregate AS aggregate,
  routes_final_merged_notes AS notes,
  routes_final_merged_exclude AS exclude,
  routes_final_merged_needs_review AS needs_review,
  ST_Length(geom),
  ST_Multi(ST_Union(geom)) AS geom
FROM final_route_data_super_routes
GROUP BY
  final_route_data_super_routes.route_source,
  final_route_data_super_routes.route_id,
  final_route_data_super_routes.surv_year,
  final_route_data_super_routes.super_route_id,
  routes_final_merged_aggregate,
  routes_final_merged_notes,
  routes_final_merged_exclude,
  routes_final_merged_needs_review,
  ST_Length(geom)
;


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

