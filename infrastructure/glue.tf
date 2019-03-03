
resource "aws_glue_catalog_database" "glue_db" {
  name = "glue-db"
}

resource "aws_glue_catalog_table" "aws_glue_item_raw" {
  name          = "item_raw"
  database_name = "${aws_glue_catalog_database.glue_db.name}"

  table_type = "EXTERNAL_TABLE"
  storage_descriptor {
    columns  {
      name = "id"
      type = "bigint"
    }
    columns  {
      name = "description"
      type = "string"
    }
    location = "s3://${aws_s3_bucket.data_bucket.bucket}/migration/dms_sample/dms_sample/item/"
    input_format = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed = "false"
    number_of_buckets = -1
    ser_de_info {
      name = "SerDeCsv"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters {
        "field.delim" = ","
      }
    }
  }
}



data "template_file" "glue_script" {
  template = "${file("${path.module}/glue-scripts/script.scala.tmpl")}"
  vars = {
    bucket = "${aws_s3_bucket.data_bucket.bucket}"
    source_table_name = "${aws_glue_catalog_table.aws_glue_item_raw.name}"
    database_name = "${aws_glue_catalog_database.glue_db.name}"
  }
}

resource "local_file" "glue_script" {
  content = "${data.template_file.glue_script.rendered}"
  filename = "${path.module}/glue-scripts/script.scala"
}

resource "aws_s3_bucket_object" "glue_script" {
  depends_on = ["local_file.glue_script"]
  bucket = "${aws_s3_bucket.data_bucket.bucket}"
  key = "glue-script.scala"
  source = "${local_file.glue_script.filename}"
  etag = "${md5(local_file.glue_script.content)}"
}

resource "aws_iam_role" "glue" {
  name = "glue_sample"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "admin_policy" {
  name = "glue_admin_policy"
  role = "${aws_iam_role.glue.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_glue_job" "example" {
  name     = "dms-sample"
  role_arn = "${aws_iam_role.glue.arn}"

  command {
    script_location = "s3://${aws_s3_bucket_object.glue_script.bucket}/${aws_s3_bucket_object.glue_script.key}"
  }

  default_arguments = {
    "--job-language" = "scala"
    "--class" = "GlueApp"
    "--job-bookmark-option" = "job-bookmark-enable"
  }
}
