
import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from "aws-lambda";
import { generatePassword, GeneratePasswordOptions } from "./generatePassword.js";

export async function handler(
  event: APIGatewayProxyEventV2
): Promise<APIGatewayProxyResultV2> {
  const params = event.queryStringParameters ?? {};

  const options: GeneratePasswordOptions = {
    length: params.length ? Number(params.length) : undefined,
    symbols: params.symbols ? params.symbols === "true" : undefined,
    numbers: params.numbers ? params.numbers === "true" : undefined,
    uppercase: params.uppercase ? params.uppercase === "true" : undefined,
    lowercase: params.lowercase ? params.lowercase === "true" : undefined,
  };

  try {
    const password = generatePassword(options);
    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    };
  } catch (err) {
    return {
      statusCode: 400,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        error: err instanceof Error ? err.message : "invalid request",
      }),
    };
  }
}