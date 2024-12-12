-- import processed super-route data - ie what we have used previously for trends
-- ingest /Users/glennehmke/MEGA/Hoodie biennial trends/Biennial_analysis_FINAL_GM_KE.csv > no missing values AS super_routes_data_analysis

alter table super_routes_data_analysis
    rename column region to assigned_region;

-- attribute super_route_id
  -- check any unmatched super_route_names
  SELECT
    super_routes.route_name AS super_routes_route_name,
    super_routes_data_analysis.super_route_name AS super_routes_data_analysis_super_route_name
  FROM super_routes
  FULL OUTER JOIN super_routes_data_analysis ON super_routes.route_name = super_routes_data_analysis.super_route_name
  ;

  -- update super route ids into analysis dataset based on super route names
  alter table super_routes_data_analysis
      add super_route_id integer;
  create index super_routes_data_analysis_super_route_id_index
      on super_routes_data_analysis (super_route_id);

  UPDATE super_routes_data_analysis
  SET super_route_id = super_routes.id
  FROM super_routes
  WHERE super_routes.route_name = super_routes_data_analysis.super_route_name;

-- compare 2008-2014 data from supplied vs generated here
COPY
(SELECT
  super_routes_consistent.route_name,
  sub.*,
  ROUND
    (CASE
      WHEN new_count_total = 0
        THEN NULL
      WHEN new_count_total > 0
        THEN ABS(delta) / new_count_total :: numeric * 100
    END, 2) AS perc_delta
FROM
  (WITH ri AS
    (SELECT
      super_route_id,
      surv_year,
      MAX(exclude) AS ri_exclude,
      MAX(needs_review) AS ri_needs_review
     FROM routes_integrated
     GROUP BY
      super_route_id,
      surv_year
    )
    SELECT
      super_routes_data_analysis.super_route_id AS old_super_route_id,
      super_routes_integrated.super_route_id AS new_super_route_id,
      super_routes_data_analysis.surv_year AS old_surv_year,
      super_routes_integrated.surv_year AS new_surv_year,
      super_routes_data_analysis.total_hp AS old_count_total,
      super_routes_integrated.num_hp_total AS new_count_total,
      COALESCE(super_routes_data_analysis.total_hp,0) - COALESCE(super_routes_integrated.num_hp_total,0) AS delta, -- relative to old numbers
      super_routes_integrated.exclude,
      ri.ri_exclude AS ri_exclude,
      super_routes_integrated.needs_review,
      ri.ri_needs_review AS ri_needs_review,
      super_routes_integrated.notes
    FROM super_routes_integrated
    FULL OUTER JOIN super_routes_data_analysis
      ON super_routes_integrated.super_route_id = super_routes_data_analysis.super_route_id
      AND super_routes_integrated.surv_year = super_routes_data_analysis.surv_year
    FULL OUTER JOIN ri
      ON super_routes_integrated.super_route_id = ri.super_route_id
      AND super_routes_integrated.surv_year = ri.surv_year
    )sub, super_routes_consistent
WHERE
  COALESCE(old_super_route_id, new_super_route_id) = super_routes_consistent.super_route_id
  AND COALESCE(sub.old_count_total, 0) <> COALESCE(new_count_total, 0)
  AND COALESCE(sub.old_surv_year, sub.new_surv_year) BETWEEN 2008 AND 2018
)
TO '/Users/glennehmke/MEGA/Hoodie biennial trends/final/outputs/super_routes_count_different.csv' (FORMAT csv, HEADER)
;

-- list super routes that differ
SELECT
  super_routes_consistent.super_route_id,
  super_routes_consistent.route_name,
  COUNT(sub.*) AS num_years_differing
FROM
    (SELECT
      super_routes_data_analysis.super_route_id AS old_super_route_id,
      super_routes_integrated.super_route_id AS new_super_route_id,
      super_routes_data_analysis.surv_year AS old_surv_year,
      super_routes_integrated.surv_year AS new_surv_year,
      super_routes_data_analysis.total_hp AS old_count_total,
      super_routes_integrated.num_hp_total AS new_count_total,
      COALESCE(super_routes_data_analysis.total_hp,0) - COALESCE(super_routes_integrated.num_hp_total,0) AS delta -- relative to old numbers
    FROM super_routes_integrated
    FULL OUTER JOIN super_routes_data_analysis
      ON super_routes_integrated.super_route_id = super_routes_data_analysis.super_route_id
      AND super_routes_integrated.surv_year = super_routes_data_analysis.surv_year
    )sub, super_routes_consistent
WHERE
  COALESCE(old_super_route_id, new_super_route_id) = super_routes_consistent.super_route_id
  AND COALESCE(sub.old_surv_year, sub.new_surv_year) BETWEEN 2008 AND 2018
  AND delta > 0
GROUP BY
  super_routes_consistent.super_route_id,
  super_routes_consistent.route_name
;






