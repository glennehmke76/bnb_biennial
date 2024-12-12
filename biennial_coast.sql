

SELECT
  biennial_coast.id,
  biennial_coast.geom,
  biennial_coast.line_source,
  biennial_coast.habitat AS habitat_id,
  lut_habitat.habitat AS habitat
FROM biennial_coast
LEFT JOIN lut_habitat on biennial_coast.habitat = lut_habitat.id