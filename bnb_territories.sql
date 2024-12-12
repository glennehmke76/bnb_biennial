DROP TABLE IF EXISTS territories;
CREATE TABLE territories (
  id serial,
  geom_line geometry (LineString, 4283),
  name varchar,
  PRIMARY KEY (id)
);

alter table public.territories
    add individuals varchar;
comment on column public.territories.individuals is 'free text field for banded birds';

alter table public.territories
    add type varchar;

comment on column public.territories.type is 'type of site - eg breeding territory or flock';

