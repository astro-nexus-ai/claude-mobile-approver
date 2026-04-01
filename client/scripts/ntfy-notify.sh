#!/bin/bash
# Claude Code remote approval script
# Shows detailed tool information on approval page

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/settings.json"

if [ -f "$CONFIG_FILE" ]; then
    NTFY_SERVER=$(jq -r '.ntfy_server // "http://localhost:2586"' "$CONFIG_FILE")
    APPROVAL_SERVER=$(jq -r '.approval_server // "http://localhost:2587"' "$CONFIG_FILE")
    NTFY_USER=$(jq -r '.ntfy_user // "claude"' "$CONFIG_FILE")
    NTFY_PASS=$(jq -r '.ntfy_pass // ""' "$CONFIG_FILE")
    NTFY_TOPIC=$(jq -r '.ntfy_topic // "claude-approve"' "$CONFIG_FILE")
else
    # Default values if config not found
    NTFY_SERVER="http://localhost:2586"
    APPROVAL_SERVER="http://localhost:2587"
    NTFY_USER="claude"
    NTFY_PASS=""
    NTFY_TOPIC="claude-approve"
fi

# Generate unique session ID
SESSION_ID="sess-$(date +%s)-$$"

# Read hook input from stdin
INPUT=$(cat)

# Debug: log full input
DEBUG_LOG="$HOME/.claude/scripts/ntfy-debug.log"
echo "[$(date)] Full input: $INPUT" >> "$DEBUG_LOG"

# Extract tool info
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Extract permission suggestions (the options shown in terminal)
SUGGESTIONS=$(echo "$INPUT" | jq -c '.permission_suggestions // []')

# Build description based on tool type
case "$TOOL_NAME" in
    Bash)
        CMD=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
        DESC="Execute shell command"
        ;;
    Edit)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        DESC="Edit file: $FILE"
        ;;
    Write)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        DESC="Write file: $FILE"
        ;;
    Read)
        FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        DESC="Read file: $FILE"
        ;;
    Glob)
        PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // ""')
        DESC="Find files: $PATTERN"
        ;;
    Grep)
        PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // ""')
        DESC="Search: $PATTERN"
        ;;
    *)
        DESC="Tool: $TOOL_NAME"
        ;;
esac

# Log
echo "[$(date)] Hook: $SESSION_ID, Tool: $TOOL_NAME, Desc: $DESC" >> "$DEBUG_LOG"

# Create approval request with full details including suggestions
curl -s -X POST "$APPROVAL_SERVER/request/$SESSION_ID" \
    -H "Content-Type: application/json" \
    -d "{
        \"tool\": \"$TOOL_NAME\",
        \"command\": $(echo "$TOOL_INPUT" | jq -c .),
        \"input\": $(echo "$TOOL_INPUT" | jq -c .),
        \"description\": \"$DESC\",
        \"suggestions\": $SUGGESTIONS
    }" > /dev/null 2>&1

# Build approval URL
APPROVAL_URL="$APPROVAL_SERVER/$SESSION_ID"

# Send notification
curl -s -u "$NTFY_USER:$NTFY_PASS" \
    -H "Title: 🤖 $DESC" \
    -H "Priority: high" \
    -H "Tags: warning,claude" \
    -H "Click: $APPROVAL_URL" \
    -H "Actions: view, ✅ View & Approve, $APPROVAL_URL, clear=true" \
    -d "Tool: $TOOL_NAME" \
    "$NTFY_SERVER/$NTFY_TOPIC" >> "$DEBUG_LOG" 2>&1

echo "" >> "$DEBUG_LOG"

# Poll for approval (max 5 minutes)
MAX_WAIT=300
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    STATUS=$(curl -s "$APPROVAL_SERVER/check/$SESSION_ID" 2>/dev/null | jq -r '.status // "pending"')

    case "$STATUS" in
        approved)
            echo "[$(date)] ✅ Approved via mobile" >> "$DEBUG_LOG"
            # Get selected suggestion if any
            SELECTED_SUGGESTION=$(curl -s "$APPROVAL_SERVER/check/$SESSION_ID" 2>/dev/null | jq -r '.selected_suggestion // empty')

            curl -s -X POST "$APPROVAL_SERVER/cleanup/$SESSION_ID" > /dev/null 2>&1

            # Build response with suggestion if selected
            if [ -n "$SELECTED_SUGGESTION" ]; then
                SUGGESTION_DATA=$(curl -s "$APPROVAL_SERVER/check/$SESSION_ID" 2>/dev/null | jq -c '.selected_suggestion_data // {}')
                # Return the selected suggestion to Claude Code
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
            ;;
        denied)
            echo "[$(date)] ❌ Denied via mobile" >> "$DEBUG_LOG"
            curl -s -X POST "$APPROVAL_SERVER/cleanup/$SESSION_ID" > /dev/null 2>&1
            jq -n '{
                hookSpecificOutput: {
                    hookEventName: "PermissionRequest",
                    decision: { behavior: "deny", message: "Denied via mobile" }
                }
            }'
            exit 0
            ;;
    esac

    sleep 2
    WAITED=$((WAITED + 2))
done

# Timeout
echo "[$(date)] ⏱️ Timeout" >> "$DEBUG_LOG"
exit 0
