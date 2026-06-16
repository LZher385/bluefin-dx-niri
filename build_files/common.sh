#!/bin/bash
set -euxo pipefail

KANATA_VERSION="v1.11.0"
KANATA_SHA256="d9f634afb4c7f078cc2aacf3998fd65b432d4d83296cc48a89f941525459b4e2"

# Add Terra only if not already present
if ! dnf5 repolist --all | awk '{print $1}' | grep -qx terra; then
  dnf5 install -y --nogpgcheck \
    --repofrompath="terra,https://repos.fyralabs.com/terra\$releasever" \
    terra-release
fi

dnf5 makecache --refresh -y

dnf5 install -y --setopt=install_weak_deps=False \
  niri \
  noctalia-shell \
  kitty \
  kanshi \
  xwayland-satellite \
  xdg-desktop-portal-gtk \
  wl-clipboard \
  cliphist \
  brightnessctl \
  tmux \
  fd-find \
  fzf \
  ripgrep \
  swayidle

# --- kanata: fetch pinned release, verify sha256, install ---
TMP="$(mktemp -d)"
curl -fsSL -o "$TMP/kanata.zip" \
  "https://github.com/jtroo/kanata/releases/download/${KANATA_VERSION}/linux-binaries-x64.zip"
echo "${KANATA_SHA256}  $TMP/kanata.zip" | sha256sum -c -
( cd "$TMP" && unzip -q kanata.zip )
KANATA_BIN="$(find "$TMP" -maxdepth 3 -type f -name 'kanata*' ! -name '*.zip' -executable -print -quit \
  || find "$TMP" -maxdepth 3 -type f -name 'kanata*' ! -name '*.zip' -print -quit)"
install -m0755 "$KANATA_BIN" /usr/bin/kanata
rm -rf "$TMP"

groupadd --system uinput || true

cat >/etc/udev/rules.d/99-input.rules <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

echo uinput >/etc/modules-load.d/uinput.conf
