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
cat << EOF > /etc/polkit-1/rules.d/90-defaults
polkit.addRule(function(action, subject) {
    // Prevent non-admin users from modifying system-wide connections
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system") {
        return polkit.Result.AUTH_ADMIN;
    }

    // Prevent non-admin users from modifying their own connections (optional, can be too restrictive)
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.own" && !subject.isInGroup("sudo") && !subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN;
    }

    // Prevent non-admin users from enabling/disabling Wi-Fi
    if (action.id == "org.freedesktop.NetworkManager.enable-disable-wifi" && !subject.isInGroup("sudo") && !subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN;
    }

    // You might also want to restrict other actions like:
    // org.freedesktop.NetworkManager.network-control (general network control)
    // org.freedesktop.NetworkManager.enable-disable-network (enable/disable all networking)

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
