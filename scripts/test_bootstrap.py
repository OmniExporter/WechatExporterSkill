"""Smoke-test the installable Windows bootstrap without network or installation."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BOOTSTRAP = (
    REPO_ROOT
    / "skills"
    / "wechat-exporter"
    / "scripts"
    / "bootstrap_windows.ps1"
)


def powershell() -> str:
    executable = shutil.which("powershell") or shutil.which("pwsh")
    if not executable:
        raise unittest.SkipTest("PowerShell is unavailable")
    return executable


class BootstrapSmokeTests(unittest.TestCase):
    def run_bootstrap(self, *arguments: str) -> dict[str, object]:
        process = subprocess.run(
            [
                powershell(),
                "-NoLogo",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(BOOTSTRAP),
                *arguments,
            ],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8-sig",
            timeout=30,
        )
        self.assertEqual(process.returncode, 0, process.stderr or process.stdout)
        return json.loads(process.stdout)

    def test_detects_explicit_client_and_writes_reusable_project_hint(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            install = root / "installed client"
            project = root / "project"
            install.mkdir()
            project.mkdir()
            cli = install / "WechatExporterCLI.cmd"
            cli.write_text(
                "@echo off\n"
                'if "%~1"=="--version" (echo WechatExporter 9.9.9& exit /b 0)\n'
                'if "%~1"=="license" (echo '
                '{"state":"missing","valid":false,"edition":null,'
                '"message":"Activation required"}& exit /b 0)\n'
                "exit /b 1\n",
                encoding="ascii",
            )
            (install / "WechatExporter.exe").write_bytes(b"test-placeholder")

            first = self.run_bootstrap(
                "-CliPath",
                str(cli),
                "-ProjectRoot",
                str(project),
                "-ConfigureProject",
            )
            self.assertEqual(first["status"], "authorization_required")
            self.assertEqual(first["source"], "explicit")
            self.assertEqual(first["trialPolicy"]["durationDays"], 7)
            self.assertTrue(first["trialPolicy"]["accountRequired"])
            config_path = Path(str(first["projectConfigPath"]))
            self.assertTrue(config_path.is_file())

            configuration = json.loads(config_path.read_text(encoding="utf-8"))
            self.assertEqual(configuration["generatedBy"], "wechat-exporter-skill")
            self.assertEqual(configuration["mcp"]["command"], str(cli.resolve()))
            self.assertEqual(configuration["mcp"]["args"], ["mcp"])

            second = self.run_bootstrap("-ProjectRoot", str(project))
            self.assertEqual(second["status"], "authorization_required")
            self.assertEqual(second["source"], "project-config")
            self.assertEqual(second["cliPath"], str(cli.resolve()))

    def test_rejects_non_official_manifest_download_url(self):
        command = (
            f'. "{BOOTSTRAP}"; '
            "$copy = $script:FallbackManifest.PSObject.Copy(); "
            "$copy.downloadUrl = 'https://example.com/client.exe'; "
            "try { Normalize-ReleaseManifest $copy | Out-Null; exit 1 } "
            "catch { exit 0 }"
        )
        process = subprocess.run(
            [powershell(), "-NoLogo", "-NoProfile", "-Command", command],
            check=False,
            capture_output=True,
            text=True,
            timeout=30,
        )
        self.assertEqual(process.returncode, 0, process.stderr or process.stdout)


if __name__ == "__main__":
    unittest.main()
