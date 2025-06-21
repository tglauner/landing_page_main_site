#!/usr/bin/env bash
# send_daily_analytics.sh
# Collect yesterday’s analytics and tracking data, then email them to $TG_NOTIFICATION_EMAIL.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────
# Required env var
# ──────────────────────────────────────────────────────────────────────────
: "${TG_NOTIFICATION_EMAIL:?TG_NOTIFICATION_EMAIL not set}"

# ──────────────────────────────────────────────────────────────────────────
# Paths (adjust if yours differ)
# ──────────────────────────────────────────────────────────────────────────
BASE_DIR="/var/www/html"

COURSE1="$BASE_DIR/mastering_interest_rate_derivatives/analytics_data.json"
COURSE2="$BASE_DIR/mastering_mbs_and_abs/analytics_data.json"
TRACK_FILE="$BASE_DIR/tracking/opens.csv"

# ──────────────────────────────────────────────────────────────────────────
# Date filter (server time)
# ──────────────────────────────────────────────────────────────────────────
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

# ──────────────────────────────────────────────────────────────────────────
# Build report
# ──────────────────────────────────────────────────────────────────────────
TMP_REPORT=$(mktemp)

{
  echo "tglauner.com – daily analytics for $YESTERDAY"
  echo "------------------------------------------------------------"
  echo

  for FILE in "$COURSE1" "$COURSE2"; do
    [[ -f $FILE ]] || { echo "Missing: $FILE"; echo; continue; }
    echo "== $(basename "$(dirname "$FILE")") =="
    jq -c --arg d "$YESTERDAY" 'select(.server_timestamp|startswith($d))' "$FILE"
    echo
  done

  echo "== tracking/opens.csv =="
  [[ -f $TRACK_FILE ]] && grep "^Pixel $YESTERDAY" "$TRACK_FILE" || echo "Missing: $TRACK_FILE"
} > "$TMP_REPORT"

# ──────────────────────────────────────────────────────────────────────────
# Send mail (requires a local MTA providing `mail`)
# ──────────────────────────────────────────────────────────────────────────
mail -s "tglauner.com analytics – $YESTERDAY" "$TG_NOTIFICATION_EMAIL" < "$TMP_REPORT"

rm -f "$TMP_REPORT"
