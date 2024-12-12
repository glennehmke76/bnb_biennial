-- permutations
-- all derived routes must have name and year to link back on
-- perm
DROP TABLE IF EXISTS routes_final;
CREATE TABLE routes_final AS (
SELECT
  routes_master.state_code,
  routes_master.route_id,
  routes_master.surv_year,
  routes_master.route_name_500 AS route_name,
  routes_master.delta_derived_500 AS delta,
  ABS(routes_master.delta_derived_500) AS abs_delta,
  'derived_500' AS route_source,
  ST_Union(routes_master.geom_derived_500) AS geom
FROM routes_master
WHERE
  route_source = 'derived'
  AND COALESCE(ABS(delta_derived_500), 0) <= COALESCE(ABS(delta_derived_2500), 0)
  AND geom_derived_500 IS NOT NULL
GROUP BY
  routes_master.state_code,
  routes_master.route_id,
  routes_master.surv_year,
  routes_master.route_name_500,
  routes_master.delta_derived_500,
  ABS(routes_master.delta_derived_500)
);

-- add 2500m geoms with lower detla to mean proivided routes than the 2500m permutation (by inference through not existing join)
INSERT INTO routes_final (state_code, route_id, surv_year, route_name, delta, abs_delta, geom, route_source)
SELECT
  routes_master.state_code,
  routes_master.route_id,
  routes_master.surv_year,
  routes_master.route_name_2500 AS route_name,
  routes_master.delta_derived_2500 AS delta,
  ABS(routes_master.delta_derived_2500) AS abs_delta,
  'derived_2500' AS route_source,
  ST_Union(routes_master.geom_derived_2500) AS geom
FROM routes_master
LEFT JOIN routes_final
  ON routes_master.route_id = routes_final.route_id
  AND routes_master.surv_year = routes_final.surv_year
WHERE
  routes_final.route_id IS NULL
  AND geom_derived_2500 IS NOT NULL
GROUP BY
  routes_master.state_code,
  routes_master.route_id,
  routes_master.surv_year,
  routes_master.route_name_2500,
  routes_master.delta_derived_2500,
  ABS(routes_master.delta_derived_2500)
;

-- add provided routes to finish permutation
INSERT INTO routes_final (state_code, route_id, surv_year, geom, route_source)
SELECT
  state_code,
  route_id,
  surv_year,
  'provided' AS route_source,
  ST_Union(geom_provided) AS geom
FROM routes_master
WHERE
  route_source = 'provided routes'
GROUP BY
  state_code,
  route_id,
  surv_year
;

-- make tables for alternative routes to use in vetting in replace working layer
DROP TABLE IF EXISTS routes_final_2500;
CREATE TABLE routes_final_2500 AS (
SELECT
  routes_master.state_code,
  routes_master.route_id,
  routes_master.surv_year,
  routes_master.route_name_500 AS route_name,
  routes_master.delta_derived_500 AS delta,
  ABS(routes_master.delta_derived_500) AS abs_delta,
  routes_master.geom_derived_2500 AS geom,
  'derived_2500' AS route_source
FROM routes_master
WHERE
  geom_derived_2500 IS NOT NULL
);

DROP TABLE IF EXISTS routes_final_500;
CREATE TABLE routes_final_500 AS (
SELECT
  routes_master.state_code,
  routes_master.route_id,
  routes_master.surv_year,
  routes_master.route_name_500 AS route_name,
  routes_master.delta_derived_500 AS delta,
  ABS(routes_master.delta_derived_500) AS abs_delta,
  routes_master.geom_derived_500 AS geom,
  'derived_500' AS route_source
FROM routes_master
WHERE
  geom_derived_500 IS NOT NULL
);

-- check any routes not included in above
SELECT
  *
FROM routes_master
LEFT JOIN routes_final
  ON routes_master.route_id = routes_final.route_id
  AND routes_master.surv_year = routes_final.surv_year
WHERE
  routes_master.route_source = 'derived'
  AND routes_final.route_id IS NULL

-- any multiple route years
SELECT
  route_id,
  surv_year,
  COUNT(*) AS xxx
FROM routes_final
GROUP BY
  route_id,
  surv_year
HAVING
  COUNT(*) > 1


-- add supoer_route_id





-- then do a run of summary stats within route_ids...
SELECT
  state_code,
  route_id,
  surv_year,
  delta,
  abs_delta,
  route_source
FROM routes_final
WHERE
  abs_delta < 1000
  AND state_code = 'VIC'

