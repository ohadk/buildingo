import { afterEach, vi } from "vitest";
import { memoryDb } from "./helpers/memory-db";
import { resetFirebaseTokens } from "./helpers/firebase-mock";

vi.mock("next/headers", () => ({
  cookies: async () => ({
    get: () => undefined,
    set: () => {},
  }),
}));

vi.mock("@/lib/firebase/admin", async () => {
  const mock = await import("./helpers/firebase-mock");
  return { adminAuth: mock.adminAuth };
});

vi.mock("@/lib/supabase/admin", async () => {
  const { memoryDb: db } = await import("./helpers/memory-db");
  return {
    supabaseAdmin: () => db.client(),
  };
});

afterEach(() => {
  memoryDb.reset();
  resetFirebaseTokens();
});
