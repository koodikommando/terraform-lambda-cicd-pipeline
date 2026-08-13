import { randomInt } from "node:crypto";

export interface GeneratePasswordOptions {
  length?: number;
  symbols?: boolean;
  numbers?: boolean;
  uppercase?: boolean;
  lowercase?: boolean;
}

const LOWERCASE = "abcdefghijklmnopqrstuvwxyz";
const UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const NUMBERS = "0123456789";
const SYMBOLS = "!@#$%^&*()-_=+[]{}";

const MIN_LENGTH = 4;
const MAX_LENGTH = 128;

export function generatePassword(options: GeneratePasswordOptions = {}): string {
  const {
    length = 16,
    symbols = true,
    numbers = true,
    uppercase = true,
    lowercase = true,
  } = options;

  if (length < MIN_LENGTH || length > MAX_LENGTH) {
    throw new Error(
      `length must be between ${MIN_LENGTH} and ${MAX_LENGTH}, got ${length}`
    );
  }

  let charset = "";
  if (lowercase) charset += LOWERCASE;
  if (uppercase) charset += UPPERCASE;
  if (numbers) charset += NUMBERS;
  if (symbols) charset += SYMBOLS;

  if (charset.length === 0) {
    throw new Error("at least one character set must be enabled");
  }

  let password = "";
  for (let i = 0; i < length; i++) {
    password += charset[randomInt(charset.length)];
  }

  return password;
}
