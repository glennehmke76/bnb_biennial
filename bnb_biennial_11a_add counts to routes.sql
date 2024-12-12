-- make full data table for routes (not yet super routes) with all counts density and absences - aggregate to super routes in latter step
DROP TABLE IF EXISTS biennial_routes_full_data;
create sequence biennial_routes_full_data_seq
  as integer;
create table biennial_routes_full_data (
  id integer primary key not null default nextval('biennial_routes_full_data_seq'::regclass),
  route_id character varying(50),
  surv_year integer,
  sp_id integer,
  num_adults integer,
  num_juvs integer,
  num_total integer
);
alter sequence biennial_routes_full_data_seq owned by biennial_routes_full_data.id;

-- add counts for all species then permute absences by species
  -- do a check layer to ensure it is the same as counts by
insert into biennial_routes_full_data (route_id, surv_year, sp_id, num_adults, num_juvs)
SELECT
  routes_integrated.route_id,
  routes_integrated.surv_year,
  sightings.sp_id,
  SUM(sightings.num_adults) AS num_adults,
  SUM(sightings.num_juvs) AS num_juvs
FROM routes_integrated
JOIN surveys
  ON routes_integrated.route_id = surveys.route_id
  AND routes_integrated.surv_year = surveys.surv_year
JOIN sightings ON surveys.id = sightings.survey_id
WHERE
  routes_integrated.route_id <> 'confounded'
GROUP BY
  routes_integrated.route_id,
  routes_integrated.surv_year,
  sightings.sp_id
;

-- then add pseudo zeros permuted across species
  -- how many null surveys are there?
  SELECT
    count(distinct surveys.id) AS num_null_surveys,
    count(distinct surveys.route_id) AS num_routes_with_a_null_survey,
    count(distinct concat(surveys.route_id, surveys.surv_year)) AS num_null_route_counts
  FROM surveys
  LEFT JOIN sightings ON surveys.id = sightings.survey_id
  WHERE
    sightings.survey_id IS NULL
  ;

-- this can be limited by habitat at a later stage

-- hoodies
insert into biennial_routes_full_data (route_id, surv_year, sp_id, num_adults, num_juvs)
WITH species_sightings AS
  (SELECT
    sightings.*
  FROM sightings
  WHERE
    sp_id = 138
  )
SELECT DISTINCT
  surveys.route_id,
  surveys.surv_year,
  138,
  0,
  0
FROM surveys
LEFT JOIN species_sightings ON surveys.id = species_sightings.survey_id
JOIN routes_integrated
  ON surveys.route_id = routes_integrated.route_id
  AND surveys.surv_year = routes_integrated.surv_year
WHERE
  species_sightings.survey_id IS NULL
;

-- red-caps
insert into biennial_routes_full_data (route_id, surv_year, sp_id, num_adults, num_juvs)
WITH species_sightings AS
  (SELECT
    sightings.*
  FROM sightings
  WHERE
    sp_id = 143
  )
SELECT DISTINCT
  surveys.route_id,
  surveys.surv_year,
  143,
  0,
  0
FROM surveys
LEFT JOIN species_sightings ON surveys.id = species_sightings.survey_id
JOIN routes_integrated
  ON surveys.route_id = routes_integrated.route_id
  AND surveys.surv_year = routes_integrated.surv_year
WHERE
  species_sightings.survey_id IS NULL
;

-- pied oycs
insert into biennial_routes_full_data (route_id, surv_year, sp_id, num_adults, num_juvs)
WITH species_sightings AS
  (SELECT
    sightings.*
  FROM sightings
  WHERE
    sp_id = 130
  )
SELECT DISTINCT
  surveys.route_id,
  surveys.surv_year,
  130,
  0,
  0
FROM surveys
LEFT JOIN species_sightings ON surveys.id = species_sightings.survey_id
JOIN routes_integrated
  ON surveys.route_id = routes_integrated.route_id
  AND surveys.surv_year = routes_integrated.surv_year
WHERE
  species_sightings.survey_id IS NULL
;

-- sooty oycs
insert into biennial_routes_full_data (route_id, surv_year, sp_id, num_adults, num_juvs)
WITH species_sightings AS
  (SELECT
    sightings.*
  FROM sightings
  WHERE
    sp_id = 131
  )
SELECT DISTINCT
  surveys.route_id,
  surveys.surv_year,
  131,
  0,
  0
FROM surveys
LEFT JOIN species_sightings ON surveys.id = species_sightings.survey_id
JOIN routes_integrated
  ON surveys.route_id = routes_integrated.route_id
  AND surveys.surv_year = routes_integrated.surv_year
WHERE
  species_sightings.survey_id IS NULL
;

-- calculate total counts
UPDATE biennial_routes_full_data
SET num_total = coalesce(num_adults, 0) + coalesce(num_juvs, 0);

-- add summary numbers to routes_integrated by species
-- hp
  alter table routes_integrated
    drop column if exists num_hp_adults;
  alter table routes_integrated
    drop column if exists num_hp_juvs;
  alter table routes_integrated
    drop column if exists num_hp_total;
  alter table routes_integrated
    drop column if exists density_hp_adults;
  alter table routes_integrated
    drop column if exists density_hp_juvs;
  alter table routes_integrated
    drop column if exists density_hp_total;

  alter table routes_integrated
    add num_hp_adults integer,
    add num_hp_juvs integer,
    add num_hp_total integer,
    add density_hp_adults numeric,
    add density_hp_juvs numeric,
    add density_hp_total numeric
  ;

  -- populate counts
  UPDATE routes_integrated
  SET
    num_hp_adults = num_adults,
    num_hp_juvs = num_juvs,
    num_hp_total = num_total
  FROM biennial_routes_full_data
  WHERE
    biennial_routes_full_data.route_id = routes_integrated.route_id
    AND biennial_routes_full_data.surv_year = routes_integrated.surv_year
    AND biennial_routes_full_data.sp_id = 138
  ;

  -- calcualte densities
  UPDATE routes_integrated
  SET
    density_hp_adults = coalesce(num_hp_adults, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_hp_adults, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_hp_juvs = coalesce(num_hp_juvs, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_hp_juvs, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_hp_total = coalesce(num_hp_total, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_hp_total, 0) > 0
  ;

-- rcp
  alter table routes_integrated
    drop column if exists num_rcp_adults;
  alter table routes_integrated
    drop column if exists num_rcp_juvs;
  alter table routes_integrated
    drop column if exists num_rcp_total;
  alter table routes_integrated
    drop column if exists density_rcp_adults;
  alter table routes_integrated
    drop column if exists density_rcp_juvs;
  alter table routes_integrated
    drop column if exists density_rcp_total;

  alter table routes_integrated
    add num_rcp_adults integer,
    add num_rcp_juvs integer,
    add num_rcp_total integer,
    add density_rcp_adults numeric,
    add density_rcp_juvs numeric,
    add density_rcp_total numeric
  ;

  -- populate counts
  UPDATE routes_integrated
  SET
    num_rcp_adults = num_adults,
    num_rcp_juvs = num_juvs,
    num_rcp_total = num_total
  FROM biennial_routes_full_data
  WHERE
    biennial_routes_full_data.route_id = routes_integrated.route_id
    AND biennial_routes_full_data.surv_year = routes_integrated.surv_year
    AND biennial_routes_full_data.sp_id = 143
  ;

  -- calcualte densities
  UPDATE routes_integrated
  SET
    density_rcp_adults = coalesce(num_rcp_adults, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_rcp_adults, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_rcp_juvs = coalesce(num_rcp_juvs, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_rcp_juvs, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_rcp_total = coalesce(num_rcp_total, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_rcp_total, 0) > 0
  ;

-- poyc
  alter table routes_integrated
    drop column if exists num_poyc_adults;
  alter table routes_integrated
    drop column if exists num_poyc_juvs;
  alter table routes_integrated
    drop column if exists num_poyc_total;
  alter table routes_integrated
    drop column if exists density_poyc_adults;
  alter table routes_integrated
    drop column if exists density_poyc_juvs;
  alter table routes_integrated
    drop column if exists density_poyc_total;

  alter table routes_integrated
    add num_poyc_adults integer,
    add num_poyc_juvs integer,
    add num_poyc_total integer,
    add density_poyc_adults numeric,
    add density_poyc_juvs numeric,
    add density_poyc_total numeric
  ;

  -- populate counts
  UPDATE routes_integrated
  SET
    num_poyc_adults = num_adults,
    num_poyc_juvs = num_juvs,
    num_poyc_total = num_total
  FROM biennial_routes_full_data
  WHERE
    biennial_routes_full_data.route_id = routes_integrated.route_id
    AND biennial_routes_full_data.surv_year = routes_integrated.surv_year
    AND biennial_routes_full_data.sp_id = 130
  ;

  -- calcualte densities
  UPDATE routes_integrated
  SET
    density_poyc_adults = coalesce(num_poyc_adults, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_poyc_adults, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_poyc_juvs = coalesce(num_poyc_juvs, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_poyc_juvs, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_poyc_total = coalesce(num_poyc_total, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_poyc_total, 0) > 0
  ;

-- soyc
  alter table routes_integrated
    drop column if exists num_soyc_adults;
  alter table routes_integrated
    drop column if exists num_soyc_juvs;
  alter table routes_integrated
    drop column if exists num_soyc_total;
  alter table routes_integrated
    drop column if exists density_soyc_adults;
  alter table routes_integrated
    drop column if exists density_soyc_juvs;
  alter table routes_integrated
    drop column if exists density_soyc_total;

  alter table routes_integrated
    add num_soyc_adults integer,
    add num_soyc_juvs integer,
    add num_soyc_total integer,
    add density_soyc_adults numeric,
    add density_soyc_juvs numeric,
    add density_soyc_total numeric
  ;

  -- populate counts
  UPDATE routes_integrated
  SET
    num_soyc_adults = num_adults,
    num_soyc_juvs = num_juvs,
    num_soyc_total = num_total
  FROM biennial_routes_full_data
  WHERE
    biennial_routes_full_data.route_id = routes_integrated.route_id
    AND biennial_routes_full_data.surv_year = routes_integrated.surv_year
    AND biennial_routes_full_data.sp_id = 131
  ;

  -- calcualte densities
  UPDATE routes_integrated
  SET
    density_soyc_adults = coalesce(num_soyc_adults, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_soyc_adults, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_soyc_juvs = coalesce(num_soyc_juvs, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_soyc_juvs, 0) > 0
  ;
  UPDATE routes_integrated
  SET
    density_soyc_total = coalesce(num_soyc_total, 0) / length :: numeric * 1000 
  WHERE
    coalesce(num_soyc_total, 0) > 0
  ;
