provider "aws" {
  region = "${var.region}"
  assume_role {
    role_arn     = "arn:aws:iam::${var.account}:role/deploy-role"
    session_name = "DeployTerraformRole"
    external_id  = "TerraformID"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#resource "aws_lambda_function" "stream_consumer_lambda" {
#  filename      = "${path.module}/empty_function.zip"
#  function_name = "stream-consumer-function"
#  role          = "${aws_iam_role.stream_consumer_lambda_role.arn}"
#  handler       = "index.handler"

#  runtime = "nodejs10.x"

#  tracing_config {
#    mode = "Active"
#  }

#  depends_on    = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.lambda_demo"]
#}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "lambda_demo" {
  name              = "/aws/lambda/stream-consumer-function"
  retention_in_days = 1
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_permissions" {
  name = "lambda_permissions"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:kms:us-east-1:619481458632:key/062e26bc-bb94-4c6e-bea1-f4ea87a6afc3"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:QueryItem",
        "dynamodb:Query",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams"
      ],
      "Resource": ["${aws_dynamodb_table.transaction.arn}","${aws_dynamodb_table.transaction.arn}/*"],
      "Effect": "Allow"
    },
    {
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "kinesis:GetRecords",
        "kinesis:PutRecords",
        "kinesis:PutRecord",
        "kinesis:GetShardIterator",
        "kinesis:DescribeStream",
        "kinesis:ListStreams"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.stream_consumer_lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_permissions.arn}"
}

resource "aws_kinesis_stream" "transaction_stream" {
  name             = "transaction-stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Environment = "dev"
  }
}

resource "aws_dynamodb_table" "transaction" {
  name           = "transaction-dynamodb-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 100
  write_capacity = 100
  hash_key       = "Id"
  range_key      = "Sort"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "Sort"
    type = "S"
  }

  tags = {
    Name        = "transaction-table"
    Environment = "dev"
  }

  stream_enabled = true
  stream_view_type = "KEYS_ONLY"
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "justin-lambda-code-bucket"
  acl    = "private"

  tags = {
    Name        = "justins code bucket"
    Environment = "dev"
  }

  force_destroy = true
}
