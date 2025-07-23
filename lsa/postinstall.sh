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

# Set the greeter logo (!)
curl -o /usr/share/pixmaps/lsa-logo-dark.svg https://raw.githubusercontent.com/computerman-dev/archinstalls/main/lsa/lsa-logo-dark.svg
chmod 644 /usr/share/pixmaps/lsa-logo-dark.svg

cat << EOF > /etc/dconf/db/gdm.d/01-logo
[org/gnome/login-screen]
logo='/usr/share/pixmaps/lsa-logo-dark.svg'
EOF

# Gnome settings
cat << EOF > /etc/dconf/db/local.d/settings
[org/gnome/online-accounts]
whitelisted-providers= ['']
[org/gnome/shell]
favorite-apps= ['org.gnome.Epiphany.desktop','org.gnome.Nautilus.desktop']
[org/gnome/desktop/lockdown]
disable-command-line=true
EOF

# Set locks
cat << EOF > /etc/dconf/db/local.d/locks/lockdown
org/gnome
EOF

# Update the system databases to apply changes
dconf update
