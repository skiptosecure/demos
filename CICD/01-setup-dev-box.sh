#!/bin/bash
###############################################################################
# 01-setup-dev-box.sh
# Provisions a fresh Rocky Linux 9 minimal install as a developer workstation.
# This is where you write code and push to GitHub. That's it.
#
# Installs: Git
# Generates: ED25519 SSH keypair for GitHub authentication
#
# Usage: sudo bash 01-setup-dev-box.sh
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}
print_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_fail() { echo -e "${RED}[FAIL]${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
    print_fail "Run this with sudo: sudo bash $0"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo "~${ACTUAL_USER}")

if [[ "$ACTUAL_USER" == "root" ]]; then
    print_warn "Running as root directly. SSH key and git config will be set for root."
    print_warn "For a regular user, run with: sudo bash $0"
fi

print_banner "DEV BOX SETUP - Rocky Linux 9"
echo "Target user: ${ACTUAL_USER}"
echo "Home dir:    ${ACTUAL_HOME}"

###############################################################################
# 1. SYSTEM UPDATE & BASE PACKAGES
#    Rocky 9 minimal is very bare. These are commonly assumed to exist but
#    are not included in the minimal install.
###############################################################################
print_banner "1/3 - System Update & Base Packages"

dnf update -y
dnf install -y \
    curl \
    wget \
    tar \
    unzip \
    vim \
    bash-completion \
    jq \
    openssh-clients \
    ca-certificates \
    gnupg2

print_ok "Base packages installed."

###############################################################################
# 2. GIT
###############################################################################
print_banner "2/3 - Git"

dnf install -y git

sudo -u "$ACTUAL_USER" git config --global init.defaultBranch main
sudo -u "$ACTUAL_USER" git config --global pull.rebase false
sudo -u "$ACTUAL_USER" git config --global core.editor vim

echo ""
read -rp "Git username (for commits): " GIT_USERNAME
read -rp "Git email (for commits):    " GIT_EMAIL

sudo -u "$ACTUAL_USER" git config --global user.name "$GIT_USERNAME"
sudo -u "$ACTUAL_USER" git config --global user.email "$GIT_EMAIL"

print_ok "Git $(git --version | awk '{print $3}') configured for ${ACTUAL_USER}."

###############################################################################
# 3. SSH KEY FOR GITHUB
###############################################################################
print_banner "3/3 - SSH Key for GitHub"

SSH_KEY_PATH="${ACTUAL_HOME}/.ssh/github_ed25519"

if [[ -f "$SSH_KEY_PATH" ]]; then
    print_warn "SSH key already exists at ${SSH_KEY_PATH}. Skipping."
else
    sudo -u "$ACTUAL_USER" mkdir -p "${ACTUAL_HOME}/.ssh"
    chmod 700 "${ACTUAL_HOME}/.ssh"
    chown "$ACTUAL_USER":"$ACTUAL_USER" "${ACTUAL_HOME}/.ssh"

    sudo -u "$ACTUAL_USER" ssh-keygen -t ed25519 -C "${GIT_EMAIL}" -f "$SSH_KEY_PATH" -N ""

    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"
fi

SSH_CONFIG="${ACTUAL_HOME}/.ssh/config"
if ! grep -q "github.com" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    chown "$ACTUAL_USER":"$ACTUAL_USER" "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

print_ok "SSH key generated."

###############################################################################
# DONE
###############################################################################
print_banner "DEV BOX READY"

echo -e "Installed:"
echo -e "  Git: $(git --version | awk '{print $3}')"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} ADD THIS SSH KEY TO YOUR GITHUB ACCOUNT${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e " 1. Go to: ${CYAN}https://github.com/settings/ssh/new${NC}"
echo -e " 2. Title: $(hostname)-dev"
echo -e " 3. Key type: Authentication Key"
echo -e " 4. Paste this public key:"
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e " 1. Copy the key above and paste it into GitHub"
echo -e " 2. Test: ssh -T git@github.com"
echo -e " 3. Run 02-setup-deploy-target.sh on your deploy box (or this same box)"
echo ""
print_ok "Done."
