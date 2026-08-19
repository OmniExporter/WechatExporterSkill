# Complete CLI reference

## Contents

- Invocation and shared rules
- Account, setup, and authorization commands
- Read and analysis commands
- Export commands
- WeChat Channels commands
- Local service commands

## Invocation and shared rules

Use `<install-dir>\WechatExporterCLI.exe` for a packaged Windows installation and `wechat-exporter` for a Python source installation. The examples use `WechatExporterCLI.exe`.

Global options must appear before the command:

```text
WechatExporterCLI.exe [--config CONFIG_PATH | --account ACCOUNT_ID] COMMAND [ARGS]
```

- `--config`: select an explicit `config.json`.
- `--account`: select an initialized profile under `~/.wechat-exporter/profiles`.
- Never pass both selectors.
- Use `COMMAND --help` as the runtime authority when the installed version differs from this reference.
- Times accept `YYYY-MM-DD`, `YYYY-MM-DD HH:MM`, or `YYYY-MM-DD HH:MM:SS`.
- Message types are `text`, `image`, `voice`, `video`, `sticker`, `location`, `link`, `file`, `call`, and `system`.
- JSON is the preferred automation format. Treat exported files and returned personal data as private.

## Commands

### `account-id`

Print the selected account ID. It has no command-specific options.

```text
WechatExporterCLI.exe --account wxid_example account-id
```

### `chat-map`

Write display-name/internal-username mappings. Options: `--format text|json` (default `text`), `--output FILE`, `--groups-only`, and `--all-contacts`. The default destination is the selected account's output directory.

```text
WechatExporterCLI.exe chat-map --groups-only
WechatExporterCLI.exe chat-map --format json --output output/chat-map.json
```

### `contacts`

List or search contacts. Options: `--query TEXT`, `--detail NAME_OR_USERNAME`, `--limit N` (default `50`), and `--format json|text`.

```text
WechatExporterCLI.exe contacts --query "李" --limit 20
WechatExporterCLI.exe contacts --detail wxid_example
```

### `export`

Export one chat. Required argument: `CHAT_NAME`. Options: `--format markdown|txt`, `--output FILE`, `--start-time`, `--end-time`, `--limit N` (default `500`), `--media`, and `--media-dir DIR`. `--media-dir` requires `--media`.

```text
WechatExporterCLI.exe export "项目群" --output project.md --limit 500
WechatExporterCLI.exe export "项目群" --output project.md --media --media-dir project-images
```

Ask before enabling media unless the user already requested it.

### `export-all`

Export every selected-account chat with messages. Options:

- `--format markdown|txt` (default `markdown`) and `--output-dir DIR`.
- `--media`.
- Repeatable `--chat-type group|private|official|unknown`.
- `--start-time`, `--end-time`, and `--limit-per-chat N` (`0` means all).
- `--resume` to skip completed files from a matching manifest.
- `--incremental` to synchronize chats changed since a compatible full run.
- `--dry-run` to inspect scope without writing chat exports.

`--resume` and `--incremental` are mutually exclusive. Incremental mode requires a prior compatible manifest and identical format/media/time/type/limit options.

```text
WechatExporterCLI.exe export-all --dry-run --chat-type group
WechatExporterCLI.exe export-all --media
WechatExporterCLI.exe export-all --media --incremental
```

Require explicit approval before a non-dry-run bulk export.

### `export-articles`

Export the article index for one official account and optionally download pages. Required argument: `ACCOUNT_NAME`.

Core options:

- `--output-dir DIR` and `--source local|wmpf` (default `local`).
- `--download`, `--images|--no-images`, `--image-workers 1..8`, and `--resume`.
- `--start-time`, `--end-time`, `--limit N` (`0` means all), `--delay SECONDS`, `--timeout SECONDS`, and `--workers 1..16`.
- `--dedupe-title` to retain the newest article with a duplicate title.

WMPF scanning options: `--wmpf-max-iterations 1..20000`, `--wmpf-idle-limit 2..100`, and `--wmpf-scroll-wait 0..60`. Require the exact official-account profile page to be visible and warn that scrolling needs exclusive mouse control.

Supplemental URL options: `--urls-file FILE` and `--urls-only`. Engagement options: `--engagement`, `--credentials-file FILE`, and `--max-comments 0..10000`. A credentials file is sensitive: never print, copy into chat, or commit it.

```text
WechatExporterCLI.exe export-articles "示例公众号" --download --resume --workers 4
WechatExporterCLI.exe export-articles "示例公众号" --source wmpf --download --resume
```

### `favorites`

Read local favorites. Options: `--limit N` (default `20`), `--type text|image|article|card|video`, `--query TEXT`, and `--format json|text`.

```text
WechatExporterCLI.exe favorites --type article --query "AI"
```

### `finder-candidates`

List locally observed Channels account candidates. Options: `--query TEXT`, `--source all|profile-cache|message|favorite`, `--limit N` (default `100`; `0` means all in the CLI), and `--format json|text`.

```text
WechatExporterCLI.exe finder-candidates --source favorite --limit 50
```

The result is not a complete following list. Preserve `is_following_list=false` in summaries.

### `finder-download`

Download the Channels video currently playing in Windows WeChat. Optional argument: `QUERY`. Options: `--output FILE`, `--overwrite`, `--keep-encrypted`, and `--timeout 5..600` (default `60`).

```text
WechatExporterCLI.exe finder-download "标题关键词" --timeout 60
```

Require explicit approval and confirmation that the exact target video is playing.

### `finder-download-account`

Scan the currently open Channels profile and download its works. Required option: `--username CHANNELS_ID`. Other options: `--nickname TEXT`, `--incremental`, `--overwrite`, `--max-iterations 1..5000` (default `200`), and `--timeout 5..600` (default `60`). Do not combine incremental behavior with overwrite.

```text
WechatExporterCLI.exe finder-download-account --username finder_id --nickname "示例号" --incremental
```

Confirm the exact profile page and username first. This Windows-only workflow needs exclusive mouse control while scanning.

### `finder-download-cards`

Download Channels videos referenced by local chat/favorite cards. Select one or more repeatable `--object-id ID` values, or use `--all` only after explicit approval. Other options: `--incremental`, `--overwrite`, `--limit 1..5000` (default `500`), and `--timeout 5..600` (default `60`).

```text
WechatExporterCLI.exe finder-download-cards --object-id OBJECT_ID --incremental
```

### `gui`

Launch the desktop GUI. It has no command-specific options.

```text
WechatExporterCLI.exe gui
```

### `history`

Read a page of one chat. Required argument: `CHAT_NAME`. Options: `--limit N` (default `50`), `--offset N`, `--start-time`, `--end-time`, `--format json|text`, `--type MESSAGE_TYPE`, and `--media` to resolve local media paths.

```text
WechatExporterCLI.exe history "项目群" --limit 50 --offset 0 --type text
```

### `image-key`

Extract and save Windows WeChat 4.x image AES/XOR keys. Option: `--timeout 0..300` (default `30`; `0` scans once).

```text
WechatExporterCLI.exe image-key --timeout 60
```

Use only after explicit initialization intent, while WeChat is running and 2–3 images from the selected account are open full-screen. Never print the extracted key material; the command intentionally reports only the configuration path.

### `init`

Initialize one local account. Options: `--db-dir DIR` and `--force`. Without `--db-dir`, the client performs its bounded account-directory detection. `--force` re-extracts database keys.

```text
WechatExporterCLI.exe init
WechatExporterCLI.exe init --db-dir "C:\path\to\db_storage" --force
```

Run only after explicit confirmation, with Windows WeChat logged in. Prefer GUI initialization for normal users.

### `license`

Manage product authorization without loading WeChat data.

```text
WechatExporterCLI.exe license status --json-output
WechatExporterCLI.exe license refresh
WechatExporterCLI.exe license export-request device-request.wexr
WechatExporterCLI.exe license import license.wexl
WechatExporterCLI.exe license activate
```

Subcommands are `status [--json-output]`, `refresh`, `export-request OUTPUT`, `import LICENSE_FILE`, and `activate [--code CODE]`. For activation, omit `--code` and let the secure interactive prompt collect it. Never place activation codes in chat, logs, scripts, or process arguments.

### `mcp`

Start the local stdio MCP server. Configure the full packaged executable path plus the single argument `mcp`. Do not expect terminal output while an MCP client owns stdio.

```text
<install-dir>\WechatExporterCLI.exe mcp
```

### `members`

Return members of one local group. Required argument: `GROUP_NAME`. Option: `--format json|text`.

```text
WechatExporterCLI.exe members "项目群" --format json
```

### `new-messages`

Return session changes since the previous invocation. Option: `--format json|text`. The per-account checkpoint is `last_check.json` beside the selected profile's `config.json`.

```text
WechatExporterCLI.exe new-messages --format json
```

The first call records a checkpoint and returns current unread sessions. Later calls return one latest-message summary for each changed session, not every intervening message. Use `history` with a time boundary to retrieve all messages.

### `official-accounts`

List official accounts stored locally. Options: `--query TEXT`, `--limit 1..500` (default `200`), and `--format json|text`.

```text
WechatExporterCLI.exe official-accounts --query "科技" --limit 50
```

### `search`

Search messages globally or within selected chats. Required argument: `KEYWORD`. Options: repeatable `--chat CHAT_NAME`, `--start-time`, `--end-time`, `--limit N` (default `20`, maximum `500`), `--offset N`, `--format json|text`, and `--type MESSAGE_TYPE`.

```text
WechatExporterCLI.exe search "合同" --chat "项目群" --limit 20
```

### `serve`

Start the authenticated local HTTP API. Options: `--host HOST` (default `127.0.0.1`), `--port 1..65535` (default `8731`), `--token TOKEN`, and `--allow-network`.

```text
WechatExporterCLI.exe serve
```

Prefer the generated token and loopback listener. Never expose or print the token. A non-loopback host requires both explicit informed approval and `--allow-network`.

### `sessions`

Return recent sessions. Options: `--limit N` (default `20`) and `--format json|text`.

```text
WechatExporterCLI.exe sessions --limit 20
```

### `stats`

Calculate totals, message-type distribution, senders, and hourly activity for one chat. Required argument: `CHAT_NAME`. Options: `--start-time`, `--end-time`, and `--format json|text`.

```text
WechatExporterCLI.exe stats "项目群" --start-time 2026-08-01
```

### `unread`

Return unread sessions and aggregate unread counts. Options: `--limit N` (default `50`) and `--format json|text`.

```text
WechatExporterCLI.exe unread --limit 20 --format json
```
