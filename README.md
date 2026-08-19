# WechatExporter Skill

English | [简体中文](README.zh-CN.md)

An open-source Agent Skill that helps AI agents use the WechatExporter Windows desktop application safely through MCP, its authenticated localhost API, or the command-line interface.

[Download WechatExporter](https://omniexporter.com/downloads) · [Plans and pricing](https://omniexporter.com/pricing) · [Official website](https://omniexporter.com)

> This repository contains instructions for AI agents. It does not contain the WechatExporter desktop application, a product license, activation codes, or signing keys.

## What this Skill does

- Checks whether WechatExporter is installed, initialized, and authorized before accessing data.
- Detects the official Windows client in bounded locations and, after explicit consent, downloads, verifies, and starts its interactive installer.
- Writes a non-secret project-local MCP hint so an agent can reuse the exact packaged CLI path.
- Discovers local WeChat accounts that the user has explicitly configured.
- Works with sessions, messages, contacts, official accounts, Channels candidates, group members, statistics, and favorites.
- Guides controlled exports of chats, articles, and videos.
- Provides exact guidance for MCP, the authenticated localhost API, and the packaged Windows CLI.
- Protects local WeChat data, application credentials, and licensing secrets.

The Skill is open source. The WechatExporter desktop application and its commercial authorization are separate products.

## Requirements

- Windows x64. The Skill can assist with installing the WechatExporter desktop application when it is missing.
- A local WeChat account initialized in WechatExporter.
- A compatible AI agent that supports folder-based Skills.
- A valid product authorization when the requested feature or plan requires one.

If the application is not installed, the Skill can use the verified official bootstrap below. You can also visit the [official download page](https://omniexporter.com/downloads). Review [plans and pricing](https://omniexporter.com/pricing) when commercial authorization is required.

## Install the Skill

### Option 1: Use the copy included with WechatExporter

Official Windows ZIP and Setup distributions include the Skill at:

```text
<install-dir>\skills\wechat-exporter
```

Copy the complete `wechat-exporter` folder into the Skill directory configured by your AI agent.

### Option 2: Install from GitHub for Codex

```powershell
git clone https://github.com/OmniExporter/WechatExporterSkill.git
$skillTarget = Join-Path $env:USERPROFILE ".codex\skills\wechat-exporter"
New-Item -ItemType Directory -Force $skillTarget | Out-Null
Copy-Item -Recurse -Force ".\WechatExporterSkill\skills\wechat-exporter\*" $skillTarget
```

Restart or refresh Codex after copying the Skill. For another compatible agent, copy the same `skills/wechat-exporter` folder into that agent's configured Skill location.

## Bootstrap the Windows client

Detection is read-only and emits JSON:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\skills\wechat-exporter\scripts\bootstrap_windows.ps1" `
  -ProjectRoot "$PWD"
```

If it reports `not_installed`, an agent must explain the download and ask before continuing. After approval, it can run the official interactive installer, detect the result, write `.wechat-exporter/client.local.json`, and open the client:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\skills\wechat-exporter\scripts\bootstrap_windows.ps1" `
  -ProjectRoot "$PWD" `
  -Install `
  -ConfigureProject `
  -Launch
```

The current official installer is unsigned. Add `-AcceptUnsignedInstaller` only after the user explicitly accepts the Windows unknown-publisher risk. Before execution, the script restricts acquisition to `omniexporter.com` and verifies the official manifest, exact size, full SHA-256 digest, and declared signature state. It does not use silent installation switches.

The generated `client.local.json` contains machine-local absolute paths and no secrets. Do not commit it unless that machine-specific configuration is intentional.

## Connect through MCP

Configure the packaged CLI as a local stdio MCP server:

```text
<install-dir>\WechatExporterCLI.exe mcp
```

Keep `WechatExporterCLI.exe`, `WechatExporter.exe`, and the `_internal` directory in their distributed locations. Use the full CLI path in your MCP client configuration.

## Example requests

- “Use WechatExporter to check whether my local setup is ready.”
- “List the WeChat accounts I have initialized and show recent sessions.”
- “Search my local messages for this keyword within the last month.”
- “Export this selected chat after showing me the scope and destination.”

The agent should begin with bounded, read-only queries. It must ask for confirmation before large exports, media downloads, installation, activation, purchases, or other networked operations.

## Security and privacy

- Access only accounts explicitly initialized by the user.
- Keep WeChat data local unless the user explicitly requests an export or network operation.
- Never expose database keys, API tokens, activation codes, refresh credentials, device private keys, or license storage.
- Never ask the user to paste an activation code into chat.
- Never use third-party mirrors, cracked builds, or license bypasses.
- Never download or start the installer without user confirmation; never pre-accept the unsigned-package risk for another user.
- Never register, sign in, start a trial, or purchase on the user's behalf. The eligible trial is 7 days, requires an account, and is limited to one claim per hardware device even across accounts.
- Do not enable network-wide API listening without explicit, informed confirmation.
- Treat the OmniExporter website as the official product and account portal, not as a WeChat data interface.

## Repository layout

```text
WechatExporterSkill/
├── skills/
│   └── wechat-exporter/
│       ├── SKILL.md
│       ├── agents/
│       │   └── openai.yaml
│       ├── scripts/
│       │   └── bootstrap_windows.ps1
│       └── references/
│           ├── api.md
│           ├── cli.md
│           ├── interfaces.md
│           ├── mcp.md
│           └── setup.md
├── scripts/
│   ├── sync_client_mirror.py
│   ├── test_bootstrap.py
│   └── validate_skill.py
└── README.zh-CN.md
```

The installable Skill is exactly `skills/wechat-exporter`. Repository documentation, CI configuration, and contributor scripts stay outside that directory so they do not consume an agent's Skill context.

## Development and validation

Validate the canonical Skill:

```powershell
python .\scripts\validate_skill.py
```

Run the offline bootstrap smoke tests (they do not download or install anything):

```powershell
python .\scripts\test_bootstrap.py
```

Check CLI/MCP/API documentation parity and verify that the desktop repository contains the exact generated mirror and matching content hash:

```powershell
python .\scripts\sync_client_mirror.py --check
```

Update the client mirror after an intentional Skill change:

```powershell
python .\scripts\sync_client_mirror.py --write
```

This repository is the canonical source. The copy at `WechatExporterWinClient-py/.agents/skills/wechat-exporter` is a generated, hash-pinned build mirror and must not be edited manually.

## License

Apache License 2.0. See [LICENSE](LICENSE).
