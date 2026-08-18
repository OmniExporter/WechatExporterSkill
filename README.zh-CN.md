# WechatExporter Skill

[English](README.md) | 简体中文

这是一个开源的 Agent Skill，用于指导 AI 助手通过 MCP、经过身份验证的本地 API 或命令行接口，安全地使用 WechatExporter Windows 桌面程序。

[下载 WechatExporter](https://omniexporter.com/downloads) · [套餐与价格](https://omniexporter.com/pricing) · [官方网站](https://omniexporter.com)

> 本仓库只包含供 AI 助手使用的操作说明，不包含 WechatExporter 桌面程序、产品许可证、激活码或签名密钥。

## Skill 可以做什么

- 在访问数据前检查 WechatExporter 是否已经安装、初始化并获得授权。
- 发现用户明确配置过的本地微信账号。
- 查询会话、消息、联系人、公众号、视频号候选数据、群成员、统计信息和收藏数据。
- 指导用户以可控方式导出聊天记录、文章和视频。
- 提供准确的 MCP、本地认证 API 和 Windows 命令行调用说明。
- 保护本地微信数据、应用凭据和许可证相关机密。

Skill 本身是开源的；WechatExporter 桌面程序及其商业授权是独立产品。

## 使用要求

- Windows 系统，并已安装 WechatExporter 桌面程序。
- 已在 WechatExporter 中初始化至少一个本地微信账号。
- 支持文件夹形式 Skill 的 AI 助手。
- 所使用的功能或套餐需要商业授权时，具备有效的产品授权。

如果尚未安装桌面程序，请访问[官方下载页面](https://omniexporter.com/downloads)。需要商业授权时，可查看[套餐与价格](https://omniexporter.com/pricing)。

## 安装 Skill

### 方式一：使用 WechatExporter 自带的 Skill

官方 Windows ZIP 压缩包和安装程序均在以下位置包含 Skill：

```text
<安装目录>\skills\wechat-exporter
```

将完整的 `wechat-exporter` 文件夹复制到 AI 助手配置的 Skill 目录中。

### 方式二：从 GitHub 安装到 Codex

```powershell
git clone https://github.com/OmniExporter/WechatExporterSkill.git
$skillTarget = Join-Path $env:USERPROFILE ".codex\skills\wechat-exporter"
New-Item -ItemType Directory -Force $skillTarget | Out-Null
Copy-Item -Recurse -Force ".\WechatExporterSkill\skills\wechat-exporter\*" $skillTarget
```

复制完成后，请重启或刷新 Codex。对于其他兼容的 AI 助手，请将同一个 `skills/wechat-exporter` 文件夹复制到该助手配置的 Skill 目录中。

## 通过 MCP 连接

将随程序发布的命令行工具配置为本地 stdio MCP 服务：

```text
<安装目录>\WechatExporterCLI.exe mcp
```

请保持 `WechatExporterCLI.exe`、`WechatExporter.exe` 和 `_internal` 目录位于原始发布位置，并在 MCP 客户端配置中使用命令行工具的完整路径。

## 使用示例

- “使用 WechatExporter 检查我的本地环境是否已经准备好。”
- “列出我已初始化的微信账号，并显示最近的会话。”
- “在最近一个月的本地消息中搜索这个关键词。”
- “先向我展示导出范围和保存位置，再导出这个选中的聊天。”

AI 助手应从范围明确的只读查询开始。在执行大批量导出、媒体下载、安装、激活、购买或其他联网操作前，必须先征得用户确认。

## 安全与隐私

- 只访问用户明确初始化过的账号。
- 除非用户明确要求导出或联网操作，否则微信数据应保留在本地。
- 不得暴露数据库密钥、API Token、激活码、刷新凭据、设备私钥或许可证存储内容。
- 不得要求用户在对话中粘贴激活码。
- 不得使用第三方下载镜像、破解版本或许可证绕过方案。
- 未经用户充分了解并明确确认，不得开启面向整个网络的 API 监听。
- OmniExporter 网站是官方产品与账号服务入口，不是微信数据访问接口。

## 仓库结构

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
└── README.md
```

可安装的 Skill 仅为 `skills/wechat-exporter` 目录。仓库说明、CI 配置和开发脚本保留在该目录之外，避免占用 AI 助手加载 Skill 时的上下文。

## 开发与校验

校验仓库中的 Skill 源文件：

```powershell
python .\scripts\validate_skill.py
```

检查 WechatExporter 桌面工程中的镜像副本及其内容哈希是否与源文件完全一致：

```powershell
python .\scripts\sync_client_mirror.py --check
```

有意修改 Skill 后，更新桌面工程中的镜像：

```powershell
python .\scripts\sync_client_mirror.py --write
```

本仓库是 Skill 的唯一维护源。`WechatExporterWinClient-py/.agents/skills/wechat-exporter` 中的副本是构建时使用的哈希锁定镜像，不应手工修改。

## 开源许可证

本项目采用 Apache License 2.0，详见 [LICENSE](LICENSE)。
