-- how many route_ids exist
SELECT DISTINCT
  routes_integrated.route_id
FROM routes_integrated
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
;

-- add 2022 name matches first then other years where not exists yielding the latest route name per route_id drawn from survey events
DROP TABLE IF EXISTS route_names;
CREATE TABLE route_names AS
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2022
;

-- add any names not captured in 2022 from 2020
INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2020
  AND route_names IS NULL
;

-- add any names not captured in 2022 or 2020 from 2018
INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2018
  AND route_names IS NULL
;

INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2016
  AND route_names IS NULL
;

INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2014
  AND route_names IS NULL
;

INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2012
  AND route_names IS NULL
;

INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2010
  AND route_names IS NULL
;

INSERT INTO route_names(route_id, route_name)
SELECT DISTINCT
  routes_integrated.route_id,
  surveys.route_name
FROM surveys
RIGHT JOIN routes_integrated ON surveys.route_id = routes_integrated.route_id
LEFT JOIN route_names ON surveys.route_id = route_names.route_id
WHERE
  routes_integrated.route_id <> 'confounded'
  AND routes_integrated.route_id IS NOT NULL
  AND routes_integrated.route_id NOT LIKE 'Ad-hoc%'
  AND surveys.surv_year = 2008
  AND route_names IS NULL
;

-- find any residual
SELECT DISTINCT
  routes_integrated.route_id,
  route_names.route_id
FROM routes_integrated
FULL OUTER JOIN route_names ON routes_integrated.route_id = route_names.route_id
WHERE
  route_names.route_id is null
;

alter table route_names
  add region varchar;
alter table route_names
  add regional_group varchar;

UPDATE route_names
SET
  region = sub.region_name,
  regional_group = sub.regional_group
FROM
  (SELECT DISTINCT
    routes_integrated.route_id,
    regions.region_name,
    regions.regional_group
  FROM routes_integrated
  JOIN regions ON ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(routes_integrated.geom))
  )sub
WHERE route_names.route_id = sub.route_id
;

alter table route_names
  drop column if exists core_habitat_hp;
alter table route_names
  add core_habitat_hp smallint;

-- set core hp routes for counts by spatial geometry
UPDATE route_names
SET core_habitat_hp = 1
WHERE
  regional_group = 'NSW'
  OR regional_group = 'Bass Coast'
  OR regional_group = 'South Gippsland'
  OR regional_group = 'Phillip Island'
  OR regional_group = 'South Gippsland'
  OR regional_group = 'Coorong'
  OR regional_group = 'South-East South Australia'
  OR regional_group = 'Kangaroo Island'
  OR regional_group = 'Eastern Victoria' -- likey needs exclusions
  OR regional_group = 'Western Victoria'
  OR regional_group = 'Shipwreck Coast'
  OR regional_group = 'Yorke Peninsula' -- may need exclusions
  OR regional_group = 'Eyre Peninsula' -- likey needs exclusions
  OR regional_group = 'Fleurieu Peninsula'
  OR (regional_group = 'Bellarine - surf coast'
        AND route_id <> 'QUE001'
        AND route_id <> 'QUE017'
     )
  OR (regional_group = 'Mornington Peninsula'
        AND (route_id = 'MOR003'
        OR route_id = 'MOR006'
        OR route_id = 'MOR007'
        OR route_id = 'MOR008'
        OR route_id = 'MOR005')
     )
;
