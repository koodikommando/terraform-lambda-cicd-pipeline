# password-generator-lambda

## What I'm learning

This project is my hands-on introduction to AWS and infrastructure-as-code.
I'm building a small serverless app end-to-end to learn:
- Deploying to AWS Lambda + API Gateway
- Managing infrastructure with Terraform (including remote state via S3 + DynamoDB)
- Setting up CI/CD with GitHub Actions
- Authenticating GitHub to AWS via OIDC instead of long-lived access keys

A cryptographically secure password generator, written in TypeScript, deployed to AWS Lambda behind API Gateway with hand-written Terraform. Built as a learning exercise covering the full path from pure logic to a live, provisioned endpoint (CI/CD still to come).

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
- API Gateway HTTP API with a `GET /` route and `$default` auto-deploy stage
- CloudWatch log group
- Lambda permission allowing API Gateway to invoke the function
- GitHub OIDC provider + an IAM role scoped to this repo, so GitHub Actions can assume AWS credentials without long-lived access keys

Deployed via `terraform apply` from a local machine. State is currently local (`terraform.tfstate`); a remote backend (S3 + DynamoDB for locking) is planned but not yet implemented.

The API is live:

```sh
curl "https://id6sqlo52c.execute-api.eu-north-1.amazonaws.com/?length=20"
```

```json
{"password":"wT2tyNnz]LBcf}%KN[wk"}
```

## CI/CD

The AWS-side trust (OIDC provider + IAM role, see above) is in place so GitHub Actions can authenticate to AWS, but the actual workflow — running tests, packaging the Lambda, and running `terraform apply` on push — hasn't been written yet.

_TODO_
