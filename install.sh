#!/bin/bash

ENV_FILE="/etc/environment"

SDL_PAD_STR="03003a73790000001b18000011010000,Venom Limited PS3/PS4 Arcade Joystick,a:b0,b:b1,x:b3,y:b2,back:b8,guide:b10,start:b9,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,lefttrigger:b6,righttrigger:b7,platform:Linux,crc:733a,"

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script as root (e.g., using sudo)."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

cp "$SCRIPT_DIR/99-venom-stick.hwdb" /etc/udev/hwdb.d/99-venom-stick.hwdb
systemd-hwdb update
udevadm trigger


# Make sure gamepad mapping doesn't already exist
if grep -qF "$SDL_PAD_STR" "$ENV_FILE"; then
    echo "Gamepad mapping already exists in $ENV_FILE. No changes made."
    exit 0
fi


# Check if the SDL variable exists, and modify or create it
if grep -q "^SDL_GAMECONTROLLERCONFIG=" "$ENV_FILE"; then
    echo "Existing SDL_GAMECONTROLLERCONFIG found. Appending mapping..."
    
    # Use awk to safely strip existing quotes, append the new mapping with a \n separator, and re-quote
    awk -v newpad="$SDL_PAD_STR" '
    /^SDL_GAMECONTROLLERCONFIG=/ {
        val = $0
        sub(/^SDL_GAMECONTROLLERCONFIG=/, "", val)
        gsub(/^"|"$/, "", val)
        print "SDL_GAMECONTROLLERCONFIG=\"" val "\\n" newpad "\""
        next
    }
    { print }
    ' "$ENV_FILE" > "${ENV_FILE}.tmp"
    
    # Safely overwrite the original file to maintain permissions
    cat "${ENV_FILE}.tmp" > "$ENV_FILE"
    rm "${ENV_FILE}.tmp"
else
    echo "SDL_GAMECONTROLLERCONFIG not found. Creating variable..."
    echo "SDL_GAMECONTROLLERCONFIG=\"$SDL_PAD_STR\"" >> "$ENV_FILE"
fi


# Notify to log back in
echo "Please restart the session or reboot to trigger changes."
