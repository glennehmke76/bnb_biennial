


-- replace new provided into integrated by deleting unsurveyed routes but NOT replacing geoms but deleting unsurveyed routes previously imported


-- add not surveyed

-- check and delete

-- update surveys > sightings based on where <> routes_integrated vs exists surveys...
  -- there should not be a difference? should there?
  -- did I populate absences (i.e. make a survey event) for absences? No...
-- find any differences


-- add route_not_surveyed
alter table routes_integrated
  drop column if exists surveyed;
alter table routes_integrated
  add surveyed smallint;

SELECT
  concat(routes_integrated.route_id, routes_integrated.surv_year) AS ri_route_year,
  concat(routes_provided.route_id, routes_provided.surv_year) AS rp_route_year
FROM routes_integrated
FULL OUTER JOIN routes_provided
  ON concat(routes_integrated.route_id, '_', routes_integrated.surv_year) = concat(routes_provided.route_id, '_', routes_provided.surv_year)
WHERE
--   concat(routes_provided.route_id, routes_provided.surv_year) = ''
  concat(routes_integrated.route_id, routes_integrated.surv_year) = ''
  AND surv_year > 2012

;

UPDATE routes_integrated
SET surveyed = 1
FROM routes_provided
WHERE
  routes_integrated.route_id = routes_provided.route_id
  AND routes_integrated.surv_year = routes_provided.surv_year
  AND
;

-- delete unsurveyed routes
DELETE
FROM routes_integrated
WHERE
surveyed is null AND surv_year > 2012
;

-- what surveys are unsurveyed (acc to routes_integrated)
SELECT
  routes_integrated.route_id AS ri_route,
  routes_integrated.surv_year AS ri_surv_year,
  routes_integrated.geom,
  surveys.route_id AS surveys_route,
  surveys.surv_year AS surveys_surv_year
FROM routes_integrated
FULL OUTER JOIN surveys
  ON concat(routes_integrated.route_id, '_', routes_integrated.surv_year) = concat(surveys.route_id, '_', surveys.surv_year)
-- JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), routes_integrated.geom)
WHERE
--   concat(surveys.route_id, surveys.surv_year) = ''
  concat(routes_integrated.route_id, routes_integrated.surv_year) = ''
  AND surveys.surv_year > 2012
  AND surveys.route_id NOT LIKE '%Ad-hoc%'
;

