#!/usr/bin/env bash
# Boot two iOS simulators for side-by-side Vaad + Tenant manual testing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
# scripts → dual-sim-manual-test → skills → .cursor → repo root
MOBILE="$ROOT/apps/mobile"
API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"

VAAD_PHONE="${VAAD_PHONE:-+972547760683}"
TENANT_PHONE="${TENANT_PHONE:-+972548899656}"
TEST_OTP="${TEST_OTP:-111111}"

VAAD_DEVICE_NAME="${VAAD_DEVICE_NAME:-}"
TENANT_DEVICE_NAME="${TENANT_DEVICE_NAME:-}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

pick_udid() {
  local want_name="$1"
  local fallback_index="$2"
  if [[ -n "$want_name" ]]; then
    xcrun simctl list devices available -j \
      | python3 -c "
import json,sys
want=sys.argv[1]
data=json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime: continue
    for d in devices:
        if d.get('isAvailable') and d.get('name')==want:
            print(d['udid']); raise SystemExit
" "$want_name" && return
  fi
  xcrun simctl list devices available -j \
    | python3 -c "
import json,sys
idx=int(sys.argv[1])
data=json.load(sys.stdin)
iphones=[]
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime: continue
    for d in devices:
        name=d.get('name','')
        if d.get('isAvailable') and name.startswith('iPhone'):
            iphones.append((name, d['udid']))
# Prefer distinct models; keep stable order
seen=set(); uniq=[]
for name,udid in iphones:
    if name in seen: continue
    seen.add(name); uniq.append((name,udid))
if len(uniq) <= idx:
    raise SystemExit(f'Need at least {idx+1} available iPhone simulators, found {len(uniq)}')
print(uniq[idx][1])
print(uniq[idx][0], file=sys.stderr)
" "$fallback_index"
}

boot_sim() {
  local udid="$1"
  local state
  state="$(xcrun simctl list devices | grep "$udid" | head -1 || true)"
  if echo "$state" | grep -q '(Booted)'; then
    log "already booted: $udid"
  else
    log "booting $udid"
    xcrun simctl boot "$udid" || true
  fi
}

[[ -d "$MOBILE" ]] || die "mobile app not found at $MOBILE"

log "resolving simulators…"
VAAD_UDID="$(pick_udid "$VAAD_DEVICE_NAME" 0 | tail -1)"
TENANT_UDID="$(pick_udid "$TENANT_DEVICE_NAME" 1 | tail -1)"
[[ "$VAAD_UDID" != "$TENANT_UDID" ]] || die "Vaad and Tenant resolved to the same simulator; set VAAD_DEVICE_NAME / TENANT_DEVICE_NAME"

boot_sim "$VAAD_UDID"
boot_sim "$TENANT_UDID"
open -a Simulator
# Show both device windows
xcrun simctl openurl "$VAAD_UDID" about:blank >/dev/null 2>&1 || true
xcrun simctl openurl "$TENANT_UDID" about:blank >/dev/null 2>&1 || true

log "Vaad simulator:   $VAAD_UDID  phone=$VAAD_PHONE"
log "Tenant simulator: $TENANT_UDID  phone=$TENANT_PHONE"
log "OTP for both Firebase test numbers: $TEST_OTP"
log "API_BASE_URL=$API_BASE_URL"

cd "$MOBILE"

COMMON_DEFINES=(
  "--dart-define=API_BASE_URL=$API_BASE_URL"
  "--dart-define=TEST_OTP=$TEST_OTP"
)
if [[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  COMMON_DEFINES+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY")
fi

log "launching Flutter on Vaad simulator (detached)…"
nohup flutter run -d "$VAAD_UDID" \
  "${COMMON_DEFINES[@]}" \
  --dart-define="TEST_PHONE=$VAAD_PHONE" \
  > /tmp/buildingo-vaad-sim.log 2>&1 &
VAAD_PID=$!
disown "$VAAD_PID" 2>/dev/null || true

# Give the first flutter run time to take the pub/tooling lock
sleep 8

log "launching Flutter on Tenant simulator (detached)…"
nohup flutter run -d "$TENANT_UDID" \
  "${COMMON_DEFINES[@]}" \
  --dart-define="TEST_PHONE=$TENANT_PHONE" \
  > /tmp/buildingo-tenant-sim.log 2>&1 &
TENANT_PID=$!
disown "$TENANT_PID" 2>/dev/null || true

cat <<EOF

Dual-sim manual test is starting.

  Vaad   → phone prefilled: $VAAD_PHONE   (tap send code → OTP $TEST_OTP)
  Tenant → phone prefilled: $TENANT_PHONE (tap send code → OTP $TEST_OTP)

  Logs:
    /tmp/buildingo-vaad-sim.log
    /tmp/buildingo-tenant-sim.log

  PIDs: vaad=$VAAD_PID tenant=$TENANT_PID
  Stop with: kill $VAAD_PID $TENANT_PID

Ensure apps/web is running (npm run dev:web) so API_BASE_URL works.
EOF
