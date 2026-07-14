#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f ".env.zego.json" ]]; then
  echo "Missing .env.zego.json. Create it with ZEGO_APP_ID and ZEGO_APP_SIGN first."
  exit 1
fi

flutter run --dart-define-from-file=.env.zego.json "$@"
