#!/bin/bash

get_all_devices() {
    bluetoothctl devices 2>/dev/null | awk '{print $2"|"$3}'
}

get_device_info() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null
}

is_paired() {
    local mac="$1"
    get_device_info "$mac" | grep -q "Paired: yes"
}

is_connected() {
    local mac="$1"
    get_device_info "$mac" | grep -q "Connected: yes"
}

is_available() {
    local mac="$1"
    get_device_info "$mac" | grep -q "Connected: no"
}

get_battery() {
    local mac="$1"
    get_device_info "$mac" | awk -F': ' '/Battery Percentage/ {print $2}' | tr -d '()'
}

get_power_state() {
    bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}'
}

case "${1:-gui}" in
    gui)
        if ! command -v bluetoothctl &> /dev/null || ! command -v fuzzel &> /dev/null; then
            notify-send "Bluetooth" "Error: bluetoothctl or fuzzel not found"
            exit 1
        fi

        POWER=$(get_power_state)
        if [ "$POWER" = "no" ]; then
            MENU="  Bluetooth is OFF\n"
            MENU="${MENU}─────────────────\n"
            MENU="${MENU}  Turn On\n"
            CHOSEN=$(echo -e "$MENU" | fuzzel --dmenu -p "Bluetooth" 2>/dev/null)
            [ -z "$CHOSEN" ] && exit 0
            if [[ "$CHOSEN" == *"Turn On"* ]]; then
                bluetoothctl power on 2>/dev/null
                notify-send "Bluetooth" "Powered on"
            fi
            exit 0
        fi

        # Section 1: Connected devices
        CONNECTED=""
        while IFS='|' read -r mac name; do
            [ -z "$name" ] && continue
            if is_connected "$mac"; then
                batt=$(get_battery "$mac")
                CONNECTED="${CONNECTED} 󰂱 ${name}"
                [ -n "$batt" ] && CONNECTED="${CONNECTED} (${batt}%)"
                CONNECTED="${CONNECTED}\n"
            fi
        done < <(get_all_devices)

        # Section 2: Paired but not connected (available)
        AVAILABLE=""
        while IFS='|' read -r mac name; do
            [ -z "$name" ] && continue
            if is_paired "$mac" && is_available "$mac"; then
                AVAILABLE="${AVAILABLE} 󰂲 ${name}\n"
            fi
        done < <(get_all_devices)

        # Build menu
        MENU=""
        if [ -n "$CONNECTED" ]; then
            MENU="${MENU}── Connected ────────────\n"
            MENU="${MENU}${CONNECTED}"
        fi

        if [ -n "$AVAILABLE" ]; then
            [ -n "$MENU" ] && MENU="${MENU}\n"
            MENU="${MENU}── Available ────────────\n"
            MENU="${MENU}${AVAILABLE}"
        fi

        if [ -z "$CONNECTED" ] && [ -z "$AVAILABLE" ]; then
            MENU="${MENU}── Paired Devices ───────\n"
            MENU="${MENU}  No paired devices\n"
        fi

        # Section 3: Commands
        MENU="${MENU}\n── Commands ─────────────\n"
        MENU="${MENU} 󰂯 Toggle Power\n"
        MENU="${MENU}  Scan & Pair New Device"

        CHOSEN=$(echo -e "$MENU" | fuzzel --dmenu -p "Bluetooth" 2>/dev/null)

        [ -z "$CHOSEN" ] && exit 0

        case "$CHOSEN" in
            *"Toggle Power"*)
                bluetoothctl power off 2>/dev/null
                notify-send "Bluetooth" "Powered off"
                ;;
            *"Scan & Pair"*)
                bluetoothctl -- pairable on 2>/dev/null
                bluetoothctl -- scan on 2>/dev/null &
                SCAN_PID=$!
                notify-send "Bluetooth" "Scanning for 10 seconds..."
                sleep 10
                kill $SCAN_PID 2>/dev/null
                bluetoothctl -- scan off 2>/dev/null

                # Build list of unpaired devices
                SCAN_MENU=""
                while IFS='|' read -r mac name; do
                    [ -z "$name" ] && continue
                    if ! is_paired "$mac"; then
                        SCAN_MENU="${SCAN_MENU}${name}\n"
                    fi
                done < <(get_all_devices)

                if [ -z "$SCAN_MENU" ]; then
                    notify-send "Bluetooth" "No new devices found"
                    exit 0
                fi

                DEVICE_CHOSEN=$(echo -e "$SCAN_MENU" | fuzzel --dmenu -p "Pair Device" 2>/dev/null)
                [ -z "$DEVICE_CHOSEN" ] && exit 0

                DEVICE_MAC=$(get_all_devices | grep "|${DEVICE_CHOSEN}$" | cut -d'|' -f1 | head -1)

                if [ -n "$DEVICE_MAC" ]; then
                    bluetoothctl pair "$DEVICE_MAC" 2>/dev/null
                    bluetoothctl trust "$DEVICE_MAC" 2>/dev/null
                    bluetoothctl connect "$DEVICE_MAC" 2>/dev/null
                    notify-send "Bluetooth" "Paired & connected: $DEVICE_CHOSEN"
                fi
                ;;
            *)
                # Extract device name (remove icons)
                DEVICE_NAME=$(echo "$CHOSEN" | sed 's/^[󰂱󰂲] //' | sed 's/ ([0-9]*%)//')
                DEVICE_MAC=$(get_all_devices | grep "|${DEVICE_NAME}$" | cut -d'|' -f1 | head -1)

                if [ -n "$DEVICE_MAC" ]; then
                    if is_connected "$DEVICE_MAC"; then
                        bluetoothctl disconnect "$DEVICE_MAC" 2>/dev/null
                        notify-send "Bluetooth" "Disconnected: $DEVICE_NAME"
                    else
                        bluetoothctl connect "$DEVICE_MAC" 2>/dev/null
                        notify-send "Bluetooth" "Connected: $DEVICE_NAME"
                    fi
                fi
                ;;
        esac
        ;;
    menu)
        if ! command -v bluetoothctl &> /dev/null; then
            echo "Error: bluetoothctl not found"
            exit 1
        fi
        bluetoothctl
        ;;
    power)
        if ! command -v bluetoothctl &> /dev/null; then
            notify-send "Bluetooth" "Error: bluetoothctl not found"
            exit 1
        fi
        if [ "$(get_power_state)" = "yes" ]; then
            bluetoothctl power off 2>/dev/null
            notify-send "Bluetooth" "Powered off"
        else
            bluetoothctl power on 2>/dev/null
            notify-send "Bluetooth" "Powered on"
        fi
        ;;
    *)
        echo "Usage: $0 {gui|menu|power}" >&2
        exit 1
        ;;
esac
