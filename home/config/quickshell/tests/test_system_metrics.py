import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "system-metrics.sh"


class SystemMetricsTests(unittest.TestCase):
    def write(self, root, relative, contents):
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)
        return path

    def run_script(self, proc_root, sys_root, after_stat=None):
        bin_dir = proc_root.parent / "bin"
        bin_dir.mkdir()
        sleep = bin_dir / "sleep"
        sleep.write_text(
            "#!/bin/sh\n"
            "if [ -n \"$AFTER_STAT\" ]; then printf '%s\\n' \"$AFTER_STAT\" >\"$TEST_STAT\"; fi\n"
        )
        sleep.chmod(0o755)
        nvidia = bin_dir / "nvidia-smi"
        nvidia.write_text("#!/bin/sh\nexit 1\n")
        nvidia.chmod(0o755)

        env = os.environ.copy()
        env.update(
            {
                "PATH": f"{bin_dir}:/usr/bin:/bin",
                "PROC_ROOT": str(proc_root),
                "SYS_ROOT": str(sys_root),
                "TEST_STAT": str(proc_root / "stat"),
                "AFTER_STAT": after_stat or "",
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

    def test_metrics_come_only_from_fixture_roots(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            proc_root = root / "proc"
            sys_root = root / "sys"
            self.write(proc_root, "stat", "cpu 100 0 100 800 0\n")
            self.write(
                proc_root,
                "meminfo",
                "MemTotal:       1000 kB\nMemAvailable:    250 kB\n",
            )
            self.write(sys_root, "class/hwmon/hwmon0/name", "coretemp\n")
            self.write(sys_root, "class/hwmon/hwmon0/temp1_input", "55000\n")
            self.write(sys_root, "class/hwmon/hwmon0/temp1_label", "CPU\n")
            self.write(sys_root, "class/hwmon/hwmon1/name", "other\n")
            self.write(sys_root, "class/hwmon/hwmon1/temp1_input", "70000\n")
            self.write(sys_root, "class/hwmon/hwmon1/temp1_label", "Package id 1\n")
            self.write(
                sys_root, "class/drm/card0/device/gpu_busy_percent", "37\n"
            )
            self.write(
                sys_root, "class/drm/card1/device/gpu_busy_percent", "82\n"
            )
            self.write(
                sys_root,
                "devices/system/cpu/cpufreq/policy0/energy_performance_preference",
                "performance\n",
            )

            result = self.run_script(
                proc_root, sys_root, after_stat="cpu 150 0 150 850 0"
            )

        self.assertEqual(
            result,
            {
                "cpuPercent": 66.7,
                "memoryPercent": 75.0,
                "temperatureC": 55.0,
                "gpuPercent": 82,
                "powerProfile": "performance",
            },
        )

    def test_missing_fixture_data_returns_null_metrics(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            proc_root = root / "proc"
            sys_root = root / "sys"
            proc_root.mkdir()
            sys_root.mkdir()

            result = self.run_script(proc_root, sys_root)

        self.assertEqual(
            result,
            {
                "cpuPercent": None,
                "memoryPercent": None,
                "temperatureC": None,
                "gpuPercent": None,
                "powerProfile": "unknown",
            },
        )


if __name__ == "__main__":
    unittest.main()
