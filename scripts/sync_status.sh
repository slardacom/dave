#!/bin/bash
# Sync Antigravity agent working status with Dave desktop pet
STATUS_DIR="$HOME/.dave"
STATUS_FILE="$STATUS_DIR/status.json"
mkdir -p "$STATUS_DIR"

MODE="${1:-idle}"
TASK="${2:-}"
TEXT="${3:-}"

if [ "$MODE" = "busy" ] || [ "$MODE" = "working" ]; then
    IS_BUSY=true
    STATUS_TEXT="${TEXT:-正在全力工作中...}"
else
    IS_BUSY=false
    STATUS_TEXT="${TEXT:-空闲待机中}"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat <<EOF > "$STATUS_FILE"
{
  "isBusy": $IS_BUSY,
  "task": "$TASK",
  "statusText": "$STATUS_TEXT",
  "conversationId": "eba2deb0-6e33-43c0-8920-1896215f35b2",
  "updatedAt": "$TIMESTAMP"
}
EOF

echo "✅ Synced Dave status: isBusy=$IS_BUSY, task='$TASK', text='$STATUS_TEXT'"
