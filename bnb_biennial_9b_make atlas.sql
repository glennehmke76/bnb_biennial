DROP TABLE IF EXISTS atlas;
CREATE TABLE atlas AS
SELECT
  route_id,
  ST_Envelope
    (ST_Collect
      (COALESCE
        (geom)))
    AS geom_bounding_box
FROM routes_integrated
WHERE
  route_id <> 'confounded'
GROUP BY
  route_id
;
alter table atlas
    add constraint atlas_pk
        primary key (route_id);

ALTER TABLE IF EXISTS atlas
ADD COLUMN state_code varchar;
ALTER TABLE IF EXISTS atlas
ADD COLUMN geom_centroid geometry;

UPDATE atlas
SET geom_centroid = ST_Centroid(geom_bounding_box)
;
UPDATE atlas
SET state_code = states_5kmbuffer.code
FROM states_5kmbuffer
WHERE
  ST_Intersects(ST_Transform(states_5kmbuffer.geom, 3112), atlas.geom_centroid)
;

DELETE FROM atlas
WHERE
  route_id IS NULL
  OR route_id LIKE '%hoc%'
;

-- for super-routes
DROP TABLE IF EXISTS atlas_super_routes;
CREATE TABLE atlas_super_routes AS
SELECT
  super_route_id,
  ST_Envelope
    (ST_Collect(geom))
    AS geom_bounding_box
FROM super_routes_consistent
GROUP BY
  super_route_id
;

ALTER TABLE IF EXISTS atlas_super_routes
ADD COLUMN geom_centroid geometry;
UPDATE atlas_super_routes
SET geom_centroid = ST_Centroid(geom_bounding_box)
;

-- Atlas automation for focal route display from https://gis.stackexchange.com/questions/225235/atlas-automation-in-qgis-showing-data-from-multiple-layers-based-on-attribute-f

DROP VIEW IF EXISTS routes_integrated_derived_500;
CREATE VIEW routes_integrated_derived_500 AS
SELECT
  row_number() over () AS id,
  route_id,
  surv_year,
  COALESCE(geom_derived_500, geom_provided) AS geom_integrated_500
FROM routes_master
WHERE
  COALESCE(geom_derived_500, geom_provided) IS NOT NULL
;


-- QGIS filters for symbology
on = "route_id" = attribute( @atlas_feature ,  'route_id')

off = "route_id" <> attribute( @atlas_feature,  'route_id')

-- for labels
"route_id" = attribute( @atlas_feature ,  'route_id') AND surv_year = xxxx


sudo -u glennehmke pg_dump -t sites -t sites_integrated -t source -t source_sharing -t species -t subspecies -t supertaxon -t supertaxon_species -t survey_type -t vetting_classification -t vetting_review -t vetting_status -t wlab -t wlab_covariates -t wlab_range -t wlab_v2 birdata | psql -h birdlife.webgis1.com -p 5432 -U birdlife -d birdlife_birdata
