#!/usr/bin/env python3
"""
VULNERABLE Flask Application - SQL Injection Lab
For educational/demonstration purposes only!

This app intentionally contains a SQL injection vulnerability.
DO NOT use this code in production!
"""

from flask import Flask, request, render_template
import sqlite3

app = Flask(__name__)

# Toggle this to show/hide the raw SQL query on screen
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
        # VULNERABLE CODE - Direct string concatenation
        # This is what you're demonstrating!
        # ============================================
        query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
        
        # Store query for debug display
        raw_query = query
        
        try:
            conn = sqlite3.connect('users.db')
            c = conn.cursor()
            c.execute(query)
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
        'login.html',
        message=message,
        message_type=message_type,
        raw_query=raw_query if DEBUG_MODE else None,
        debug_mode=DEBUG_MODE
    )


@app.route('/toggle-debug')
def toggle_debug():
    """Toggle debug mode to show/hide SQL queries"""
    global DEBUG_MODE
    DEBUG_MODE = not DEBUG_MODE
    from flask import redirect
    return redirect('/')


if __name__ == '__main__':
    print("\n" + "=" * 50)
    print("  SQL INJECTION LAB - VULNERABLE APP")
    print("  For educational purposes only!")
    print("=" * 50)
    print(f"\n[*] Debug mode: {'ON' if DEBUG_MODE else 'OFF'}")
    print("[*] Starting server on http://0.0.0.0:5000")
    print("[*] Press Ctrl+C to stop\n")
    
    # Bind to 0.0.0.0 so it's accessible from other machines if needed
    app.run(host='0.0.0.0', port=5000, debug=True)
