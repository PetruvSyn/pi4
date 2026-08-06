#!/bin/bash

set -e

BACKUP_DIR="$HOME/backups"
DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP_FILE="$BACKUP_DIR/pi4-media-backup-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Creating backup..."

sudo tar -czvf "$BACKUP_FILE" \
    --exclude="/mnt/*/Plex*" \
    --exclude="/mnt/*/Downloads*" \
    \
    "$HOME/docker" \
    /etc/wireguard \
    /etc/ufw \
    /etc/systemd/system/docker.service.d \
    2>/dev/null

sudo chown "$USER:$USER" "$BACKUP_FILE"

echo
echo "Backup complete:"
echo "$BACKUP_FILE"
