alter table surveys
  drop column if exists route_id_final CASCADE;
alter table surveys
  add route_id_final varchar;

-- update post 2014 direct
UPDATE surveys
SET route_id_final = route_id
WHERE
  surv_year > 2013
;

-- update 2008-2014 - derived
UPDATE surveys
SET route_id_final = routes_final.route_id
FROM routes_final
WHERE
  surveys.route_name = routes_final.route_name
  AND surveys.surv_year = routes_final.surv_year
  AND surveys.surv_year < 2014
;

alter table sightings
  drop column if exists route_id_final CASCADE;
alter table sightings
    add route_id_final varchar;
UPDATE sightings
SET route_id_final = surveys.route_id_final
FROM surveys
WHERE surveys.id = sightings.survey_id;

-- solidify route_id_final as route_id
UPDATE surveys
SET route_id = route_id_final;
UPDATE sightings
SET route_id = route_id_final;
alter table surveys
  drop column route_id_final;
alter table sightings
  drop column route_id_final;

