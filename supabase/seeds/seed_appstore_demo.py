#!/usr/bin/env python3
"""Seed polished Hebrew demo data for App Store screenshots (מייזנר 17)."""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENV_PATH = ROOT / "apps" / "web" / ".env.local"

BID = "3f61059a-b9a9-4b8d-b452-224f04d05dc6"
VAAD = "4134151d-d649-43fb-85d4-0973da0c7f93"
TENANT = "5dabc463-8435-4b16-9aba-3eb8b4053495"
APT_TENANT = "25df1cea-a384-4f38-8bfe-11324822191e"
APT_VAAD = "216a1711-8862-4687-ba0e-ab02be4398b6"


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
            with urllib.request.urlopen(request, timeout=30) as res:
                raw = res.read().decode()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:500]}")

    def get(path: str):
        return req("GET", path) or []

    today = datetime(2026, 9, 7, tzinfo=timezone.utc)

    # Cleanup junk + previous demo titles
    for row in get(f"announcements?building_id=eq.{BID}&select=id,title"):
        t = row["title"]
        if "asdasd" in t.lower() or "גיורש" in t:
            req("DELETE", f"announcements?id=eq.{row['id']}", prefer="return=minimal")
    for row in get(f"meetings?building_id=eq.{BID}&select=id,title"):
        if "asdasd" in row["title"].lower():
            req("DELETE", f"meetings?id=eq.{row['id']}", prefer="return=minimal")

    anns = [
        {
            "building_id": BID,
            "title": "ניקיון חדר האשפה – יום שלישי",
            "body": "ביום שלישי בין 08:00–11:00 יתבצע ניקיון יסודי בחדר האשפה ובחדר המדרגות. אנא פנו שקיות גדולות מראש.",
            "category": "maintenance",
            "event_date": "2026-09-09",
            "created_by": VAAD,
            "created_at": (today - timedelta(days=1)).isoformat(),
        },
        {
            "building_id": BID,
            "title": "תזכורת: תשלום ועד לחודש ספטמבר",
            "body": "ניתן לשלם באפליקציה או בהעברה בנקאית. מי שכבר שילם – תודה רבה! לשאלות פנו לוועד.",
            "category": "update",
            "event_date": None,
            "created_by": VAAD,
            "created_at": (today - timedelta(hours=8)).isoformat(),
        },
        {
            "building_id": BID,
            "title": "אסיפת דיירים – 18 בספטמבר",
            "body": "נפגשים בלובי בשעה 20:00. על הפרק: תקציב 2026, גינון החצר, ושדרוג תאורת הכניסה. נשמח לראותכם.",
            "category": "meeting",
            "event_date": "2026-09-18",
            "created_by": VAAD,
            "created_at": (today - timedelta(hours=2)).isoformat(),
        },
        {
            "building_id": BID,
            "title": "טיפ: מיחזור קרטון",
            "body": "קרטונים גדולים יש לקפל ולשים ליד מתקן המיחזור – לא בחדר האשפה. תודה על השמירה על הניקיון!",
            "category": "tip",
            "event_date": None,
            "created_by": VAAD,
            "created_at": (today - timedelta(days=2)).isoformat(),
        },
    ]
    for a in anns:
        for row in get(
            f"announcements?building_id=eq.{BID}&title=eq.{urllib.parse.quote(a['title'])}&select=id"
        ):
            req("DELETE", f"announcements?id=eq.{row['id']}", prefer="return=minimal")
    req("POST", "announcements", anns)
    print("announcements ok")

    for row in get(f"meetings?building_id=eq.{BID}&select=id,title"):
        if row["title"].startswith("אסיפת דיירים –"):
            req("DELETE", f"meetings?id=eq.{row['id']}", prefer="return=minimal")
    req(
        "POST",
        "meetings",
        [
            {
                "building_id": BID,
                "title": "אסיפת דיירים – סיכום קיץ",
                "agenda": "1. סיכום הוצאות הקיץ\n2. תכנון גינון לחורף\n3. הצבעה: התקנת מצלמות בכניסה",
                "meeting_date": "2026-09-07T20:00:00+00:00",
                "location": "לובי הבניין",
                "created_by": VAAD,
                "is_closed": False,
            },
            {
                "building_id": BID,
                "title": "אסיפת דיירים – תקציב 2026",
                "agenda": "1. הצגת תקציב מוצע\n2. דיון על דמי ועד\n3. בחירת נציג ועד נוסף",
                "meeting_date": "2026-09-18T17:00:00+00:00",
                "location": "לובי הבניין",
                "created_by": VAAD,
                "is_closed": False,
            },
        ],
    )
    print("meetings ok")

    bulb = get(
        f"tickets?building_id=eq.{BID}&title=eq.{urllib.parse.quote('מנורה שרופה בקומה 1')}&select=id"
    ) or get(
        f"tickets?building_id=eq.{BID}&title=eq.{urllib.parse.quote('מנורה שרופה')}&select=id"
    )
    if bulb:
        req(
            "PATCH",
            f"tickets?id=eq.{bulb[0]['id']}",
            {
                "status": "in_progress",
                "title": "מנורה שרופה בקומה 1",
                "description": "המנורה בחלל המדרגות בקומה הראשונה כבויה. צריך החלפת נורה / נטל.",
                "location": "חדר מדרגות · קומה 1",
                "category": "lights",
                "progress_note": "הזמנו חשמלאי – מתוכנן להגיע מחר בבוקר",
                "fix_date": "2026-09-08",
            },
        )

    tickets = [
        {
            "building_id": BID,
            "apartment_id": APT_TENANT,
            "reported_by": TENANT,
            "title": "דלת החניון לא נסגרת",
            "description": "הדלת האוטומטית של החניון נתקעת באמצע ומשאירה פתח. קורה בעיקר בערב.",
            "status": "open",
            "location": "חניון תת-קרקעי",
            "category": "door",
            "agent_status": "idle",
            "progress_note": None,
            "fix_date": None,
            "cost_amount": None,
        },
        {
            "building_id": BID,
            "apartment_id": APT_TENANT,
            "reported_by": TENANT,
            "title": "רטיבות בתקרה ליד הדירה 15",
            "description": "כתם רטיבות גדל ליד תאורת המסדרון. נראה כמו נזילה מצינור מעל.",
            "status": "in_progress",
            "location": "מסדרון · קומה 5",
            "category": "leak",
            "agent_status": "idle",
            "progress_note": "אינסטלטור ביקר היום – ממתין לחלק",
            "fix_date": "2026-09-10",
            "cost_amount": None,
        },
        {
            "building_id": BID,
            "apartment_id": APT_VAAD,
            "reported_by": VAAD,
            "title": "ניקיון לובי אחרי שיפוץ",
            "description": "נותר אבק בנייה בלובי אחרי עבודות הצבע. מבקשים ניקיון יסודי.",
            "status": "resolved",
            "location": "לובי",
            "category": "cleaning",
            "agent_status": "idle",
            "progress_note": None,
            "fix_date": None,
            "cost_amount": 450,
        },
    ]
    for t in tickets:
        for row in get(
            f"tickets?building_id=eq.{BID}&title=eq.{urllib.parse.quote(t['title'])}&select=id"
        ):
            req("DELETE", f"tickets?id=eq.{row['id']}", prefer="return=minimal")
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
                    "actor": VAAD,
                }
            )
        if t["status"] == "in_progress":
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "Progress update",
                    "detail": "אינסטלטור ביקר היום – ממתין לחלק",
                    "actor": VAAD,
                }
            )
        if t["status"] == "resolved":
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "Done",
                    "detail": "הניקיון הושלם",
                    "actor": VAAD,
                }
            )
            events.append(
                {
                    "ticket_id": t["id"],
                    "building_id": BID,
                    "label": "Repair cost recorded",
                    "detail": "₪450",
                    "actor": VAAD,
                }
            )
        req("POST", "ticket_events", events)
    print("tickets ok", len(created))

    pays = get(
        f"payments?building_id=eq.{BID}&month=eq.9&year=eq.2026&status=eq.pending&select=id&limit=8"
    )
    for p in pays[:6]:
        req(
            "PATCH",
            f"payments?id=eq.{p['id']}",
            {"status": "paid", "payment_date": "2026-09-03"},
            prefer="return=minimal",
        )
    print("done — pull to refresh in the app")


if __name__ == "__main__":
    main()
