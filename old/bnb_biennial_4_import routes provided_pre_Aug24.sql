-- import provided - routes_provided

TRUNCATE TABLE routes_provided;
  CREATE TABLE IF NOT EXISTS public.routes_provided
  (
      id integer NOT NULL DEFAULT nextval('routes_provided_id_seq'::regclass),
      geom geometry(MultiLineString,3112),
      route_id character varying(50) COLLATE pg_catalog."default",
      region_id character varying COLLATE pg_catalog."default",
      region_name character varying(50) COLLATE pg_catalog."default",
      surv_year integer,
      CONSTRAINT routes_provided_pkey PRIMARY KEY (id)
  );
  ALTER TABLE IF EXISTS public.routes_provided
      OWNER to gehmke;
  DROP INDEX IF EXISTS public.sidx_routes_provided_geom;
  CREATE INDEX IF NOT EXISTS sidx_routes_provided_geom
      ON public.routes_provided USING gist
      (geom)
      TABLESPACE pg_default;
  ALTER TABLE IF EXISTS public.routes_provided
      OWNER to gehmke;

-- merge route shapefiles for 2020, 18, 16 and 14 - dissolve before import
-- import via QGIS

ALTER TABLE IF EXISTS public.routes_provided
ADD COLUMN route_length numeric;
UPDATE routes_provided
SET route_length = ST_Length(geom);

-- import 'super-routes' - ie pre 2008 routes provided by someone
alter table public.super_routes
    drop column objectid;
alter table public.super_routes
    drop column state;
alter table public.super_routes
    drop column shape_leng;
alter table public.super_routes
    rename column routenames to "route name";
alter table public.super_routes
    drop column objectid_1;
alter table public.super_routes
    drop column site;
alter table public.super_routes
    rename column yrs to surv_yrs;
alter table public.super_routes
    rename column lengthm to route_length;
alter table public.super_routes
    alter column surv_yrs type integer using surv_yrs::integer;