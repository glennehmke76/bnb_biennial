-- export super routes for analysis
  -- for modern years only
COPY
(SELECT
  regions.id AS region_id,
  regions.region_name,
  regional_group_id,
  regions.regional_group AS regional_group_name,
  super_routes_integrated.super_route_id,
  super_routes_integrated.name AS super_route_name,
  super_routes_integrated.surv_year AS year,
  super_routes_integrated.delta,
  super_routes_integrated.abs_delta,
--   super_routes_integrated.notes,
--   notes_super_routes,
  super_routes_integrated.exclude,
  super_routes_integrated.needs_review,
  super_routes_integrated.length,
  coalesce(num_hp_adults,0) AS num_hp_adults,
  coalesce(num_hp_juvs,0) AS num_hp_juvs,
  coalesce(num_hp_total,0) AS num_hp_total,
  coalesce(density_hp_adults,0) AS density_hp_adults,
  coalesce(density_hp_juvs,0) AS density_hp_juvs,
  coalesce(density_hp_total,0) AS density_hp_total
FROM super_routes_integrated
RIGHT JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(super_routes_integrated.geom))
)
TO '/Users/glennehmke/MEGA/Hoodie biennial trends/final/outputs/super_routes_integrated_data.csv' (FORMAT csv, HEADER)
;

-- for modern years + past
drop table if exists super_route_counts_integrated;
CREATE TABLE super_route_counts_integrated AS
SELECT
  coalesce(super_routes_integrated.super_route_id, super_routes_data_analysis.super_route_id) AS super_route_id,
  coalesce(super_routes_data_analysis.super_route_name, super_routes_integrated.name) AS name,
  coalesce(super_routes_integrated.surv_year, super_routes_data_analysis.surv_year) AS surv_year,
  super_routes_integrated.delta,
  super_routes_integrated.abs_delta,
  super_routes_integrated.exclude,
  super_routes_integrated.needs_review,
  super_routes_integrated.notes,
  super_routes_integrated.length / 1000 :: numeric AS super_routes_integrated_length,
  super_routes_data_analysis.length AS super_routes_data_analysis_length,
  super_routes_integrated.num_hp_total AS num_hp_total,
  super_routes_data_analysis.total_hp AS old_count_total
FROM super_routes_integrated
FULL OUTER JOIN super_routes_data_analysis
  ON super_routes_integrated.super_route_id = super_routes_data_analysis.super_route_id
  AND super_routes_integrated.surv_year = super_routes_data_analysis.surv_year
ORDER BY
  coalesce(super_routes_integrated.super_route_id, super_routes_data_analysis.super_route_id),
  coalesce(super_routes_integrated.surv_year, super_routes_data_analysis.surv_year)
;

-- add regions
alter table super_route_counts_integrated
  drop column if exists region_name,
  drop column if exists regional_group_id,
  drop column if exists regional_group
;
alter table super_route_counts_integrated
  add region_name varchar,
  add regional_group_id integer,
  add regional_group varchar
;

WITH super_routes_regions AS
  (SELECT
    super_routes_integrated.super_route_id,
    regions.region_name,
    regional_group_id,
    regions.regional_group
  FROM super_routes_integrated
  JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(super_routes_integrated.geom))
  )
UPDATE super_route_counts_integrated
SET
  region_name = super_routes_regions.region_name,
  regional_group_id = super_routes_regions.regional_group_id,
  regional_group = super_routes_regions.regional_group
FROM super_routes_regions
WHERE super_route_counts_integrated.super_route_id = super_routes_regions.super_route_id
;

-- set global length
UPDATE super_route_counts_integrated
SET super_routes_data_analysis_length = super_routes_data_analysis.length
FROM super_routes_data_analysis
WHERE super_route_counts_integrated.super_route_id = super_routes_data_analysis.super_route_id;

-- delta
alter table super_route_counts_integrated
    add count_delta integer;
UPDATE super_route_counts_integrated
SET count_delta = old_count_total - num_hp_total;

-- create count permutations
-- priority new
alter table super_route_counts_integrated
  drop column if exists count_priority_new;
alter table super_route_counts_integrated
    add count_priority_new integer;

UPDATE super_route_counts_integrated
SET count_priority_new = sub.count_priority_new
FROM
  (SELECT
    super_route_id,
    surv_year,
    CASE
      WHEN num_hp_total IS NULL THEN old_count_total
      WHEN old_count_total IS NULL THEN num_hp_total
      WHEN num_hp_total = old_count_total THEN num_hp_total
      WHEN num_hp_total <> old_count_total THEN old_count_total
    END AS count_priority_new
  FROM super_route_counts_integrated
  )sub
WHERE
  super_route_counts_integrated.super_route_id = sub.super_route_id
  AND super_route_counts_integrated.surv_year = sub.surv_year
;

-- priority old
alter table super_route_counts_integrated
  drop column if exists count_priority_old;
alter table super_route_counts_integrated
    add count_priority_old integer;

UPDATE super_route_counts_integrated
SET count_priority_old = sub.count_priority_old
FROM
  (SELECT
    super_route_id,
    surv_year,
    CASE
      WHEN num_hp_total IS NULL THEN old_count_total
      WHEN old_count_total IS NULL THEN num_hp_total
      WHEN num_hp_total = old_count_total THEN num_hp_total
      WHEN num_hp_total <> old_count_total THEN num_hp_total
    END AS count_priority_old
  FROM super_route_counts_integrated
  )sub
WHERE
  super_route_counts_integrated.super_route_id = sub.super_route_id
  AND super_route_counts_integrated.surv_year = sub.surv_year
;

-- density
-- density for old counts
alter table super_route_counts_integrated
  drop column if exists density_priority_old;
alter table super_route_counts_integrated
    add density_priority_old numeric;
UPDATE super_route_counts_integrated
SET density_priority_old = coalesce(count_priority_old, 0) / super_routes_data_analysis_length :: numeric
;

-- density for new counts
alter table super_route_counts_integrated
  drop column if exists density_priority_new;
alter table super_route_counts_integrated
    add density_priority_new numeric;
UPDATE super_route_counts_integrated
SET density_priority_new = coalesce(count_priority_new, 0) / coalesce(super_routes_integrated_length, super_routes_data_analysis_length) :: numeric
;

alter table super_route_counts_integrated
  drop column if exists perc_count_delta;
alter table super_route_counts_integrated
    add perc_count_delta numeric;

UPDATE super_route_counts_integrated
SET perc_count_delta = 100 - count_priority_new / count_priority_old :: numeric * 100
WHERE
  count_priority_new IS NOT NULL
  AND count_priority_old IS NOT NULL
  AND count_priority_new > 0
  AND count_priority_old > 0
  AND count_priority_new <> count_priority_old
;

-- where do densities differ
density_priority_old <> density_priority_new

-- dataset export
  -- all routes
  SELECT
    super_route_counts_integrated.region_name,
    super_route_counts_integrated.super_route_id,
    super_route_counts_integrated.name,
    super_route_counts_integrated.surv_year,
    super_route_counts_integrated.delta,
    super_route_counts_integrated.abs_delta,
    super_route_counts_integrated.exclude,
    super_route_counts_integrated.needs_review,
    super_route_counts_integrated.notes,
    round(super_routes.route_length :: numeric / 1000, 3) AS provided_super_route_lengths_from_geom,
    round(super_routes_integrated_length :: numeric, 3) AS "2008_2012_summed_route_lengths",
    round(super_routes_data_analysis_length :: numeric, 3) AS old_route_length_from_spreadsheet,
    super_route_counts_integrated.count_priority_new,
    super_route_counts_integrated.count_priority_old,
    super_route_counts_integrated.density_priority_old,
    super_route_counts_integrated.density_priority_new,
    round(super_route_counts_integrated.perc_count_delta :: numeric, 2) AS perc_count_delta
  FROM super_route_counts_integrated
  JOIN super_routes ON super_route_counts_integrated.super_route_id = super_routes.id
  WHERE super_route_counts_integrated.region_name IS NOT NULL -- to exclude any confounded super routes
  ORDER BY super_route_id ASC
  ;

 -- clean data
  SELECT
    super_route_counts_integrated.region_name,
    super_route_counts_integrated.super_route_id,
    super_route_counts_integrated.name,
    super_route_counts_integrated.surv_year,
    super_routes.route_length :: numeric / 1000 AS route_length,
    super_route_counts_integrated.count_priority_new,
    super_route_counts_integrated.count_priority_old,
    super_route_counts_integrated.density_priority_old,
    super_route_counts_integrated.density_priority_new
  FROM super_route_counts_integrated
  JOIN super_routes ON super_route_counts_integrated.super_route_id = super_routes.id
  WHERE
    coalesce(exclude, needs_review) IS NULL
    AND super_route_counts_integrated.region_name IS NOT NULL
  ;



setwd("~/MEGAsync/Hoodie biennial trends/Rbiennial")
"HP" <- read.csv("/Users/glennehmke/MEGA/Hoodie biennial trends/Rbiennial/super_route_counts_integrated_clean.csv", header = TRUE, sep = ",")

# Overall mixed model
GAMMHP_selected <- gamm (density_priority_old~s(surv_year,k=5), data=HP, family = nb, random=list(super_route_id=~1))
GAMMHP_selected
plot(GAMMHP_selected$gam)

