#!/bin/bash
# Universal Claude Mobile Approver hook script
# Supports both Claude Code (PermissionRequest) and Kiro CLI (preToolUse)

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/settings.json"

if [ -f "$CONFIG_FILE" ]; then
    NTFY_SERVER=$(jq -r '.ntfy_server // "http://localhost:2586"' "$CONFIG_FILE")
    APPROVAL_SERVER=$(jq -r '.approval_server // "http://localhost:2587"' "$CONFIG_FILE")
    NTFY_USER=$(jq -r '.ntfy_user // "claude"' "$CONFIG_FILE")
    NTFY_PASS=$(jq -r '.ntfy_pass // ""' "$CONFIG_FILE")
    NTFY_TOPIC_CLAUDE=$(jq -r '.ntfy_topic // "claude-approve"' "$CONFIG_FILE")
    NTFY_TOPIC_KIRO=$(jq -r '.ntfy_topic_kiro // "kiro-approve"' "$CONFIG_FILE")
else
    NTFY_SERVER="http://localhost:2586"
    APPROVAL_SERVER="http://localhost:2587"
    NTFY_USER="claude"
    NTFY_PASS=""
    NTFY_TOPIC_CLAUDE="claude-approve"
    NTFY_TOPIC_KIRO="kiro-approve"
fi

SESSION_ID="sess-$(date +%s)-$$"
DEBUG_LOG="$HOME/.claude/scripts/ntfy-debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")"

# Read hook input from stdin
INPUT=$(cat)
echo "[$(date)] Full input: $INPUT" >> "$DEBUG_LOG"

# Detect caller: Kiro CLI sends hook_event_name, Claude Code sends tool_name at top level
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

if [ -n "$HOOK_EVENT" ]; then
    # === Kiro CLI mode ===
    MODE="kiro"
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
    TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')
    SUGGESTIONS="[]"

    # Map Kiro tool names to display names
    case "$TOOL_NAME" in
        execute_bash|shell)
            DISPLAY_TOOL="Bash"
            CMD=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
            DESC="Execute: $(echo "$CMD" | cut -c1-50)"
            ;;
        fs_write|write)
            DISPLAY_TOOL="Write"
            FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')
            DESC="Write file: $FILE"
            ;;
        fs_read|read)
            DISPLAY_TOOL="Read"
            FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')
            DESC="Read file: $FILE"
            ;;
        use_aws|aws)
            DISPLAY_TOOL="AWS"
            DESC="AWS CLI call"
            ;;
        *)
            DISPLAY_TOOL="$TOOL_NAME"
            DESC="Tool: $TOOL_NAME"
            ;;
    esac
else
    # === Claude Code mode ===
    MODE="claude"
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
    TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')
    SUGGESTIONS=$(echo "$INPUT" | jq -c '.permission_suggestions // []')
    DISPLAY_TOOL="$TOOL_NAME"

    case "$TOOL_NAME" in
        Bash)
            CMD=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
            DESC="Execute: $(echo "$CMD" | cut -c1-50)"
            ;;
        Edit)  DESC="Edit file: $(echo "$TOOL_INPUT" | jq -r '.file_path // ""')" ;;
        Write) DESC="Write file: $(echo "$TOOL_INPUT" | jq -r '.file_path // ""')" ;;
        Read)  DESC="Read file: $(echo "$TOOL_INPUT" | jq -r '.file_path // ""')" ;;
        Glob)  DESC="Find files: $(echo "$TOOL_INPUT" | jq -r '.pattern // ""')" ;;
        Grep)  DESC="Search: $(echo "$TOOL_INPUT" | jq -r '.pattern // ""')" ;;
        *)     DESC="Tool: $TOOL_NAME" ;;
    esac
fi

# Select topic by mode
if [ "$MODE" = "kiro" ]; then
    NTFY_TOPIC="$NTFY_TOPIC_KIRO"
else
    NTFY_TOPIC="$NTFY_TOPIC_CLAUDE"
fi

echo "[$(date)] Mode: $MODE, Topic: $NTFY_TOPIC, Hook: $SESSION_ID, Tool: $DISPLAY_TOOL, Desc: $DESC" >> "$DEBUG_LOG"

# Create approval request
curl -s -X POST "$APPROVAL_SERVER/request/$SESSION_ID" \
    -H "Content-Type: application/json" \
    -d "{
        \"tool\": \"$DISPLAY_TOOL\",
        \"command\": $(echo "$TOOL_INPUT" | jq -c .),
        \"input\": $(echo "$TOOL_INPUT" | jq -c .),
        \"description\": \"$DESC\",
        \"suggestions\": $SUGGESTIONS,
        \"source\": \"$MODE\"
    }" > /dev/null 2>&1

APPROVAL_URL="$APPROVAL_SERVER/$SESSION_ID"

# Send notification
curl -s -u "$NTFY_USER:$NTFY_PASS" \
    -H "Title: 🤖 $DESC" \
    -H "Priority: high" \
    -H "Tags: warning,claude" \
    -H "Click: $APPROVAL_URL" \
    -H "Actions: view, ✅ View & Approve, $APPROVAL_URL, clear=true" \
    -d "Tool: $DISPLAY_TOOL" \
    "$NTFY_SERVER/$NTFY_TOPIC" >> "$DEBUG_LOG" 2>&1

echo "" >> "$DEBUG_LOG"

# Poll for approval (max 5 minutes)
MAX_WAIT=300
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    RESPONSE=$(curl -s "$APPROVAL_SERVER/check/$SESSION_ID" 2>/dev/null)
    STATUS=$(echo "$RESPONSE" | jq -r '.status // "pending"')

    case "$STATUS" in
        approved)
            echo "[$(date)] ✅ Approved via mobile ($MODE)" >> "$DEBUG_LOG"
            curl -s -X POST "$APPROVAL_SERVER/cleanup/$SESSION_ID" > /dev/null 2>&1

            if [ "$MODE" = "kiro" ]; then
                # Kiro CLI: exit 0 = allow tool execution
                exit 0
            else
                # Claude Code: return JSON decision
                SELECTED_SUGGESTION=$(echo "$RESPONSE" | jq -r '.selected_suggestion // empty')
                if [ -n "$SELECTED_SUGGESTION" ]; then
                    SUGGESTION_DATA=$(echo "$RESPONSE" | jq -c '.selected_suggestion_data // {}')
                    jq -n --argjson suggestion "$SUGGESTION_DATA" '{
                        hookSpecificOutput: {
                            hookEventName: "PermissionRequest",
                            decision: $suggestion
                        }
                    }'
                else
                    jq -n '{
                        hookSpecificOutput: {
                            hookEventName: "PermissionRequest",
                            decision: { behavior: "allow" }
                        }
                    }'
                fi
                exit 0
            fi
            ;;
        denied)
            echo "[$(date)] ❌ Denied via mobile ($MODE)" >> "$DEBUG_LOG"
            curl -s -X POST "$APPROVAL_SERVER/cleanup/$SESSION_ID" > /dev/null 2>&1

            if [ "$MODE" = "kiro" ]; then
                # Kiro CLI: exit 2 = block, stderr returned to LLM
                echo "Denied via mobile approval" >&2
                exit 2
            else
                # Claude Code: return JSON decision
                jq -n '{
                    hookSpecificOutput: {
                        hookEventName: "PermissionRequest",
                        decision: { behavior: "deny", message: "Denied via mobile" }
                    }
                }'
                exit 0
            fi
            ;;
    esac

    sleep 2
    WAITED=$((WAITED + 2))
done

# Timeout
echo "[$(date)] ⏱️ Timeout ($MODE)" >> "$DEBUG_LOG"
if [ "$MODE" = "kiro" ]; then
    exit 0
else
    exit 0
fi
