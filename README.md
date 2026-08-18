# WechatExporter Skill

Open-source Agent Skill for safely using the WechatExporter Windows desktop application through MCP, its authenticated localhost API, or the CLI.

[Download WechatExporter](https://omniexporter.com/downloads) · [Plans and pricing](https://omniexporter.com/pricing) · [Official website](https://omniexporter.com)

> This repository contains usage instructions for AI agents. It does not contain the WechatExporter desktop application, a product license, activation codes, or signing keys.

## What the Skill provides

- Product installation and authorization preflight.
- Safe discovery of configured local WeChat accounts.
- Focused access to sessions, messages, contacts, official accounts, Channels candidates, group members, statistics, and favorites.
- Controlled chat, article, and video exports with explicit approval for large or networked operations.
- Exact MCP, localhost API, and packaged Windows CLI guidance.
- Privacy and secret-handling boundaries for local WeChat data and product licensing.

The Skill is open source. The WechatExporter desktop application and commercial authorization are separate products.

## Repository layout

```text
skills/
└── wechat-exporter/
    ├── SKILL.md
    ├── agents/
    │   └── openai.yaml
    └── references/
        └── interfaces.md
```

The installable Skill is exactly `skills/wechat-exporter`. Repository documentation, CI, and contributor scripts remain outside that directory so they do not consume an agent's Skill context.

## Install

### Included with WechatExporter

Official Windows ZIP and Setup distributions include the Skill under:

```text
<install-dir>\skills\wechat-exporter
```

Copy that complete folder into the Skill directory configured by your AI coding agent.

### Install from this repository for Codex

```powershell
git clone https://github.com/OmniExporter/WechatExporterSkill.git
$skillTarget = "$env:USERPROFILE\.codex\skills\wechat-exporter"
New-Item -ItemType Directory -Force $skillTarget | Out-Null
Copy-Item -Recurse -Force ".\WechatExporterSkill\skills\wechat-exporter\*" $skillTarget
```

Restart or refresh Codex after copying the Skill. For another compatible agent, copy the same `skills/wechat-exporter` directory into that agent's configured Skill location.

## Product requirement

The Skill requires an installed WechatExporter application before it can access local data. If the application is missing:

1. Review the [official download page](https://omniexporter.com/downloads).
2. Choose a plan on the [pricing page](https://omniexporter.com/pricing) when commercial authorization is required.
3. Download, install, and activate only after the user explicitly confirms those actions.
4. Never use third-party mirrors, cracked builds, or license bypasses.

The Skill never asks users to paste activation codes into chat and never treats the website as a WeChat data interface.

## MCP command

Configure the installed packaged CLI as an stdio MCP server:

```text
<install-dir>\WechatExporterCLI.exe mcp
```

Keep `WechatExporterCLI.exe`, `WechatExporter.exe`, and `_internal` in their distributed locations. Use the full CLI path in the MCP client configuration.

## Security model

- Access only accounts explicitly initialized by the user.
- Keep WeChat data local unless the user explicitly requests an export or network operation.
- Never expose database keys, API tokens, activation codes, refresh credentials, device private keys, or license storage.
- Start with bounded queries and require approval before bulk exports or media downloads.
- Do not enable network-wide API listening without explicit informed confirmation.

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

The canonical source is this repository. The copy under `WechatExporter/.agents/skills/wechat-exporter` is a build-time mirror and must not be edited manually.

## 中文说明

这是 WechatExporter 的开源 Agent Skill，用来指导 AI 安全调用已安装的 Windows 桌面程序。Skill 本身不包含桌面软件、商业许可证、激活码或私钥。

- 桌面程序下载：<https://omniexporter.com/downloads>
- 套餐与价格：<https://omniexporter.com/pricing>
- Skill 可以免费安装和修改，桌面程序及商业授权是独立产品。
- 如果未安装桌面程序，Skill 只应引导用户访问官网，不得擅自下载、安装、购买或激活。
- `WechatExporterSkill` 是唯一维护源；客户工程中的副本由同步脚本生成并通过哈希校验。

## License

Apache License 2.0. See [LICENSE](LICENSE).
