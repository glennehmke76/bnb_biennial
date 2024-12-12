-- archive previous
alter table routes_provided
    rename to routes_provided_v1;

-- merge route shapefiles for 2020, 18, 16 and 14 - dissolve before import
-- import via QGIS

alter table routes_provided
    rename column routeid to route_id;
alter table routes_provided
    rename column routename to route_name;
alter table routes_provided
    rename column regionid to region_id;
alter table routes_provided
    rename column routenames to route_name_;
alter table routes_provided
    add surv_year integer;
alter table routes_provided
    alter column route_name type varchar using route_name::varchar;

UPDATE routes_provided
SET route_name = route_name_
WHERE route_name IS NULL;

UPDATE routes_provided
SET surv_year = right(layer,4) :: integer;

alter table routes_provided
    drop column fid;
alter table routes_provided
    drop column route_name_;

-- 2014 and 2020 geom SRID error - correct and replace

ALTER TABLE IF EXISTS public.routes_provided
ADD COLUMN route_length numeric;
UPDATE routes_provided
SET route_length = ST_Length(geom);

