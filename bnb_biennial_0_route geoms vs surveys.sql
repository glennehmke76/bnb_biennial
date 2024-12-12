
WITH summary_routes AS
  (SELECT DISTINCT
    route_id route_geom,
    surv_year year_geom,
    route_length
  FROM routes_provided_consistent
  ),
  summary_surveys AS
  (SELECT DISTINCT
    route_id route_surveys,
    surv_year year_surveys
  FROM surveys
  )

SELECT
  *
FROM summary_routes
FULL OUTER JOIN summary_surveys
  ON summary_routes.route_geom = summary_surveys.route_surveys
  AND summary_routes.year_geom = summary_surveys.year_surveys
WHERE
  route_surveys IS NULL
  AND year_geom > 2013
;


-- how many survey events with no birds recorded are there?
SELECT
  *
FROM sightings
WHERE sp_id IS NULL
AND sightings.surv_year > 2013
