#!/usr/bin/env python3
"""
CopyQ integration helper for Quickshell.
Provides fast JSON retrieval of CopyQ clipboard items, item selection, and deletion.
"""
import sys
import subprocess
import json

def fetch_history(limit=80):
    eval_script = f'''
    var out = [];
    var n = Math.min({limit}, count());
    for (var i = 0; i < n; ++i) {{
        var text = str(read("text/plain", i));
        if (text && text.trim().length > 0) {{
            out.push({{"row": i, "text": text}});
        }}
    }}
    print(JSON.stringify(out));
    '''
    try:
        res = subprocess.check_output(['copyq', 'eval', eval_script], text=True, timeout=2)
        print(res.strip())
    except Exception:
        print("[]")

def select_item(row):
    try:
        subprocess.run(['copyq', 'select', str(row)], check=True)
    except Exception:
        pass

def delete_item(row):
    try:
        subprocess.run(['copyq', 'remove', str(row)], check=True)
    except Exception:
        pass

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    if action == 'list':
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 80
        fetch_history(limit)
    elif action == 'select' and len(sys.argv) > 2:
        select_item(sys.argv[2])
    elif action == 'delete' and len(sys.argv) > 2:
        delete_item(sys.argv[2])
