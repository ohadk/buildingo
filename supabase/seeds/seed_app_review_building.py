#!/usr/bin/env python3
"""
Seed a compact App Review / QA building: 2 floors × 2 apartments = 4 units.

Leaves מייזנר 17 alone (real QA data). Creates or refreshes:

  Apt 1 · Floor 1 · Vaad   · +972501234567 · OTP 123456
  Apt 2 · Floor 1 · Tenant · +972548899653 · OTP 111111
  Apt 3 · Floor 2 · Tenant · +972547777777 · OTP 111111
  Apt 4 · Floor 2 · Tenant · +972501234568 · OTP 123456

Plus announcements, meetings, tickets, payments, expenses.

Requires apps/web/.env.local (SUPABASE_URL + SUPABASE_SECRET_KEY).

  python3 supabase/seeds/seed_app_review_building.py

Also add the four numbers as Firebase Authentication → Phone → test numbers
(matching OTPs above). Backend accepts them via apps/web/src/lib/auth/test-phones.ts.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENV_PATH = ROOT / "apps" / "web" / ".env.local"

# Stable IDs so re-runs are idempotent (valid hex UUIDs)
BID = "a11c0001-a000-4e11-8001-000000000001"
APT = {
    1: "a11c0001-a001-4e11-8001-000000000001",
    2: "a11c0001-a001-4e11-8001-000000000002",
    3: "a11c0001-a001-4e11-8001-000000000003",
    4: "a11c0001-a001-4e11-8001-000000000004",
}
UID = {
    "vaad": "a11c0001-a002-4e11-8001-000000000001",
    "t2": "a11c0001-a002-4e11-8001-000000000002",
    "t3": "a11c0001-a002-4e11-8001-000000000003",
    "t4": "a11c0001-a002-4e11-8001-000000000004",
}

BUILDING_NAME = "בניין דמו — App Review"
JOIN_CODE = "APPREV01"

RESIDENTS = [
    {
        "key": "vaad",
        "apt": 1,
        "role": "vaad",
        "phone": "+972501234567",
        "name": "דנה כהן",
        "occupants": 2,
    },
    {
        "key": "t2",
        "apt": 2,
        "role": "tenant",
        "phone": "+972548899653",
        "name": "יוסי לוי",
        "occupants": 3,
    },
    {
        "key": "t3",
        "apt": 3,
        "role": "tenant",
        "phone": "+972547777777",
        "name": "מיכל אברהם",
        "occupants": 2,
    },
    {
        "key": "t4",
        "apt": 4,
        "role": "tenant",
        "phone": "+972501234568",
        "name": "נועם שפירא",
        "occupants": 1,
    },
]


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def main() -> None:
    env = load_env()
    base = env["SUPABASE_URL"].rstrip("/")
    key = env["SUPABASE_SECRET_KEY"]
    today = datetime.now(timezone.utc)
    month, year = today.month, today.year
    prev = date(year, month, 1) - timedelta(days=1)
    prev_m, prev_y = prev.month, prev.year

    def req(method: str, path: str, body=None, prefer: str = "return=representation"):
        data = None if body is None else json.dumps(body).encode()
        headers = {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": prefer,
        }
        request = urllib.request.Request(
            f"{base}/rest/v1/{path}", data=data, headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as res:
                raw = res.read().decode()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:800]}")

    def get(path: str):
        return req("GET", path) or []

    def soft_req(method: str, path: str, body=None, prefer: str = "return=representation"):
        try:
            return req(method, path, body, prefer)
        except SystemExit as e:
            return e

    # --- Building ---
    existing = get(f"buildings?id=eq.{BID}&select=id")
    building_row = {
        "id": BID,
        "name": BUILDING_NAME,
        "address": "רחוב הדגמה 4",
        "city": "תל אביב",
        "country": "IL",
        "fee_method": "fixed",
        "fixed_monthly_fee": 450,
        "plan_status": "active",
        "is_active": True,
        "join_code": JOIN_CODE,
        "require_join_docs": False,
        "elevator_count": 1,
        "entrances": [{"label": "ראשית", "code": "1234"}],
        "bank_name": "הפועלים",
        "bank_branch": "600",
        "bank_account_number": "123456",
    }
    if existing:
        req("PATCH", f"buildings?id=eq.{BID}", building_row, prefer="return=minimal")
        print("building updated", BID)
    else:
        for row in get(f"buildings?join_code=eq.{JOIN_CODE}&select=id"):
            if row["id"] != BID:
                req(
                    "PATCH",
                    f"buildings?id=eq.{row['id']}",
                    {"join_code": f"OLD{JOIN_CODE[:8]}"},
                    prefer="return=minimal",
                )
        req("POST", "buildings", building_row)
        print("building created", BID)

    # --- Apartments ---
    for n, floor in ((1, 1), (2, 1), (3, 2), (4, 2)):
        row = {
            "id": APT[n],
            "building_id": BID,
            "apartment_number": n,
            "floor": floor,
            "monthly_fee": 450,
            "size_sqm": 75 if n % 2 else 90,
        }
        if get(f"apartments?id=eq.{APT[n]}&select=id"):
            req("PATCH", f"apartments?id=eq.{APT[n]}", row, prefer="return=minimal")
        else:
            req("POST", "apartments", row)
    for row in get(f"apartments?building_id=eq.{BID}&select=id,apartment_number"):
        if row["apartment_number"] not in (1, 2, 3, 4):
            req("DELETE", f"apartments?id=eq.{row['id']}", prefer="return=minimal")
    print("apartments ok: 1–4 (floors 1–2)")

    def phone_eq(phone: str) -> str:
        # PostgREST: encode '+' as %2B or the filter is truncated
        return f"phone_number=eq.{urllib.parse.quote(phone, safe='')}"

    # --- Users ---
    for r in RESIDENTS:
        phone = r["phone"]
        patch = {
            "full_name": r["name"],
            "role": r["role"],
            "building_id": BID,
            "apartment_id": APT[r["apt"]],
            "num_occupants": r["occupants"],
            "onboarded_at": (today - timedelta(days=14)).isoformat(),
            "account_status": "active",
            "is_active": True,
            "deleted_at": None,
            "status_reason": None,
        }
        found = get(f"users?{phone_eq(phone)}&select=id")
        if not found:
            found = get(f"users?id=eq.{UID[r['key']]}&select=id")
        if found:
            req("PATCH", f"users?id=eq.{found[0]['id']}", patch, prefer="return=minimal")
            UID[r["key"]] = found[0]["id"]
            print(f"  user relinked {phone} → apt {r['apt']} ({r['role']})")
        else:
            req(
                "POST",
                "users",
                {
                    "id": UID[r["key"]],
                    "firebase_uid": f"seed-pending-{phone.lstrip('+')}",
                    "phone_number": phone,
                    **patch,
                },
            )
            print(f"  user created {phone} → apt {r['apt']} ({r['role']})")

    for r in RESIDENTS:
        rows = get(f"users?{phone_eq(r['phone'])}&select=id")
        if not rows:
            rows = get(f"users?id=eq.{UID[r['key']]}&select=id")
        if rows:
            UID[r["key"]] = rows[0]["id"]
    vaad_id = UID["vaad"]

    # --- Tenancies ---
    for r in RESIDENTS:
        apt_id = APT[r["apt"]]
        for t in get(
            f"tenancies?apartment_id=eq.{apt_id}&status=eq.active&select=id,user_id"
        ):
            if t.get("user_id") != UID[r["key"]]:
                end_patch = {"status": "ended"}
                # ended_at may or may not exist
                soft = soft_req(
                    "PATCH",
                    f"tenancies?id=eq.{t['id']}",
                    {**end_patch, "ended_at": today.date().isoformat()},
                    prefer="return=minimal",
                )
                if isinstance(soft, SystemExit):
                    req(
                        "PATCH",
                        f"tenancies?id=eq.{t['id']}",
                        end_patch,
                        prefer="return=minimal",
                    )
        mine = get(
            f"tenancies?apartment_id=eq.{apt_id}&user_id=eq.{UID[r['key']]}&status=eq.active&select=id"
        )
        if not mine:
            req(
                "POST",
                "tenancies",
                {
                    "building_id": BID,
                    "apartment_id": apt_id,
                    "user_id": UID[r["key"]],
                    "full_name": r["name"],
                    "phone_number": r["phone"],
                    "holder_type": "owner" if r["role"] == "vaad" else "renter",
                    "num_occupants": r["occupants"],
                    "status": "active",
                },
            )
    print("tenancies ok")

    # --- Clear previous demo content ---
    # Delete ticket_events first (FK), then tickets, then other content
    ticket_ids = [t["id"] for t in get(f"tickets?building_id=eq.{BID}&select=id")]
    for tid in ticket_ids:
        soft_req("DELETE", f"ticket_events?ticket_id=eq.{tid}", prefer="return=minimal")
    for table in ("tickets", "announcements", "meetings", "expenses", "payments"):
        for row in get(f"{table}?building_id=eq.{BID}&select=id"):
            req("DELETE", f"{table}?id=eq.{row['id']}", prefer="return=minimal")
    sched_existing = soft_req(
        "GET", f"schedule_events?building_id=eq.{BID}&select=id", prefer="return=representation"
    )
    if not isinstance(sched_existing, SystemExit):
        for row in sched_existing or []:
            req("DELETE", f"schedule_events?id=eq.{row['id']}", prefer="return=minimal")

    # --- Announcements ---
    req(
        "POST",
        "announcements",
        [
            {
                "building_id": BID,
                "title": "ברוכים הבאים לבניין הדמו",
                "body": "זה בניין לדוגמה לביקורת App Store ול-QA. אפשר להתחבר עם מספרי הבדיקה של Firebase.",
                "category": "update",
                "event_date": None,
                "created_by": vaad_id,
                "created_at": (today - timedelta(days=3)).isoformat(),
            },
            {
                "building_id": BID,
                "title": "תזכורת: דמי ועד לחודש הנוכחי",
                "body": "נא לשלם עד ה־10 בחודש. העברה בנקאית או סימון באפליקציה אחרי תשלום מחוץ לאפליקציה.",
                "category": "update",
                "event_date": None,
                "created_by": vaad_id,
                "created_at": (today - timedelta(days=1)).isoformat(),
            },
            {
                "building_id": BID,
                "title": "אסיפת דיירים — השבוע",
                "body": "נפגשים בלובי בשעה 20:00. על הפרק: ניקיון החצר ותאורת הכניסה.",
                "category": "meeting",
                "event_date": (today + timedelta(days=5)).date().isoformat(),
                "created_by": vaad_id,
                "created_at": (today - timedelta(hours=6)).isoformat(),
            },
            {
                "building_id": BID,
                "title": "ניקיון חדר מדרגות",
                "body": "ביום שלישי בבוקר יתבצע ניקיון יסודי. אנא פנו חפצים מהמסדרון.",
                "category": "maintenance",
                "event_date": (today + timedelta(days=2)).date().isoformat(),
                "created_by": vaad_id,
                "created_at": today.isoformat(),
            },
        ],
    )
    print("announcements ok")

    # --- Meetings ---
    req(
        "POST",
        "meetings",
        [
            {
                "building_id": BID,
                "title": "אסיפת דיירים — היכרות",
                "agenda": "1. היכרות עם הדיירים\n2. כללי הבניין\n3. שאלות ותשובות",
                "meeting_date": (today - timedelta(days=7)).isoformat(),
                "location": "לובי",
                "created_by": vaad_id,
                "is_closed": True,
            },
            {
                "building_id": BID,
                "title": "אסיפת דיירים — תחזוקה",
                "agenda": "1. תקציב ניקיון\n2. תאורת כניסה\n3. הצבעה: שדרוג מנעול חניה",
                "meeting_date": (today + timedelta(days=5))
                .replace(hour=17, minute=0, second=0, microsecond=0)
                .isoformat(),
                "location": "לובי",
                "created_by": vaad_id,
                "is_closed": False,
            },
        ],
    )
    print("meetings ok")

    # --- Schedule (optional) ---
    sched = soft_req(
        "POST",
        "schedule_events",
        [
            {
                "building_id": BID,
                "event_type": "garbage",
                "title": "פינוי אשפה",
                "notes": "שקיות ליד המתקן עד 07:00",
                "recurrence": "weekly",
                "day_of_week": 0,
                "day_of_month": None,
                "specific_date": None,
                "time_of_day": "07:00:00",
                "created_by": vaad_id,
            },
            {
                "building_id": BID,
                "event_type": "cleaning",
                "title": "ניקיון לובי ומדרגות",
                "notes": None,
                "recurrence": "weekly",
                "day_of_week": 2,
                "day_of_month": None,
                "specific_date": None,
                "time_of_day": "09:00:00",
                "created_by": vaad_id,
            },
        ],
    )
    if isinstance(sched, SystemExit):
        print("schedule_events skipped:", str(sched)[:120])
    else:
        print("schedule_events ok")

    # --- Tickets ---
    tickets = [
        {
            "building_id": BID,
            "apartment_id": APT[2],
            "reported_by": UID["t2"],
            "title": "נזילה קלה מתחת לכיור",
            "description": "טיפטוף איטי בארון הכיור בדירה 2. מבקשים אינסטלטור.",
            "status": "open",
            "location": "דירה 2 · מטבח",
            "category": "leak",
            "agent_status": "idle",
            "progress_note": None,
            "fix_date": None,
            "cost_amount": None,
        },
        {
            "building_id": BID,
            "apartment_id": APT[3],
            "reported_by": UID["t3"],
            "title": "מנורה שרופה במסדרון קומה 2",
            "description": "התאורה ליד דירה 3 כבויה כבר יומיים.",
            "status": "in_progress",
            "location": "מסדרון · קומה 2",
            "category": "lights",
            "agent_status": "idle",
            "progress_note": "הוזמן חשמלאי — מגיע מחר",
            "fix_date": (today + timedelta(days=1)).date().isoformat(),
            "cost_amount": None,
        },
        {
            "building_id": BID,
            "apartment_id": APT[4],
            "reported_by": UID["t4"],
            "title": "דלת החניה נסגרת לאט",
            "description": "הדלת האוטומטית נתקעת לכמה שניות לפני הסגירה.",
            "status": "resolved",
            "location": "חניון",
            "category": "door",
            "agent_status": "idle",
            "progress_note": None,
            "fix_date": None,
            "cost_amount": 280,
        },
    ]
    created = req("POST", "tickets", tickets) or []
    for t in created:
        events = [
            {
                "ticket_id": t["id"],
                "building_id": BID,
                "label": "Reported",
                "detail": None,
                "actor": t["reported_by"],
            }
        ]
        if t["status"] in ("in_progress", "resolved"):
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "In Progress",
                    "detail": None,
                    "actor": vaad_id,
                }
            )
        if t["status"] == "in_progress":
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "Progress update",
                    "detail": "הוזמן חשמלאי — מגיע מחר",
                    "actor": vaad_id,
                }
            )
        if t["status"] == "resolved":
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "Done",
                    "detail": "תוקן מנגנון הסגירה",
                    "actor": vaad_id,
                }
            )
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "Repair cost recorded",
                    "detail": "₪280",
                    "actor": vaad_id,
                }
            )
        # Post one-by-one to avoid PGRST102 across mixed optional fields
        for ev in events:
            req("POST", "ticket_events", ev)
    print("tickets ok", len(created))

    # --- Payments ---
    pay_rows = []
    for n in (1, 2, 3, 4):
        pay_rows.append(
            {
                "building_id": BID,
                "apartment_id": APT[n],
                "month": prev_m,
                "year": prev_y,
                "amount": 450,
                "status": "paid",
                "payment_date": date(prev_y, prev_m, 5).isoformat(),
            }
        )
    for n in (1, 2, 3, 4):
        status = "paid" if n in (1, 2) else "pending"
        pay_rows.append(
            {
                "building_id": BID,
                "apartment_id": APT[n],
                "month": month,
                "year": year,
                "amount": 450,
                "status": status,
                "payment_date": date(year, month, 3).isoformat()
                if status == "paid"
                else None,
            }
        )
    # Split posts so paid/pending batches share identical keys within each request
    req("POST", "payments", pay_rows[:4])
    req(
        "POST",
        "payments",
        [
            {
                "building_id": BID,
                "apartment_id": APT[n],
                "month": month,
                "year": year,
                "amount": 450,
                "status": "paid" if n in (1, 2) else "pending",
                "payment_date": date(year, month, 3).isoformat()
                if n in (1, 2)
                else None,
            }
            for n in (1, 2, 3, 4)
        ],
    )
    print("payments ok")

    # --- Expenses ---
    req(
        "POST",
        "expenses",
        [
            {
                "building_id": BID,
                "title": "חשמל משותף",
                "category": "electricity",
                "amount": 620,
                "expense_date": date(year, month, 1).isoformat(),
                "created_by": vaad_id,
            },
            {
                "building_id": BID,
                "title": "ניקיון חודשי",
                "category": "cleaning",
                "amount": 900,
                "expense_date": date(year, month, 2).isoformat(),
                "created_by": vaad_id,
            },
            {
                "building_id": BID,
                "title": "תיקון דלת חניה",
                "category": "maintenance",
                "amount": 280,
                "expense_date": (today - timedelta(days=2)).date().isoformat(),
                "created_by": vaad_id,
            },
        ],
    )
    print("expenses ok")

    print()
    print("=== App Review building ready ===")
    print(f"Building: {BUILDING_NAME}")
    print(f"Join code: {JOIN_CODE}")
    print(f"id: {BID}")
    print()
    print("Firebase test phones (add in Console if missing):")
    print("  +972501234567  → 123456  (Vaad · דירה 1)")
    print("  +972548899653  → 111111  (Tenant · דירה 2)")
    print("  +972547777777  → 111111  (Tenant · דירה 3)")
    print("  +972501234568  → 123456  (Tenant · דירה 4)")
    print()
    print("מייזנר 17 left unchanged for day-to-day QA.")


if __name__ == "__main__":
    main()
