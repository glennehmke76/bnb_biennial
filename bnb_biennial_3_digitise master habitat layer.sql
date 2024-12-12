-- digitise master habitat layer
  -- Table: public.biennial_coast

  -- DROP TABLE IF EXISTS public.biennial_coast;

  CREATE TABLE IF NOT EXISTS public.biennial_coast
  (
      id integer NOT NULL DEFAULT nextval('biennial_coast_id_seq'::regclass),
      geom geometry(LineString,3112),
      line_source character varying COLLATE pg_catalog."default",
      habitat integer,
      CONSTRAINT biennial_coast_pkey PRIMARY KEY (id)
  )

  TABLESPACE pg_default;

  ALTER TABLE IF EXISTS public.biennial_coast
      OWNER to gehmke;
  -- Index: sidx_biennial_coast_geom

  -- DROP INDEX IF EXISTS public.sidx_biennial_coast_geom;

  CREATE INDEX IF NOT EXISTS sidx_biennial_coast_geom
      ON public.biennial_coast USING gist
      (geom)
      TABLESPACE pg_default;


  DROP TABLE IF EXISTS lut_habitat;
  CREATE TABLE lut_habitat (
    id int NOT NULL,
    habitat varchar DEFAULT NULL,
  CONSTRAINT lut_habitat_pkey PRIMARY KEY (id)
  );


  -- add length
  ALTER TABLE IF EXISTS biennial_coast
    ADD COLUMN length numeric;
  UPDATE biennial_coast
  SET length = ST_Length(geom);

  SELECT
    line_source,
    SUM(length) / 1000 AS kms
  FROM biennial_coast
  WHERE habitat = 1
  GROUP BY
    line_source
  ;

  ALTER TABLE IF EXISTS biennial_coast
    ADD COLUMN suitable_hp integer;