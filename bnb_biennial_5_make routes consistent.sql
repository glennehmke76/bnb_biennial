-- archive previous
alter table routes_provided_consistent
    rename to routes_provided_consistent_v1;

-- make buffer from biennial coast (end-cap and mitre are salient)
DROP TABLE IF EXISTS routes_provided_consistent CASCADE;
CREATE TABLE routes_provided_consistent AS
  WITH buffered_routes AS
    (SELECT
      route_id,
      surv_year,
      ST_Union
        (ST_Buffer(geom, 50, 'quad_segs=2 endcap=flat join=mitre')) AS geom
    FROM routes_provided
    GROUP BY
      route_id,
      surv_year
    )
  -- create consistent routes
  SELECT
    sub.route_id,
    sub.surv_year,
    ST_Union(sub.geom) AS geom
  FROM
      (SELECT
        buffered_routes.route_id,
        buffered_routes.surv_year,
        ST_CollectionExtract
          (ST_Intersection(biennial_coast.geom, buffered_routes.geom), 2) AS geom
      FROM buffered_routes
      JOIN biennial_coast ON ST_Intersects(buffered_routes.geom, biennial_coast.geom)
      )sub
  JOIN buffered_routes
    ON sub.route_id = buffered_routes.route_id
    AND sub.surv_year = buffered_routes.surv_year
  GROUP BY
    sub.route_id,
    sub.surv_year
  ;
alter table routes_provided_consistent
    add geom_ geometry(MultiLinestring, 3112);
UPDATE routes_provided_consistent
SET geom_ = sub.multi
FROM
  (SELECT
    route_id,
    ST_Multi(geom) AS multi
FROM routes_provided_consistent
)sub
WHERE
  sub.route_id = routes_provided_consistent.route_id
;
alter table routes_provided_consistent
    drop column geom;
alter table routes_provided_consistent
    rename column geom_ to geom;
alter table public.routes_provided_consistent
    add constraint routes_provided_consistent_pk
        primary key (route_id, surv_year);
CREATE INDEX idx_routes_provided_consistent_geom ON routes_provided_consistent USING gist (geom);

-- -- or QGIS intersection
--         SELECT
--           route_id,
--           surv_year,
--           ST_Union
--             (ST_Buffer(geom, 50, 'quad_segs=2 endcap=flat join=mitre')) AS geom
--         FROM routes_provided
--         GROUP BY
--           route_id,
--           surv_year
--         ;
--
--     processing.run("native:intersection", {'INPUT':'postgres://dbname=\'bnb_biennial\' host=localhost port=5432 user=\'gehmke\' password=\'pf2x5n\' sslmode=disable key=\'id\' srid=3112 type=LineString checkPrimaryKeyUnicity=\'1\' table="public"."biennial_coast" (geom)','OVERLAY':'postgres://dbname=\'bnb_biennial\' host=localhost port=5432 user=\'gehmke\' password=\'pf2x5n\' sslmode=disable key=\'_uid_\' checkPrimaryKeyUnicity=\'1\' table="(SELECT row_number() over () AS _uid_,* FROM (SELECT   route_id,   surv_year,   ST_Union     (ST_Buffer(geom, 50, \'quad_segs=2 endcap=flat join=mitre\')) AS geom FROM routes_provided GROUP BY   route_id,   surv_year \n) AS _subq_1_\n)" (geom)','INPUT_FIELDS':['habitat'],'OVERLAY_FIELDS':['route_id','surv_year'],'OVERLAY_FIELDS_PREFIX':'','OUTPUT':'TEMPORARY_OUTPUT','GRID_SIZE':None})
--

-- populate new route lengths
ALTER TABLE IF EXISTS public.routes_provided_consistent
  ADD COLUMN route_length numeric;
UPDATE routes_provided_consistent
SET route_length = ST_Length(geom);

-- identify any zero length routes
SELECT
  routes_provided_consistent.route_id,
  routes_provided_consistent.surv_year,
  ST_GeometryType(routes_provided_consistent.geom),
  routes_provided_consistent.route_length
FROM routes_provided_consistent
JOIN routes_provided
  ON routes_provided_consistent.route_id = routes_provided.route_id
  AND routes_provided_consistent.surv_year = routes_provided.surv_year
WHERE routes_provided_consistent.route_length = 0;

-- check lines are not duplicated (addressed with ST_Union above)
SELECT
  route_id,
  surv_year,
  SUM(sub.counter) AS num_lines
FROM
    (SELECT
      route_id,
      surv_year,
      1 AS counter
    FROM routes_provided_consistent
    )sub
GROUP BY
  route_id,
  surv_year
HAVING
  SUM(sub.counter) > 1
;

-- calculate routes provided vs consistent delta
alter table routes_provided_consistent
    add delta numeric;
WITH
  total_length_routes_provided AS
    (SELECT
      route_id,
      surv_year,
      SUM(route_length) AS route_length,
      COUNT(*) AS num_lines
    FROM routes_provided
    GROUP BY
      route_id,
      surv_year
    ),
  total_length_routes_provided_consistent AS
    (SELECT
      route_id,
      surv_year,
      SUM(route_length) AS route_length,
      COUNT(*) AS num_lines
    FROM routes_provided_consistent
    GROUP BY
      route_id,
      surv_year
    )
-- delta positive = routes_provided_consistent is larger
UPDATE routes_provided_consistent
SET delta = sub.delta
FROM
  (SELECT
    total_length_routes_provided_consistent.route_id,
    total_length_routes_provided_consistent.surv_year,
    100 - (total_length_routes_provided.route_length / total_length_routes_provided_consistent.route_length) :: numeric * 100 AS delta
  FROM total_length_routes_provided
  JOIN total_length_routes_provided_consistent
    ON total_length_routes_provided.route_id = total_length_routes_provided_consistent.route_id
    AND total_length_routes_provided.surv_year = total_length_routes_provided_consistent.surv_year
  WHERE
    total_length_routes_provided.route_length > 0
    AND total_length_routes_provided_consistent.route_length > 0
  )sub
WHERE
  sub.route_id = routes_provided_consistent.route_id
  AND sub.surv_year = routes_provided_consistent.surv_year
;

-- negative deltas indicate areas not captured in routes_provided_consistent likely arising from incomplete coast habitat digitisation in biennial_coast
  -- Action - digitise coast (shoreline in lakes etc)
    -- Nov 2023 - added inlets not previously digitised where delta is >-5% for VIC only. Some residuals remain for NSW/SA
-- positive deltas indicate buffer overlaps that need to be dissolved out
  -- Action - xxxxx
    -- then need to go back to make/import routes_consistent

-- alternative to count # overlapping lines with different route_ids?

-- create unique index routes_provided_consistent_route_id_surv_year_habitat_uindex
--     on public.routes_provided_consistent (route_id, surv_year, habitat);

-- identify routes missing buffers (as provided_vs_consistent.delta <-3% and re-digitise those manually - only done for Vic
WITH buffered_routes_consistent AS
  (SELECT
    route_id,
    surv_year,
    ST_Union
      (ST_Buffer(geom, 50, 'quad_segs=2 endcap=flat join=mitre')) AS geom
  FROM routes_provided_consistent
  GROUP BY
    route_id,
    surv_year
  )
SELECT
  routes_provided.route_id,
  routes_provided.surv_year,
  ST_Difference(routes_provided.geom, buffered_routes_consistent.geom) AS geom_disjoint
FROM routes_provided
JOIN buffered_routes_consistent
  ON routes_provided.route_id = buffered_routes_consistent.route_id
  AND routes_provided.surv_year = buffered_routes_consistent.surv_year
WHERE
  ST_Disjoint(buffered_routes_consistent.geom, routes_provided.geom)
;
