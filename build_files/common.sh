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
# Print the actual sha256 first so a mismatch surfaces the new value in CI logs
# (Renovate bumps KANATA_VERSION via a regex manager; paste the printed sha into
# KANATA_SHA256 when the next line fails).
sha256sum "$TMP/kanata.zip"
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

# --- cosign policy: require signed images on rebase/upgrade ---
# Without this, `bootc upgrade` will accept any image pushed to the repo's
# ghcr namespace. The pubkey is the same one CI signs with (see workflow's
# "Sign container image" step + cosign.pub at repo root).
install -Dm0644 /ctx/cosign.pub /etc/pki/containers/bluefin-dx-niri.pub

mkdir -p /etc/containers/registries.d
cat >/etc/containers/registries.d/bluefin-dx-niri.yaml <<'EOF'
docker:
  ghcr.io/lzher385/bluefin-dx-niri-fw13:
    use-sigstore-attachments: true
  ghcr.io/lzher385/bluefin-dx-niri-desktop-nvidia:
    use-sigstore-attachments: true
EOF

# Merge a sigstoreSigned entry into the existing policy.json (the bluefin
# base already wires up ghcr.io/ublue-os/*; we add our two image refs).
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("/etc/containers/policy.json")
policy = json.loads(p.read_text())
policy.setdefault("transports", {}).setdefault("docker", {})
for img in (
    "ghcr.io/lzher385/bluefin-dx-niri-fw13",
    "ghcr.io/lzher385/bluefin-dx-niri-desktop-nvidia",
):
    policy["transports"]["docker"][img] = [{
        "type": "sigstoreSigned",
        "keyPath": "/etc/pki/containers/bluefin-dx-niri.pub",
        "signedIdentity": {"type": "matchRepository"},
    }]
p.write_text(json.dumps(policy, indent=2) + "\n")
PY
