#!/bin/sh

DROPBEAR_KEY_DIR="/mnt/SDCARD/sprig/etc/ssh"

cd /mnt/SDCARD/sprig/bin

mkdir -p "$DROPBEAR_KEY_DIR"
[ ! -f "$DROPBEAR_KEY_DIR/dropbear_rsa_host_key" ] && ./dropbearmulti dropbearkey -t rsa -f "$DROPBEAR_KEY_DIR/dropbear_rsa_host_key"
[ ! -f "$DROPBEAR_KEY_DIR/dropbear_ecdsa_host_key" ] && ./dropbearmulti dropbearkey -t ecdsa -f "$DROPBEAR_KEY_DIR/dropbear_ecdsa_host_key"
[ ! -f "$DROPBEAR_KEY_DIR/dropbear_ed25519_host_key" ] && ./dropbearmulti dropbearkey -t ed25519 -f "$DROPBEAR_KEY_DIR/dropbear_ed25519_host_key"

./dropbearmulti dropbear \
    -r "$DROPBEAR_KEY_DIR/dropbear_rsa_host_key" \
    -r "$DROPBEAR_KEY_DIR/dropbear_ecdsa_host_key" \
    -r "$DROPBEAR_KEY_DIR/dropbear_ed25519_host_key" \
    -c "./ssh_wrapper"
