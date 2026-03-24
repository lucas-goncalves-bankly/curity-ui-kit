#!/usr/bin/env bash

#
# Remote deployment script for Curity UI Kit artifacts.
# Builds are produced locally and synced to a remote Identity Server host via SSH/rsync.
#
# Usage examples:
#   ./deploy-remote.sh --host idsvr.example.com --user deploy
#   ./deploy-remote.sh --host idsvr.example.com --user deploy --port 2222 --identity-file ~/.ssh/id_rsa
#   ./deploy-remote.sh --host idsvr.example.com --user deploy --remote-share-dir /opt/idsvr/usr/share --restart-cmd "sudo systemctl restart idsvr"
#   ./deploy-remote.sh --host idsvr.example.com --user deploy --dry-run
#
# Optional env vars:
#   REMOTE_HOST, REMOTE_USER, REMOTE_PORT, REMOTE_SHARE_DIR, SSH_IDENTITY_FILE,
#   DRY_RUN (1/0), DELETE_EXTRA (1/0), RESTART_CMD

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_SHARE_DIR="${REMOTE_SHARE_DIR:-/opt/idsvr/usr/share}"
SSH_IDENTITY_FILE="${SSH_IDENTITY_FILE:-}"
DRY_RUN="${DRY_RUN:-0}"
DELETE_EXTRA="${DELETE_EXTRA:-0}"
RESTART_CMD="${RESTART_CMD:-}"

print_help() {
  cat <<'EOF'
Deploy local build artifacts to a remote Curity Identity Server over SSH.

Required:
  --host <hostname>              Remote host
  --user <username>              SSH user

Optional:
  --port <port>                  SSH port (default: 22)
  --remote-share-dir <path>      Remote usr/share dir (default: /opt/idsvr/usr/share)
  --identity-file <path>         SSH private key file
  --restart-cmd <command>        Command to run remotely after sync (e.g. "sudo systemctl restart idsvr")
  --dry-run                      Show rsync actions without changing remote files
  --delete                       Delete remote files not present locally within synced folders
  --help                         Show this help

The script syncs these local folders to remote:
  src/identity-server/build/webroot   -> <remote>/webroot
  src/identity-server/build/templates -> <remote>/templates
  src/identity-server/build/messages  -> <remote>/messages
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      REMOTE_HOST="$2"
      shift 2
      ;;
    --user)
      REMOTE_USER="$2"
      shift 2
      ;;
    --port)
      REMOTE_PORT="$2"
      shift 2
      ;;
    --remote-share-dir)
      REMOTE_SHARE_DIR="$2"
      shift 2
      ;;
    --identity-file)
      SSH_IDENTITY_FILE="$2"
      shift 2
      ;;
    --restart-cmd)
      RESTART_CMD="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --delete)
      DELETE_EXTRA=1
      shift
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      print_help
      exit 1
      ;;
  esac
done

if [[ -z "$REMOTE_HOST" || -z "$REMOTE_USER" ]]; then
  echo -e "${RED}Error: --host and --user are required.${NC}"
  print_help
  exit 1
fi

LOCAL_WEBROOT="src/identity-server/build/webroot"
LOCAL_TEMPLATES="src/identity-server/build/templates"
LOCAL_MESSAGES="src/identity-server/build/messages"

for p in "$LOCAL_WEBROOT" "$LOCAL_TEMPLATES" "$LOCAL_MESSAGES"; do
  if [[ ! -d "$p" ]]; then
    echo -e "${RED}Error: Missing local build folder: $p${NC}"
    echo "Run: npm run build:identity-server"
    exit 1
  fi
done

SSH_OPTS=(-p "$REMOTE_PORT" -o BatchMode=yes -o StrictHostKeyChecking=accept-new)
if [[ -n "$SSH_IDENTITY_FILE" ]]; then
  SSH_OPTS+=(-i "$SSH_IDENTITY_FILE")
fi

RSYNC_OPTS=(-az --progress)
if [[ "$DRY_RUN" == "1" ]]; then
  RSYNC_OPTS+=(--dry-run)
fi
if [[ "$DELETE_EXTRA" == "1" ]]; then
  RSYNC_OPTS+=(--delete)
fi

REMOTE="$REMOTE_USER@$REMOTE_HOST"

echo -e "${GREEN}Remote deploy target:${NC} $REMOTE"
echo -e "${GREEN}Remote usr/share:${NC} $REMOTE_SHARE_DIR"
if [[ "$DRY_RUN" == "1" ]]; then
  echo -e "${YELLOW}Dry run mode enabled.${NC}"
fi
if [[ "$DELETE_EXTRA" == "1" ]]; then
  echo -e "${YELLOW}Delete mode enabled (--delete).${NC}"
fi

ssh "${SSH_OPTS[@]}" "$REMOTE" "mkdir -p '$REMOTE_SHARE_DIR/webroot' '$REMOTE_SHARE_DIR/templates' '$REMOTE_SHARE_DIR/messages'"

sync_dir() {
  local src="$1"
  local dst="$2"
  local label="$3"

  echo -e "${YELLOW}Syncing $label...${NC}"
  rsync "${RSYNC_OPTS[@]}" -e "ssh ${SSH_OPTS[*]}" "$src/" "$REMOTE:$dst/"
  echo -e "${GREEN}✓ $label synced${NC}"
}

sync_dir "$LOCAL_WEBROOT" "$REMOTE_SHARE_DIR/webroot" "Identity Server webroot"
sync_dir "$LOCAL_TEMPLATES" "$REMOTE_SHARE_DIR/templates" "Identity Server templates"
sync_dir "$LOCAL_MESSAGES" "$REMOTE_SHARE_DIR/messages" "Identity Server messages"

if [[ -n "$RESTART_CMD" && "$DRY_RUN" != "1" ]]; then
  echo -e "${YELLOW}Running remote restart command...${NC}"
  ssh "${SSH_OPTS[@]}" "$REMOTE" "$RESTART_CMD"
  echo -e "${GREEN}✓ Remote restart command executed${NC}"
fi

echo -e "${GREEN}Remote deployment completed successfully.${NC}"
