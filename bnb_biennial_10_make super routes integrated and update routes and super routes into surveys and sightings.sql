DROP TABLE IF EXISTS super_routes_integrated;
create sequence super_routes_integrated_seq
  as integer;
create table super_routes_integrated (
  id integer primary key not null default nextval('super_routes_integrated_seq'::regclass),
  super_route_id integer,
  surv_year integer,
  delta double precision,
  abs_delta double precision,
  notes character varying,
  exclude integer,
  needs_review integer,
  length integer,
  geom geometry(MultiLineString,3112)
);
create index sidx_super_routes_integrated_geom on super_routes_integrated using gist (geom);
alter sequence super_routes_integrated_seq owned by super_routes_integrated.id;

-- add 2008-present data from routes_integrated
insert into super_routes_integrated (super_route_id, surv_year, notes, needs_review,
                                      geom)
SELECT
  super_route_id,
  surv_year,
  notes_super_routes,
  needs_review,
  ST_Multi(ST_Union(geom)) AS geom
FROM routes_integrated
WHERE
  super_route_id IS NOT NULL
GROUP BY
  super_route_id,
  surv_year,
  notes_super_routes,
  needs_review
;

-- check super routes are distinct
SELECT
  super_route_id, surv_year,
  Count((Concat(super_route_id, surv_year))) AS count
FROM
  (SELECT
    surv_year,
    notes,
    super_route_id
  FROM super_routes_integrated
  GROUP BY
    surv_year,
    notes,
    super_route_id
  )sub
  GROUP BY
    super_route_id, surv_year
  HAVING
    Count((Concat(super_route_id, surv_year))) > 1;
  ;

-- add length
UPDATE super_routes_integrated
SET length = ST_Length(geom)
;

-- add delta from provided super routes
UPDATE super_routes_integrated
SET delta = 100 - (super_routes_integrated.length / super_routes_consistent.route_length) :: numeric * 100
FROM super_routes_consistent
WHERE
  super_routes_consistent.super_route_id = super_routes_integrated.super_route_id
  AND super_routes_integrated.surv_year >= 2008
;
UPDATE super_routes_integrated
SET abs_delta = ABS(delta);

-- do super_route_integrated match super_routes provided?
SELECT DISTINCT
  super_routes_integrated.super_route_id AS sri_id,
  super_routes_consistent.super_route_id AS src_id
FROM super_routes_integrated
FULL OUTER JOIN super_routes_consistent
  ON super_routes_integrated.super_route_id = super_routes_consistent.super_route_id
WHERE
  super_routes_integrated.super_route_id IS NULL
  OR super_routes_consistent.super_route_id IS NULL
;
-- super_route 27 (Mouth of the Snowy to Cape Conran) and 28 (Cape Conran to Pearl Point) are not in sr integrated due to confounding which must be checked in routes_integrated

-- are routes nested in super routes? - should ne null
SELECT
  super_route_id, route_id,
  Count((Concat(super_route_id, route_id))) AS count
FROM
  (SELECT
    route_id,
    super_route_id
  FROM routes_integrated
  WHERE super_route_id IS NOT NULL
  GROUP BY
    route_id,
    super_route_id
  )sub
  GROUP BY
    super_route_id, route_id
  HAVING
    Count((Concat(super_route_id, route_id))) > 1;
  ;

-- add date for QGIS animation
alter table super_routes_integrated
  add date date;
UPDATE super_routes_integrated
SET date = TO_DATE(CONCAT(surv_year, '/00', '/00'), 'YYYY/MM/DD')
;


-- update super route ids into surveys and sightings based on route_ids
alter table surveys
  drop column if exists super_route_id;
alter table surveys
  add super_route_id integer;
create index surveys_super_route_id_index
    on surveys (super_route_id);
UPDATE surveys
SET super_route_id = routes_integrated.super_route_id
FROM routes_integrated
WHERE
  routes_integrated.route_id = surveys.route_id
  AND routes_integrated.surv_year = surveys.surv_year
;

alter table sightings
  drop column if exists super_route_id;
alter table sightings
  add super_route_id integer;
create index sightings_super_route_id_index
    on sightings (super_route_id);
UPDATE sightings
SET super_route_id = routes_integrated.super_route_id
FROM routes_integrated
WHERE
  routes_integrated.route_id = sightings.route_id
  AND routes_integrated.surv_year = sightings.surv_year
;

-- add names from super_routes_consistent
alter table super_routes_integrated
  add name varchar;
UPDATE super_routes_integrated
SET name = route_name
FROM super_routes_consistent
WHERE super_routes_integrated.super_route_id = super_routes_consistent.super_route_id;




    -- once off addition of previously made notes
    UPDATE super_routes_integrated
    SET notes_sri_data = sr_data_notes
    FROM super_routes_final_data
    WHERE super_routes_integrated.super_route_id = super_routes_final_data.super_route_id;

    UPDATE super_routes_integrated
    SET excl_review_sri_data = sr_data_exclude_review
    FROM super_routes_final_data
    WHERE super_routes_integrated.super_route_id = super_routes_final_data.super_route_id;



