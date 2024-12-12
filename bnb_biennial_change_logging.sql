-- WLAB change logging
  -- from https://dba.stackexchange.com/questions/233735/track-all-modifications-to-a-postgresql-table
  -- https://www.cybertec-postgresql.com/en/tracking-changes-in-postgresql/#:~:text=To%20track%20the%20changes%20made,definitely%20not%20hard%20to%20do.

    -- set-up
    CREATE SCHEMA log;

    CREATE TABLE log.table_history (
            id serial,
            timestamp timestamp DEFAULT now(),
            schema text,
            table_name text,
            operation text,
            usr text DEFAULT current_user, -- this may need to direct to a user table etc
            new_values jsonb,
            old_values jsonb
    );

    CREATE FUNCTION log.change_trigger() RETURNS trigger AS $$
    BEGIN
    INSERT INTO log.table_history (table_name, schema, operation, new_values, old_values)
    VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, pg_catalog.row_to_json(NEW), pg_catalog.row_to_json(OLD));
    RETURN NULL;
    END;
    $$ LANGUAGE 'plpgsql' SECURITY DEFINER
    SET search_path = pg_catalog,pg_temp;

    -- create triggers
    DROP TRIGGER IF EXISTS audit_sightings on public.sightings;
    CREATE TRIGGER audit_sightings
    AFTER INSERT OR UPDATE OR DELETE ON sightings
    FOR EACH ROW EXECUTE PROCEDURE log.change_trigger();

TRUNCATE TABLE log.table_history;