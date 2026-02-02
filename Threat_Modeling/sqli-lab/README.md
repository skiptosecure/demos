# SQL Injection Lab - Build & Break Live

A simple vulnerable login application for demonstrating SQL injection attacks and their remediation.

## Rocky Linux 9 Setup

### Quick Start (Copy & Paste)

```bash
# 1. Install dependencies
sudo dnf install -y python3 python3-pip

# 2. Install Flask
pip3 install --user flask

# 3. Add local bin to PATH (for Flask)
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc

# 4. Create and enter lab directory
mkdir -p ~/sqli-lab/templates
cd ~/sqli-lab
```

### Or Use the Setup Script

```bash
chmod +x setup_rocky9.sh
./setup_rocky9.sh
```

---

## Running the Lab

### Step 1: Initialize the Database

```bash
cd ~/sqli-lab
python3 init_db.py
```

This creates `users.db` with sample accounts:
| Username | Password        | Role  |
|----------|-----------------|-------|
| admin    | supersecret123  | admin |
| jsmith   | password456     | user  |
| demo     | demo123         | user  |

### Step 2: Start the Vulnerable App

```bash
python3 app.py
```

Open your browser to: **http://localhost:5000** (or your server IP)

---

## The Demo

### Normal Login Flow
1. Enter `admin` / `supersecret123`
2. Shows: "Welcome, admin! You're logged in as admin."

### SQL Injection Attack
1. In the **Username** field, enter:
   ```
   ' OR '1'='1' --
   ```
2. In the **Password** field, enter anything (or leave blank)
3. Click **Sign In**
4. You're logged in as admin without knowing the password!

### What's Happening?

The vulnerable query:
```sql
SELECT * FROM users WHERE username = '' OR '1'='1' --' AND password = ''
```

- `' OR '1'='1'` — Always evaluates to TRUE
- `--` — Comments out the rest of the query (password check)

### Show the Fix

Stop the vulnerable app (`Ctrl+C`) and start the secure version:

```bash
python3 app_secure.py
```

Try the same attack — it fails! The parameterized query treats the input as a literal string, not SQL code.

---

## File Structure

```
sqli-lab/
├── app.py              # Vulnerable application
├── app_secure.py       # Fixed/secure version
├── init_db.py          # Database setup script
├── users.db            # SQLite database (created by init_db.py)
├── setup_rocky9.sh     # Rocky 9 setup script
├── README.md           # This file
└── templates/
    ├── login.html          # Vulnerable app template (red theme)
    └── login_secure.html   # Secure app template (green theme)
```

---

## Video Recording Tips

1. **Debug Mode**: The raw SQL query displays on-screen. Toggle it with the link at the bottom.

2. **Color Coding**: 
   - Vulnerable app = Red/orange theme
   - Secure app = Green theme

3. **Suggested Flow**:
   - Show normal login working
   - Show invalid login failing
   - Type the injection payload slowly
   - Point out the debug panel showing the malformed query
   - Switch to secure app
   - Try same attack — fails
   - Show the one-line code difference

4. **Payloads to Try**:
   ```
   ' OR '1'='1' --
   ' OR '1'='1' /*
   admin' --
   ' UNION SELECT 1,2,3,4 --
   ```

---

## Firewall (if accessing remotely)

```bash
# Open port 5000 temporarily
sudo firewall-cmd --add-port=5000/tcp

# Or permanently
sudo firewall-cmd --add-port=5000/tcp --permanent
sudo firewall-cmd --reload
```

---

## Cleanup

```bash
# Stop the app
Ctrl+C

# Remove the database
rm users.db

# Remove everything
rm -rf ~/sqli-lab
```

---

## ⚠️ Warning

This application is **intentionally vulnerable**. Use only in:
- Isolated lab environments
- Local development machines
- Controlled demo/training scenarios

**Never expose to the internet or use with real data.**
