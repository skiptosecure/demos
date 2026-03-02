#!/bin/bash
###############################################################################
# 02-setup-deploy-target.sh
# Provisions a fresh Rocky Linux 9 minimal install as a deployment target.
# This is where containers run after the CI/CD pipeline passes in GitHub.
#
# You push code from your dev box → GitHub Actions builds, scans, and pushes
# the image to GHCR → you pull it here and run it.
#
# Installs: Docker CE, Docker Compose plugin, firewalld
# Creates:  'deploy' user for running containers
# Configures: Firewall rules, Docker daemon defaults, GHCR login helper
#
# Usage: sudo bash 02-setup-deploy-target.sh
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

print_banner "DEPLOY TARGET SETUP - Rocky Linux 9"

###############################################################################
# 1. SYSTEM UPDATE & BASE PACKAGES
#    Rocky 9 minimal is missing a lot. dnf-plugins-core is required for
#    dnf config-manager which Docker CE repo setup needs.
###############################################################################
print_banner "1/5 - System Update & Base Packages"

dnf update -y
dnf install -y \
    curl \
    wget \
    tar \
    vim \
    jq \
    dnf-plugins-core \
    openssh-server \
    openssh-clients

systemctl enable --now sshd

print_ok "Base packages installed."

###############################################################################
# 2. DOCKER CE
#    Official Docker repo for CentOS/RHEL. Not podman.
###############################################################################
print_banner "3/5 - Docker CE"

# Remove conflicting packages that ship with Rocky
dnf remove -y podman buildah containers-common 2>/dev/null || true

# Add Docker CE repo
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE, CLI, containerd, and compose plugin
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin

# Configure Docker daemon for sensible defaults
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF

systemctl enable --now docker

print_ok "Docker $(docker --version | awk '{print $3}' | tr -d ',') installed and running."
print_ok "Docker Compose $(docker compose version | awk '{print $NF}') installed."

###############################################################################
#3. DEPLOY USER
#    Dedicated user for running containers. No password.
###############################################################################
print_banner "4/5 - Deploy User"

DEPLOY_USER="deploy"
DEPLOY_HOME="/home/${DEPLOY_USER}"

if id "$DEPLOY_USER" &>/dev/null; then
    print_warn "User '${DEPLOY_USER}' already exists. Skipping creation."
else
    useradd -m -s /bin/bash "$DEPLOY_USER"
    print_ok "User '${DEPLOY_USER}' created."
fi

# Add to docker group so deploy user can run docker without sudo
usermod -aG docker "$DEPLOY_USER"

# Create app directory
sudo -u "$DEPLOY_USER" mkdir -p "${DEPLOY_HOME}/apps"

print_ok "Deploy user ready."

###############################################################################
# 4. GHCR LOGIN HELPER
#    This script logs the deploy user into GitHub Container Registry so
#    they can pull images from your private repo. Run it once.
###############################################################################
print_banner "5/5 - GHCR Login Helper"

cat > "${DEPLOY_HOME}/ghcr-login.sh" <<'GHCR_SCRIPT'
#!/bin/bash
###############################################################################
# ghcr-login.sh
# Logs into GitHub Container Registry (GHCR) so this box can pull images
# from your private repo.
#
# BEFORE RUNNING THIS SCRIPT you need a GitHub Personal Access Token (PAT):
#
#   1. Go to https://github.com/settings/tokens/new
#   2. Note: name it something like "ghcr-deploy"
#   3. Expiration: 90 days is fine for a demo
#   4. Check these two scopes:
#        [x] read:packages
#        [x] write:packages
#   5. Click "Generate token"
#   6. COPY THE TOKEN before leaving the page. You cannot see it again.
#   7. Now run this script.
#
# Usage: bash /home/deploy/ghcr-login.sh
###############################################################################

echo ""
echo "============================================"
echo " GitHub Container Registry Login"
echo "============================================"
echo ""
echo "You need a GitHub Personal Access Token (PAT)."
echo "If you don't have one yet, create it first:"
echo ""
echo "  1. Go to: https://github.com/settings/tokens/new"
echo "  2. Name:  ghcr-deploy"
echo "  3. Scopes: read:packages, write:packages"
echo "  4. Generate and COPY the token"
echo ""
read -rp "GitHub username: " GH_USER
echo "Paste your GitHub PAT (it won't show on screen):"
read -rs GH_TOKEN
echo ""

echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin

if [[ $? -eq 0 ]]; then
    echo ""
    echo "Success. Docker is now logged into GHCR."
    echo "This login persists until you log out or the token expires."
else
    echo ""
    echo "Login failed. Check your username and token."
    exit 1
fi
GHCR_SCRIPT

chmod +x "${DEPLOY_HOME}/ghcr-login.sh"
chown "$DEPLOY_USER":"$DEPLOY_USER" "${DEPLOY_HOME}/ghcr-login.sh"

print_ok "GHCR login helper created at ${DEPLOY_HOME}/ghcr-login.sh"

###############################################################################
# DONE
###############################################################################
print_banner "DEPLOY TARGET READY"

echo -e "Installed:"
echo -e "  Docker:  $(docker --version | awk '{print $3}' | tr -d ',')"
echo -e "  Compose: $(docker compose version | awk '{print $NF}')"
echo -e "  User:    ${DEPLOY_USER}"
echo -e "  App dir: ${DEPLOY_HOME}/apps"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW} NEXT STEPS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e " ${CYAN}STEP 1: Create a GitHub repo (if you haven't already)${NC}"
echo -e "   Go to: https://github.com/new"
echo -e "   Make it private. Don't initialize with a README."
echo ""
echo -e " ${CYAN}STEP 2: Create a GitHub Personal Access Token for GHCR${NC}"
echo -e "   Go to: https://github.com/settings/tokens/new"
echo -e "   Name:  ghcr-deploy"
echo -e "   Scopes: read:packages, write:packages"
echo -e "   Generate it and COPY the token."
echo ""
echo -e " ${CYAN}STEP 3: Log this box into GHCR${NC}"
echo -e "   Run:  sudo -u deploy bash ${DEPLOY_HOME}/ghcr-login.sh"
echo -e "   Enter your GitHub username and paste the token from Step 2."
echo -e "   You only need to do this once."
echo ""
echo -e " ${CYAN}STEP 4: Verify Docker works${NC}"
echo -e "   Run:  sudo -u deploy docker run hello-world"
echo ""
echo -e " ${CYAN}STEP 5: After your pipeline passes, pull and run${NC}"
echo -e "   sudo -u deploy docker pull ghcr.io/YOUR_GITHUB_USER/YOUR_REPO/app-pass:latest"
echo -e "   sudo -u deploy docker run -d --name app-pass --restart unless-stopped -p 5000:5000 ghcr.io/YOUR_GITHUB_USER/YOUR_REPO/app-pass:latest"
echo -e "   curl http://localhost:5000"
echo ""
print_ok "Done."
