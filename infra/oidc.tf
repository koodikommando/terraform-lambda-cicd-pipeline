resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-password-generator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      StringLike = {
        "token.actions.githubusercontent.com:sub" = "repo:koodikommando@122229021/terraform-lambda-cicd-pipeline@1333561958:*"
    }
    }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-terraform-permissions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:*",
        "apigateway:*",
        "s3:*",
        "iam:*",
        "logs:*",
        "dynamodb:*"
      ]
      Resource = "*"
    }]
  })
}