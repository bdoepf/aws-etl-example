resource "aws_dms_endpoint" "mysql_source" {
  database_name = "dms_sample"
  endpoint_id = "mysql-source"
  endpoint_type = "source"
  engine_name = "mysql"
  extra_connection_attributes = ""
  username = "${aws_db_instance.dms-sample.username}"
  password = "${aws_db_instance.dms-sample.password}"
  port = 3306
  server_name = "${aws_db_instance.dms-sample.address}"
  ssl_mode = "none"
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "iot-data-19"
}

resource "aws_iam_role" "access_data_bucket" {
  name = "access_data_bucket"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dms.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.access_data_bucket.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.data_bucket.bucket}*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.data_bucket.bucket}*"
            ]
        }
    ]
}
EOF
}

resource "aws_dms_endpoint" "s3_target" {
  endpoint_id = "s3-target"
  endpoint_type = "target"
  engine_name = "s3"
  s3_settings {
    service_access_role_arn = "${aws_iam_role.access_data_bucket.arn}"
    bucket_name = "${aws_s3_bucket.data_bucket.bucket}"
    bucket_folder = "migration/dms_sample/"
  }
}

resource "aws_dms_replication_instance" "replication_instance" {
  allocated_storage = 20
  apply_immediately = true
  auto_minor_version_upgrade = true
  engine_version = "3.1.2"
  multi_az = false
  publicly_accessible = true
  replication_instance_class = "dms.t2.micro"
  replication_instance_id = "dms-replication-instance-tf"
}

resource "aws_dms_replication_task" "replication_task" {
  migration_type = "full-load-and-cdc"
  replication_instance_arn = "${aws_dms_replication_instance.replication_instance.replication_instance_arn}"
  replication_task_id = "dms-replication-task-tf"
  source_endpoint_arn = "${aws_dms_endpoint.mysql_source.endpoint_arn}"
  table_mappings = <<EOF
  {
	"rules": [
		{
			"rule-type": "selection",
			"rule-id": "1",
			"rule-name": "1",
			"object-locator": {
				"schema-name": "dms_sample",
				"table-name": "item"
			},
			"rule-action": "include"
		}
	]
  }
  EOF
  target_endpoint_arn = "${aws_dms_endpoint.s3_target.endpoint_arn}"
  replication_task_settings = "{\"TargetMetadata\":{\"TargetSchema\":\"\",\"SupportLobs\":true,\"FullLobMode\":false,\"LobChunkSize\":64,\"LimitedSizeLobMode\":true,\"LobMaxSize\":32,\"InlineLobMaxSize\":0,\"LoadMaxFileSize\":0,\"ParallelLoadThreads\":0,\"ParallelLoadBufferSize\":0,\"BatchApplyEnabled\":false,\"TaskRecoveryTableEnabled\":false},\"FullLoadSettings\":{\"TargetTablePrepMode\":\"DROP_AND_CREATE\",\"CreatePkAfterFullLoad\":false,\"StopTaskCachedChangesApplied\":false,\"StopTaskCachedChangesNotApplied\":false,\"MaxFullLoadSubTasks\":8,\"TransactionConsistencyTimeout\":600,\"CommitRate\":10000},\"Logging\":{\"EnableLogging\":false,\"LogComponents\":[{\"Id\":\"SOURCE_UNLOAD\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"SOURCE_CAPTURE\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TARGET_LOAD\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TARGET_APPLY\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"},{\"Id\":\"TASK_MANAGER\",\"Severity\":\"LOGGER_SEVERITY_DEFAULT\"}],\"CloudWatchLogGroup\":null,\"CloudWatchLogStream\":null},\"ControlTablesSettings\":{\"historyTimeslotInMinutes\":5,\"ControlSchema\":\"\",\"HistoryTimeslotInMinutes\":5,\"HistoryTableEnabled\":false,\"SuspendedTablesTableEnabled\":false,\"StatusTableEnabled\":false},\"StreamBufferSettings\":{\"StreamBufferCount\":3,\"StreamBufferSizeInMB\":8,\"CtrlStreamBufferSizeInMB\":5},\"ChangeProcessingDdlHandlingPolicy\":{\"HandleSourceTableDropped\":true,\"HandleSourceTableTruncated\":true,\"HandleSourceTableAltered\":true},\"ErrorBehavior\":{\"DataErrorPolicy\":\"LOG_ERROR\",\"DataTruncationErrorPolicy\":\"LOG_ERROR\",\"DataErrorEscalationPolicy\":\"SUSPEND_TABLE\",\"DataErrorEscalationCount\":0,\"TableErrorPolicy\":\"SUSPEND_TABLE\",\"TableErrorEscalationPolicy\":\"STOP_TASK\",\"TableErrorEscalationCount\":0,\"RecoverableErrorCount\":-1,\"RecoverableErrorInterval\":5,\"RecoverableErrorThrottling\":true,\"RecoverableErrorThrottlingMax\":1800,\"ApplyErrorDeletePolicy\":\"IGNORE_RECORD\",\"ApplyErrorInsertPolicy\":\"LOG_ERROR\",\"ApplyErrorUpdatePolicy\":\"LOG_ERROR\",\"ApplyErrorEscalationPolicy\":\"LOG_ERROR\",\"ApplyErrorEscalationCount\":0,\"ApplyErrorFailOnTruncationDdl\":false,\"FullLoadIgnoreConflicts\":true,\"FailOnTransactionConsistencyBreached\":false,\"FailOnNoTablesCaptured\":false},\"ChangeProcessingTuning\":{\"BatchApplyPreserveTransaction\":true,\"BatchApplyTimeoutMin\":1,\"BatchApplyTimeoutMax\":30,\"BatchApplyMemoryLimit\":500,\"BatchSplitSize\":0,\"MinTransactionSize\":1000,\"CommitTimeout\":1,\"MemoryLimitTotal\":1024,\"MemoryKeepTime\":60,\"StatementCacheSize\":50},\"PostProcessingRules\":null}"
}