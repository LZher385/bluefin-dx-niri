#!/bin/bash
set -euxo pipefail

dnf5 install -y --setopt=install_weak_deps=False \
  fprintd \
  fprintd-pam
