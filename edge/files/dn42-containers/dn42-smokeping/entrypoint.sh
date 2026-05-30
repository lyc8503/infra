#!/bin/bash
set -e

# Debian smokeping installs default /etc/smokeping/config that @include's config.d/*
# Default General, Alerts, Slaves, pathnames files stay intact
# We only override Database, Presentation, Probes, Targets as individual mounted files

# Create required directories
mkdir -p /var/run/smokeping /var/cache/smokeping/images
chown -R www-data:www-data /var/lib/smokeping /var/cache/smokeping

# Start fcgiwrap
rm -f /var/run/fcgiwrap.socket
spawn-fcgi -s /var/run/fcgiwrap.socket -u www-data -g www-data -n -- /usr/sbin/fcgiwrap &
sleep 1
chmod 666 /var/run/fcgiwrap.socket

# Start smokeping
echo "Starting smokeping..."
smokeping --config /etc/smokeping/config --pid-dir=/var/run/smokeping --logfile=/var/log/smokeping.log &

# Start nginx
echo "Starting nginx..."
exec nginx -g "daemon off;"
