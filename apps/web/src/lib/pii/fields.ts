import {
  decryptPii,
  emailHash,
  encryptPii,
  isPiiProtectionEnabled,
  normalizePhone,
  phoneHash,
} from "./crypto";

type Row = Record<string, unknown>;

export type { Row };

function readPlain(row: Row, plain: string, enc: string, fallback = ""): string {
  const encrypted = row[enc];
  if (typeof encrypted === "string" && encrypted.length > 0) {
    try {
      return decryptPii(encrypted);
    } catch {
      /* fall through */
    }
  }
  const value = row[plain];
  return typeof value === "string" ? value : fallback;
}

/** Resolve plaintext PII fields on a user row for API responses. */
export function decryptUserRow<T extends Row>(row: T): T {
  if (!row) return row;
  const out: Row = { ...row };
  out.phone_number = readPlain(row, "phone_number", "phone_number_enc");
  out.full_name = readPlain(row, "full_name", "full_name_enc", "");
  if (row.email_enc || row.email) {
    out.email = readPlain(row, "email", "email_enc") || null;
  }
  return out as T;
}

export function decryptUserRows<T extends Row>(rows: T[]): T[] {
  return rows.map((r) => decryptUserRow(r));
}

/** Decrypt nested `users` arrays on apartment/directory payloads. */
export function decryptDirectoryApartments<T extends Row>(apartments: T[]): T[] {
  return apartments.map((apt) => {
    const users = apt.users;
    if (!Array.isArray(users)) return apt;
    return { ...apt, users: decryptUserRows(users as Row[]) };
  });
}

export function decryptInvitationRow<T extends Row>(row: T): T {
  if (!row) return row;
  const out: Row = { ...row };
  out.phone_number = readPlain(row, "phone_number", "phone_number_enc");
  return out as T;
}

export function decryptInvitationRows<T extends Row>(rows: T[]): T[] {
  return rows.map((r) => decryptInvitationRow(r));
}

export function decryptTenancyRow<T extends Row>(row: T): T {
  if (!row) return row;
  const out: Row = { ...row };
  out.phone_number = row.phone_number_enc
    ? readPlain(row, "phone_number", "phone_number_enc")
    : (row.phone_number as string | null);
  out.full_name = row.full_name_enc
    ? readPlain(row, "full_name", "full_name_enc", "")
    : (row.full_name as string | null);
  return out as T;
}

export function decryptJoinRequestRow<T extends Row>(row: T): T {
  if (!row) return row;
  const out: Row = { ...row };
  out.full_name = readPlain(row, "full_name", "full_name_enc", "");
  if (row.email_enc || row.email) {
    out.email = readPlain(row, "email", "email_enc") || null;
  }
  return out as T;
}

/** DB columns to write when storing a phone number. */
export function phoneStorageFields(phone: string): Row {
  const normalized = normalizePhone(phone);
  if (!isPiiProtectionEnabled()) {
    return { phone_number: normalized };
  }
  return {
    phone_number: null,
    phone_number_hash: phoneHash(normalized),
    phone_number_enc: encryptPii(normalized),
  };
}

export function fullNameStorageFields(fullName: string | null | undefined): Row {
  const name = fullName?.trim() ?? "";
  if (!isPiiProtectionEnabled()) {
    return { full_name: name };
  }
  if (!name) {
    return { full_name: null, full_name_enc: null };
  }
  return {
    full_name: null,
    full_name_enc: encryptPii(name),
  };
}

export function emailStorageFields(email: string | null | undefined): Row {
  const value = email?.trim() ?? "";
  if (!value) {
    return isPiiProtectionEnabled()
      ? { email: null, email_hash: null, email_enc: null }
      : { email: null };
  }
  if (!isPiiProtectionEnabled()) {
    return { email: value };
  }
  return {
    email: null,
    email_hash: emailHash(value),
    email_enc: encryptPii(value),
  };
}

export function userPiiStorageFields(input: {
  phone?: string;
  fullName?: string | null;
  email?: string | null;
}): Row {
  return {
    ...(input.phone ? phoneStorageFields(input.phone) : {}),
    ...(input.fullName !== undefined ? fullNameStorageFields(input.fullName) : {}),
    ...(input.email !== undefined ? emailStorageFields(input.email) : {}),
  };
}

export function tenancyPiiStorageFields(input: {
  phone?: string | null;
  fullName?: string | null;
}): Row {
  return {
    ...(input.phone ? phoneStorageFields(input.phone) : {}),
    ...(input.fullName !== undefined ? fullNameStorageFields(input.fullName) : {}),
  };
}

export function joinRequestPiiStorageFields(input: {
  fullName?: string;
  email?: string | null;
}): Row {
  return {
    ...(input.fullName !== undefined ? fullNameStorageFields(input.fullName) : {}),
    ...(input.email !== undefined ? emailStorageFields(input.email) : {}),
  };
}

/** Lazy backfill: encrypt legacy plaintext and clear raw columns. */
export function migrateRowPiiFields(row: Row, kind: "user" | "invitation" | "tenancy" | "join_request"): Row {
  if (!isPiiProtectionEnabled()) return {};

  const patch: Row = {};

  if (kind === "user" || kind === "invitation" || kind === "tenancy") {
    const phone = row.phone_number as string | null;
    if (phone && !row.phone_number_hash) {
      Object.assign(patch, phoneStorageFields(phone));
    }
  }

  if (kind === "user" || kind === "tenancy" || kind === "join_request") {
    const name = row.full_name as string | null;
    if (name && !row.full_name_enc) {
      Object.assign(patch, fullNameStorageFields(name));
    }
  }

  if (kind === "user" || kind === "join_request") {
    const email = row.email as string | null;
    if (email && !row.email_hash) {
      Object.assign(patch, emailStorageFields(email));
    }
  }

  return patch;
}
