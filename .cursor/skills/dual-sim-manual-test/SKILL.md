---
name: dual-sim-manual-test
description: >-
  Boots two iOS Simulator instances of the Buildingo Flutter app for side-by-side
  manual testing — one prefilled with the Vaad test phone, one with the Tenant
  test phone. Use when the user asks to run two simulators, dual-sim test, Vaad
  vs tenant manual QA, or to compare Vaad/tenant behavior visually.
---

# Dual-sim manual test (Vaad + Tenant)

## Goal

Run **two iOS simulators** so the user can manually exercise flows:

| Simulator | Role | Phone (prefilled) | OTP |
|---|---|---|---|
| A | Vaad | `+972547760683` | `111111` |
| B | Tenant | `+972548899656` | `111111` |

Login fields are prefilled via `--dart-define=TEST_PHONE` / `TEST_OTP`. The user only taps **send code** → enters/uses OTP (already prefilled) → continue.

## When invoked

1. Ensure the web API is up (`http://localhost:3000` by default):
   - If nothing listens on `:3000`, start `npm run dev:web` from the repo root (background).
2. Run the boot script (requires `all` permissions — Simulator + Flutter):

```bash
chmod +x .cursor/skills/dual-sim-manual-test/scripts/boot-dual-sims.sh
.cursor/skills/dual-sim-manual-test/scripts/boot-dual-sims.sh
```

3. Tell the user:
   - Which phone is on which simulator
   - OTP is `111111` for both
   - Logs: `/tmp/buildingo-vaad-sim.log` and `/tmp/buildingo-tenant-sim.log`
   - They can tap through login themselves and compare Vaad vs tenant UI

Do **not** reinstall on a physical iPhone unless the user explicitly asks.

## Optional env overrides

```bash
API_BASE_URL=http://localhost:3000 \
VAAD_PHONE=+972547760683 \
TENANT_PHONE=+972548899656 \
VAAD_DEVICE_NAME="iPhone 17 Pro" \
TENANT_DEVICE_NAME="iPhone 17 Pro Max" \
.cursor/skills/dual-sim-manual-test/scripts/boot-dual-sims.sh
```

## Stop

```bash
kill $(pgrep -f 'flutter run' | tr '\n' ' ') 2>/dev/null || true
```

Or use the PIDs printed by the script.

## Notes

- Firebase Console test numbers; no real SMS.
- Physical LAN testing: set `API_BASE_URL=http://<mac-lan-ip>:3000`.
- Script picks the first two available iPhone simulators unless `VAAD_DEVICE_NAME` / `TENANT_DEVICE_NAME` are set.
