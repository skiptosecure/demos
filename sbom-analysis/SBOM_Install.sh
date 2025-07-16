#!/bin/bash
#
# SBOM Tools Installation Script for Rocky Linux
# Installs: Syft, Grype, Trivy, Git
#

set -e

echo "Installing SBOM tools..."

# Update system and install basics
sudo dnf update -y
sudo dnf install -y git curl wget

# Install Syft
echo "Installing Syft..."
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin

# Install Grype
echo "Installing Grype..."
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin

# Install Trivy
echo "Installing Trivy..."
sudo tee /etc/yum.repos.d/trivy.repo << 'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF

sudo dnf install -y trivy

# Add /usr/local/bin to PATH if not already there
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    export PATH="/usr/local/bin:$PATH"
fi

# Configure SELinux if enabled
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo "Configuring SELinux..."
    sudo setsebool -P allow_execheap on
    sudo restorecon -Rv /usr/local/bin/
fi

# Verify installations
echo "Verifying installations..."
syft version
grype version  
trivy version
git --version

echo "Installation complete!"
echo "Tools installed: syft, grype, trivy, git"