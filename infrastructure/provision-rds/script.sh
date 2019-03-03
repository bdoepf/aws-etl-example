#!/bin/bash
mysql -h ${RDS_ENDPOINT} -u${RDS_USERNAME} -p${RDS_PASSWORD} < /provision/provision_rds.sql
