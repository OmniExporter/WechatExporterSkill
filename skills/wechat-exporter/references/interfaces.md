# Interface selection and preflight

## Contents

- Installation and executable selection
- Interface decision table
- Authorization and account preflight
- Capability routing
- Fallback and error handling

## Installation and executable selection

This Skill does not contain the desktop application. If neither an existing MCP configuration nor a user-supplied installation path resolves `WechatExporterCLI.exe`, run the bundled `scripts/bootstrap_windows.ps1` in its default read-only mode. Read [setup.md](setup.md) for the bounded detection and consent flow.

- Official download: <https://omniexporter.com/downloads>
- Plans and pricing: <https://omniexporter.com/pricing>
- Packaged Windows command: `<install-dir>\WechatExporterCLI.exe`
- Python source command: `wechat-exporter`

Do not download or run an installer without explicit confirmation. Keep `WechatExporter.exe`, `WechatExporterCLI.exe`, and `_internal` in their distributed locations. Use the full packaged CLI path in configuration and examples.

## Interface decision table

| Need | Preferred interface | Reason |
|---|---|---|
| A person browses chats, contacts, group members, statistics, Favorites, or chat mapping | Bilingual GUI | Direct tables, filters, selectors, and buttons; no terminal required |
| Agent reads, searches, analyzes, or performs a supported export | MCP stdio | Structured schemas and explicit read/write annotations |
| Application integration or background jobs | Authenticated localhost API | Stable HTTP requests, OpenAPI, and job polling |
| Full option surface, maintenance, initialization, or license recovery | CLI | Complete command coverage and interactive secure prompts |
| Registration, sign-in, trial, purchase, account initialization | GUI plus official website | User-controlled commercial and credential flow |

Use the smallest interface and data scope that satisfies the request. Do not use the website as a WeChat-data interface.

## Authorization and account preflight

WechatExporter has three gates: product authorization, account initialization, then feature access.

For MCP:

1. Call `wechat_list_accounts`.
2. Select exactly one profile with `account` or `config_path`; never set both.
3. Call `wechat_status` for that profile.

For CLI:

```text
WechatExporterCLI.exe license status --json-output
WechatExporterCLI.exe --account ACCOUNT_ID account-id
```

For HTTP:

1. Call `GET /api/v1/license/status` with the local API token.
2. Call `GET /api/v1/accounts`.
3. Call `GET /api/v1/status?account=ACCOUNT_ID`.

On a `license_*` error, stop data calls. Direct the user to the GUI's **Product Authorization** page or the CLI recovery commands. Never request an activation code in chat or put it in process arguments. If no account exists, use GUI initialization; invoke CLI `init` only after explicit confirmation and while Windows WeChat is logged in.

## Capability routing

| Task | GUI | MCP | HTTP API | CLI fallback |
|---|---|---|---|---|
| Accounts/readiness | Home and More → Account Setup | `wechat_list_accounts`, `wechat_status` | `/accounts`, `/status` | `account-id` |
| Sessions/unread/changes | Chats → Refresh Chats / Check for New Messages | `wechat_sessions`, `wechat_unread`, `wechat_new_messages` | `/sessions`, `/unread`, `/new-messages` | `sessions`, `unread`, `new-messages` |
| History/search | Chats → View Recent Messages / search buttons | `wechat_history`, `wechat_search` | `/history/{chat_name}`, `/search` | `history`, `search` |
| Contacts/favorites/map | Data Tools → Contacts / Favorites / Chat Mapping | `wechat_contacts`, `wechat_favorites`, `wechat_chat_map` | `/contacts`, `/favorites`, `/chat-map` | same named CLI commands |
| Groups/statistics | Data Tools → Group Members / Chat Statistics | `wechat_group_members`, `wechat_stats` | `/members/{group_name}`, `/stats/{chat_name}` | `members`, `stats` |
| Official accounts/articles | Official Accounts | `wechat_official_accounts`, `wechat_export_articles` | `/official-accounts`, `/exports/articles` | `official-accounts`, `export-articles` |
| Channels discovery | Channels | `wechat_finder_candidates`, `wechat_finder_video_cards` | `/finder-candidates`, `/finder-video-cards` | `finder-candidates` |
| Chat export | Chats or More → Batch Export | `wechat_export_chat`, `wechat_export_all` | `/exports`, `/exports/all` | `export`, `export-all` |
| Channels download | Channels | three `wechat_download_finder_*` tools | three `/exports/finder-*` routes | three `finder-download*` commands |
| Initialization/image-key/license | More → Product Authorization / Account Setup | Not exposed | License status only | `init`, `image-key`, `license` |

## Fallback and error handling

- If MCP is unavailable or a client version lacks a tool, use the authenticated API or exact CLI equivalent; never fabricate an MCP call.
- If exact CLI flags are required, read `cli.md`; do not guess defaults.
- If an HTTP schema is required, read `api.md` or the running local OpenAPI document at `http://127.0.0.1:8731/docs`.
- Start with `limit=20` for lists/search and `limit=50` for history. Paginate rather than requesting unbounded results.
- Resolve ambiguous display names through sessions, contacts, or chat map and retry with the returned internal `username`.
- For a nontechnical user, use the GUI's **Chat Mapping** table and **Copy selected ID** action instead of exposing CLI syntax.
- Ask before media export, bulk export, network download, WMPF scrolling, or Channels account scanning unless the user explicitly requested that exact operation.
- A Channels candidate list is local evidence, not a following list. Never label it as complete.
- `new-messages` stores a checkpoint and reports changed session summaries; use history to recover all messages in the interval.
