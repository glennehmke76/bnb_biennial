-- make buffer from biennial coast (end-cap and mitre are salient)
DROP TABLE IF EXISTS super_routes_consistent CASCADE;
CREATE TABLE super_routes_consistent AS
WITH buffered_routes AS
  (SELECT
    id,
    route_name,
    ST_Buffer(geom, 50, 'quad_segs=2 endcap=flat join=mitre') AS geom
  FROM super_routes
  )
-- create consistent routes
SELECT
  sub.id AS super_route_id,
  sub.route_name,
  ST_Union(sub.geom) AS geom
FROM
    (
    SELECT
      buffered_routes.id,
      route_name,
      ST_CollectionExtract
        (ST_Intersection(biennial_coast.geom, buffered_routes.geom), 2) AS geom
    FROM buffered_routes
    JOIN biennial_coast ON ST_Intersects(buffered_routes.geom, biennial_coast.geom)
    )sub
JOIN buffered_routes
  ON sub.id = buffered_routes.id
GROUP BY
  sub.id,
  sub.route_name
;

alter table super_routes_consistent
    add geom_ geometry(MultiLinestring, 3112);
UPDATE super_routes_consistent
SET geom_ = sub.multi
FROM
  (SELECT
    super_route_id,
    ST_Multi(geom) AS multi
FROM super_routes_consistent
)sub
WHERE
  sub.super_route_id = super_routes_consistent.super_route_id
;
alter table super_routes_consistent
    drop column geom;
alter table super_routes_consistent
    rename column geom_ to geom;
alter table public.super_routes_consistent
    add constraint super_routes_consistent_pk
        primary key (super_route_id);
CREATE INDEX idx_super_routes_consistent_geom ON super_routes_consistent USING gist (geom);

-- -- or QGIS intersection
--         SELECT
--           id,
--           ST_Union
--             (ST_Buffer(geom, 50, 'quad_segs=2 endcap=flat join=mitre')) AS geom
--         FROM super_routes
--         GROUP BY
--           id
--         ;
--
--     processing.run("native:intersection", {'INPUT':'postgres://dbname=\'bnb_biennial\' host=localhost port=5432 user=\'gehmke\' password=\'pf2x5n\' sslmode=disable key=\'id\' srid=3112 type=LineString checkPrimaryKeyUnicity=\'1\' table="public"."biennial_coast" (geom)','OVERLAY':'postgres://dbname=\'bnb_biennial\' host=localhost port=5432 user=\'gehmke\' password=\'pf2x5n\' sslmode=disable key=\'_uid_\' checkPrimaryKeyUnicity=\'1\' table="(SELECT row_number() over () AS _uid_,* FROM (SELECT   id,   surv_year,   ST_Union     (ST_Buffer(geom, 50, \'quad_segs=2 endcap=flat join=mitre\')) AS geom FROM super_routes GROUP BY   id,   surv_year \n) AS _subq_1_\n)" (geom)','INPUT_FIELDS':['habitat'],'OVERLAY_FIELDS':['id','surv_year'],'OVERLAY_FIELDS_PREFIX':'','OUTPUT':'TEMPORARY_OUTPUT','GRID_SIZE':None})
--

-- populate new route lengths
ALTER TABLE IF EXISTS public.super_routes_consistent
  ADD COLUMN route_length numeric;
UPDATE super_routes_consistent
SET route_length = ST_Length(geom);

-- identify any zero length routes
SELECT
  super_routes_consistent.super_route_id,
  ST_GeometryType(super_routes_consistent.geom),
  super_routes_consistent.route_length
FROM super_routes_consistent
JOIN super_routes
  ON super_routes_consistent.super_route_id = super_routes.id
WHERE super_routes_consistent.route_length = 0;

-- check lines are not duplicated (addressed with ST_Union above)
SELECT
  super_route_id,
  SUM(sub.counter) AS num_lines
FROM
    (SELECT
      super_route_id,
      1 AS counter
    FROM super_routes_consistent
    )sub
GROUP BY
  super_route_id
HAVING
  SUM(sub.counter) > 1
;

-- calculate routes provided vs consistent delta
DROP VIEW IF EXISTS super_vs_consistent;
CREATE VIEW super_vs_consistent AS
WITH
  total_length_super_routes AS
    (SELECT
      id,
      SUM(route_length) AS route_length,
      COUNT(*) AS num_lines
    FROM super_routes
    GROUP BY
      id
    ),

  total_length_super_routes_consistent AS
    (SELECT
      super_routes_consistent.super_route_id,
      SUM(route_length) AS route_length,
      COUNT(*) AS num_lines
    FROM super_routes_consistent
    GROUP BY
      super_route_id
    )
-- delta positive = super_routes_consistent is larger
SELECT
  total_length_super_routes_consistent.super_route_id,
  100 - (total_length_super_routes.route_length / total_length_super_routes_consistent.route_length) :: numeric * 100 AS delta
FROM total_length_super_routes
JOIN total_length_super_routes_consistent
  ON total_length_super_routes.id = total_length_super_routes_consistent.super_route_id
WHERE
  total_length_super_routes.route_length > 0
  AND total_length_super_routes_consistent.route_length > 0
;

-- negative deltas indicate areas not captured in super_routes_consistent likely arising from incomplete coast habitat digitisation in biennial_coast
  -- Action - digitise coast (shoreline in lakes etc)
    -- Nov 2023 - added inlets not previously digitised where delta is >-5% for VIC only. Some residuals remain for NSW/SA
-- positive deltas indicate buffer overlaps that need to be dissolved out
  -- Action - xxxxx
    -- then need to go back to make/import routes_consistent

-- alternative to count # overlapping lines with different ids?

-- create unique index super_routes_consistent_id_surv_year_habitat_uindex
--     on public.super_routes_consistent (id, surv_year, habitat);

-- identify routes missing buffers (as super_vs_consistent.delta <-3% and re-digitise those manually - only done for Vic
WITH buffered_routes_consistent AS
  (SELECT
    super_route_id,
    ST_Union
      (ST_Buffer(geom, 50, 'quad_segs=2 endcap=flat join=mitre')) AS geom
  FROM super_routes_consistent
  GROUP BY
    super_route_id
  )
SELECT
  super_routes.id,
  ST_Difference(super_routes.geom, buffered_routes_consistent.geom) AS geom_disjoint
FROM super_routes
JOIN buffered_routes_consistent
  ON super_routes.id = buffered_routes_consistent.super_route_id
WHERE
  ST_Disjoint(buffered_routes_consistent.geom, super_routes.geom)
;
--   ST_Difference(super_routes.geom, buffered_routes_consistent.geom)