resource "aws_db_parameter_group" "dms-sample" {
  name = "dms-sample-pg"
  family = "mysql5.7"

  parameter {
    name = "binlog_format"
    value = "ROW"
  }

  parameter {
    name = "binlog_checksum"
    value = "NONE"
  }
}

resource "aws_security_group" "rds_mysql" {
  name = "mysql_sg"
  description = "allow access to mysql instance"
  #vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${var.access_cidr}"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups  = ["${var.default_vpc_sg_id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "random_string" "password" {
  length = 16
  special = true
  override_special = "/@\" "
}

resource "aws_db_instance" "dms-sample" {
  allocated_storage = 10
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "mydb"
  username = "dmsuser"
  publicly_accessible = true
  password = "${random_string.password.result}"
  parameter_group_name = "${aws_db_parameter_group.dms-sample.name}"
  vpc_security_group_ids = [
    "${aws_security_group.rds_mysql.id}"]
  skip_final_snapshot = true
  backup_retention_period = 3
}

resource "null_resource" "fill-rds" {
  provisioner "local-exec" {
    command = "docker run --rm -e RDS_ENDPOINT=${aws_db_instance.dms-sample.address} -e RDS_USERNAME=${aws_db_instance.dms-sample.username} -e RDS_PASSWORD=${aws_db_instance.dms-sample.password} --entrypoint=/provision/script.sh -v $PWD/provision-rds:/provision mysql:5.7"
  }
}