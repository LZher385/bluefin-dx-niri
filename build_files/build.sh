#!/bin/bash

set -ouex pipefail

# Core session stack
dnf5 install -y \
  niri \
  noctalia-shell \
  kitty \
  kanshi \
  xwayland-satellite \
  xdg-desktop-portal-gtk \
  wl-clipboard \
  cliphist \
  brightnessctl \
  fprintd \
  fprintd-pam \
  tmux

# Install vendored Kanata binary from build context
install -Dm0755 /ctx/kanata /usr/local/bin/kanata

# Kanata host plumbing
groupadd --system uinput || true

cat >/etc/udev/rules.d/99-input.rules <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

echo uinput >/etc/modules-load.d/uinput.conf

# Uncomment only if you verify you need them in the Niri session:
#
# dnf5 install -y \
#   xdg-desktop-portal-gnome \
#   gnome-keyring \
#   nautilus

# Optional later:
#
# dnf5 install -y \
#   wf-recorder
