# Client bootstrap and commercial authorization handoff

## Default read-only detection

On Windows, run the bundled script without installation flags:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>\scripts\bootstrap_windows.ps1" -ProjectRoot "<repository-root>"
```

The script emits one JSON document. It checks only bounded locations: an explicit CLI path, `.wechat-exporter/client.local.json`, the Skill's packaged-client parent, `PATH`, WechatExporter uninstall entries, and standard per-user/program installation directories. It does not crawl drives or inspect WeChat data.

Important states:

- `ready`: client and product authorization are available.
- `authorization_required`: the client is installed, but the user must finish authorization in the GUI and official website.
- `not_installed` with exit code `10`: ask before downloading or running anything.
- `unsigned_consent_required` with exit code `12`: explain the unsigned-installer risk and wait for explicit acceptance.
- `downloaded`: a verified installer was downloaded with `-DownloadOnly` but was not executed.
- `installation_not_detected`: installation completed but the CLI was not found; ask for the exact `WechatExporterCLI.exe` path.
- `error`: report the returned `nextActions` message without exposing unrelated local state.

## Consent-based install

Only after the user approves the official download and interactive installation, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>\scripts\bootstrap_windows.ps1" `
  -ProjectRoot "<repository-root>" `
  -Install `
  -ConfigureProject `
  -Launch
```

If the returned manifest says `unsigned`, explain that Windows may show an unknown-publisher warning. Add `-AcceptUnsignedInstaller` only after the user explicitly accepts that risk. Do not add this flag pre-emptively. When the official manifest says `authenticode`, the script requires a valid Authenticode signature and the unsigned-risk flag is unnecessary.

The script performs these steps:

1. Fetch `https://omniexporter.com/api/downloads/windows/manifest` without following redirects. If that endpoint is not yet available, use the embedded hash-pinned official 0.4.3 fallback.
2. Accept only the version-bound official URL `https://omniexporter.com/api/downloads/windows?version=<manifest-version>` as the installer URL.
3. Download into the user's product-specific local cache, without following redirects.
4. Verify exact byte size, the full SHA-256 digest, and the signature state declared by the manifest.
5. Start the normal interactive installer and wait for it to finish. Never use silent switches.
6. Detect `WechatExporter.exe` and its sibling `WechatExporterCLI.exe` again.
7. Optionally write the project hint and launch the GUI.

Use `-DownloadOnly -AcceptUnsignedInstaller` instead of `-Install` when the user approves acquisition but wants to execute the verified installer manually. `-Install` and `-DownloadOnly` are mutually exclusive.

## Project-local configuration

`-ConfigureProject` writes `.wechat-exporter/client.local.json` atomically. It contains no account credentials, license material, activation codes, API tokens, WeChat database keys, or user data. Its machine-local absolute paths make it unsuitable for routine commits.

The useful fields are:

```json
{
  "schemaVersion": 1,
  "generatedBy": "wechat-exporter-skill",
  "cliPath": "C:\\...\\WechatExporterCLI.exe",
  "guiPath": "C:\\...\\WechatExporter.exe",
  "mcp": {
    "transport": "stdio",
    "command": "C:\\...\\WechatExporterCLI.exe",
    "args": ["mcp"]
  }
}
```

The script refuses to overwrite a file it did not generate. On later runs it checks this hint before registry or standard-location discovery.

## Authorization and conversion handoff

Installation is not authorization. When the state is `authorization_required`:

1. Launch `WechatExporter.exe` and direct the user to **Activate with account**.
2. The GUI opens the official site at <https://omniexporter.com>. The user registers or signs in there; the Skill never asks for passwords, activation codes, or browser credentials.
3. An eligible signed-in user may explicitly choose the 7-day trial. Trial eligibility is tied to both account and hardware: registration/sign-in is required, and the same hardware cannot obtain another trial by changing accounts or reinstalling.
4. If the user is not eligible or needs longer access, direct them to <https://omniexporter.com/pricing>.
5. Wait for the desktop client to receive and store its refresh credential, then rerun the default detection or `WechatExporterCLI.exe license status --json-output`.
6. After authorization, initialize the intended local WeChat account before invoking data tools.

Do not automatically open checkout, create a trial, select a license, submit website forms, or retry authorization requests aggressively. The user must make commercial decisions and browser confirmations. A `429` response is a backoff signal, not proof that authorization failed; wait for the server-provided delay and refresh the existing device authorization instead of creating duplicates.
