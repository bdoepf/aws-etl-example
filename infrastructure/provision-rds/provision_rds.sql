create database if not exists dms_sample;
use dms_sample;
create table if not exists item(id BIGINT NOT NULL AUTO_INCREMENT, description TEXT, PRIMARY KEY (id));
INSERT INTO item (description) values ('foo');
INSERT INTO item (description) values ('bar');
INSERT INTO item (description) values ('hello');
INSERT INTO item (description) values ('world');