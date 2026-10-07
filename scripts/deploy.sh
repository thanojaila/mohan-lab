#!/usr/bin/env bash
#
# deploy.sh - update the LIVE website. Runs ON THE SERVER.
#
#   ./scripts/deploy.sh             deploy the latest code on the main branch
#   ./scripts/deploy.sh <commit>    deploy one specific commit (emergency "go back")
#
# If the new version fails to build or fails to start, the previous
# version is restored automatically and this script exits with an error.
#
# A history of deploys is kept in ~/mohanlab-deploys.log
#
# NOTE: everything is wrapped in functions and the script ends with
# "main; exit" on a single line, so it is safe for this file to be
# replaced by git while it is running.

set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/mohan-lab}"
SERVICE="${SERVICE:-mohanlab}"
APP_PORT="${APP_PORT:-3000}"
LOG_FILE="$HOME/mohanlab-deploys.log"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

wait_healthy() {
  for _ in $(seq 1 30); do
    if curl -fsS -o /dev/null "http://127.0.0.1:${APP_PORT}/"; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# Put the given commit live: checkout, install, build, restart, health-check.
release() {
  git reset --hard --quiet "$1"            || return 1
  npm ci --no-audit --no-fund              || return 1
  npm run build                            || return 1
  sudo systemctl restart "$SERVICE"        || return 1
  wait_healthy                             || return 1
}

main() {
  cd "$APP_DIR"
  git fetch --quiet origin

  local target="${1:-origin/main}"
  local previous new
  previous="$(git rev-parse HEAD)"
  new="$(git rev-parse "${target}^{commit}")"

  if [ "$previous" = "$new" ] && [ -z "${FORCE:-}" ]; then
    say "Already running ${new:0:7} - rebuilding anyway to be safe"
  fi

  say "Deploying ${new:0:7} (currently live: ${previous:0:7})"
  if release "$new"; then
    echo "$(date -Is) OK      ${new}" >> "$LOG_FILE"
    say "Done. The new version is live."
    return 0
  fi

  say "FAILED - restoring the previous version ${previous:0:7}"
  echo "$(date -Is) FAILED  ${new} (restoring ${previous})" >> "$LOG_FILE"
  if release "$previous"; then
    echo "$(date -Is) RESTORED ${previous}" >> "$LOG_FILE"
    say "The previous version is live again. The site was not changed."
  else
    echo "$(date -Is) RESTORE-FAILED ${previous}" >> "$LOG_FILE"
    say "Restoring also failed. Check: sudo journalctl -u ${SERVICE} -n 80"
  fi
  return 1
}

main "$@"; exit $?
