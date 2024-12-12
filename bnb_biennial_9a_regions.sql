-- attribute covariates to routes
-- regions
DROP TABLE IF EXISTS regions;
create sequence regions_seq
  as integer;
CREATE TABLE regions (
  id integer primary key not null default nextval('regions_seq'::regclass),
  region_name character varying,
  regional_group_id integer,
  regional_group character varying,
  geom geometry(MultiPolygon, 4283)
);
alter sequence regions_seq owned by regions.id;

-- fails
--         INSERT INTO regions (geom)
--         SELECT
--           ST_Multi(ST_Union(ST_Transform(ST_Buffer(geom, 10000, 'quad_segs=2'), 4283)))
--         FROM coastlines_annual
--         WHERE
--           year = 2022
--           AND
--             (id_primary LIKE '%VIC%'
--             OR id_primary LIKE '%SA%')
--         ;

-- import QGIS as regions_insert
INSERT INTO regions (geom)
SELECT
  geom
FROM regions_insert


  code

-- simplify in transaction
BEGIN;
  INSERT INTO regions (geom)
  SELECT
    ST_Simplify(geom, 0.005)
  FROM regions;

  DELETE FROM regions
  WHERE id = 1
COMMIT;

-- dissolver (if modified)
BEGIN;
  DROP TABLE IF EXISTS regions_;
  CREATE TABLE regions_ AS
  SELECT
    region_name,
    regional_group_id,
    regional_group,
    ST_Multi(ST_Union(geom)) AS geom
  FROM regions
  GROUP BY
    region_name,
    regional_group_id,
    regional_group
  ;
  TRUNCATE TABLE regions;
  INSERT INTO regions (region_name, regional_group_id, regional_group, geom)
  SELECT
    region_name,
    regional_group_id,
    regional_group,
    geom
  FROM regions_
  ;
  drop table if exists regions_;
COMMIT;

alter table super_routes
    add region varchar;
UPDATE super_routes
SET region = regions.region_name
FROM regions
WHERE ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(super_routes.geom))
;

alter table super_routes_consistent
    add region varchar;
UPDATE super_routes_consistent
SET region = regions.region_name
FROM regions
WHERE ST_Intersects(ST_Transform(regions.geom, 3112), ST_PointOnSurface(super_routes_consistent.geom))
;
