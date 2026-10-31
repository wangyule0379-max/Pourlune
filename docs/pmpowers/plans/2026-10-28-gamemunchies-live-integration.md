# GameMunchies 统计与广告控制补齐计划

> 执行：现有“Pourlune ｜ App 设计 开发”按执行计划逐项实现；“Pourlune ｜ Use Computer”独占后台和设备操作；总控负责独立审查。不新建聊天，不要求逐步骤汇报。

**目标：** 用户在 GameMunchies 看得到对应版本的真实统计，并能通过后台控制 Pourlune 已有插屏和加瓶激励广告。

**方案：** 复用 `gamemunchies_client`，保留现有 Flutter、SQLite、AdMob 和奖励事务。先在独立测试登记验证，然后把明确的正式登记和生产统计配置接进后续分发候选；广告仍为现有官方测试模式。需要的 SDK 改动回到同一通用 SDK，不在游戏复制另写上报或配置客户端。

**依据：** GameMunchies `docs/game-integration/README.md`、`advertising-integration.md`、`sdk/dart/README.md`；Pourlune 原统计接线报告与当前 SDK。用户已要求直接完成、不要自加审批流程，执行本计划无需再问一次方案许可。

## 最新授权与真实基线

- 本聊天用户随后明确：**“把统计和广告控制都接好，你实际验收通过后，让开发更新 TestFlight，确保我能在后台看到数据、控制广告，不要再只停留在测试包里。”** 本轮必须包含新 TestFlight 分发；此句覆盖此前等待具体上传范围的限制。总控实际验收通过后由原开发完成新版本，不再重复询问上传许可。
- 总控实际读取 GameMunchies 总控 `01a16818-affe-7f01-9761-2873d36bd4aa` 中的人类最新要求：客户端单独使用 `api.gamemunchies.com`，不携带管理后台地址，且直接实施。该域名已由对应工作流发布验证。**本轮 Pourlune 新客户端/正式候选使用 `https://api.gamemunchies.com`；管理界面仍用原 studio 域名。** 旧地址只保留兼容。17 尚无 GM，正式用户无需迁移旧 GM scope；独立测试包切 origin 会产生新作用域，旧队列/ID不伪迁移，原SQLite广告冷却仍须保留。
- 总控实际读取 Use Computer 聊天 `01a17b8e-aee4-7322-ae34-7b8d1531cae4` 的人类消息 `01a180df-e440-7e12-b17e-1d542bf35078`：**“那就把 GameMunchies 的统计和广告设置接好，让我能在后台看到数据并控制广告。”** 此授权覆盖第一版“远程控制后续再做”的限制。
- 已上传 TestFlight 17 的运行源 `5fb8b79a8f228a0ece125fba7aa8bb91e2d48b3a` 不含 GM；不把其包内不存在的功能称为上线。
- 当前主工作区的统计接线 `d86891bdebe0ac804934c84ad7bb672f7a1273f4` 使用 `gamemunchies_client` 0.1.0，SDK 源 `a954fbace61ef16539a762833b6a286a4f373a5f`。已验证的测试事件、持久化和重试证据复用，不重跑完整 UI / 题库。
- 独立测试登记 `566121d2-a3f5-4950-8bd9-6ff2f673a0ac`，两平台 `com.pourlune.app`，`environment=test`。
- 正式登记 `8feaf0dc-ec12-4308-ac58-16b2180f2d63`（Pourlune App），两平台当前页面登记 `com.pourlune.game`，应核对并更正为工程真实 `com.pourlune.app`，保留已有 gameId，不另造 ID。
- 2026-10-28 当前后台两平台显示“等待数据”，广告能力未声明。当地源码 `dist/app.js:406` 请求 stats 未传 environment，Worker 默认 production；界面无 test 筛选。历史 test 数据不能据此判定丢失。公开静态资产读取返回 403，本轮未绕过或反复探测；线上行为还须通过正常后台操作确认。

## 全局边界

- 一个 scope 一个 SDK 客户端；启动与离线玩法不能等待上报服务。
- `round_start` 只在新实例首次成功落盘；保留稳定 ID / 首次时间、恢复不新开局及现有去重。
- 活跃由 SDK 生命周期处理；广告展示只认实际 `onAdImpression`，加载失败只认 SDK 实际加载失败。广告关闭、调用 show、加载成功都不能冒充展示。
- Analytics 关闭时不得采集或发送 GM 统计；远程广告规则不能因 Analytics 关闭而失效。必要时最小扩展通用 Dart SDK，分开规则拉取与统计同意；不得通过开启统计来换取控制。关闭后的持久队列不得继续偷偷上传。
- SDK 管理员身份、Cookie、令牌不得进入客户端、公开配置或提交。后台管理操作留在 Use Computer 的已授权会话或支持的管理工具，不提取浏览器凭据。
- 测试用独立 gameId + test + 官方测试广告；正式候选使用正式 gameId + production。测试统计和正式统计明确展示，绝不把测试记录搬迁成生产数据。
- 不开启付费/正式广告，不接 MAX / 横幅，不改题库、固定目标、奖励规则或清存档。不自行公开商店发布。
- F9 和原保护设备、历史库全部保留。CLI 由原开发串行；实际 GUI / 模拟器由 Use Computer 执行，先 inventory。

## 任务 1：后台登记与可见统计

**涉及：** GameMunchies `dist/app.js`、`dist/api.js` 及已有 stats / UI adapter 测试；相关后台登记。开发改代码，Use Computer 操作真实后台。

- [ ] 记录正式/测试两登记两平台当前 appId、capabilities、config/version；只更正本项目的错误 appId，不触碰其他游戏。
- [ ] 用现有后台能力提供明确 test / production 统计筛选，默认 production，所有总览/游戏/平台请求一致携带 environment；没有数据时说明环境，不把空值伪装成零。若线上已支持则直接使用，不重复建 UI。
- [ ] 复用历史测试记录验证 test 能显示且 production 不混入；只补环境切换请求与过期响应不覆盖当前页面的针对性测试。
- [ ] 后台初始能力只声明 interstitial `next_level` 和 rewarded `extra_bottle`。默认配置使用下方数据，两平台分别登记；能力初始化已有时比对，不能覆盖不同配置或重置版本。

```json
{"initialConfig":{"enabled":true,"interstitial":{"enabled":true,"scenes":{"next_level":true},"minIntervalSeconds":180},"rewarded":{"scenes":{"extra_bottle":true}}}}
```

该值来自当前应用 `GameMunchiesReporting.defaultConfig`，不代表启用真实收费广告。当前后台没有首次 capability UI；先核支持的已认证管理路径。若工具或权限缺失，由开发准备最小合法初始化入口/资料并集中说明实际阻塞，不复制 Cookie、不虚报完成。

### 实际管理缺口补充

Computer 与父源码检查确认：当前 PATCH 仅支持改 name，没有编辑既有平台 appId 的 UI/API；capability 已有受认证 PUT，但无 UI。`UNIQUE(platform, app_id)` 又使错误占用 `com.pourlune.app` 的测试登记与正式登记冲突。父核旧真实测试包为 iOS `dev.pourlune.gamemunchiesValidation`、Android `dev.pourlune.pourlune_dev`。优先让测试登记匹配真实 QA 身份，再为正式登记保留 `com.pourlune.app`，保留两 gameId 和历史统计；不要先删除全局唯一约束或迁移/伪造历史数据。开发核下一轮 QA 身份后，在既有认证/RBAC/CSRF 机制内补最小 appId 编辑和首次能力登记界面，复用已存在的 capability API；冲突应明确报错，已初始化配置不能被重置。Computer 在正常 UI 中操作，不绕过界面限制调用浏览器脚本管理接口。

## 任务 2：接通规则，保留隐私与奖励

**涉及：** `app/lib/services/gamemunchies_reporting.dart`、`service_hub.dart`、`ad_coordinator.dart`、`google_ads_transport.dart`、`service_policy.dart`、必要应用控制器；通用 SDK `sdk/dart/lib/src/client.dart` / options 及其测试。

- [ ] 保留已验统计接点，显式支持经核验的正式和独立测试配置，拒绝未知 ID / 环境错配。
- [ ] 加载前、异步返回后、show 前检查最新 GM 类型/场景规则，叠加本地 consent、广告模式、首通资格、全屏互斥、前台与机会有效性。远程总开关与已有 Firebase 安全开关任一个关闭均不能请求/展示。
- [ ] 使用 SDK 配置缓存和刷新限频；启动离线沿用既有策略默认值，失败不阻塞玩法。后台不是瞬时开关，报告实际客户端收到版本的时间。
- [ ] 插屏默认 180 秒。核清现有固定全屏冷却与远程插屏间隔的关系，给出唯一、可验证的有效间隔，避免后台已变但被未说明的固定值遮蔽。保留未授权更改的首通/全屏安全条件；若仍有安全下限在报告中明示。
- [ ] 关闭后取消尚未开始的请求/机会，不能迟到补弹；已经展示的广告允许完成，合法奖励仍按原 SQLite 事务、原实例和凭据发放一次。上报失败不影响奖励。
- [ ] 统计同意与广告规则独立：Analytics off 时依然拉规则，禁止 active/round/impression/failure 事件排队与发送；同意切换保留原代次防竞态。测试默认值/缓存/同意撤回/异步关闭和广告进行中关闭。
- [ ] 缺省/关闭远程激励不能被错误当作 disabled 本地免费加瓶捷径。沿用既有已确认的具体广告模式，不新增免费发奖分支。

## 任务 3：可复现构建与实际联调

**涉及：** `app/pubspec.yaml` / lock、`app/config/gamemunchies/`、构建配置/CI、SDK 来源记录、现有测试与 QA 入口。

- [ ] 先明确 SDK 可被干净构建取得的固定来源。保持通用 SDK 本地依赖或受控内部归档，不公开私有 SDK、不复制一份独立修改、不把 sibling path 缺失当通过。准备最小可用方案；若唯一方案需新账号/仓库公开权限，集中列明再请用户，不自行曝光代码。
- [ ] 开发完成代码/聚焦检查/正常 main 测试包后，一次性交 Use Computer 执行。复用原重试证据，只针对新增的统计开关与配置控制补差额。
- [ ] 两平台实际新局、前后台统计在正确 test 后台可见；同一事件重试保持 ID/时间、恢复不增加新局。
- [ ] 真实后台关闭、恢复 next_level / extra_bottle，客户端收到对应 config version 后按预期请求/跳过。测试 Analytics off 的规则仍生效且统计不增加。
- [ ] 官方测试广告实际 impression、奖励/关闭，后台增量和本地实际回调关联；没有填充时精确标未验证，不用 show 调用或假事件顶替。
- [ ] 网络不可用仍启动/游玩；已存在离线缓存与重试测试不整套重复，仅补本次策略和隐私差额。

## 任务 4：独立验收与用户可用版本

- [ ] 开发交付 `docs/development/deliveries/gamemunchies-live-integration.md` 和同名 evidence，按 iOS / Android / 后台列通过、未验证、实际来源与配置；仅结果上报。
- [ ] 总控读代码与实际图/事件/配置版本回执，对照隐私和商店披露差额。不能以 SDK 单测或旧 QA 包代替当前用户版本。
- [ ] 新 TestFlight 候选必须包含已验接线，明确版本、正式 gameId `8feaf0dc-ec12-4308-ac58-16b2180f2d63`、`environment=production`、线上服务、官方测试广告模式和真实统计同意门控。不得再排除 GM 来解决 CI 或拿旧17称完成；新版本号先查空闲，不重复上传17。
- [ ] 总控实际检查真实配置控制/事件回执、候选来源/SDK固定来源/隐私配置及包内生效开关后，明确通知原开发上传并完成原 Pourlune Self 组。Use Computer 执行 GUI；分别回读上传、处理、组可安装，不重邀现有测试员，不公开发行或开启收费广告。
- [ ] 正式分发后由真实安装产生数据；后台回读实际安装/开局/展示与开关效果。未完成这一项前不能说“用户已经能看数据并控制广告”。
- [ ] 独立 QA 的测试数据和真实用户正式数据分开；不向正式环境制造演示统计。现有统计同意仍有效，关闭统计时无数据是预期，远程规则继续生效。交付时清楚给出后台正式登记/平台/环境入口及 App 统计开关位置；不能为满足面板有数字擅自打开用户统计。

## 审查重点

- 用户关统计，配置仍需生效而事件不能发送。
- 后台切环境不能显示旧请求的错误统计，不能将 test 复制为 production。
- 广告载入/等待期间关闭，show 前不能漏检；已获奖励不能撤销。
- SDK 本地依赖不能让仅本机能编译的包冒充干净 CI 可复现。
- 后台规则可能需刷新间隔后生效，实际说明版本/时间，不承诺即时控制。

## 2026-10-28 最新客户端地址专项

用户直接要求仅切换 `baseUrl: https://api.gamemunchies.com`（无 `/api` 后缀），检查构建、默认值和测试配置，重建后用原独立测试登记验配置、上报和重复去重。此专项不升级或重接 SDK，不改变 gameId/platform/environment、事件回调或 AdMob 策略，也不触发商店发布。此前获批的统计和广告控制实现另记差额；完整接入通过后才适用其 TestFlight 授权，不能把地址专项通过当作全项通过。

- 服务交付依据：`/Volumes/data/App Development/gamemunchies/docs/deployment/client-api-domain.md`。服务器同 Worker/D1、旧入口兼容；游戏验证不能用服务方的 HTTP 验证代替。
- 旧地址定位：`app/lib/services/gamemunchies_reporting.dart`、`app/test/gamemunchies_reporting_test.dart`、`app/test/gamemunchies_native_transport_test.dart`（根目录）、`tools/validation/gamemunchies_replay_probe.py` 及其测试。更新活跃运行默认值与测试配置；历史报告和旧作用域兼容夹具不批量替换。
- 父实际源码确认 SDK scope 是 origin/gameId/platform/environment 四元组；installationId、events、configEnvelope、lastShownAt 不会自动继承。已分发 TestFlight17 无 GM，无正式 GM 安装迁移；旧独立测试 scope 保留并与新 scope 分别记录，不能复制旧事件冒充新包产生。原 SQLite 存档和广告冷却保持。
- 开发交重建源、版本、SDK固定来源及仅地址差额；Computer 用既有独立测试 gameId 核配置、真实事件 ACK、同ID同首次时间重复 accepted=0。分别列 iOS/Android，缺项明确未验，不造管理员凭据或生产统计。
- 证据独立标为域名专项，不把同轮隐私或广告控制改动写成地址切换所必需。

### 后台并发发布已定位

Computer 管理UI发布 edd69da / Worker ac15f46c 于13:25:45完成；18秒后独立API域名工作流将 Worker3551e0c6 以100%上线，覆盖其UI。首次测试登记保存仅见通用失败，原appId未变；没有捕获HTTP状态，不推断数据损坏或具体SQL错误。域名工作流随后合并2416758，根目录4a27c6d含域名隔离与管理UI，两批代码均保留；对应聊天已idle。开发交冻结合并输出，Computer在明确窗口一次发布并先只读复核，再重新打开表单执行已授权登记。不回滚域名隔离、不重放旧表单、不迁移D1。
