import { describe, expect, it } from "vitest";
import { POST as sessionPost } from "@/app/api/auth/session/route";
import { POST as onboardingPost } from "@/app/api/onboarding/route";
import { GET as announcementsGet, POST as announcementsPost } from "@/app/api/announcements/route";
import { issueTestIdToken } from "../helpers/firebase-mock";
import { invoke } from "../helpers/http";
import { memoryDb } from "../helpers/memory-db";

const BUILDING_ID = "11111111-1111-1111-1111-111111111111";
const APT_VAAD = "22222222-2222-2222-2222-222222222222";
const APT_TENANT = "33333333-3333-3333-3333-333333333333";
const VAAD_PHONE = "+972547760683";
const TENANT_PHONE = "+972548899656";

function seedBuildingWorld() {
  memoryDb.seed("buildings", [
    {
      id: BUILDING_ID,
      name: "מייזנר 17",
      address: "מייזנר 17",
      city: "פתח תקווה",
      country: "IL",
      is_active: true,
      plan_status: "active",
      trial_ends_at: new Date(Date.now() + 86400000 * 30).toISOString(),
    },
  ]);
  memoryDb.seed("apartments", [
    {
      id: APT_VAAD,
      building_id: BUILDING_ID,
      apartment_number: 2,
      floor: 1,
      monthly_fee: 350,
    },
    {
      id: APT_TENANT,
      building_id: BUILDING_ID,
      apartment_number: 15,
      floor: 5,
      monthly_fee: 350,
    },
  ]);
}

function seedExistingVaad() {
  return memoryDb.seed("users", [
    {
      id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      firebase_uid: `uid-${VAAD_PHONE}`,
      phone_number: VAAD_PHONE,
      full_name: "אוהד קצב",
      role: "vaad",
      building_id: BUILDING_ID,
      apartment_id: APT_VAAD,
      num_occupants: 2,
      onboarded_at: new Date().toISOString(),
      is_active: true,
      lease_contract_path: null,
    },
  ])[0];
}

describe("Auth + announcements end-to-end flow", () => {
  it("signup via invite → onboard → Vaad posts → tenant sees message", async () => {
    seedBuildingWorld();
    const vaad = seedExistingVaad();

    memoryDb.seed("invitations", [
      {
        id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
        building_id: BUILDING_ID,
        apartment_id: APT_TENANT,
        phone_number: TENANT_PHONE,
        role: "tenant",
        status: "pending",
        invite_code: "JOIN15",
        expires_at: new Date(Date.now() + 86400000 * 7).toISOString(),
      },
    ]);

    // 1) Tenant signup (first session after phone OTP)
    const tenantToken = issueTestIdToken(TENANT_PHONE);
    const signup = await invoke(sessionPost, {
      method: "POST",
      path: "http://localhost/api/auth/session",
      body: { idToken: tenantToken },
    });
    expect(signup.status).toBe(200);
    expect(signup.json.needsOnboarding).toBe(true);
    expect(signup.json.user.role).toBe("tenant");
    expect(signup.json.user.building_id).toBe(BUILDING_ID);
    expect(signup.json.user.apartment_id).toBe(APT_TENANT);
    expect(signup.json.user.onboarded_at).toBeNull();

    const invites = memoryDb.all("invitations");
    expect(invites[0].status).toBe("accepted");
    expect(invites[0].accepted_by).toBe(signup.json.user.id);

    // 2) Tenant completes onboarding
    const onboard = await invoke(onboardingPost, {
      method: "POST",
      path: "http://localhost/api/onboarding",
      bearer: tenantToken,
      body: { fullName: "אבנר נתניהו", numOccupants: 3 },
    });
    expect(onboard.status).toBe(200);
    expect(onboard.json.user.full_name).toBe("אבנר נתניהו");
    expect(onboard.json.user.onboarded_at).toBeTruthy();

    // 3) Returning login (same Firebase user)
    const login = await invoke(sessionPost, {
      method: "POST",
      path: "http://localhost/api/auth/session",
      body: { idToken: tenantToken },
    });
    expect(login.status).toBe(200);
    expect(login.json.needsOnboarding).toBe(false);
    expect(login.json.user.id).toBe(signup.json.user.id);

    // 4) Vaad logs in and posts a community message
    const vaadToken = issueTestIdToken(VAAD_PHONE, vaad.firebase_uid as string);
    const vaadLogin = await invoke(sessionPost, {
      method: "POST",
      path: "http://localhost/api/auth/session",
      body: { idToken: vaadToken },
    });
    expect(vaadLogin.status).toBe(200);
    expect(vaadLogin.json.user.role).toBe("vaad");

    const post = await invoke(announcementsPost, {
      method: "POST",
      path: "http://localhost/api/announcements",
      bearer: vaadToken,
      body: {
        title: "אסיפת דיירים",
        body: "מחר ב-20:00 בחדר המדרגות",
      },
    });
    expect(post.status).toBe(201);
    expect(post.json.announcement.title).toBe("אסיפת דיירים");
    expect(post.json.announcement.building_id).toBe(BUILDING_ID);
    expect(post.json.announcement.created_by).toBe(vaad.id);

    // 5) Tenant sees the message on the board
    const board = await invoke(announcementsGet, {
      method: "GET",
      path: "http://localhost/api/announcements",
      bearer: tenantToken,
    });
    expect(board.status).toBe(200);
    expect(board.json.announcements).toHaveLength(1);
    expect(board.json.announcements[0].title).toBe("אסיפת דיירים");
    expect(board.json.announcements[0].body).toBe("מחר ב-20:00 בחדר המדרגות");

    // 6) Tenant cannot publish to the board
    const denied = await invoke(announcementsPost, {
      method: "POST",
      path: "http://localhost/api/announcements",
      bearer: tenantToken,
      body: { title: "ניסיון", body: "לא אמור לעבור" },
    });
    expect(denied.status).toBe(403);
  });

  it("signup without invite creates a bare profile that cannot read the board", async () => {
    seedBuildingWorld();
    const phone = "+972547777777";
    const token = issueTestIdToken(phone);

    const signup = await invoke(sessionPost, {
      method: "POST",
      path: "http://localhost/api/auth/session",
      body: { idToken: token },
    });
    expect(signup.status).toBe(200);
    expect(signup.json.user.role).toBe("tenant");
    expect(signup.json.user.building_id).toBeNull();
    expect(signup.json.needsOnboarding).toBe(true);

    const board = await invoke(announcementsGet, {
      method: "GET",
      path: "http://localhost/api/announcements",
      bearer: token,
    });
    expect(board.status).toBe(409);
    expect(board.json.error).toMatch(/building/i);
  });

  it("rejects unauthenticated announcement access", async () => {
    const board = await invoke(announcementsGet, {
      method: "GET",
      path: "http://localhost/api/announcements",
    });
    expect(board.status).toBe(401);
  });

  it("relinks an existing phone profile when Firebase UID changes", async () => {
    seedBuildingWorld();
    memoryDb.seed("users", [
      {
        id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
        firebase_uid: "old-uid",
        phone_number: TENANT_PHONE,
        full_name: "דייר קיים",
        role: "tenant",
        building_id: BUILDING_ID,
        apartment_id: APT_TENANT,
        num_occupants: 1,
        onboarded_at: new Date().toISOString(),
        is_active: true,
        lease_contract_path: null,
      },
    ]);

    const token = issueTestIdToken(TENANT_PHONE, "new-uid-after-reinstall");
    const login = await invoke(sessionPost, {
      method: "POST",
      path: "http://localhost/api/auth/session",
      body: { idToken: token },
    });
    expect(login.status).toBe(200);
    expect(login.json.user.id).toBe("cccccccc-cccc-cccc-cccc-cccccccccccc");
    expect(login.json.user.firebase_uid).toBe("new-uid-after-reinstall");
    expect(login.json.needsOnboarding).toBe(false);
  });
});
