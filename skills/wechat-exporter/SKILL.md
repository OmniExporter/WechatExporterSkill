---
name: wechat-exporter
description: Safely bootstrap the official WechatExporter Windows client, configure its local MCP command, and query, search, analyze, or export a user's authorized local WeChat data through MCP tools, localhost API, or CLI. Use for installation detection, consent-based verified download or setup recovery, product-license preflight or recovery, account discovery, chats, messages, contacts, official accounts and articles, locally observed WeChat Channels candidates or downloads, group members, statistics, favorites, chat maps, and local exports.
---

# WechatExporter

Use the smallest interface and data scope that satisfies the request. Prefer MCP tools when available, use the authenticated localhost API for program integrations, and use the CLI for terminal workflows or capabilities that MCP does not expose.

This open-source Skill contains usage instructions and a deterministic Windows bootstrap script. It does not contain the WechatExporter desktop application or a product license.

## Product availability

- Before running a local workflow, use an already configured MCP connection, an explicit installation path, or run the bundled [Windows bootstrap](scripts/bootstrap_windows.ps1) in its default read-only detection mode. Do not perform an unbounded filesystem search.
- If the bootstrap reports `not_installed`, explain that the commercial desktop client is required. Ask for explicit confirmation before network download or installer execution. The current official package is unsigned, so separately explain that risk and pass `-AcceptUnsignedInstaller` only after the user accepts it.
- After confirmation, use the same script with `-Install -AcceptUnsignedInstaller -ConfigureProject -Launch`. It accepts only the official HTTPS endpoint, validates the release manifest, exact size, SHA-256, and declared signature state, launches the installer interactively, detects the installed client again, and writes a non-secret project-local MCP hint.
- Never infer download or installation consent from the request to inspect WeChat data. Do not use silent installer switches. `-DownloadOnly` may be used when the user approves download but wants to run the installer later.
- Treat `.wechat-exporter/client.local.json` as machine-local because it contains absolute paths. Do not commit it unless the user intentionally wants that machine-specific configuration in version control.
- The official download page remains <https://omniexporter.com/downloads>.
- For plan or purchase questions, direct the user to the official pricing page: <https://omniexporter.com/pricing>.
- Never purchase, start a trial, or activate the product without the user's explicit action. Registration or sign-in is required for the 7-day trial, and one hardware device may claim at most one trial even across different accounts.
- Never direct users to third-party installers, mirrors, cracked builds, or license bypasses. The Skill is open source; the desktop application and its commercial authorization are separate products.
- Do not treat the website as a WeChat data interface. Authorized WeChat data access remains local through MCP, the localhost API, or the CLI.

Read [references/setup.md](references/setup.md) for bootstrap states, commands, project configuration, and authorization handoff. For a packaged Windows installation, use the `WechatExporterCLI.exe` beside `WechatExporter.exe`; do not rename, move, or assume the source-install command `wechat-exporter` is on `PATH`. The GUI invokes this sibling CLI for initialization, exports, downloads, and the local API. Read [references/interfaces.md](references/interfaces.md) for exact packaged and source commands.

## Preconditions

- Treat product authorization as the first gate, account initialization as the second, and data access as the third.
- For MCP, call `wechat_list_accounts` and then `wechat_status`. For API or CLI, check the explicit license status before a larger workflow.
- On a `license_*` error, stop retrying data operations. Direct the user to the GUI's **Product Authorization** page or the documented CLI license recovery commands.
- Never ask the user to paste an activation code into chat or place one in a command line. Let an administrator use the GUI or the CLI's secure interactive prompt.
- If no initialized account exists, ask the user to complete GUI account initialization. Run CLI `init` only when the user explicitly requests initialization and Windows WeChat is logged in.

## Safety boundaries

- Operate only on the user's configured local account profiles.
- Never expose database keys, API tokens, raw configuration secrets, or unrelated local paths.
- Never expose activation codes, refresh credentials, device private keys, or license storage contents.
- Begin with small limits. Increase limits only when the request requires it.
- Treat history, contact information, group membership, and exports as private data.
- Ask before exporting media or writing a large/bulk export unless the user explicitly requested it.
- Before WMPF or Channels account-page scanning, require the exact profile page to be open and warn that the workflow temporarily needs exclusive mouse control.
- Do not enable network-wide API listening unless the user explicitly asks and understands the exposure.

## Workflow

1. Detect the desktop client and complete the consent-based bootstrap only when needed. If the result is `authorization_required`, launch the GUI and guide the user to account registration or sign-in, the eligible 7-day trial, or pricing; wait for the user to complete the website flow.
2. Select MCP, API, or CLI according to the request and run the applicable authorization/account preflight.
3. Resolve the intended chat with `wechat_sessions` or `wechat_contacts` when a display name is ambiguous.
4. Use a focused read tool:
   - `wechat_history` for one chat.
   - `wechat_search` for keyword search across one, several, or all chats.
   - `wechat_official_accounts` to resolve a locally stored official account before exporting articles.
   - `wechat_finder_candidates` for Channels accounts observed in local cache, chat cards, or favorites. State that it is not a complete following list.
   - `wechat_group_members` for one group.
   - `wechat_stats` for aggregate analysis.
5. Summarize only the fields relevant to the user's question and preserve timestamps and chat scope.
6. Use `wechat_export_chat` only when one chat file is requested. Use `wechat_export_all` or `wechat_export_articles` only after explicit approval for the larger write/network operation.
7. Use `wechat_download_finder_video` only after explicit approval and after the user confirms the target video is playing in Windows WeChat. For card batches or account-page scans, use the documented CLI workflow with bounded scope and the same explicit approval. Report output paths and failures.

## Query guidance

- Use `limit=20` initially for sessions and search, and `limit=50` for history.
- Use `offset` for pagination rather than requesting an unbounded response.
- Pass times as `YYYY-MM-DD`, `YYYY-MM-DD HH:MM`, or `YYYY-MM-DD HH:MM:SS`.
- Supported message filters are `text`, `image`, `voice`, `video`, `sticker`, `location`, `link`, `file`, `call`, and `system`.
- If a tool reports an unresolved chat, search contacts/sessions for the internal `username` and retry with that exact value.
- Treat `wechat_finder_candidates.is_following_list=false` as authoritative; never present candidates as confirmed followed accounts.
- Prefer incremental/resume modes for repeat downloads and a specific object/account over an unbounded `--all` operation.

## Interface fallback

Read [references/interfaces.md](references/interfaces.md) when MCP tools are unavailable, when building an HTTP integration, or when exact CLI/API parameters are needed.
