# password-generator-lambda

## What I'm learning

This project is my hands-on introduction to AWS and infrastructure-as-code.
I'm building a small serverless app end-to-end to learn:
- Deploying to AWS Lambda + API Gateway
- Managing infrastructure with Terraform (including remote state via S3 + DynamoDB)
- Setting up CI/CD with GitHub Actions
- Authenticating GitHub to AWS via OIDC instead of long-lived access keys

A cryptographically secure password generator, written in TypeScript, deployed to AWS Lambda behind API Gateway with hand-written Terraform and deployed via a GitHub Actions CI/CD pipeline. Built as a learning exercise covering the full path from pure logic to a live, automatically deployed endpoint.

The API is live:

```sh
curl "https://id6sqlo52c.execute-api.eu-north-1.amazonaws.com/?length=20"
```

```json
{"password":"wT2tyNnz]LBcf}%KN[wk"}
```

## `generatePassword`

`src/generatePassword.ts` exports a pure function:

```ts
generatePassword(options?: {
  length?: number;     // default 16, must be between 4 and 128
  symbols?: boolean;   // default true
  numbers?: boolean;   // default true
  uppercase?: boolean; // default true
  lowercase?: boolean; // default true
}): string
```

It builds a character set from the enabled options and uses Node's `crypto.randomInt` (not `Math.random`) to pick each character, so output is suitable for real passwords. At least one character set must remain enabled, and `length` must be between 4 and 128 — otherwise it throws.

## Development

Install dependencies:

```sh
npm install
```

Run the tests (via [Vitest](https://vitest.dev/)):

```sh
npm test
```

Generate a password on the command line (via [tsx](https://github.com/privatenumber/tsx)):

```sh
npm run demo
```

Compile to `dist/`:

```sh
npm run build
```

## Lambda Handler

`src/handler.ts` wraps `generatePassword` for API Gateway HTTP API. It parses the incoming query string parameters (`length`, `symbols`, `numbers`, `uppercase`, `lowercase`) into a `GeneratePasswordOptions` object, calls `generatePassword`, and returns a proper API Gateway response: `200` with `{ "password": "..." }` on success, or `400` with `{ "error": "..." }` if the options are invalid.

## Infrastructure

Provisioned by hand-written Terraform in `infra/` (`main.tf`, `variables.tf`, `output.tf`, `oidc.tf`):

- IAM role + policy attachment for the Lambda
- S3 bucket (random ID suffix) storing the packaged Lambda deployment zip
- Lambda function (Node.js 20 runtime)
- API Gateway HTTP API with a `GET /` route and `$default` auto-deploy stage, throttled to 5 requests/sec (burst 10) to guard against abuse since the endpoint has no authentication
- CloudWatch log group
- Lambda permission allowing API Gateway to invoke the function
- GitHub OIDC provider + an IAM role (`oidc.tf`), scoped to this repo, so GitHub Actions can assume AWS credentials without long-lived access keys

State is remote: an S3 bucket + DynamoDB table (for locking) were provisioned by hand via the AWS CLI, deliberately outside Terraform — Terraform can't manage the backend that stores its own state, so this is bootstrapped once and referenced via a `backend "s3" {}` block in `main.tf`. State was migrated from local to remote with `terraform init -migrate-state`.

## CI/CD

A GitHub Actions workflow at `.github/workflows/deploy.yml` runs on every push and pull request to `main`: it builds the TypeScript app (`npm ci` + `npm run build`), runs the test suite (`npm test`), authenticates to AWS via OIDC (no stored credentials), and runs `terraform init` + `terraform plan`. On pushes to `main`, it also runs `terraform apply`, deploying automatically. Since tests run before the AWS/Terraform steps, a failing test blocks deployment — `terraform apply` is gated on the test suite passing.

Getting OIDC working required actual debugging: GitHub Actions currently sends the `sub` claim in an immutable org-ID/repo-ID format (e.g. `repo:org@12345/repo@67890:*`) rather than the plain-name format most tutorials show. Diagnosed by inspecting the actual `AssumeRoleWithWebIdentity` claim via AWS CloudTrail, then fixing the IAM role's trust policy condition to match.
