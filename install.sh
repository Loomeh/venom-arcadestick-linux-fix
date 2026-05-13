#!/bin/bash

ENV_FILE="/etc/environment"

SDL_PAD_STR="03003a73790000001b18000011010000,Venom Limited PS3/PS4 Arcade Joystick,a:b0,b:b1,x:b3,y:b2,back:b8,guide:b10,start:b9,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,lefttrigger:b6,righttrigger:b7,platform:Linux,crc:733a,"

# Extract the controller name from the SDL string (2nd field separated by comma)
CONTROLLER_NAME=$(echo "$SDL_PAD_STR" | cut -d',' -f2)

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script as root (e.g., using sudo)."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

cp "$SCRIPT_DIR/99-venom-stick.hwdb" /etc/udev/hwdb.d/99-venom-stick.hwdb
systemd-hwdb update
udevadm trigger


# Make sure the exact gamepad mapping doesn't already exist
if grep -qF "$SDL_PAD_STR" "$ENV_FILE"; then
    echo "Exact gamepad mapping already exists in $ENV_FILE. No changes made."
    exit 0
fi


# Check if the SDL variable exists, and modify or create it
if grep -q "^SDL_GAMECONTROLLERCONFIG=" "$ENV_FILE"; then
    echo "Existing SDL_GAMECONTROLLERCONFIG found. Updating mapping for '$CONTROLLER_NAME'..."

    # Use awk to handle multi-line string parsing, replace mapping if the name matches, or append if it doesn't
    awk -v newpad="$SDL_PAD_STR" -v cname="$CONTROLLER_NAME" '
    BEGIN { in_var = 0; var_content = "" }

    # Match the beginning of the variable
    /^SDL_GAMECONTROLLERCONFIG=/ {
        in_var = 1
        val = $0
        sub(/^SDL_GAMECONTROLLERCONFIG=/, "", val)
        has_quote = sub(/^"/, "", val)

        # If it opens and closes quotes on the same line, process immediately
        if (has_quote && val ~ /"$/) {
            sub(/"$/, "", val)
            in_var = 0
            process_mappings(val, cname, newpad)
            next
        } else if (!has_quote) { # Unquoted single-line variable
            in_var = 0
            process_mappings(val, cname, newpad)
            next
        }
        var_content = val
        next
    }

    # Accumulate lines if the variable spans multiple lines
    in_var == 1 {
        val = $0
        if (val ~ /"$/) {
            sub(/"$/, "", val)
            var_content = var_content "\n" val
            in_var = 0
            process_mappings(var_content, cname, newpad)
            next
        } else {
            var_content = var_content "\n" val
            next
        }
    }

    # Print all other lines untouched
    in_var == 0 { print }

    function process_mappings(content, cname, newpad) {
        n = split(content, maps, "\n")
        replaced = 0
        final_str = ""

        for (i = 1; i <= n; i++) {
            if (maps[i] == "") continue
            split(maps[i], fields, ",")

            # Field 2 in an SDL mapping is the Controller Name
            if (fields[2] == cname) {
                maps[i] = newpad
                replaced = 1
            }

            if (final_str == "") {
                final_str = maps[i]
            } else {
                final_str = final_str "\n" maps[i]
            }
        }

        # If no existing mapping matched the name, append the new one
        if (replaced == 0) {
            if (final_str == "") {
                final_str = newpad
            } else {
                final_str = final_str "\n" newpad
            }
        }

        print "SDL_GAMECONTROLLERCONFIG=\"" final_str "\""
    }
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
