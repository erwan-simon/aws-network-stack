resource "aws_lambda_function" "functional_tests" {
  filename      = "functional_tests_lambda_function_payload.zip"
  function_name = "${local.environment_name}_functional_tests"
  description   = "Lambda which fails if it cannot reach google, used to test private subnets"
  role          = aws_iam_role.functional_tests_lambda.arn
  handler       = "main.lambda_handler"
  timeout       = 10

  source_code_hash = data.archive_file.functional_tests_lambda.output_base64sha256

  runtime = "python3.10"
  vpc_config {
    security_group_ids = [aws_security_group.functional_tests_lambda.id]
    subnet_ids         = aws_subnet.privates[*].id
  }
  depends_on = [aws_iam_role_policy_attachment.functional_tests_lambda]
}

resource "aws_security_group" "functional_tests_lambda" {
  name        = "${local.environment_name}_functional_tests_lambda"
  description = "Allow TLS all outbound traffic for functional_tests_lambda"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.environment_name}_functional_tests_lambda"
  }
}

resource "aws_vpc_security_group_egress_rule" "functional_tests_lambda" {
  security_group_id = aws_security_group.functional_tests_lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_iam_policy_document" "functional_tests_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "functional_tests_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "functional_tests_lambda" {
  name        = "${local.environment_name}_functional_tests_lambda"
  description = "IAM policy for logging from the functional_tests lambda"
  policy      = data.aws_iam_policy_document.functional_tests_lambda.json
}

resource "aws_iam_role_policy_attachment" "functional_tests_lambda" {
  role       = aws_iam_role.functional_tests_lambda.name
  policy_arn = aws_iam_policy.functional_tests_lambda.arn
}

resource "aws_iam_role" "functional_tests_lambda" {
  name               = "${local.environment_name}_functional_tests_lambda"
  assume_role_policy = data.aws_iam_policy_document.functional_tests_lambda_assume_role.json
}

data "archive_file" "functional_tests_lambda" {
  type        = "zip"
  source_file = "functional_tests_code/main.py"
  output_path = "functional_tests_lambda_function_payload.zip"
}

resource "null_resource" "always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

resource "time_sleep" "wait_for_nat_gateway_to_create" {
  # nat gateway takes a little while to kick in
  triggers = {
    timestamp = "${timestamp()}"
  }

  create_duration = "60s"
  depends_on      = [null_resource.always_run, aws_nat_gateway.instances]
}

resource "aws_lambda_invocation" "run_functionnal_tests" {
  function_name = aws_lambda_function.functional_tests.function_name

  input = jsonencode({})
  lifecycle {
    replace_triggered_by = [time_sleep.wait_for_nat_gateway_to_create]
  }
}
