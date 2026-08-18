# WechatExporter Skill

English | [简体中文](README.zh-CN.md)

An open-source Agent Skill that helps AI agents use the WechatExporter Windows desktop application safely through MCP, its authenticated localhost API, or the command-line interface.

[Download WechatExporter](https://omniexporter.com/downloads) · [Plans and pricing](https://omniexporter.com/pricing) · [Official website](https://omniexporter.com)

> This repository contains instructions for AI agents. It does not contain the WechatExporter desktop application, a product license, activation codes, or signing keys.

## What this Skill does

- Checks whether WechatExporter is installed, initialized, and authorized before accessing data.
- Discovers local WeChat accounts that the user has explicitly configured.
- Works with sessions, messages, contacts, official accounts, Channels candidates, group members, statistics, and favorites.
- Guides controlled exports of chats, articles, and videos.
- Provides exact guidance for MCP, the authenticated localhost API, and the packaged Windows CLI.
- Protects local WeChat data, application credentials, and licensing secrets.

The Skill is open source. The WechatExporter desktop application and its commercial authorization are separate products.

## Requirements

- Windows with the WechatExporter desktop application installed.
- A local WeChat account initialized in WechatExporter.
- A compatible AI agent that supports folder-based Skills.
- A valid product authorization when the requested feature or plan requires one.

If the application is not installed, visit the [official download page](https://omniexporter.com/downloads). Review [plans and pricing](https://omniexporter.com/pricing) when commercial authorization is required.

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
│       └── references/
│           └── interfaces.md
├── scripts/
│   ├── sync_client_mirror.py
│   └── validate_skill.py
└── README.zh-CN.md
```

The installable Skill is exactly `skills/wechat-exporter`. Repository documentation, CI configuration, and contributor scripts stay outside that directory so they do not consume an agent's Skill context.

## Development and validation

Validate the canonical Skill:

```powershell
python .\scripts\validate_skill.py
```

Check that the WechatExporter desktop repository contains the exact generated mirror and matching content hash:

```powershell
python .\scripts\sync_client_mirror.py --check
```

Update the client mirror after an intentional Skill change:

```powershell
python .\scripts\sync_client_mirror.py --write
```

This repository is the canonical source. The copy at `WechatExporter/.agents/skills/wechat-exporter` is a generated, hash-pinned build mirror and must not be edited manually.

## License

Apache License 2.0. See [LICENSE](LICENSE).
