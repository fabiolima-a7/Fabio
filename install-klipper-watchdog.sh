#!/bin/sh
# install-klipper-watchdog.sh
#
# Builds and enables a systemd --user watchdog that self-heals the KDE/Qt
# X11 clipboard-ownership bug (bugs.kde.org #363832): when plasmashell loses
# the ability to own the CLIPBOARD selection, copy/paste breaks system-wide
# until plasmashell is restarted. This installs a daemon that watches the
# user journal for the failure signature and restarts plasmashell for you.
#
# Usage: run as the affected user on the target machine.
#   sh install-klipper-watchdog.sh

set -eu

BIN_DIR="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
WATCHDOG_SCRIPT="$BIN_DIR/klipper-watchdog.sh"
UNIT_FILE="$UNIT_DIR/klipper-watchdog.service"

mkdir -p "$BIN_DIR" "$UNIT_DIR"

cat > "$WATCHDOG_SCRIPT" <<'EOF'
#!/bin/bash
# Watches the user journal for the X11 clipboard-ownership failure signature
# and restarts plasmashell automatically when it appears.

COOLDOWN=30
last_restart=0

while read -r _; do
  now=$(date +%s)
  if (( now - last_restart > COOLDOWN )); then
    systemctl --user restart plasma-plasmashell.service
    logger -t klipper-watchdog "clipboard ownership failure detected -> plasmashell restarted"
    last_restart=$now
  fi
done < <(journalctl --user -f -o cat 2>/dev/null | grep --line-buffered "Cannot set X11 selection owner")
EOF
chmod +x "$WATCHDOG_SCRIPT"

cat > "$UNIT_FILE" <<EOF
[Unit]
Description=Auto-restart plasmashell on X11 clipboard ownership failure
After=plasma-plasmashell.service

[Service]
Type=simple
ExecStart=$WATCHDOG_SCRIPT
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now klipper-watchdog.service

echo "OK: klipper-watchdog.service instalado e ativo."
systemctl --user status klipper-watchdog.service --no-pager
