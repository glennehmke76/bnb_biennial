

-- hp
  alter table super_routes_integrated
    drop column if exists num_hp_adults;
  alter table super_routes_integrated
    drop column if exists num_hp_juvs;
  alter table super_routes_integrated
    drop column if exists num_hp_total;
  alter table super_routes_integrated
    drop column if exists density_hp_adults;
  alter table super_routes_integrated
    drop column if exists density_hp_juvs;
  alter table super_routes_integrated
    drop column if exists density_hp_total;

  alter table super_routes_integrated
    add num_hp_adults integer,
    add num_hp_juvs integer,
    add num_hp_total integer,
    add density_hp_adults numeric,
    add density_hp_juvs numeric,
    add density_hp_total numeric
  ;

-- populate counts
UPDATE super_routes_integrated
SET
  num_hp_adults = counts.num_hp_adults,
  num_hp_juvs = counts.num_hp_juvs,
  num_hp_total = counts.num_hp_total
FROM
  (SELECT
    super_route_id,
    surv_year,
    SUM(num_hp_adults) AS num_hp_adults,
    SUM(num_hp_juvs) AS num_hp_juvs,
    SUM(num_hp_total) AS num_hp_total
  FROM routes_integrated
  GROUP BY
    super_route_id,
    surv_year
  )counts
WHERE
  super_routes_integrated.super_route_id = counts.super_route_idz
  AND super_routes_integrated.surv_year = counts.surv_year
;

-- calculate densities
  UPDATE super_routes_integrated
  SET
    density_hp_adults = coalesce(num_hp_adults, 0) / length :: numeric * 1000
  WHERE
    coalesce(num_hp_adults, 0) > 0
  ;
  UPDATE super_routes_integrated
  SET
    density_hp_juvs = coalesce(num_hp_juvs, 0) / length :: numeric * 1000
  WHERE
    coalesce(num_hp_juvs, 0) > 0
  ;
  UPDATE super_routes_integrated
  SET
    density_hp_total = coalesce(num_hp_total, 0) / length :: numeric * 1000
  WHERE
    coalesce(num_hp_total, 0) > 0
  ;