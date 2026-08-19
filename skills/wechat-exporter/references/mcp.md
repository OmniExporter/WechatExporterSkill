# Complete MCP tool reference

## Contents

- Server configuration and selectors
- Read-only and stateful tools
- Export and network tools
- Tool-by-tool reference
- Error and fallback rules

## Server configuration and selectors

Configure a local stdio server with the packaged CLI:

```text
command: <install-dir>\WechatExporterCLI.exe
args: ["mcp"]
```

Call `wechat_list_accounts`, select a profile, then call `wechat_status`. Every account-bound tool accepts optional `account` and `config_path`; never set both. Omit both only when the intended default profile is unambiguous.

Use small initial limits. Times accept `YYYY-MM-DD`, `YYYY-MM-DD HH:MM`, or `YYYY-MM-DD HH:MM:SS`. Message filters are `text`, `image`, `voice`, `video`, `sticker`, `location`, `link`, `file`, `call`, and `system`.

The server exposes 21 tools: 14 read-only tools, one local-checkpoint tool, two local export tools, and four network/Windows-automation tools. Tool annotations are authoritative for side effects.

## Tool reference

### `wechat_list_accounts`

List initialized local profiles without returning database keys or tokens. Parameters: none. Use the returned `account_id` as `account` in later calls.

### `wechat_status`

Check readiness, selected account ID, safe paths, and message-database count. Parameters: common profile selectors only. Continue only when `ready=true`; `query_ready=false` means chat-message keys need recovery.

### `wechat_sessions`

Return recent sessions. Parameters: `limit=20` plus selectors. Read-only.

### `wechat_unread`

Return unread sessions, `chat_count`, and aggregate `unread_count`. Parameters: `limit=50` plus selectors. Read-only.

### `wechat_new_messages`

Return changed-session summaries since the previous call. Parameters: selectors only. This writes `last_check.json` beside the selected profile's config.

- First call: records a checkpoint and returns current unread sessions.
- Later calls: returns one latest-message summary per session whose latest timestamp changed.
- It does not return every intervening message; follow with `wechat_history` for complete content.

### `wechat_history`

Read one chat page. Parameters:

- Required `chat_name` (display name or internal username).
- `limit=50`, `offset=0`, `start_time=""`, `end_time=""`, and `msg_type=null`.
- `media=false` resolves local media paths when enabled; do not enable it unless needed.
- Common selectors.

Paginate with `offset`. If the display name is ambiguous, resolve the internal username with sessions, contacts, or chat map.

### `wechat_search`

Search messages globally or within selected chats. Parameters:

- Required `keyword`.
- `chats=null` for global search or a list of chat names/usernames.
- `limit=20`, `offset=0`, `start_time=""`, `end_time=""`, and `msg_type=null`.
- Common selectors.

### `wechat_contacts`

List, search, or inspect contacts. Parameters: `query=""`, `detail=null`, `limit=50`, plus selectors. Set `detail` to a display name, remark, or username for a single record.

### `wechat_favorites`

Return recent local favorites. Parameters: `limit=20`, `fav_type=null`, `query=null`, plus selectors. `fav_type` supports `text`, `image`, `article`, `card`, and `video`.

### `wechat_chat_map`

Map display names to internal usernames. Parameters: `groups_only=false`, `all_contacts=false`, plus selectors. Read-only; unlike the CLI command, it returns structured data and does not write a file.

### `wechat_official_accounts`

List locally stored official accounts and local article-source availability. Parameters: `query=""`, `limit=200`, plus selectors.

### `wechat_finder_candidates`

List locally observed Channels account candidates. Parameters: `query=""`, `source="all"`, `limit=100`, plus selectors. `source` is `all`, `profile-cache`, `message`, or `favorite`.

Always preserve `is_following_list=false`. These candidates are local evidence, not a complete following list.

### `wechat_finder_video_cards`

Return safe metadata for locally observed Channels video cards without signed media URLs. Parameters: `query=""`, `limit=100` (maximum `500`), plus selectors. Use returned `object_id` values to scope card downloads.

### `wechat_group_members`

Return one local group's members. Parameters: required `group_name` plus selectors. If a name is ambiguous, pass the internal `@chatroom` username.

### `wechat_stats`

Return totals, type distribution, sender activity, and hourly activity for one chat. Parameters: required `chat_name`, `start_time=""`, `end_time=""`, plus selectors.

### `wechat_export_chat`

Export one chat locally. Parameters:

- Required `chat_name`.
- `format="markdown"` (`markdown` or `txt`).
- `output_path=null`, `start_time=""`, `end_time=""`, and `limit=500`.
- `media=false` and `media_dir=null`; `media_dir` is meaningful only with media enabled.
- Common selectors.

This writes local files. Require approval for media or a large scope unless already explicit in the request.

### `wechat_export_all`

Export all selected-account chats. Parameters:

- `mode="incremental"`: `full`, `incremental`, or `resume`.
- `format="markdown"`: `markdown` or `txt`.
- `output_dir=null`, `media=true`, and `chat_types=null` (`group`, `private`, `official`, `unknown`).
- `start_time=""`, `end_time=""`, `limit_per_chat=0`, and `dry_run=false`.
- Common selectors.

Run `dry_run=true` to inspect scope when approval is not yet clear. A real bulk export requires explicit approval. Incremental mode requires a compatible prior manifest.

### `wechat_export_articles`

Download official-account articles. Parameters: required `account_name`; `source="local"` (`local` or `wmpf`); `incremental=true`; `images=true`; `workers=4` (range `1..16`); plus selectors.

This writes files and accesses article pages. `source="wmpf"` additionally scrolls the exact official-account page open in Windows WeChat and requires explicit approval plus exclusive mouse control. Use the CLI for advanced URL-list, engagement, credential, WMPF-bound, or download-tuning options.

### `wechat_download_finder_video`

Download the exact Channels video currently playing in Windows WeChat. Parameters: `query=""`, `output_path=null`, `overwrite=false`, `keep_encrypted=false`, `timeout=60` (`5..600`), plus selectors.

Require explicit approval and confirmation that the target is actively playing. This controls Windows WeChat, accesses the network, and writes an MP4.

### `wechat_download_finder_cards`

Download selected local card videos. Parameters:

- `object_ids=null` or `download_all=true`; exactly one selection method is required.
- `incremental=true`, `overwrite=false`, `limit=500` (`1..5000`), and `timeout=60` (`5..600`).
- Common selectors.

Do not combine incremental and overwrite. Prefer exact `object_ids`; use `download_all=true` only after the user explicitly requests the bounded full card list. This controls Windows WeChat, accesses the network, and writes files.

### `wechat_download_finder_account`

Scan the Channels profile currently open in Windows WeChat and download its works. Parameters: required `username`; `nickname=""`; `incremental=true`; `overwrite=false`; `max_iterations=200` (`1..5000`); `timeout=60` (`5..600`); plus selectors.

Do not combine incremental and overwrite. Confirm the exact username and open profile page, require explicit approval, and warn that scanning temporarily needs exclusive mouse control.

## Error and fallback rules

- On `license_*`, stop and resolve product authorization. Do not retry data calls.
- On `not_initialized`, initialize the intended account through GUI or explicitly approved CLI `init`.
- On `chat_not_found`, use sessions, contacts, or chat map and retry with the internal username.
- On `message_keys_missing`, keep WeChat logged in, open a normal chat, and rerun explicitly approved initialization/key recovery.
- If a tool is absent from the connected server, verify the installed client version and use the equivalent authenticated API or documented CLI command. Never invent a tool.
- MCP intentionally does not expose product activation, offline-license import/export, account initialization, or image-key extraction. Use GUI/CLI so secrets and interactive consent remain outside the agent protocol.
