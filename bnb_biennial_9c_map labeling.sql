-- map labeling
-- for super routes
concat(
"super_route_id", ' (',"surv_year", ')', '\n',
'length ', round(("length_final"/1000),1), ' kms', '\n',
'total_hp ', "sr_data_total_count")

-- for routes
-- derived
-- concat(
-- "route_id", '_',"surv_year", '\n',
-- 'length ', round(("length" /1000),1), ' kms', '\n',
-- 'derived delta ', round("routes_final_merged_delta", 0), '\n', 'total_hp ',  "total_count")

concat(
"route_id", '_',"surv_year", '\n',
'length ', round(("length" /1000),1), ' kms', '\n',
'derived delta ', round("delta", 0))

-- provided
-- concat(
-- "route_id", '_',"surv_year", '\n',
-- 'length ', round(("length" /1000),1), ' kms', '\n',
-- 'total_hp ', "total_count")

concat(
"route_id", '_',"surv_year", '\n',
'length ', round(("length" /1000),1), ' kms')


-- underlying super-routes
concat('super route ', "super_route_id",  '\n',
'length ',round(("route_length"/1000),1))

-- QGIS style files
/Users/glennehmke/MEGA/Workflows/code/pg_sql/pg_code/bnb_biennial/super_routes_final.qml
/Users/glennehmke/MEGA/Workflows/code/pg_sql/pg_code/bnb_biennial/routes_final.qml


-- with multiple species counts by route
-- for provided routes
concat(
"route_id", ' (',"surv_year", ')', '\n',
'length ', round(("length"/1000),1), ' kms', '\n',
'hp = ', "num_hp_total" , '(', coalesce("num_hp_adults",0), ',', coalesce("num_hp_juvs" ,0), ')', '\n',
'rcp = ', "num_rcp_total" , '(', coalesce("num_rcp_adults",0), ',', coalesce("num_rcp_juvs" ,0), ')', '\n',
'poyc = ', "num_poyc_total" , '(', coalesce("num_poyc_adults",0), ',', coalesce("num_poyc_juvs" ,0), ')', '\n',
'soyc = ', "num_soyc_total" , '(', coalesce("num_soyc_adults",0), ',', coalesce("num_soyc_juvs" ,0), ')'
)

-- for derived routes
concat(
"route_id", ' (',"surv_year", ')', '\n',
'length ', round(("length"/1000),1), ' kms', '\n',
'derived delta ', round("delta", 0), '\n',
'hp = ', "num_hp_total" , '(', coalesce("num_hp_adults",0), ',', coalesce("num_hp_juvs" ,0), ')', '\n',
'rcp = ', "num_rcp_total" , '(', coalesce("num_rcp_adults",0), ',', coalesce("num_rcp_juvs" ,0), ')', '\n',
'poyc = ', "num_poyc_total" , '(', coalesce("num_poyc_adults",0), ',', coalesce("num_poyc_juvs" ,0), ')', '\n',
'soyc = ', "num_soyc_total" , '(', coalesce("num_soyc_adults",0), ',', coalesce("num_soyc_juvs" ,0), ')'
)


-- atlas feature ids
"route_id" = attribute( @atlas_feature ,  'route_id')
"route_id"<> attribute( @atlas_feature ,  'route_id')

"super_route_id" = attribute( @atlas_feature ,  'super_route_id')
"super_route_id" <> attribute( @atlas_feature ,  'super_route_id')

"route_id" = attribute( @atlas_feature ,  'route_id') AND surv_year = xxxx
"super_route_id" = attribute( @atlas_feature , 'super_route_id') AND surv_year = xxxx