#!/bin/bash
# Sync Antigravity agent working status with Dave desktop pet
STATUS_DIR="$HOME/.dave"
STATUS_FILE="$STATUS_DIR/status.json"
mkdir -p "$STATUS_DIR"

MODE="${1:-idle}"
TASK="${2:-}"
TEXT="${3:-}"

# Discover latest active conversation ID if available
DB_PATH="$HOME/.gemini/antigravity/conversation_summaries.db"
CID=""
if [ -f "$DB_PATH" ] && command -v sqlite3 >/dev/null 2>&1; then
    CID=$(sqlite3 "$DB_PATH" "SELECT conversation_id FROM conversation_summaries ORDER BY (CASE WHEN not_fully_idle = 1 OR status = 'CASCADE_RUN_STATUS_RUNNING' THEN 0 ELSE 1 END), last_modified_time DESC LIMIT 1;" 2>/dev/null || true)
fi

STATE="idle"
IS_BUSY=false

case "$MODE" in
    busy|working|coding)
        IS_BUSY=true
        STATE="coding"
        STATUS_TEXT="${TEXT:-正在疯狂码字与执行指令...}"
        ;;
    debugging|thinking)
        IS_BUSY=true
        STATE="debugging"
        STATUS_TEXT="${TEXT:-正在抓虫思考与分析规划...}"
        ;;
    celebrating|done|finished)
        IS_BUSY=false
        STATE="celebrating"
        STATUS_TEXT="${TEXT:-任务搞定啦！🎉}"
        ;;
    coffee)
        IS_BUSY=false
        STATE="coffee"
        STATUS_TEXT="${TEXT:-品味咖啡中... ☕️}"
        ;;
    sleeping)
        IS_BUSY=false
        STATE="sleeping"
        STATUS_TEXT="${TEXT:-午休小憩中... 💤}"
        ;;
    *)
        IS_BUSY=false
        STATE="idle"
        STATUS_TEXT="${TEXT:-空闲待机中}"
        ;;
esac

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat <<EOF > "$STATUS_FILE"
{
  "isBusy": $IS_BUSY,
  "state": "$STATE",
  "task": "$TASK",
  "statusText": "$STATUS_TEXT",
  "conversationId": "$CID",
  "updatedAt": "$TIMESTAMP"
}
EOF

echo "✅ Synced Dave status: isBusy=$IS_BUSY, state='$STATE', task='$TASK', text='$STATUS_TEXT'"
