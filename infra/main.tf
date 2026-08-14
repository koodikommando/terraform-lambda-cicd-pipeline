provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "password-generator-lambda"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_package" {
  type = "zip"

  source_dir  = "${path.module}/../dist"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_object" "lambda_package" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda.zip"
  source = data.archive_file.lambda_package.output_path

  etag = filemd5(data.archive_file.lambda_package.output_path)
}

resource "aws_iam_role" "lambda_exec" {
  name = "password-generator-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "password_generator" {
  function_name = "password-generator"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_package.key

  runtime = "nodejs20.x"
  handler = "handler.handler"

  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "password_generator" {
  name = "/aws/lambda/${aws_lambda_function.password_generator.function_name}"

  retention_in_days = 30
}

resource "aws_apigatewayv2_api" "password_generator" {
  name          = "password-generator-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "password_generator" {
  api_id = aws_apigatewayv2_api.password_generator.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime              = "$context.requestTime"
      protocol                 = "$context.protocol"
      httpMethod                = "$context.httpMethod"
      resourcePath              = "$context.resourcePath"
      routeKey                  = "$context.routeKey"
      status                    = "$context.status"
      responseLength             = "$context.responseLength"
      integrationErrorMessage    = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "password_generator" {
  api_id = aws_apigatewayv2_api.password_generator.id

  integration_uri    = aws_lambda_function.password_generator.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "password_generator" {
  api_id = aws_apigatewayv2_api.password_generator.id

  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.password_generator.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.password_generator.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.password_generator.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.password_generator.execution_arn}/*/*"
}