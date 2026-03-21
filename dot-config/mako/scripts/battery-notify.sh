#!/usr/bin/env bash
# =============================================================================
# Battery Notification Script for Mako
# =============================================================================
# Monitors battery and sends notifications at critical levels
# =============================================================================

# Thresholds
CRITICAL_LEVEL=15
LOW_LEVEL=30
FULL_LEVEL=95

# Get battery info
get_battery_info() {
    upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null
}

get_battery_percentage() {
    get_battery_info | grep "percentage:" | awk '{print $2}' | tr -d '%'
}

get_battery_state() {
    get_battery_info | grep "state:" | awk '{print $2}'
}

get_battery_time() {
    local time_str=$(get_battery_info | grep -E "time to (empty|full):" | head -1 | awk -F': ' '{print $2}')
    if [[ -n "$time_str" && "$time_str" != "pending" ]]; then
        echo "$time_str"
    else
        echo "calculating..."
    fi
}

# Send notification
send_notification() {
    local urgency="$1"
    local summary="$2"
    local body="$3"
    notify-send -u "$urgency" "$summary" "$body"
}

# Main monitoring function
check_battery() {
    local percentage=$(get_battery_percentage)
    local state=$(get_battery_state)
    
    # Handle no battery (desktop)
    if [[ -z "$percentage" ]]; then
        return
    fi
    
    case "$state" in
        "charging")
            if [[ $percentage -ge $FULL_LEVEL ]]; then
                send_notification "low" " Battery Full" "Battery is fully charged at ${percentage}%"
            fi
            ;;
        "discharging")
            if [[ $percentage -le $CRITICAL_LEVEL ]]; then
                send_notification "critical" " Critical Battery" "Only ${percentage}% remaining - Plug in now!"
            elif [[ $percentage -le $LOW_LEVEL ]]; then
                # notify-send accepts: low, normal, critical — 'high' is invalid
                send_notification "normal" " Low Battery" "${percentage}% remaining - ${get_battery_time} until empty"
            fi
            ;;
    esac
}

# Show current status
show_status() {
    local percentage=$(get_battery_percentage)
    local state=$(get_battery_state)
    local time=$(get_battery_time)

    if [[ -z "$percentage" ]]; then
        echo "No battery detected"
        return
    fi

    local icon=""
    if [[ "$state" == "charging" ]]; then
        icon=""
    elif [[ $percentage -le $CRITICAL_LEVEL ]]; then
        icon=""
    elif [[ $percentage -le $LOW_LEVEL ]]; then
        icon=""
    fi

    echo "$icon Battery: ${percentage}% | $state | $time"
}

# CLI interface
case "${1:-check}" in
    "check")
        check_battery
        ;;
    "status"|"show")
        show_status
        ;;
    "notify")
        check_battery
        send_notification "normal" "$(show_status)" "Battery status update"
        ;;
    *)
        echo "Usage: $0 {check|status|notify}"
        exit 1
        ;;
esac
