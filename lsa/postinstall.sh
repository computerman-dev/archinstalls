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
mkdir /etc/dconf/db/local.d/locks/

# Prevent non-sudo users from adjusting network
cat << EOF > /etc/polkit-1/rules.d/90-defaults.rules
polkit.addRule(function(action, subject) {
    // Prevent non-admin users from modifying system-wide connections
    if (action.id == "org.freedesktop.NetworkManager.network-control") {
        return polkit.Result.AUTH_ADMIN;
    }
    // For other actions, let the default policy apply
    return polkit.Result.NO;
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
favorite-apps= ['org.gnome.Epiphany.desktop','org.gnome.Nautilus.desktop']

[org/gnome/epiphany]
homepage-url='https://www.ixl.com/signin'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/lsa-background.svg'
picture-uri-dark='file:///usr/share/backgrounds/lsa-background.svg'

[org/gnome/desktop/lockdown]
disable-command-line=true
user-administration-disabled=true
EOF

# Set locks
cat << EOF > /etc/dconf/db/local.d/locks/lockdown
#Nothing is currently locked.
EOF

# Update the system databases to apply changes
dconf update
