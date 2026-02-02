#!/usr/bin/env python3
"""
SECURE Flask Application - SQL Injection Lab
This version uses parameterized queries to prevent SQL injection.

Compare this to app.py to see the fix!
"""

from flask import Flask, request, render_template
import sqlite3

app = Flask(__name__)

DEBUG_MODE = True


@app.route('/', methods=['GET', 'POST'])
def login():
    message = ""
    message_type = ""
    raw_query = ""
    
    if request.method == 'POST':
        username = request.form.get('username', '')
        password = request.form.get('password', '')
        
        # ============================================
        # SECURE CODE - Parameterized query
        # The ? placeholders prevent SQL injection!
        # ============================================
        query = "SELECT * FROM users WHERE username = ? AND password = ?"
        params = (username, password)
        
        # For debug display, show what the query looks like
        raw_query = f"{query}\nParameters: {params}"
        
        try:
            conn = sqlite3.connect('users.db')
            c = conn.cursor()
            
            # Parameters are passed separately - never concatenated!
            c.execute(query, params)
            user = c.fetchone()
            conn.close()
            
            if user:
                message = f"✓ Welcome, {user[1]}! You're logged in as {user[3]}."
                message_type = "success"
            else:
                message = "✗ Invalid credentials."
                message_type = "error"
                
        except sqlite3.Error as e:
            message = f"Database error: {e}"
            message_type = "error"
    
    return render_template(
        'login_secure.html',
        message=message,
        message_type=message_type,
        raw_query=raw_query if DEBUG_MODE else None,
        debug_mode=DEBUG_MODE
    )


@app.route('/toggle-debug')
def toggle_debug():
    global DEBUG_MODE
    DEBUG_MODE = not DEBUG_MODE
    from flask import redirect
    return redirect('/')


if __name__ == '__main__':
    print("\n" + "=" * 50)
    print("  SQL INJECTION LAB - SECURE APP")
    print("  Using parameterized queries!")
    print("=" * 50)
    print(f"\n[*] Debug mode: {'ON' if DEBUG_MODE else 'OFF'}")
    print("[*] Starting server on http://0.0.0.0:5000")
    print("[*] Press Ctrl+C to stop\n")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
