# ntfy 单向同步契约（阶段② · 桌面 → 手机）

> 版本 v1 · 2026-06-11。链路：**桌面捕获 → ntfy.sh/<topic> → 手机订阅 → 落库收件箱/今日**。
> 单向（桌面→手机）；today 快照回推是后续（spec §5b）。

## 1. 传输

- **服务**：`ntfy.sh`（公共实例；MVP 用**超长随机 topic** 当弱口令，敏感后再自托管 + 鉴权）。
- **发布（桌面）**：`POST https://ntfy.sh/<topic>`，**body = 下面的 JSON 字符串**（即把 capture 负载直接作为 ntfy 消息正文）。可选 header `Title`/`Tags`，本契约不依赖。
- **订阅（手机）**：`GET https://ntfy.sh/<topic>/json`，**行式流**（每行一个 ntfy 事件 JSON）。长连接，断线重连。

## 2. ntfy 事件外层（ntfy 定义，我们只读取需要的字段）

```json
{"id":"<ntfy事件id>","time":1718000000,"event":"message","topic":"<topic>","message":"<我们的JSON字符串>"}
```
- 只处理 `event=="message"`；`open`/`keepalive`/`poll_request` 等忽略。
- 真正的负载在 `message` 字段里（字符串），需二次 `jsonDecode`。

## 3. 捕获负载（我们定义，放在 `message` 里）

```json
{"v":1,"type":"capture","id":"<客户端生成唯一id>","text":"想法正文","domain":"工作","dest":"inbox","ts":1718000000}
```

| 字段 | 必填 | 说明 |
|---|---|---|
| `v` | ✅ | 协议版本，当前 `1`；不匹配则忽略（向前兼容） |
| `type` | ✅ | 固定 `"capture"`；其它类型忽略 |
| `id` | ✅ | **幂等键**，客户端生成（UUID/时间戳+随机）。重发同 id 不重复落库 |
| `text` | ✅ | 想法正文，空串忽略 |
| `domain` | ⬜ | 领域标签，可空（→ 未分类） |
| `dest` | ⬜ | `"inbox"`（默认）或 `"today"`：进收件箱 / 直接进今日 |
| `ts` | ⬜ | 客户端时间戳（秒），仅参考 |

## 4. 手机侧落库规则

- 按 `id` 幂等去重：`Tasks.syncId == id` 已存在 → **跳过**（不重复插入）。
- `dest=="today"` → `scheduledDate = 今天`（进今日）；否则 `scheduledDate = null`（进收件箱）。
- `source = capture`；`domain` 原样写入。
- 解析失败 / 缺必填 / `v|type` 不符 → 静默忽略该条（不崩、不影响后续流）。

## 5. 手动验证（还没写 Mac app 时，用 curl 自测「桌面→手机」通路）

```bash
TOPIC=promptme-<你的超长随机串>
curl -d '{"v":1,"type":"capture","id":"t-001","text":"用 curl 发的想法","domain":"工作","dest":"inbox","ts":1718000000}' \
  https://ntfy.sh/$TOPIC
# 手机 App（设置里填了同一 topic 且开了同步）应在收件箱出现「用 curl 发的想法」。
# 再发一次同样 id=t-001 → 不应重复出现（幂等）。
```

## 6. 隐私 / 后续（未定）

- **隐私**：ntfy.sh 公共 topic 公开可读 → 先用超长随机 topic；敏感了再自托管 ntfy + 鉴权（权衡「最少运维」）。
- **后台接收**：App 被杀也要收 = 前台服务 / 推送，硬化项，**MVP 先做 App 运行时同步**。
- **回推**：today 快照双向对齐（spec §5b）后续。
