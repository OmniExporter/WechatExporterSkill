# WechatExporter interfaces

## Installation and official acquisition

This Skill does not contain the desktop application. If neither an existing MCP configuration nor a user-supplied installation path resolves `WechatExporterCLI.exe`, stop the data workflow and direct the user to:

- Official download: <https://omniexporter.com/downloads>
- Plans and pricing: <https://omniexporter.com/pricing>

Do not download or run an installer without explicit user confirmation. Do not use third-party mirrors or treat the open-source Skill as a replacement for a valid product license. After installation, use the exact CLI located beside `WechatExporter.exe`; do not move it out of the installed directory.

Choose the command that matches the installation:

- Packaged Windows ZIP or Setup: `<install-dir>\WechatExporterCLI.exe`
- Python source installation: `wechat-exporter`

Use the full executable path in MCP client configuration. The examples below use `WechatExporterCLI.exe`; replace it with `wechat-exporter` for a source installation.

For a packaged installation, keep `WechatExporter.exe`, `WechatExporterCLI.exe`, and `_internal` in their distributed locations. The GUI looks for the exact sibling name `WechatExporterCLI.exe` when it starts initialization, export, download, or API workflows.

## Authorization and account preflight

WechatExporter uses three gates: product authorization, account initialization, then data access. GUI and CLI share the same device license and account profiles.

Check authorization from the CLI:

```text
WechatExporterCLI.exe license status --json-output
```

For offline recovery:

```text
WechatExporterCLI.exe license export-request device-request.wexr
WechatExporterCLI.exe license import license.wexl
```

Use `WechatExporterCLI.exe license refresh` for an existing online license. For a new online activation, prefer the administrator-only GUI flow. If CLI activation is explicitly required, run `license activate` without `--code` so the program prompts securely; never expose an activation code in chat, logs, or process arguments.

If an interface returns a `license_*` error, stop data calls and resolve authorization first. If authorization is valid but no account is listed, complete account initialization in the GUI or run CLI `init` only after explicit user confirmation with Windows WeChat logged in.

## MCP

Start the stdio server:

```text
<install-dir>\WechatExporterCLI.exe mcp
```

Tools:

- `wechat_list_accounts`
- `wechat_status`
- `wechat_sessions`
- `wechat_history`
- `wechat_search`
- `wechat_contacts`
- `wechat_official_accounts`
- `wechat_finder_candidates`
- `wechat_group_members`
- `wechat_stats`
- `wechat_export_chat`
- `wechat_export_all`
- `wechat_export_articles`
- `wechat_download_finder_video`

Select an account with `account`, or an explicit configuration with `config_path`. Do not set both.

## Local HTTP API

Start the server:

```text
WechatExporterCLI.exe serve
```

The default base URL is `http://127.0.0.1:8731/api/v1`. Health is public on the local listener; all data endpoints require either `Authorization: Bearer <token>` or `X-API-Key: <token>`.

The generated token is stored in `~/.wechat-exporter/api-token`. Never print it in logs or responses. Interactive OpenAPI documentation is at `http://127.0.0.1:8731/docs`.

Key routes:

- `GET /health`
- `GET /license/status`
- `GET /accounts`
- `GET /status`
- `GET /sessions`
- `GET /unread`
- `GET /history/{chat_name}`
- `POST /search`
- `GET /contacts`
- `GET /official-accounts`
- `GET /finder-candidates`
- `GET /members/{group_name}`
- `GET /stats/{chat_name}`
- `GET /chat-map`
- `GET /favorites`
- `POST /exports`
- `POST /exports/all`
- `POST /exports/articles`
- `POST /exports/finder-video`
- `GET /jobs/{job_id}`

Exports are asynchronous. Poll the returned job identifier until `completed` or `failed`.

## CLI

```text
WechatExporterCLI.exe license status --json-output
WechatExporterCLI.exe unread --limit 20 --format text
WechatExporterCLI.exe new-messages --format text
WechatExporterCLI.exe sessions --limit 20
WechatExporterCLI.exe history "chat name" --limit 50
WechatExporterCLI.exe search "keyword" --chat "chat name"
WechatExporterCLI.exe contacts --query "name"
WechatExporterCLI.exe chat-map --groups-only
WechatExporterCLI.exe favorites --limit 20 --format text
WechatExporterCLI.exe official-accounts --query "name"
WechatExporterCLI.exe finder-candidates --source all
WechatExporterCLI.exe members "group name"
WechatExporterCLI.exe stats "chat name"
WechatExporterCLI.exe export "chat name" --output chat.md
WechatExporterCLI.exe export-articles "official account" --download --resume
WechatExporterCLI.exe export-articles "official account" --source wmpf --download --resume
WechatExporterCLI.exe finder-download
WechatExporterCLI.exe finder-download-cards --object-id "video object id" --incremental
WechatExporterCLI.exe finder-download-cards --all --incremental
WechatExporterCLI.exe finder-download-account --username "Channels ID" --nickname "name" --incremental
```

`finder-candidates` and `wechat_finder_candidates` report locally observed candidates, not a complete following list.

- `finder-download` and `wechat_download_finder_video` require explicit approval and a target video actively playing in Windows WeChat.
- Prefer one or more `--object-id` values for card downloads. Use `--all` only when the user explicitly requests the full bounded list.
- Before `finder-download-account`, require the exact Channels profile page to be open, verify `--username`, prefer `--incremental`, and warn that scrolling needs exclusive mouse control.
- Before WMPF article scanning, require explicit approval and the selected official account's real profile page to be open; the scan also needs exclusive mouse control. Both full and incremental scans traverse from a verified top to a verified viewport end. If that scan already completed but body downloads remain unfinished, incremental `--resume --download` reuses `articles.scan.json` and continues the missing bodies without reopening or rescanning the profile page. GUI workflows stream each scan/download line while the child runs.

Downloaded articles use `pages/<date_title_article-id>/article.html`, `article.md`, and `article.json`, plus a per-article image directory. A download or resume run migrates the legacy flat `pages` layout automatically.

Use global `--account ACCOUNT_ID` or `--config CONFIG_PATH` before the subcommand to select a non-default profile.
