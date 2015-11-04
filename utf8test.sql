-- createdb -U postgres -E SQL_ASCII -T template0 utf8test

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;

DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (t_id SERIAL PRIMARY KEY, t_data TEXT, t_json JSONB);

INSERT INTO t1 VALUES (DEFAULT, E'Cr\355\240\215ud', NULL);
INSERT INTO t1 VALUES (DEFAULT, E'Ta\314\200st', E'{"mykey": "T\303\240st"}');
INSERT INTO t1 VALUES (DEFAULT, 'Clean as a whistle', '{"mykey": "Howdy"}');
INSERT INTO t1 VALUES (DEFAULT, E'Funk\377 Letters', E'{"mykey": "Ta\314\200rp"}');
