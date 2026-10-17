#!/bin/bash
# Runs once on first boot (cloud-init). Installs Docker so the pipeline can deploy the app.
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io curl

systemctl enable --now docker
usermod -aG docker ubuntu
