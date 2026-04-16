#!/bin/bash
set -ouex pipefail

echo "=== REPOS ==="
dnf5 repolist --all || true

echo "=== INSTALLED RELEASE PACKAGES ==="
rpm -q terra-release || true

echo "=== CHECK KANATA BUILD CONTEXT ==="
ls -l /ctx || true
test -f /ctx/kanata

# Add Terra only if the terra repo is not already present
if ! dnf5 repolist --all | awk '{print $1}' | grep -qx terra; then
  dnf5 install -y --nogpgcheck \
    --repofrompath="terra,https://repos.fyralabs.com/terra\$releasever" \
    terra-release
fi

echo "=== VERIFY PACKAGE AVAILABILITY ==="
dnf5 repoquery niri || true
dnf5 repoquery noctalia-shell || true
dnf5 repoquery kitty || true
dnf5 repoquery kanshi || true
dnf5 repoquery xwayland-satellite || true
dnf5 repoquery xdg-desktop-portal-gtk || true
dnf5 repoquery wl-clipboard || true
dnf5 repoquery cliphist || true
dnf5 repoquery brightnessctl || true
dnf5 repoquery fprintd || true
dnf5 repoquery fprintd-pam || true
dnf5 repoquery fd-find || true
dnf5 repoquery fzf || true
dnf5 repoquery ripgrep || true
dnf5 repoquery swayidle || true

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
  tmux \
  fd-find \
  fzf \
  ripgrep \
  swayidle

dnf5 clean all

install -m0755 /ctx/kanata /usr/bin/kanata

groupadd --system uinput || true

cat >/etc/udev/rules.d/99-input.rules <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

echo uinput >/etc/modules-load.d/uinput.conf
