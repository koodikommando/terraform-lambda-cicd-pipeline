output "api_url" {
  description = "Invoke URL for the password generator API"
  value       = aws_apigatewayv2_stage.password_generator.invoke_url
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.password_generator.function_name
}

output "lambda_bucket_name" {
  description = "S3 bucket storing the Lambda deployment package"
  value       = aws_s3_bucket.lambda_bucket.id
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role GitHub Actions assumes via OIDC"
  value       = aws_iam_role.github_actions.arn
}