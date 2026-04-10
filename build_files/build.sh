#!/bin/bash

set -ouex pipefail

# Add Terra for Noctalia on Fedora
dnf5 install -y --nogpgcheck \
  --repofrompath="terra,https://repos.fyralabs.com/terra\$releasever" \
  terra-release

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

# Usually already present on Bluefin DX / GNOME base.
# Uncomment only if you verify you need them in the Niri session.
#
# dnf5 install -y \
#   xdg-desktop-portal-gnome \
#   gnome-keyring \
#   nautilus

# Optional later:
#
# dnf5 install -y \
#   wf-recorder

# Intentionally omitted from v1:
# - grim / slurp      # Niri has built-in screenshot UI/actions
# - hypridle          # avoid cross-ecosystem overlap
# - wireplumber       # likely already part of the GNOME/Bluefin base
# - polkit-gnome      # test first; GNOME base usually already covers this
