Lab Requirements
What you need:

Rocky Linux 9 (minimal install is fine)
4 GB RAM
Internet connection (for package installs)

Setup:
Run updates first, then the setup script handles everything else —
Python 3, Flask, SQLite, and the vulnerable app files.
bashsudo dnf update -y
chmod +x setup_rocky9.sh
./setup_rocky9.sh
python3 init_db.py
python3 app.py
Five commands. You're up and running.
