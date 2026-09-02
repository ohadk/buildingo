import { describe, expect, it, beforeEach, afterEach } from "vitest";
import {
  decryptPii,
  emailHash,
  encryptPii,
  normalizePhone,
  phoneHash,
} from "@/lib/pii/crypto";

describe("pii crypto", () => {
  const original = process.env.PII_SECRET_KEY;

  beforeEach(() => {
    process.env.PII_SECRET_KEY = Buffer.alloc(32, 7).toString("base64");
  });

  afterEach(() => {
    if (original === undefined) delete process.env.PII_SECRET_KEY;
    else process.env.PII_SECRET_KEY = original;
  });

  it("normalizes Israeli local numbers to E.164", () => {
    expect(normalizePhone("054-889-9656")).toBe("+972548899656");
    expect(normalizePhone("+972548899656")).toBe("+972548899656");
  });

  it("encrypts and decrypts round-trip", () => {
    const plain = "אבנר נתניהו";
    const enc = encryptPii(plain);
    expect(enc).not.toContain(plain);
    expect(decryptPii(enc)).toBe(plain);
  });

  it("produces stable phone hashes for lookup", () => {
    const a = phoneHash("+972548899656");
    const b = phoneHash(normalizePhone("0548899656"));
    expect(a).toBe(b);
    expect(a).toHaveLength(64);
  });

  it("normalizes email before hashing", () => {
    expect(emailHash("  Test@Example.COM ")).toBe(emailHash("test@example.com"));
  });
});
