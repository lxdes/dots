import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "privacy-status.sh"


class PrivacyStatusTests(unittest.TestCase):
    def run_script(self, *, pactl_output="", recording_process="", screen_share=False):
        with tempfile.TemporaryDirectory() as directory:
            bin_dir = Path(directory)
            stubs = {
                "pactl": """#!/bin/sh
if [ "$1 $2" = "list source-outputs" ]; then
    printf '%s' "$PACTL_OUTPUT"
elif [ "$1 $2 $3" = "list short source-outputs" ]; then
    printf '%s' "$PACTL_SHORT_OUTPUT"
fi
""",
                "pgrep": """#!/bin/sh
[ -n "$RECORDING_PROCESS" ] && [ "$2" = "$RECORDING_PROCESS" ]
""",
                "pw-dump": """#!/bin/sh
printf '%s\n' '[{"info":{"props":{"media.name":"screen-cast"}}}]'
""",
                "jq": """#!/bin/sh
cat >/dev/null
[ "$SCREEN_SHARE" = 1 ]
""",
            }
            for name, contents in stubs.items():
                path = bin_dir / name
                path.write_text(contents)
                path.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{bin_dir}:/usr/bin:/bin",
                    "PACTL_OUTPUT": pactl_output,
                    "PACTL_SHORT_OUTPUT": "",
                    "RECORDING_PROCESS": recording_process,
                    "SCREEN_SHARE": "1" if screen_share else "0",
                }
            )
            completed = subprocess.run(
                ["/bin/sh", str(SCRIPT)],
                check=True,
                capture_output=True,
                text=True,
                env=env,
            )
        return json.loads(completed.stdout)

    def test_reports_active_and_corked_microphones_recording_and_screen_share(self):
        result = self.run_script(
            pactl_output=(
                "Source Output #10\n    Corked: no\n"
                "Source Output #11\n    Corked: yes\n"
            ),
            recording_process="obs",
            screen_share=True,
        )

        self.assertEqual(
            result,
            {
                "microphoneActive": True,
                "recordingProcess": True,
                "screenShareActive": True,
                "microphoneCorked": True,
            },
        )

    def test_idle_stubs_report_no_privacy_activity(self):
        self.assertEqual(
            self.run_script(),
            {
                "microphoneActive": False,
                "recordingProcess": False,
                "screenShareActive": False,
                "microphoneCorked": False,
            },
        )


if __name__ == "__main__":
    unittest.main()
