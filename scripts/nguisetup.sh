#!/bin/sh
#
# Script for automatic setup of an NGINX UI on Ubuntu LTS and Debian.
# Works on any dedicated server or virtual private server.
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC!
#
# The latest version of this script is available at:
# https://github.com/shyjuk/nginx-ui/
#
# Copyright (C) 2021-2022 Shyju Kanaprath <k@shyju.win>
# Based on the work of Lin Song 
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

# =====================================================

# Define your own values for these variables
# - NGINX UI username and password
# - All values MUST be placed inside 'single quotes'
# - DO NOT use these special characters within values: \ " '

YOUR_USERNAME=''
YOUR_PASSWORD=''
INSTALL_PATH=''

# =====================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT="$(date +%F-%T)"

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo; echo "## $1"; echo; }

nguisetup() {

os_type="$(lsb_release -si 2>/dev/null)"
if [ -z "$os_type" ]; then
  [ -f /etc/os-release  ] && os_type="$(. /etc/os-release  && echo "$ID")"
  [ -f /etc/lsb-release ] && os_type="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if ! printf '%s' "$os_type" | head -n 1 | grep -qiF -e ubuntu -e debian -e raspbian; then
  exiterr "This script only supports Ubuntu and Debian."
fi

if [ "$(sed 's/\..*//' /etc/debian_version)" = "7" ]; then
  exiterr "Debian 7 is not supported."
fi

if [ "$(id -u)" != 0 ]; then
  exiterr "Script must be run as root. Try 'sudo sh $0'"
fi

[ -n "$INSTALL_PATH" ] && NGUI_INSTALL_PATH="$INSTALL_PATH"
[ -n "$YOUR_USERNAME" ] && NGUI_USER="$YOUR_USERNAME"
[ -n "$YOUR_PASSWORD" ] && NGUI_PASSWORD="$YOUR_PASSWORD"

if [ -z "$NGUI_INSTALL_PATH" ] && [ -z "$NGUI_USER" ] && [ -z "$NGUI_PASSWORD" ]; then
  bigecho "NGINX credentials not set by user. Installing nginx-ui under /opt and generating random password..."
  NGUI_INSTALL_PATH="/opt/"
  NGUI_USER=ngadmin
  NGUI_PASSWORD="$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 8)"
fi

if [ -z "$NGUI_INSTALL_PATH" ] || [ -z "$NGUI_USER" ] || [ -z "$NGUI_PASSWORD" ]; then
  exiterr "All NGINX UI credentials must be specified. Edit the script and re-enter them."
fi

if printf '%s' "$NGUI_INSTALL_PATH $NGUI_USER $NGUI_PASSWORD" | LC_ALL=C grep -q '[^ -~]\+'; then
  exiterr "NGINX UI credentials must not contain non-ASCII characters."
fi

case "$NGUI_INSTALL_PATH $NGUI_USER $NGUI_PASSWORD" in
  *[\\\"\']*)
    exiterr "NGINX UI credentials must not contain these special characters: \\ \" '"
    ;;
esac

bigecho "NGINX UI setup in progress... Please be patient."

# Create and change to working dir
mkdir -p $NGUI_INSTALL_PATH
cd $NGUI_INSTALL_PATH || exit 1

count=0
APT_LK=/var/lib/apt/lists/lock
PKG_LK=/var/lib/dpkg/lock
while fuser "$APT_LK" "$PKG_LK" >/dev/null 2>&1 \
  || lsof "$APT_LK" >/dev/null 2>&1 || lsof "$PKG_LK" >/dev/null 2>&1; do
  [ "$count" = "0" ] && bigecho "Waiting for apt to be available..."
  [ "$count" -ge "60" ] && exiterr "Could not get apt/dpkg lock."
  count=$((count+1))
  printf '%s' '.'
  sleep 3
done

bigecho "Populating apt-get cache..."

export DEBIAN_FRONTEND=noninteractive
apt-get -yq update || exiterr "'apt-get update' failed."

bigecho "Installing packages required for setup..."

apt-get -yq install nginx git python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools || exiterr2


bigecho "Trying to clone the git repo..."

git -C $NGUI_INSTALL_PATH  clone https://github.com/shyjuk/nginx-ui

bigecho "Installing packages required for the NGINX UI..."

pip3 install -r $NGUI_INSTALL_PATH/nginx-ui/requirements.txt

# Create NGINX UI Service config
conf_bk "/etc/systemd/system/nginxui.service"
cat > /etc/systemd/system/nginxui.service <<EOF
[Unit]
Description="Nginx-UI"
After=network.target

[Service]
User=root
WorkingDirectory=$NGUI_INSTALL_PATH/nginx-ui/
#ExecStart=/usr/local/bin/flask run
ExecStart=/usr/local/bin/uwsgi  --socket 127.0.0.1:5000 --protocol=http -w wsgi:app
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF

# Remove the default NGNIX config file
unlink /etc/nginx/sites-enabled/default

# Get the server IP
PRIVATE_IP=$(ip -4 route get 1 | sed 's/ uid .*//' | awk '{print $NF;exit}')

# Create NGINX config for NGINX UI
cat > /etc/nginx/conf.d/nginxui.conf <<EOF
server {
listen 80;
server_name $PRIVATE_IP;

location / {
 proxy_pass http://127.0.0.1:5000;
}

}

EOF

# Create NGINX UI Password

PHASH=`cat <<EOF
from passlib.hash import sha256_crypt
import sys

password = sys.argv[1] 
print(sha256_crypt.hash(password))
EOF`

PASS_HASH=`python3 -c "$PHASH" $NGUI_PASSWORD`


# Create NGINX UI config file
cat > $NGUI_INSTALL_PATH/nginx-ui/config.py <<EOF
import os

class Config(object):
    SECRET_KEY = os.urandom(64).hex()
    NGINX_PATH = '/etc/nginx'
    CONFIG_PATH = os.path.join(NGINX_PATH, 'conf.d')
    USER = "$NGUI_USER"
    PASS = "$PASS_HASH"

    @staticmethod
    def init_app(app):
        pass

class DevConfig(Config):
    DEBUG = False

class WorkingConfig(Config):
    DEBUG = False

config = {
    'dev': DevConfig,
    'default': WorkingConfig
}

EOF


bigecho "Enabling NGINX UI on boot..."
systemctl enable nginxui

bigecho "Starting services..."
service nginx reload
systemctl start nginxui

cat <<EOF

================================================

NGINX UI is now ready for use!

NGINXUI installed under directory: $NGUI_INSTALL_PATH

Connect to your new NGINX UI with these details:

Server URL: http://$PRIVATE_IP
Username: $NGUI_USER
Password: $NGUI_PASSWORD

Write these down. You'll need them to connect!

================================================

EOF

}

## Defer setup until we have the complete script
nguisetup "$@"

exit 0
