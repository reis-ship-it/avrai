#!/usr/bin/env python3
"""
Script to create a user in Supabase via REST API

Usage:
    python3 scripts/create_supabase_user.py <email> <password> [name]

Example:
    python3 scripts/create_supabase_user.py reis@avrai.org avrai "Reis Gordon"
"""

import sys
import json
import requests
from typing import Optional

# Supabase configuration - loaded from environment or .env file
import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env from project root
_env_path = Path(__file__).parent.parent / '.env'
if _env_path.exists():
    load_dotenv(_env_path)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "")

if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env or environment")
    sys.exit(1)


def create_user(email: str, password: str, name: Optional[str] = None) -> dict:
    """Create a user in Supabase"""
    if not name:
        name = email.split('@')[0]
    
    url = f"{SUPABASE_URL}/auth/v1/signup"
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    payload = {
        "email": email,
        "password": password,
        "data": {
            "name": name
        }
    }
    
    print(f"\n{'=' * 60}")
    print("Creating Supabase User")
    print(f"{'=' * 60}")
    print(f"\nEmail: {email}")
    print(f"Name: {name}")
    print(f"Password: {'*' * len(password)}\n")
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        result = response.json()
        
        if "user" in result and result["user"]:
            user = result["user"]
            print("✅ User created successfully!")
            print(f"   User ID: {user.get('id', 'N/A')}")
            print(f"   Email: {user.get('email', 'N/A')}")
            print(f"   Email Confirmed: {user.get('email_confirmed_at') is not None}")
            
            if user.get('email_confirmed_at') is None:
                print("\n⚠️  WARNING: Email confirmation required")
                print("   The user will need to confirm their email before they can sign in.")
                print("   You can confirm the email in the Supabase dashboard:")
                print("   Authentication → Users → Find user → Confirm email")
            
            print(f"\n{'=' * 60}")
            print("✅ SUCCESS: User created")
            print(f"{'=' * 60}")
            print(f"\nYou can now sign in with:")
            print(f"  Email: {email}")
            print(f"  Password: {password}\n")
            
            return result
        else:
            print("❌ ERROR: User creation failed - no user returned")
            print(f"   Response: {json.dumps(result, indent=2)}")
            return None
            
    except requests.exceptions.HTTPError as e:
        error_data = {}
        try:
            error_data = e.response.json()
        except:
            error_data = {"message": str(e)}
        
        print(f"❌ ERROR: Failed to create user")
        print(f"   Status: {e.response.status_code}")
        print(f"   Error: {json.dumps(error_data, indent=2)}")
        
        error_msg = str(error_data.get("message", "")).lower()
        if "user already registered" in error_msg or "email already exists" in error_msg:
            print("\nℹ️  This email is already registered.")
            print("   Try signing in instead, or use a different email.")
        elif "password" in error_msg and "weak" in error_msg:
            print("\nℹ️  Password is too weak.")
            print("   Supabase requires stronger passwords.")
        elif "rate limit" in error_msg or "over_email_send_rate_limit" in error_msg:
            print("\nℹ️  Rate limit exceeded.")
            print("   Wait a few minutes and try again.")
        
        return None
    except Exception as e:
        print(f"❌ ERROR: Unexpected error: {e}")
        return None


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 scripts/create_supabase_user.py <email> <password> [name]")
        print("\nExample:")
        print('  python3 scripts/create_supabase_user.py reis@avrai.org avrai "Reis Gordon"')
        sys.exit(1)
    
    email = sys.argv[1]
    password = sys.argv[2]
    name = sys.argv[3] if len(sys.argv) > 3 else None
    
    result = create_user(email, password, name)
    
    if result is None:
        sys.exit(1)


if __name__ == "__main__":
    main()
