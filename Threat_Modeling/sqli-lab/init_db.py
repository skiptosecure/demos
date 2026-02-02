#!/usr/bin/env python3
"""
Database initialization script for SQL Injection Lab
Run this once before starting the app
"""

import sqlite3
import os

DB_PATH = 'users.db'

# Remove existing database if it exists
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
    print(f"[*] Removed existing {DB_PATH}")

# Create new database
conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

# Create users table
c.execute('''
    CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user'
    )
''')
print("[+] Created users table")

# Insert sample users
sample_users = [
    ('admin', 'supersecret123', 'admin'),
    ('jsmith', 'password456', 'user'),
    ('demo', 'demo123', 'user'),
]

for username, password, role in sample_users:
    c.execute(
        "INSERT INTO users (username, password, role) VALUES (?, ?, ?)",
        (username, password, role)
    )
    print(f"[+] Added user: {username}")

conn.commit()
conn.close()

print("\n[✓] Database initialized successfully!")
print(f"[i] Database file: {DB_PATH}")
print("\nTest credentials:")
print("  admin / supersecret123  (admin role)")
print("  jsmith / password456    (user role)")
print("  demo / demo123          (user role)")
