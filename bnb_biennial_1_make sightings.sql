-- make core data table

-- id is the row number of the original spreadsheet which is also added to that spreadsheet. That field must be left as is if the database is to link to the spreadsheets


dates/times not imported due to text entries in earlier years - eg 16/11/10-19/11/10, 01.00 PM etc

instead populated year based on sheet


primary key is year+id

2012 replaced dashes with null in counts + removed trailling zeros in lat/longs changed degrees symbol 150.467623°

-- 2008 data
2008 data is non-spatial currently
for grids, I can import grid refs directly but I need to know the spatial reference ID (EPSG #) reference for them.

For lat/longs they need to be numerical not text.

2008 coordinates have text (38 20 55) and in some cases grids. Must know the EPSG for grids or change to lat/long and all lat/longs must be decimal degrees. Data are imported but are not yet spatial.

Zone has a mix of integer IDs and text. These fields are split to region_id and region_name




counts sometimes have 0s under 'NBS' or 'N' (which presumably means no birds), sometimes has blanks in count against a blank in the species field and in latter years there are no null surveys

0s are converted to nulls in the database and absences are then inferred from the nuber of surveys without the presence of a species



bnb site polygons overlap in some cases and so should not be used to infer routes_provided/regions from points










DO CHECK OF YEARS WITH NO BNBs sighted


CREATE DATABASE bnb_biennial;
    -- mb4 notes/comments excluded
    -- no autoincreiments
    -- timestamps as char
    -- tinyint as smallint
    -- only pk on create then make indexes / constraints after import

  DROP TABLE IF EXISTS sightings;
  CREATE TABLE sightings (
    id int NOT NULL,
    form_id varchar DEFAULT NULL,
    region_id int DEFAULT NULL,
    region_name varchar DEFAULT NULL,
    surv_year int NOT NULL,
    route_id varchar DEFAULT NULL,
    route_name varchar DEFAULT NULL,
    start_name varchar DEFAULT NULL,
    start_y double precision DEFAULT NULL,
    start_x double precision DEFAULT NULL,
    finish_name varchar DEFAULT NULL,
    finish_y double precision DEFAULT NULL,
    finish_x double precision DEFAULT NULL,
    sighting_y double precision DEFAULT NULL,
    sighting_x double precision DEFAULT NULL,
    sp_id varchar DEFAULT NULL,
    num_adults int DEFAULT NULL,
    num_juvs int DEFAULT NULL,
    start_srid int DEFAULT NULL,
    finish_srid int DEFAULT NULL
  );

  copy sightings FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/2020.csv' DELIMITER ',' CSV HEADER;
  copy sightings FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/2018.csv' DELIMITER ',' CSV HEADER;
  copy sightings FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/2016.csv' DELIMITER ',' CSV HEADER;
  copy sightings FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/2014.csv' DELIMITER ',' CSV HEADER;
  copy sightings FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/2012.csv' DELIMITER ',' CSV HEADER;
  copy sightings FROM '/Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/2010.csv' DELIMITER ',' CSV HEADER;

ALTER TABLE IF EXISTS public.sightings
    ADD CONSTRAINT sighting_pkey PRIMARY KEY (id, surv_year);

-- clean up bivariate coords
  UPDATE sightings
  SET start_y = -start_y
  WHERE
    start_y > 0
    AND start_y < 90
    AND start_y < 90
    AND start_srid = 4283;

  UPDATE sightings
  SET finish_y = -finish_y
  WHERE
    finish_y > 0
    AND finish_y < 90
    AND start_srid = 4283;
;

  UPDATE sightings
  SET long = 149.990479
  WHERE long = 149990479
  ;
  UPDATE sightings
  SET long = 140.96117
  WHERE long = 14096117
  ;
  UPDATE sightings
  SET long = 144.356724
  WHERE long = 144356724
  ;
  UPDATE sightings
  SET long = 150.143556
  WHERE long = 150143556
  ;
  UPDATE sightings
  SET long = 150.143697
  WHERE long = 150143697
  ;
  UPDATE sightings
  SET long = 150002967
  WHERE long = 150002967
  ;

-- make start / finish lat/long 0s into NULLs
  UPDATE sightings
  SET start_long = NULL
  WHERE start_long = 0
  ;
  UPDATE sightings
  SET start_lat = NULL
  WHERE start_lat = 0
  ;

  UPDATE sightings
  SET finish_long = NULL
  WHERE finish_long = 0
  ;
  UPDATE sightings
  SET finish_lat = NULL
  WHERE finish_lat = 0
  ;

-- add 2022 - from /Users/glennehmke/MEGAsync/Hoodie biennial trends/Biennial_2008_present/BC 2022_Data analysis_Tables.xlsx > import
    -- import 2022 csv through datagrip ingester
    insert into sightings (id, form_id, region_id, region_name, surv_year, route_id, route_name, start_name, start_y,
                           start_x, finish_name, finish_y, finish_x, sighting_x, sighting_y, sp_id, num_adults, num_juvs, start_srid,
                           finish_srid)
    SELECT * from "2022";

    DROP TABLE "2022";

-- alter table to accom multiple srid coords from 2008 data
DELETE FROM sightings
  WHERE surv_year = 2008;

-- import 2008 csv into temp table through datagrip ingester, then dump to main sightings table
-- master file is /Users/glennehmke/MEGA/Hoodie biennial trends/Biennial_2008_present/raw_2009_HP_270609_TwoSheetsOnly.xlsx - but positive lats and sundry errors are corrected later in import csv
-- data imported from /Users/glennehmke/MEGA/Hoodie biennial trends/Biennial_2008_present/2008.xlsx as csv
alter table public."2008"
    alter column region_id type integer using region_id::integer;
alter table public."2008"
    alter column lat type double precision using lat::double precision;
alter table public."2008"
    alter column long type double precision using long::double precision;
alter table public."2008"
    alter column num_juvs type integer using num_juvs::integer;

INSERT INTO sightings (id, form_id, region_id, region_name, surv_year, route_id, route_name, start_name, start_y,
                       start_x, finish_name, finish_y, finish_x, sighting_y, sighting_x, sp_id, num_adults, num_juvs, start_srid,
                       finish_srid)
SELECT * from "2008";

DROP TABLE "2008";

-- make geometries from coordinates
  -- clean up x/ys
  UPDATE sightings
  SET start_x = NULL
  WHERE start_x = 0;

  UPDATE sightings
  SET start_y = NULL
  WHERE start_y = 0;

  UPDATE sightings
  SET finish_x = NULL
  WHERE finish_x = 0;

  UPDATE sightings
  SET finish_y = NULL
  WHERE finish_y = 0;

  UPDATE sightings
  SET start_srid = 4283
  WHERE
    start_srid IS NULL
    AND start_x IS NOT NULL;

  UPDATE sightings
  SET finish_srid = 4283
  WHERE
    finish_srid IS NULL
    AND finish_x IS NOT NULL
    AND surv_year <> 2008;

-- vet geometries
    UPDATE sightings
    SET start_x = NULL
    WHERE
      start_srid = 4283
      AND start_x >180;

    UPDATE sightings
    SET finish_x = NULL
    WHERE
      start_srid = 4283
      AND finish_x >180;

    UPDATE sightings
    SET start_y = NULL
    WHERE
      start_srid = 4283
      AND start_y >0;

    UPDATE sightings
    SET finish_y = NULL
    WHERE
      start_srid = 4283
      AND finish_y >0;

-- check srid's before making geometries
ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS geom_start;
ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS geom_finish;
ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS geom_sighting;
ALTER TABLE IF EXISTS sightings
ADD COLUMN geom_start geometry(Point,4283);
ALTER TABLE IF EXISTS sightings
ADD COLUMN geom_finish geometry(Point,4283);
ALTER TABLE IF EXISTS sightings
ADD COLUMN geom_sighting geometry(Point,4283);
CREATE INDEX idx_geom_start ON sightings USING gist (geom_start);
CREATE INDEX idx_geom_finish ON sightings USING gist (geom_finish);
CREATE INDEX idx_geom_sighting ON sightings USING gist (geom_sighting);

SELECT DISTINCT start_srid
FROM sightings;

-- make start-point geometries
UPDATE sightings
SET geom_start = sub.geom
FROM
    (SELECT
      id,
      surv_year,
      start_srid,
      start_y,
      start_x,
      start_name,
      route_name,
      CASE
          WHEN start_srid = 28353
          THEN ST_Transform
                (ST_SetSRID
                  (ST_MakePoint(start_x, start_y), 28353), 4283)
          WHEN start_srid = 28354
          THEN ST_Transform
                (ST_SetSRID
                  (ST_MakePoint(start_x, start_y), 28354), 4283)
          WHEN start_srid = 28355
          THEN ST_Transform
                (ST_SetSRID
                  (ST_MakePoint(start_x, start_y), 28355), 4283)
          WHEN start_srid = 4283
          THEN ST_SetSRID
                (ST_MakePoint(start_x, start_y), 4283)
          ELSE NULL
          END AS geom
     FROM sightings
    )sub
WHERE
  sub.id = sightings.id
  AND sub.surv_year = sightings.surv_year
;

-- make finish-point geometries
UPDATE sightings
SET geom_finish = sub.geom
FROM
    (SELECT
      id,
      surv_year,
      finish_srid,
      finish_y,
      finish_x,
      finish_name,
      route_name,
      CASE
          WHEN finish_srid = 28353
          THEN
            ST_Transform
              (ST_SetSRID
                (ST_MakePoint(finish_x, finish_y), 28353), 4283)
          WHEN finish_srid = 28354
          THEN
            ST_Transform
              (ST_SetSRID
                (ST_MakePoint(finish_x, finish_y), 28354), 4283)
          WHEN finish_srid = 28355
          THEN
            ST_Transform
              (ST_SetSRID
                (ST_MakePoint(finish_x, finish_y), 28355), 4283)
          WHEN finish_srid = 4283
          THEN
            ST_SetSRID
              (ST_MakePoint(finish_x, finish_y), 4283)
          ELSE NULL
          END AS geom
     FROM sightings
    )sub
WHERE
  sub.id = sightings.id
  AND sub.surv_year = sightings.surv_year
;

-- make projected geometries on sightings
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS geom_start_GALCC;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS geom_finish_GALCC;
  ALTER TABLE IF EXISTS public.sightings DROP COLUMN IF EXISTS geom_sighting_GALCC;

  ALTER TABLE IF EXISTS sightings
    ADD COLUMN geom_start_GALCC geometry(Point,3112);
  UPDATE sightings
  SET geom_start_GALCC = ST_Transform(geom_start,3112);

  ALTER TABLE IF EXISTS sightings
    ADD COLUMN geom_finish_GALCC geometry(Point,3112);
  UPDATE sightings
  SET geom_finish_GALCC = ST_Transform(geom_finish,3112);

  ALTER TABLE IF EXISTS sightings
    ADD COLUMN geom_sighting_GALCC geometry(Point,3112);
  UPDATE sightings
  SET geom_sighting_GALCC = ST_Transform(geom_start,3112);

  CREATE INDEX idx_geom_start_GALCC ON sightings USING gist (geom_start_GALCC);
  CREATE INDEX idx_geom_finish_GALCC ON sightings USING gist (geom_finish_GALCC);
  CREATE INDEX idx_geom_sighting_GALCC ON sightings USING gist (geom_sighting_GALCC);


------------------------------
-- alter species identifiers and make consistent
    SELECT DISTINCT sp_id
    FROM sightings;

    "RC"
    "NBS"
    "HP"
    "LT"
    "SG"
    "143"
    "RCP"
    "PO"
    "131"
    "CP"
    "138"
    "115"
    "112"
    "117"
    "SO"
    "130"
    "FT"
    "CT"
    "5102"
    "BSC"
    "118"

    UPDATE sightings
    SET sp_id = 143
    WHERE sp_id = 'RC' OR sp_id = 'RCP';

    UPDATE sightings
    SET sp_id = NULL
    WHERE sp_id = 'NBS' OR sp_id = 'N';

    UPDATE sightings
    SET sp_id = 138
    WHERE sp_id = 'HP' OR sp_id = 'HP ';

    UPDATE sightings
    SET sp_id = 117
    WHERE sp_id = 'LT';

    UPDATE sightings
    SET sp_id = 125
    WHERE sp_id = 'SG';

    UPDATE sightings
    SET sp_id = 130
    WHERE sp_id = 'PO'  OR sp_id = 'PO ';

    UPDATE sightings
    SET sp_id = 131
    WHERE sp_id = 'SO';

    UPDATE sightings
    SET sp_id = 118
    WHERE sp_id = 'FT';

    UPDATE sightings
    SET sp_id = 175
    WHERE sp_id = 'BSC';

    -- have assumed 'CP' is caspian tern and 'CT' is crested tern. These are only in 2014 data.
    UPDATE sightings
    SET sp_id = 112
    WHERE sp_id = 'CP';

    UPDATE sightings
    SET sp_id = 115
    WHERE sp_id = 'CT';

    -- convert sp_id to int
    ALTER TABLE sightings
    ALTER COLUMN sp_id TYPE INT
    USING sp_id::integer;

-- clean-up
    DELETE FROM sightings
    WHERE region_name LIKE 'Notes - pink means data missing%';

    DELETE FROM sightings
    WHERE region_name LIKE 'Red letters indicates missing lat long added';


-- make 0s null
    UPDATE sightings
    SET num_adults = NULL
    WHERE num_adults = 0;

    UPDATE sightings
    SET num_juvs = NULL
    WHERE num_juvs = 0;




