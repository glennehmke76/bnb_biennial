
-- make view layer of aggregated count data...
SELECT
  super_route_id,
  super_route_name,
  surv_year,
  count_total,
  ROUND(density_total, 4) density_total,
--   route_source,
  ROUND(route_length,0) AS route_length,
  ROUND(delta_from_super_route, 2) AS delta_from_super_route,
--   aggregate,
  exclude,
  needs_review,
  notes
FROM super_routes_integrated
-- WHERE super_route_name = 'Mallacoota to NSW Border'
ORDER BY
  super_route_id,
  surv_year

-- 20 july...
-- export whole dataset
-- does not have
SELECT
  combined.*,
  routes_master.region_name,
  routes_master.route_id AS routes_master_route_id,
  routes_master.surv_year AS routes_master_surv_year,
  route_length_provided,
  delta_provided_vs_consistent,
  routes_master.centroid_x,
  routes_master.route_source,
  route_name_2500,
  route_name_500,
  route_length_derived_2500,
  route_length_derived_500,
  delta_derived_500,
  delta_derived_2500,
  routes_master.state_code,
  routes_master.multiple_surveys,
  assigned_route_id_derived_500,
  assigned_route_id_derived_2500,
  routes_master.super_route_id
FROM
    (SELECT
      final_route_data_super_routes.super_route_id,
      final_route_data_super_routes.routes_integrated_merged_route_name,
      final_route_data_super_routes.routes_integrated_merged_super_route_id,
      final_route_data_super_routes.super_route_name,
      routes_integrated_merged_route_name,
      routes_integrated_merged_delta,
      routes_integrated_merged_abs_delta,
      routes_integrated_merged_route_source,
      routes_integrated_merged_aggregate,
      routes_integrated_merged_notes,
      routes_integrated_merged_exclude,
      routes_integrated_merged_needs_review,
      sightings.form_id,
      sightings.region_id,
      sightings.region_name,
      sightings.surv_year,
      sightings.route_id,
      sightings.route_name,
      sightings.start_name,
      sightings.start_y,
      sightings.start_x,
      sightings.finish_name,
      sightings.finish_y,
      sightings.finish_x,
      sighting_y,
      sighting_x,
      sightings.sp_id,
      sightings.num_adults,
      sightings.num_juvs,
      start_end_same,
      sightings.start_srid,
      sightings.finish_srid,
      sightings.super_route_id AS sightings_super_route_id,
      sightings.survey_id AS sightings_survey_id,
      surveys.multiple_surveys
    FROM final_route_data_super_routes
    FULL OUTER JOIN surveys ON final_route_data_super_routes.survey_id = surveys.id
    FULL OUTER JOIN sightings ON final_route_data_super_routes.survey_id = sightings.survey_id
    WHERE
      surveys.route_id <> 'Ad-hoc'
      AND surveys.route_id <> 'Ad-hoc route'
    )combined
JOIN routes_master
  ON combined.route_id = routes_master.route_id
  AND combined.surv_year = routes_master.surv_year
WHERE
  combined.route_id <> 'Ad-hoc'
  AND combined.route_id <> 'Ad-hoc route'
  AND routes_master.route_id <> 'Ad-hoc'
  AND routes_master.route_id <> 'Ad-hoc route'
;