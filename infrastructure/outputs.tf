output rds_password {
  value = "${random_string.password.result}"
}

output "rds_endpoint" {
  value = "${aws_db_instance.dms-sample.endpoint}"
}

output "connect_to_rds" {
  value = "docker run --rm -it --entrypoint=mysql mysql:5.7 -h${aws_db_instance.dms-sample.address} -u${aws_db_instance.dms-sample.username} -p${aws_db_instance.dms-sample.password}"
}