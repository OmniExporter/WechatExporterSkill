# Complete localhost HTTP API reference

## Contents

- Start, authenticate, and select an account
- Route inventory
- Read request parameters
- Export request bodies and job polling
- Errors and network safety

## Start, authenticate, and select an account

Start the server on loopback:

```text
WechatExporterCLI.exe serve
```

Default base URL: `http://127.0.0.1:8731/api/v1`. Interactive OpenAPI: `http://127.0.0.1:8731/docs`.

`GET /api/v1/health` is public on the listener. Every other route requires one of:

```text
Authorization: Bearer <local-token>
X-API-Key: <local-token>
```

The generated token is stored in `~/.wechat-exporter/api-token`. Load it only inside the calling process; never print, return, or commit it. Prefer loopback. A non-loopback listener requires explicit informed approval and CLI `--allow-network`.

Account-bound requests accept `account` or `config_path`, never both. GET/parameterless POST routes use query parameters; JSON export/search routes carry selectors in the body.

## Route inventory

| Route | Purpose | Side effect |
|---|---|---|
| `GET /api/v1/health` | Server/version health | None; public |
| `GET /api/v1/license/status` | Product-license status | None |
| `GET /api/v1/accounts` | Initialized profile list | None |
| `GET /api/v1/status` | Selected-profile readiness | None |
| `GET /api/v1/sessions` | Recent sessions | None |
| `GET /api/v1/unread` | Unread sessions and totals | None |
| `POST /api/v1/new-messages` | Changed sessions since checkpoint | Writes local checkpoint |
| `GET /api/v1/history/{chat_name}` | One chat page | Optional local media resolution |
| `POST /api/v1/search` | Global or scoped message search | None |
| `GET /api/v1/contacts` | Contact list/search/detail | None |
| `GET /api/v1/official-accounts` | Local official accounts | None |
| `GET /api/v1/finder-candidates` | Locally observed Channels accounts | None |
| `GET /api/v1/finder-video-cards` | Safe local Channels card metadata | None |
| `GET /api/v1/members/{group_name}` | Group members | None |
| `GET /api/v1/stats/{chat_name}` | Chat statistics | None |
| `GET /api/v1/chat-map` | Display-name/username mapping | None |
| `GET /api/v1/favorites` | Local favorites | None |
| `POST /api/v1/exports` | One-chat export job | Writes local files |
| `POST /api/v1/exports/all` | All-chat export job | Writes many local files |
| `POST /api/v1/exports/articles` | Article download job | Network and local files |
| `POST /api/v1/exports/finder-video` | Playing-video download job | Windows automation/network/files |
| `POST /api/v1/exports/finder-cards` | Card-video batch job | Windows automation/network/files |
| `POST /api/v1/exports/finder-account` | Profile scan/download job | Mouse control/network/files |
| `GET /api/v1/jobs/{job_id}` | Poll asynchronous job | None |

## Read request parameters

- `/license/status`, `/accounts`: no account selector required.
- `/status`: `account`, `config_path`.
- `/sessions`: `limit=20` (`1..500`) plus selectors.
- `/unread`: `limit=50` (`1..500`) plus selectors.
- `/new-messages`: selectors. The first call writes a checkpoint and returns unread sessions; later calls return one summary per changed session, not every intervening message.
- `/history/{chat_name}`: `limit=50`, `offset=0`, `start_time`, `end_time`, `msg_type`, `media=false`, plus selectors.
- `/contacts`: `query`, `detail`, `limit=50` (`1..500`), plus selectors.
- `/official-accounts`: `query`, `limit=200` (`1..500`), plus selectors.
- `/finder-candidates`: `query`, `source=all` (`all|profile-cache|message|favorite`), `limit=100` (`1..500`), plus selectors. It is not a following list.
- `/finder-video-cards`: `query`, `limit=100` (`1..500`), plus selectors. Signed media URLs are omitted.
- `/members/{group_name}`: selectors.
- `/stats/{chat_name}`: `start_time`, `end_time`, plus selectors.
- `/chat-map`: `groups_only=false`, `all_contacts=false`, plus selectors.
- `/favorites`: `limit=20` (`1..500`), `fav_type`, `query`, plus selectors. Favorite types are `text`, `image`, `article`, `card`, and `video`.

Search JSON body:

```json
{
  "keyword": "合同",
  "chats": ["项目群"],
  "start_time": "2026-08-01",
  "end_time": "",
  "limit": 20,
  "offset": 0,
  "msg_type": "text",
  "account": "wxid_example",
  "config_path": null
}
```

`keyword` is required. `chats=[]` searches globally. `limit` is `1..500`; `offset` is non-negative.

## Export request bodies and job polling

One-chat export (`POST /exports`):

```json
{
  "chat_name": "项目群",
  "format": "markdown",
  "output_path": null,
  "start_time": "",
  "end_time": "",
  "limit": 500,
  "media": false,
  "media_dir": null,
  "account": "wxid_example",
  "config_path": null
}
```

All-chat export (`POST /exports/all`):

```json
{
  "mode": "incremental",
  "media": true,
  "account": "wxid_example",
  "config_path": null
}
```

`mode` is `full`, `incremental`, or `resume`. Use the CLI or MCP for dry-run, chat-type, time, format, output-directory, and per-chat-limit controls.

Article export (`POST /exports/articles`):

```json
{
  "account_name": "示例公众号",
  "source": "local",
  "incremental": true,
  "images": true,
  "workers": 4,
  "account": "wxid_example",
  "config_path": null
}
```

`source` is `local` or `wmpf`; `workers` is `1..16`. WMPF requires the exact profile page open and exclusive mouse control.

Playing-video export (`POST /exports/finder-video`):

```json
{
  "query": "标题关键词",
  "output_path": null,
  "overwrite": false,
  "keep_encrypted": false,
  "timeout": 60,
  "account": "wxid_example",
  "config_path": null
}
```

Card batch (`POST /exports/finder-cards`):

```json
{
  "object_ids": ["OBJECT_ID"],
  "download_all": false,
  "incremental": true,
  "overwrite": false,
  "limit": 500,
  "timeout": 60,
  "account": "wxid_example",
  "config_path": null
}
```

Provide at least one object ID or explicitly set `download_all=true`, but not both. Do not combine incremental and overwrite.

Account scan (`POST /exports/finder-account`):

```json
{
  "username": "finder_id",
  "nickname": "示例号",
  "incremental": true,
  "overwrite": false,
  "max_iterations": 200,
  "timeout": 60,
  "account": "wxid_example",
  "config_path": null
}
```

Confirm the exact username and open page before submission. Do not combine incremental and overwrite.

Every `/exports*` route returns HTTP `202` and a job record. Poll `GET /api/v1/jobs/{job_id}` until `status` is `completed` or `failed`. Do not resubmit while a job is merely `queued` or `running`.

## Errors and network safety

- `401`: missing/invalid local API token.
- `403` with `license_*`: stop and resolve product authorization.
- `404`: account/chat/contact/job not found; resolve identifiers before retrying.
- `422`: request schema validation failure; fix fields instead of retrying unchanged.
- Service errors use `{"error":{"code":"...","message":"..."}}`.
- Background failures appear in the job record. Report the bounded error and output path; do not expose token, keys, credentials, or unrelated paths.
