# App Store Connect — Buildingo listing copy & assets

Primary language for Israel: **Hebrew (he)**. Keep **English (en-US)** as a localization.

Upload assets from this folder (`apps/mobile/store/`). After changing icons/launch images, rebuild the IPA before distributing.

---

## App information

| Field | Value |
|---|---|
| App name | Buildingo |
| Bundle ID | `com.buildingo.buildingoMobile` |
| Version | 1.0.0 |
| Copyright | `© 2026 Buildingo` |
| Support URL | `https://buildingo.com/support` |
| Marketing URL | `https://buildingo.com` |
| Privacy Policy URL | `https://buildingo.com/privacy` |

> Paste these into App Store Connect. Pages live in the Next.js app (`/support`, `/privacy`; `/contact` redirects to `/support`). Deploy the web app to `buildingo.com` before submit. Apple requires a working **Support URL** and (for account-based apps) a **Privacy Policy URL**.

---

## Promotional text (max 170 characters) — editable anytime

### Hebrew
```
ניהול בניין לדיירים ולועד: תשלומים, תקלות, הודעות, מסמכים והזמנות — הכל באפליקציה אחת בעברית.
```

### English
```
Building management for residents and the Vaad: dues, faults, announcements, documents, and invites — one Hebrew-first app.
```

---

## Description (max 4000 characters)

### Hebrew
```
Buildingo היא האפליקציה שמסדרת את הבניין.

לועד הבית:
• מעקב גביית דמי ועד ואישור תשלומים
• ניהול דיירים והזמנות לפי דירה
• פרסום הודעות ללוח הקהילה
• טיפול בתקלות ושיגור סוכני ספקים
• מסמכי בניין ולוח אירועים / אסיפות

לדיירים:
• צפייה בתשלומים הקרובים וביתרת הבניין
• דיווח תקלות ומעקב סטטוס
• הודעות ועד ואירועים קרובים
• מסמכים אישיים של הדירה
• הצטרפות לבניין בהזמנה

עברית מלאה (RTL), התחברות עם מספר טלפון, והתראות על מה שקורה בבניין.

Buildingo — הבית של הבניין.
```

### English
```
Buildingo keeps your building organized.

For the Vaad (building committee):
• Track monthly dues and mark payments received
• Manage residents and per-apartment invites
• Publish announcements to the community board
• Handle maintenance tickets and dispatch vendor agents
• Building documents, schedule, and assemblies

For residents:
• See upcoming dues and building context
• Report faults and follow status
• Read Vaad announcements and upcoming events
• Access apartment documents
• Join a building with an invite

Hebrew-first (RTL), phone sign-in, and a clear home for everything that happens in the building.

Buildingo — your building, organized.
```

---

## Keywords (max 100 characters, comma-separated, no spaces after commas preferred)

### Hebrew
```
ועד בית,דיירים,דמי ועד,תקלות,בניין,אסיפה,ניהול בניין,תשלומים,הודעות
```
(count carefully in App Store Connect; trim if over 100)

### English
```
building,hoa,dues,maintenance,tenants,committee,apartment,vaad,residents
```

---

## What’s New (Version 1.0.0)

### Hebrew
```
גרסה ראשונה של Buildingo: בית לדיירים ולועד — תשלומים, תקלות, הודעות ומסמכים.
```

### English
```
First release of Buildingo: home for residents and the Vaad — dues, faults, announcements, and documents.
```

---

## Assets checklist

### App icon (required)
- `icon/AppIcon-1024.png` — 1024×1024, RGB, **no alpha** (also `AppIcon-1024.jpg`)
- Same art is wired into `ios/.../AppIcon.appiconset/` and Android `mipmap-*/ic_launcher.png`
- Launch / splash: cream background + centered logo in `LaunchImage.imageset` (was a 1×1 placeholder — that is why the last build looked logo-less)

### Screenshots — prefer **real UI** for App Review

| Set | Path | Size | Use |
|---|---|---|---|
| **iPad 13″ (upload this)** | `screenshots/ipad-13/` | **2064×2752** | Required 13-inch iPad portrait (HE) |
| iPad 13″ EN | `screenshots/ipad-13-en/` | **2064×2752** | English 13-inch portrait |
| iPad landscape | `screenshots/ipad-asc-2752x2064-he/` | **2752×2064** | 13″ landscape (HE) |
| iPad 12.9″ alt | `screenshots/ipad-asc-2048x2732-he/` | **2048×2732** | Alternate portrait (HE) |
| iPad 12.9″ land. | `screenshots/ipad-asc-2732x2048-he/` | **2732×2048** | Alternate landscape (HE) |
| Same sizes (EN) | `screenshots/ipad-asc-*-en/` | same | English variants |
| iPhone 6.5″ | `screenshots/asc-1284x2778-he/` | 1284×2778 | iPhone 6.5″ slot |
| iPhone 6.7″ | `screenshots/iphone-6.7/` | 1320×2868 | Modern iPhone |
| Marketing (HE/EN) | `screenshots/marketing/` / `marketing-en/` | 1320×2868 | Source / extras |

**13-inch iPad accepted sizes:** `2064×2752`, `2752×2064`, `2048×2732`, or `2732×2048`.  
Upload **`ipad-13/`** (2064×2752 portrait) into the **13-inch Display** slot.

Minimum: upload at least **2–3** real screenshots per device size. Current real captures:
1. Tenant home
2. Vaad home

Capture more tabs (Payments / Residents / Docs) in Simulator before submit if you want a fuller gallery.

### App Preview (optional)
- `preview/app-preview.mp4` — MP4, under 500 MB
- Apple also accepts M4V / MOV; 15–30s is typical

---

## After uploading listing assets

1. Rebuild release so the icon + launch screen ship, **with the production API**:  
   ```bash
   cd apps/mobile
   flutter build ipa --release \
     --dart-define=API_BASE_URL=https://buildingo-api--buildingo-6ff54.us-central1.hosted.app
   ```
   (Release builds also default to that URL if the define is omitted — never ship `localhost`.)
2. In Xcode → Organizer → Distribute App (needs Apple ID + **Apple Distribution** certificate)
3. In App Store Connect → prepare for submission → paste the copy above → attach screenshots / preview / 1024 icon

### App Review rejection note (Guideline 2.1 — “app did not load”)

Cause: the submitted IPA was talking to `http://localhost:3000`, so App Review’s devices could not reach the backend and hung on launch. Fixed by defaulting release builds to the App Hosting URL and not blocking startup on `/api/config`.
