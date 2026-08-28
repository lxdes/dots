#!/usr/bin/env python3
"""Tests for suspend and hibernate functionality."""

import json
import subprocess
import sys
from pathlib import Path

TEST_DIR = Path.home() / ".local/state" / "quickshell"
SUSPEND_SCRIPT = TEST_DIR / "suspend-test.sh"
HIBERNATE_SCRIPT = TEST_DIR / "hibernate-test.sh"


def run_script(script_path, *args):
    """Run a shell script and return output."""
    cmd = [sys.executable, "-c", f'''
import subprocess, json, sys
try:
    result = subprocess.run(["sh", "{script_path}", {" ".join(args)}], capture_output=True, text=True)
    print(json.dumps({"code": result.returncode, "stdout": result.stdout, "stderr": result.stderr}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
    sys.exit(1)
''']
    return json.loads(subprocess.run(cmd, capture_output=True, text=True).stdout)


def test_suspend_check():
    """Test suspend availability check."""
    result = run_script(SUSPEND_SCRIPT)
    assert result is not None, "Script should return JSON"
    assert "available" in result, "Should check suspend availability"
    print("✓ test_suspend_check passed")


def test_hibernate_check():
    """Test hibernate availability check."""
    result = run_script(HIBERNATE_SCRIPT)
    assert result is not None, "Script should return JSON"
    assert "available" in result, "Should check hibernate availability"
    print("✓ test_hibernate_check passed")


def test_suspend_command_format():
    """Test suspend command format."""
    result = run_script(SUSPEND_SCRIPT, "check")
    assert result is not None
    assert result["available"] is True, "Suspend should be available"
    print("✓ test_suspend_command_format passed")


def test_hibernate_command_format():
    """Test hibernate command format."""
    result = run_script(HIBERNATE_SCRIPT, "check")
    assert result is not None
    # Hibernate may not be available on all systems
    assert "available" in result, "Should return availability status"
    print("✓ test_hibernate_command_format passed")


def test_script_permissions():
    """Test that scripts have execute permissions."""
    assert SUSPEND_SCRIPT.exists(), "Suspend script should exist"
    assert SUSPEND_SCRIPT.stat().st_mode & 0o111, "Suspend script should be executable"
    print("✓ test_script_permissions passed")


def test_output_format():
    """Test that output format is correct."""
    result = run_script(SUSPEND_SCRIPT)
    assert result is not None
    assert isinstance(result, dict), "Should return dict"
    assert "available" in result, "Should have 'available' key"
    print("✓ test_output_format passed")


def main():
    print("Running suspend/hibernate tests...")
    print(f"Test directory: {TEST_DIR}")
    
    try:
        test_script_permissions()
        test_suspend_check()
        test_hibernate_check()
        test_suspend_command_format()
        test_hibernate_command_format()
        test_output_format()
        
        print("\n✅ All tests passed!")
        return 0
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
