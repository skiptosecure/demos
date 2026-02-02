#!/bin/bash
# Rocky Linux 9 Setup Script for SQL Injection Lab
# "Build & Break Live" Demo Environment

set -e

echo "=========================================="
echo "  SQL Injection Lab - Rocky 9 Setup"
echo "=========================================="

# Update system
echo "[1/5] Updating system packages..."
sudo dnf update -y

# Install Python 3 and pip
echo "[2/5] Installing Python 3 and development tools..."
sudo dnf install -y python3 python3-pip python3-devel

# Install Flask
echo "[3/5] Installing Flask..."
pip3 install --user flask

# Create lab directory structure
echo "[4/5] Creating lab directory structure..."
mkdir -p ~/sqli-lab/templates

# Verify installation
echo "[5/5] Verifying installation..."
python3 --version
pip3 show flask

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. cd ~/sqli-lab"
echo "  2. python3 init_db.py     # Create the database"
echo "  3. python3 app.py         # Start the vulnerable app"
echo "  4. Open http://localhost:5000 in your browser"
echo ""
echo "Attack payload to demo:"
echo "  Username: ' OR '1'='1' --"
echo "  Password: (anything)"
echo ""
