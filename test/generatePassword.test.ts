import { describe, expect, it } from "vitest";
import { generatePassword } from "../src/generatePassword.js";

describe("generatePassword", () => {
  it("uses the default options: length 16, all character sets enabled", () => {
    const password = generatePassword();
    expect(password).toHaveLength(16);
    expect(password).toMatch(/[a-z]/);
  });

  it("respects a custom length", () => {
    const password = generatePassword({ length: 32 });
    expect(password).toHaveLength(32);
  });

  it("only uses lowercase letters when other character sets are disabled", () => {
    const password = generatePassword({
      symbols: false,
      numbers: false,
      uppercase: false,
    });
    expect(password).toMatch(/^[a-z]+$/);
  });

  it("throws when length is out of range", () => {
    expect(() => generatePassword({ length: 3 })).toThrow();
    expect(() => generatePassword({ length: 129 })).toThrow();
  });

  it("throws when every character set is disabled", () => {
    expect(() =>
      generatePassword({
        symbols: false,
        numbers: false,
        uppercase: false,
        lowercase: false,
      })
    ).toThrow(/at least one character set/i);
  });
});
