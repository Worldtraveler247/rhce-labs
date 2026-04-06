#!/bin/bash
# daily-check.sh — RHCE Daily Practice Reminder & Streak Tracker

RHCE_DIR="$HOME/Documents/rhce"
LOG_FILE="$RHCE_DIR/notes/progress-log.md"
STREAK_FILE="$RHCE_DIR/notes/.streak"
TODAY=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%A)

# Day rotation for CLI drills (7-day cycle)
DAY_NUM=$(( ($(date +%u) - 1) % 7 + 1 ))
DRILLS=("File & directory navigation" "User & group management" "Process management" "Networking" "Services (systemd)" "File permissions" "Package management")
TODAY_DRILL="${DRILLS[$((DAY_NUM - 1))]}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        RHCE Daily Practice — Jason       ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Date: $TODAY ($DAY_OF_WEEK)"
echo "║  Today's CLI drill: $TODAY_DRILL"
echo "╠══════════════════════════════════════════╣"
echo "║  📋 TASKS:"
echo "║  1. Run today's CLI drill (5 min)"
echo "║  2. Open ansible-labs/ — do one lab (20 min)"
echo "║  3. Log your progress in notes/progress-log.md"
echo "╚══════════════════════════════════════════╝"
echo ""

# Streak tracking
if [ -f "$STREAK_FILE" ]; then
    LAST_DATE=$(cat "$STREAK_FILE" | grep "last:" | awk '{print $2}')
    STREAK=$(cat "$STREAK_FILE" | grep "streak:" | awk '{print $2}')
    YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null)
    
    if [ "$LAST_DATE" == "$TODAY" ]; then
        echo "✅ Already logged today. Streak: $STREAK days"
    elif [ "$LAST_DATE" == "$YESTERDAY" ]; then
        STREAK=$((STREAK + 1))
        printf "last: %s\nstreak: %s\n" "$TODAY" "$STREAK" > "$STREAK_FILE"
        echo "🔥 Streak: $STREAK days! Keep going."
    else
        printf "last: %s\nstreak: 1\n" "$TODAY" > "$STREAK_FILE"
        echo "📅 Streak reset. Starting fresh — day 1."
    fi
else
    mkdir -p "$RHCE_DIR/notes"
    printf "last: %s\nstreak: 1\n" "$TODAY" > "$STREAK_FILE"
    echo "🚀 Starting your streak — day 1!"
fi

echo ""
echo "📂 Open your lab: $RHCE_DIR/ansible-labs/"
echo "📝 Log progress: $LOG_FILE"
echo ""
