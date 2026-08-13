# password-generator-lambda

## What I'm learning

This project is my hands-on introduction to AWS and infrastructure-as-code. 
I'm building a small serverless app end-to-end to learn:
- Deploying to AWS Lambda + API Gateway
- Managing infrastructure with Terraform (including remote state via S3 + DynamoDB)
- Setting up CI/CD with GitHub Actions
- Authenticating GitHub to AWS via OIDC instead of long-lived access keys

The core password-generation logic below is done. The Lambda handler, 
Terraform config, and CI/CD pipeline are next.

A cryptographically secure password generator, written in TypeScript. This is the core logic for a Lambda function I'm building as a learning exercise (handler, infrastructure, and CI/CD to be added separately).

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

_TODO_

## Infrastructure

_TODO_

## CI/CD

_TODO_
