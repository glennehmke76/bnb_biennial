-- survey summary
WITH num_surveys AS
  (SELECT
    surv_year,
  COUNT(id) AS num
  FROM surveys
  GROUP BY
    surv_year
  )

SELECT
  sightings.surv_year,
  wlab_sp.taxon_name,
  num_surveys.num AS num_surveys,
  COUNT(sightings.id) AS num_sightings
FROM sightings
LEFT JOIN wlab_sp ON sightings.sp_id = wlab_sp.sp_id
JOIN num_surveys ON sightings.surv_year = num_surveys.surv_year
GROUP BY
  sightings.surv_year,
  wlab_sp.taxon_name,
  num_surveys.num
ORDER BY
  sightings.surv_year,
  wlab_sp.taxon_name
;


SELECT
  count(id)
FROM surveys
WHERE
  route_id is null
AND surv_year >2012


select
  route_id
from surveys
where surv_year = 2022



  and route_id = '%Ad-hoc%'


SELECT
  surv_year,
  Count(id)
  FROM surveys
WHERE route_id IS NULL
GROUP BY
  surv_year;


-- sub-routes
SELECT
  *
FROM surveys
WHERE route_id LIKE '%.%';


-- routes_ids with >1 route name
SELECT
sub2.route_id
FROM
  (SELECT
  sub.route_id,
  Count(sub.route_id) AS cnt
  FROM
    (SELECT DISTINCT
      route_id,
      route_name
    FROM surveys
    WHERE
      route_id IS NOT NULL AND route_name IS NOT NULL
    )sub
  GROUP BY
  route_id
  )sub2
WHERE sub2.cnt >1


-- regions
SELECT
  Count(*),
  region_id
FROM surveys
GROUP BY
  region_id
;

SELECT
  Count(*),
  region_name
FROM surveys
GROUP BY
  region_name
;

SELECT
  Count(id),
  region_id,
  region_name
FROM surveys
GROUP BY
  region_id,
  region_name


-- routes_ids with >1 region_id
SELECT
sub2.route_id
FROM
  (SELECT
  sub.route_id,
  Count(sub.route_id) AS cnt
  FROM
    (SELECT DISTINCT
      route_id,
      region_id
    FROM surveys
    WHERE
      route_id IS NOT NULL AND region_id IS NOT NULL
    )sub
  GROUP BY
  route_id
  )sub2
WHERE sub2.cnt >1
