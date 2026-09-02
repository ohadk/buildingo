import {
  createCipheriv,
  createDecipheriv,
  createHmac,
  hkdfSync,
  randomBytes,
} from "crypto";

const ENC_INFO = "dira-pii-aes-gcm";
const HMAC_INFO = "dira-pii-hmac";

function masterKey(): Buffer | null {
  const raw = process.env.PII_SECRET_KEY?.trim();
  if (!raw) return null;
  return Buffer.from(raw, "base64");
}

/** True when PII_SECRET_KEY is set — encrypted storage + hash lookups. */
export function isPiiProtectionEnabled(): boolean {
  const key = masterKey();
  return key != null && key.length >= 32;
}

function encKey(): Buffer {
  const key = masterKey();
  if (!key) throw new Error("PII_SECRET_KEY is not configured");
  return Buffer.from(hkdfSync("sha256", key, "", ENC_INFO, 32));
}

function hmacKey(): Buffer {
  const key = masterKey();
  if (!key) throw new Error("PII_SECRET_KEY is not configured");
  return Buffer.from(hkdfSync("sha256", key, "", HMAC_INFO, 32));
}

/** Normalize phone to E.164 for consistent hashing. */
export function normalizePhone(phone: string): string {
  const digits = phone.replace(/[^\d+]/g, "");
  if (digits.startsWith("+")) return digits;
  if (digits.startsWith("972")) return `+${digits}`;
  if (digits.startsWith("0")) return `+972${digits.slice(1)}`;
  return `+${digits}`;
}

export function phoneHash(phone: string): string {
  const normalized = normalizePhone(phone);
  if (!isPiiProtectionEnabled()) return normalized;
  return createHmac("sha256", hmacKey()).update(normalized).digest("hex");
}

export function emailHash(email: string): string {
  const normalized = email.trim().toLowerCase();
  if (!isPiiProtectionEnabled()) return normalized;
  return createHmac("sha256", hmacKey()).update(normalized).digest("hex");
}

/** AES-256-GCM: base64(iv || ciphertext || tag). */
export function encryptPii(plaintext: string): string {
  if (!isPiiProtectionEnabled()) return plaintext;
  const iv = randomBytes(12);
  const c = createCipheriv("aes-256-gcm", encKey(), iv);
  const encrypted = Buffer.concat([c.update(plaintext, "utf8"), c.final()]);
  const tag = c.getAuthTag();
  return Buffer.concat([iv, encrypted, tag]).toString("base64");
}

export function decryptPii(payload: string): string {
  if (!isPiiProtectionEnabled()) return payload;
  const buf = Buffer.from(payload, "base64");
  const iv = buf.subarray(0, 12);
  const tag = buf.subarray(buf.length - 16);
  const ciphertext = buf.subarray(12, buf.length - 16);
  const d = createDecipheriv("aes-256-gcm", encKey(), iv);
  d.setAuthTag(tag);
  return Buffer.concat([d.update(ciphertext), d.final()]).toString("utf8");
}

/** Last 4 digits for audit logs — never store full phone in JSONB. */
export function maskPhone(phone: string): string {
  const digits = phone.replace(/\D/g, "");
  if (digits.length < 4) return "****";
  return `***${digits.slice(-4)}`;
}
