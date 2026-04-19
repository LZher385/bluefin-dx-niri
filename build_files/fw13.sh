#!/bin/bash
set -ouex pipefail

dnf5 repoquery fprintd || true
dnf5 repoquery fprintd-pam || true

dnf5 install -y \
  fprintd \
  fprintd-pam