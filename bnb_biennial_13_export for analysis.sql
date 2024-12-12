-- sum some counts etc in an aggeregate with filters... super routes or regional groups etc
DROP TABLE IF EXISTS summed_counts;
CREATE TABLE summed_counts AS
SELECT
  'core hoodie routes' AS permutation,
  region_name AS region,
  regional_group,
  length / 1000 :: numeric AS length_kms,
  surv_year,
  num_hp_total,
  coalesce(num_hp_total, 0) / length :: numeric * 1000 AS density_hp_total
FROM
  (SELECT
    regions.region_name,
    regions.regional_group,
    routes_integrated.surv_year,
    SUM(routes_integrated.length) AS length,
    SUM(coalesce(num_hp_adults,0)) AS num_hp_adults,
    SUM(coalesce(num_hp_juvs,0)) AS num_hp_juvs,
    SUM(coalesce(num_hp_total,0)) AS num_hp_total
  FROM routes_integrated
  JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112),
                                ST_PointOnSurface(routes_integrated.geom))
  JOIN route_names ON routes_integrated.route_id = route_names.route_id
  WHERE
    route_names.core_habitat_hp = 1
  GROUP BY
    routes_integrated.surv_year,
    regions.region_name,
    regions.regional_group
  )summed_counts
ORDER BY
  region_name,
  regional_group,
  surv_year
;

insert into summed_counts (permutation, region, regional_group, length_kms, surv_year, num_hp_total, density_hp_total)
SELECT
  'all routes' AS permutation,
  region_name AS region,
  regional_group,
  length / 1000 :: numeric AS length_kms,
  surv_year,
  num_hp_total,
  coalesce(num_hp_total, 0) / length :: numeric * 1000 AS density_hp_total
FROM
  (SELECT
    regions.region_name,
    regions.regional_group,
    routes_integrated.surv_year,
    SUM(routes_integrated.length) AS length,
    SUM(coalesce(num_hp_adults,0)) AS num_hp_adults,
    SUM(coalesce(num_hp_juvs,0)) AS num_hp_juvs,
    SUM(coalesce(num_hp_total,0)) AS num_hp_total
  FROM routes_integrated
  JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(routes_integrated.geom))
  JOIN route_names ON routes_integrated.route_id = route_names.route_id
  WHERE
    regions.regional_group = 'Mornington Peninsula'
  GROUP BY
    routes_integrated.surv_year,
    regions.region_name,
    regions.regional_group
  )summed_counts
ORDER BY
  region_name,
  regional_group,
  surv_year
;




-- sum counts in a region
SELECT
  surv_year,
  SUM(length) AS total_length,
  COUNT(DISTINCT route_id) AS num_routes,
  SUM(num_hp_total) AS total_hp_count,
  SUM(num_rcp_total) AS total_rcp_count,
  SUM(num_poyc_total) AS total_poyc_count,
  SUM(num_soyc_total) AS total_soyc_count
FROM routes_integrated
JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), routes_integrated.geom)
WHERE
  regions.regional_group_id = 1
GROUP BY
  surv_year
;

-- export routes for analysis
COPY
(SELECT
  regions.region_name,
  regions.regional_group,
  routes_integrated.route_source,
  routes_integrated.route_id,
  routes_integrated.surv_year,
  routes_integrated.super_route_id,
  routes_integrated.delta,
  routes_integrated.abs_delta,
  routes_integrated.aggregate,
--   routes_integrated.notes,
--   notes_super_routes,
  routes_integrated.exclude,
  routes_integrated.needs_review,
  routes_integrated.length,
  coalesce(num_hp_adults,0) AS num_hp_adults,
  coalesce(num_hp_juvs,0) AS num_hp_juvs,
  coalesce(num_hp_total,0) AS num_hp_total,
  coalesce(density_hp_adults,0) AS density_hp_adults,
  coalesce(density_hp_juvs,0) AS density_hp_juvs,
  coalesce(density_hp_total,0) AS density_hp_total,
  coalesce(num_rcp_adults,0) AS num_rcp_adults,
  coalesce(num_rcp_juvs,0) AS num_rcp_juvs,
  coalesce(num_rcp_total,0) AS num_rcp_total,
  coalesce(density_rcp_adults,0) AS density_rcp_adults,
  coalesce(density_rcp_juvs,0) AS density_rcp_juvs,
  coalesce(density_rcp_total,0) AS density_rcp_total,
  coalesce(num_poyc_adults,0) AS num_poyc_adults,
  coalesce(num_poyc_juvs,0) AS num_poyc_juvs,
  coalesce(num_poyc_total,0) AS num_poyc_total,
  coalesce(density_poyc_adults,0) AS density_poyc_adults,
  coalesce(density_poyc_juvs,0) AS density_poyc_juvs,
  coalesce(density_poyc_total,0) AS density_poyc_total,
  coalesce(num_soyc_adults,0) AS num_soyc_adults,
  coalesce(num_soyc_juvs,0) AS num_soyc_juvs,
  coalesce(num_soyc_total,0) AS num_soyc_total,
  coalesce(density_soyc_adults,0) AS density_soyc_adults,
  coalesce(density_soyc_juvs,0) AS density_soyc_juvs,
  coalesce(density_soyc_total,0) AS density_soyc_total
FROM routes_integrated
JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(routes_integrated.geom))
WHERE routes_integrated.route_id <> 'confounded'
)
TO '/Users/glennehmke/MEGA/Hoodie biennial trends/final/outputs/routes_integrated_data.csv' (FORMAT csv, HEADER)
;

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
JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(super_routes_integrated.geom))
)
TO '/Users/glennehmke/MEGA/Hoodie biennial trends/final/outputs/super_routes_integrated_data.csv' (FORMAT csv, HEADER)
;

  -- for modern years + past

  add names / regions


COPY
(

WITH joined AS
  (SELECT
    coalesce(super_routes_integrated.super_route_id, super_routes_data_analysis.super_route_id) AS super_route_id,
    coalesce(super_routes_integrated.surv_year, super_routes_data_analysis.surv_year) AS surv_year,
    coalesce(super_routes_integrated.super_route_id, super_routes_data_analysis.super_route_id) AS super_route_id,
    super_routes_integrated.name AS super_route_name,
    super_routes_integrated.surv_year AS year,
    super_routes_integrated.delta,
    super_routes_integrated.abs_delta,
  --   super_routes_integrated.notes,
  --   notes_super_routes,
    super_routes_integrated.exclude,
    super_routes_integrated.needs_review,
    super_routes_integrated.length / 1000 :: numeric AS super_routes_integrated_length,
    super_routes_data_analysis.length AS super_routes_data_analysis_length,
    coalesce(super_routes_integrated.num_hp_total,0) AS num_hp_total,
    super_routes_data_analysis.total_hp AS old_count_total
  FROM super_routes_integrated
  FULL OUTER JOIN super_routes_data_analysis
    ON super_routes_integrated.super_route_id = super_routes_data_analysis.super_route_id
    AND super_routes_integrated.surv_year = super_routes_data_analysis.surv_year
  )
SELECT
  *,
  COALESCE(joined.num_hp_total,0) - COALESCE(joined.old_count_total,0) AS delta
FROM joined



)
TO '/Users/glennehmke/MEGA/Hoodie biennial trends/final/outputs/super_routes_integrated_data_compared.csv' (FORMAT csv, HEADER)
;







SELECT
  *,
  COALESCE(joined.num_hp_total,0) - COALESCE(joined.old_count_total,0) AS delta
FROM joined





-- attribute trend slope in super regions then update to consistent for GIS
alter table super_routes_consistent
    add slope varchar;
UPDATE super_routes_consistent
SET slope = super_routes.slope
FROM super_routes
WHERE super_routes.id = super_routes_consistent.super_route_id
;


      -- count of years
      WITH unioned AS
        (SELECT
          super_routes_consistent.super_route_id,
          super_routes_integrated.surv_year,
          super_routes_consistent.geom
        FROM super_routes_integrated
        JOIN super_routes_consistent ON super_routes_integrated.super_route_id = super_routes_consistent.super_route_id
        WHERE
          super_routes_integrated.count_total is not null
          AND super_routes_integrated.geom is not null
          AND super_routes_integrated.exclude is null
        )
          SELECT
            super_route_id,
            geom,
            COUNT(*) as num
          FROM unioned
          GROUP BY
            super_route_id,
            geom
          ;


SELECT
  regions.region_name,
  regions.regional_group,
  surv_year,
  SUM(length) AS total_length,
  COUNT(DISTINCT route_id) AS num_routes,
  SUM(num_hp_total) AS total_hp_count,
  SUM(num_rcp_total) AS total_rcp_count,
  SUM(num_poyc_total) AS total_poyc_count,
  SUM(num_soyc_total) AS total_soyc_count
FROM routes_integrated
JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), routes_integrated.geom)

GROUP BY
  regions.region_name,
  regions.regional_group,
  surv_year
;


--

