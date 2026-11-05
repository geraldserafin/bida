-- Empties the whole database before the v0.5 money model is deployed
-- (SWS v0.5, chapter 14: the data is test data, there is no migration).
--
-- IRREVERSIBLE: every account, session and amount is gone. Take a dump first:
--   pg_dump "$DATABASE_URL" -Fc -f bida-before-v05.dump
--
-- Then, with the API stopped:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v wipe_confirmed=true -f wipe-database.sql
--
-- Start the new API afterwards: its migrator creates the schema from
-- 0001_base. Without -v wipe_confirmed=true the script does nothing.

\if :{?wipe_confirmed}
\else
  \echo 'Refusing to run: pass -v wipe_confirmed=true'
  \quit
\endif

\if :wipe_confirmed
  BEGIN;
  DROP SCHEMA public CASCADE;
  CREATE SCHEMA public;
  COMMIT;
  \echo 'Database wiped. Start the API to create the v0.5 schema.'
\else
  \echo 'Refusing to run: pass -v wipe_confirmed=true'
\endif
