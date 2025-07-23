#! /bin/bash

# Set the hostname using the last 8 digits of the serial number
SERIAL_NUMBER=$(cat /sys/class/dmi/id/product_serial 2>/dev/null)
SERIAL_NUMBER=$(echo "$SERIAL_NUMBER" | tail -c 9)
SERIAL_NUMBER="${SERIAL_NUMBER%$'\n'}"
echo "lsa-$SERIAL_NUMBER" > /etc/hostname

# Set user display names
usermod -c "Teacher" teacher
usermod -c "Student" student

# Enable automatic login for the student user
sed -i '/^\[daemon\]/a\
AutomaticLoginEnable=True\
AutomaticLogin=student' /etc/gdm/custom.conf

# Create necessary directories
mkdir /etc/dconf/profile
mkdir /etc/dconf/db
mkdir /etc/dconf/db/gdm.d/
mkdir /etc/dconf/db/local.d/

# Remove unwanted desktop entries from the student user
SYSTEM_DESKTOP_DIR="/usr/share/applications"
USER_DESKTOP_DIR="/home/student/.local/share/applications"

# IMPORTANT: List of .desktop filenames to keep ENABLED (whitelist)
# These should be just the filenames, e.g., "firefox.desktop"
# Separate multiple entries with spaces.
WHITELISTED_DESKTOPS=(
    "org.gnome.Epiphany.desktop"
    "org.gnome.Nautilus.desktop"
    "org.gnome.Calculator.desktop"
    "org.gnome.TextEditor.desktop"
    "org.gnome.Snapshot.desktop"
    "gnome-universal-access-panel.desktop"
    # Add other .desktop files you want to keep enabled here
)

# Create user desktop directory if it doesn't exist
mkdir -p "$USER_DESKTOP_DIR"

# Loop through all .desktop entries in the system's folder
for system_desktop_file in "$SYSTEM_DESKTOP_DIR"/*.desktop; do
    if [ -f "$system_desktop_file" ]; then
        filename=$(basename "$system_desktop_file")
        user_desktop_path="$USER_DESKTOP_DIR/$filename"

        # Check if the current file is in our whitelist
        is_whitelisted=false
        for whitelisted_file in "${WHITELISTED_DESKTOPS[@]}"; do
            if [[ "$filename" == "$whitelisted_file" ]]; then
                is_whitelisted=true
                break
            fi
        done

        if [ "$is_whitelisted" = true ]; then
            echo "Keeping ENABLED (whitelisted): $filename"
            # If a hidden file for this exists in user's dir, remove it
            if [ -f "$user_desktop_path" ]; then
                # Check if it's a "hidden" file created by this script
                if grep -q "Hidden=true" "$user_desktop_path" || grep -q "NoDisplay=true" "$user_desktop_path"; then
                    echo "  - Removing disabling file from user directory: $user_desktop_path"
                    rm "$user_desktop_path"
                else
                    echo "  - User-specific override exists, not touching: $user_desktop_path"
                fi
            fi
        else
            echo "Disabling: $filename"
            # Create a disabling .desktop file in the user's directory
            # If it already exists, overwrite it to ensure it's disabled
            cat > "$user_desktop_path" <<EOL
[Desktop Entry]
Hidden=true
NoDisplay=true
EOL
            echo "  - Created/Updated: $user_desktop_path"
        fi
    fi
done

update-desktop-database



# Prevent non-sudo users from adjusting network
cat << EOF > /etc/polkit-1/rules.d/90-defaults.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.network-control") {
        return polkit.Result.AUTH_ADMIN;
    }
    if (action.id == "org.freedesktop.NetworkManager.enable-disable-network") {
        return polkit.Result.AUTH_ADMIN;
    }
    if (action.id == "org.freedesktop.NetworkManager.enable-disable-wifi") {
        return polkit.Result.AUTH_ADMIN;
    }
    if (action.id == "org.freedesktop.NetworkManager.wifi.share.protected") {
        return polkit.Result.AUTH_ADMIN;
    }
});
EOF

# Create GDM profile
cat << EOF > /etc/dconf/profile/gdm
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
EOF

# Create user profile
cat << EOF > /etc/dconf/profile/user
user-db:user
system-db:local
EOF

# Download the greeter logo
curl -o /usr/share/pixmaps/lsa-logo-dark.svg https://raw.githubusercontent.com/computerman-dev/archinstalls/main/lsa/lsa-logo-dark.svg
chmod 644 /usr/share/pixmaps/lsa-logo-dark.svg

# Download the desktop wallpaper
curl -o /usr/share/backgrounds/lsa-background.svg https://raw.githubusercontent.com/computerman-dev/archinstalls/main/lsa/lsa-background.svg
chmod 644 /usr/share/backgrounds/lsa-background.svg

# Set the GDM default settings
cat << EOF > /etc/dconf/db/gdm.d/10-defaults
[org/gnome/login-screen]
logo='/usr/share/pixmaps/lsa-logo-dark.svg'

[org/gnome/desktop/session]
session-chooser-enabled=false
EOF

# Set Gnome settings
cat << EOF > /etc/dconf/db/local.d/10-defaults

[org/gnome/online-accounts]
whitelisted-providers= ['']

[org/gnome/shell]
favorite-apps= ['org.gnome.Epiphany.desktop','org.gnome.Nautilus.desktop', 'org.gnome.Calculator.desktop']

[org/gnome/epiphany]
homepage-url='https://www.ixl.com/signin'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/lsa-background.svg'
picture-uri-dark='file:///usr/share/backgrounds/lsa-background.svg'

[org/gnome/desktop/lockdown]
disable-command-line=true
user-administration-disabled=true
EOF

# Update the system databases to apply changes
dconf update