-- createdb -U postgres -E SQL_ASCII -T template0 utf8test

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;

DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (t_id SERIAL PRIMARY KEY, t_data TEXT, t_json JSONB);

INSERT INTO t1 VALUES (DEFAULT, 'CrÌ†çud', NULL);
INSERT INTO t1 VALUES (DEFAULT, 'TaÃÄst', '{"mykey": "T√†st"}');
INSERT INTO t1 VALUES (DEFAULT, 'Clean as a whistle', '{"mykey": "Howdy"}');
INSERT INTO t1 VALUES (DEFAULT, 'Funkˇ Letters', '{"mykey": "TaÃÄrp"}');
