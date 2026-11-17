#!/usr/bin/env python3
"""Count error lines in a log file and print a summary."""
import os
import sys

LOG_FILE = os.environ.get("LOG_FILE", "/var/log/nginx/error.log")
API_TOKEN = os.environ.get("API_TOKEN")  # simulated secret, never hardcoded

def main() -> int:
    if not API_TOKEN:
        print("API_TOKEN is not set. Export it or put it in the env file.", file=sys.stderr)
        return 1
    try:
        with open(LOG_FILE, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Log file not found: {LOG_FILE}", file=sys.stderr)
        return 1
    except PermissionError:
        print(f"No permission to read: {LOG_FILE}", file=sys.stderr)
        return 1

    errors = sum(1 for line in lines if "error" in line.lower())
    print(f"File: {LOG_FILE}")
    print(f"Lines: {len(lines)}")
    print(f"ERROR lines: {errors}")
    print(f"Token loaded: yes (ends in ...{API_TOKEN[-4:]})")
    return 0

if __name__ == "__main__":
    sys.exit(main())


