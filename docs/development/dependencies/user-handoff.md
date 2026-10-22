# Pourlune 首版：用户一次性交接清单

## 当前执行目标（2026-10-22 最新）

用户已接受现有效果，授权原开发连续推进至 TestFlight / Google Play **封闭测试提交前就绪**，架构负责监管和独立检查。实施顺序见[封测计划](../../pmpowers/plans/2026-10-22-beta-readiness.md)。后续由开发核实账号、签名、支持入口和设备的现状，将必须用户处理的具体动作汇总到 `beta-readiness-user-actions.md`；先继续可独立完成的工作，不要求用户重建已有账号或 Firebase 配置。下文包含历史交接记录，不将其中旧“未注册/无配置/仅有iOS运行”等状态直接当现状。

正式双端ID仍为 `com.pourlune.app`，Firebase开发/生产四App和配置已验；完整棋盘及页面转场已验且CI成功。真实Firebase收件、签名/设备/素材权属等分别按实际证据核验。达到可提交后再以具体候选包和资料交接实际上传/开启测试；当前不等同已经上传或分发。

2026-10-22；由产品架构整理。依据 B04 外部依赖与 B05 交付；具体内部验收状态见 ../review/B05-acceptance.md。2026-10-22用户已确认：Apple、Google、Firebase沿用FishPilot现有账号。账号来源已确认；Pourlune专属应用注册、配置、签名与真实联调仍分别核验，其他未交接项保持待办。

## 现在准备：真实服务联调和真机验收

|项目|请提供或安排|收到后我们完成什么|
|---|---|---|
|发布身份|个人/公司发布主体、联系人；确认应用名 Pourlune；正式 iOS Bundle ID 与 Android applicationId 已确认均为 `com.pourlune.app`；尚未注册，需核对注册结果。当前 dev.* 只作开发身份。可先反馈“尚未申请”，无需临时编造。|统一客户端身份、平台配置、候选版本及分发方案，避免配置绑定错误应用。|
|Firebase 开发环境|账号已确认沿用FishPilot；继续核对Pourlune所属Firebase项目和协作访问方式（沿用账号不自动认定共用FishPilot项目）；两端匹配开发身份的客户端配置：iOS GoogleService-Info.plist、Android google-services.json。若使用独立正式项目，另行标明。|真实初始化、Analytics DebugView 事件与去重、Crashlytics 测试报告/符号、Remote Config 有效值/坏值/离线回退，以及采集选择撤回。仅配置文件存在不算联调通过。|
|AdMob / UMP|你拥有的 AdMob 应用、iOS/Android App ID、插屏和激励广告位 ID；同意/隐私消息的配置情况及计划发行地区。通过授权账号协作或公开配置交接。测试设备登记由联调时采集。|先保持测试广告，核验真实展示、关闭无奖、earned 回调绑定原局并写入 SQLite、冷却、后台/锁屏中断与消息配置。当前共享样例 App ID 和受控回调不能代替这一步。|
|可连接设备|至少先安排一台 iPhone、一台 Android 手机，说明型号/系统版本/可用时间；提供数据线，解锁并按系统提示授权开发调试。尽量同时覆盖一台较小屏/较低性能设备；最低系统最终支持范围随设备验证确定。|Android 原生运行、两端 profile 性能与内存、真实断网/弱网、升级保留存档、VoiceOver/TalkBack、物理音频/系统中断和广告覆盖层。当前只有 iOS Simulator，未完成这些验证。|
|iOS 开发签名协作|Apple Developer / App Store Connect 沿用FishPilot现有账号；核对所属团队、签名负责人、可受邀协作方式；在本机按需完成账号授权/证书配置。先确认现有条件，不要求把密码或私钥交给聊天。|在已授权 iPhone 安装和运行候选；正式分发与上传另行授权。Android 本地 debug/profile 验收可先做，无需等商店账号。|

Firebase 与广告项目需明确区分开发、测试及正式环境。配置接入前会再次查官方资料，并核对真实 Bundle ID / applicationId。Remote Config 不能替你决定未确认的广告次数上限。

## 上架前必须补齐：可与联调并行准备

|项目|需要你确认/准备|通过条件|
|---|---|---|
|商店与签名|Apple Developer/App Store Connect、Google Play Console 沿用FishPilot现有账号，无需另建账号；核对负责人和Pourlune独立商店记录；最终签名/上传密钥由你控制；发行地区、目标年龄/受众、版本和上架资料负责人。|身份与签名一致；最终归档、内部渠道安装升级实测；商店资料和隐私披露与真实启用 SDK 对齐。购买、条款签署、上传和发布需另行明确授权。|
|支持和隐私入口|真实 HTTPS 支持网址、隐私政策网址、有效反馈邮箱、处理来信和隐私请求的负责人。可给已有域名或确认需要后续部署，不能填示例地址。|链接真实打开、邮箱能收件、运营主体/地区/数据用途文案获你确认。现有英文 help/privacy 是草稿，未部署或法律批准。|
|素材商业使用权|原 UI、原/派生插画、图标等的来源和允许商业发行的依据（授权、合同或原创归属证明）；确认最终图标和商店截图。|素材权属记录关闭 UNCONFIRMED。Nunito OFL 与本地音频来源已有记录，但不能据此推定整套视觉素材可商用。|
|产品与内容最终确认|确认 60 主线、30 每日候选编排及实际试玩难度/节奏；审核正式语言、商店介绍和干净截图。|候选内容经真人试玩确认；QA 种子、开发标记、测试广告画面不直接作商店素材。参考解验证不等于真人难度已通过。|

## 交接方式与后续顺序

1. 先回复现有账号/项目、身份、设备清单和负责人；缺少的逐项标“未建立”。无需一次完成所有注册才能开始设备测试。
2. 优先使用平台邀请或本机授权。客户端公开配置通过项目约定的本地配置方式提供；私钥、签名密码、验证码、服务账号和访问令牌不放聊天、Git 或验收日志。
3. 我们核对资料后由原执行聊天完成配置与真机/SDK 联调，本聊天独立验收并修复缺陷；只对实际通过项更新状态。
4. 完成全部发布门槛后，再单独确认内部渠道上传或正式发布。当前内部验收与分支推送不等于商店发布批准。

首版不需要新增账号系统、云数据库、业务服务器或云同步服务。仅静态支持网站和上述可选 SDK 服务依赖外部配置。

## 账号复用记录（2026-10-22）

- 来源：用户明确指令“Apple / Google Firebase账号沿用Fish pILOt的帐户”。账号来源确认不等于控制台登录、协作权限或Pourlune应用注册已完成。
- 只读查到FishPilot当前本地主线工作区的iOS工程Team为 `T7U878Z8H6`；这是已有工程记录，Pourlune使用前仍核对实际团队归属和可用签名。未读取或复制私钥。
- FishPilot旧checkout存在 `fishpilot-staging`、`com.fishtk.fishpilot` 客户端配置，已按其AGENTS定位当前工作区；旧配置仅作历史线索，不复制进Pourlune，不据此声称当前Firebase项目/访问权限已核验。
- 本次没有授权共用FishPilot Firebase业务项目、广告位或应用身份，也没有确认AdMob账号。开发方先盘点Pourlune专属配置缺口，再在相同账号下推进适用准备。
- 不新增账号、认证能力或FishPilot后端依赖；不修改FishPilot工作树、商店状态或运行服务。

## 只读预检已验收（2026-10-22）

架构已独立确认Apple/Play/Firebase现有会话及FishPilot对象可见；无需重复新开户或当前重新登录。详见[预检验收](../review/account-reuse-preflight-acceptance.md)。Pourlune专属注册、Firebase文件、iOS资源/符号上传、签名和真机仍未完成。

当前需要收束的选择：正式双端应用ID已由用户确认改为 `com.pourlune.app`；同账号下建立独立开发/生产Firebase项目（候选 `pourlune-dev` / `pourlune-prod`，未查重/未注册）。应用ID与Firebase开发/生产项目隔离均已确认；用户已授权执行聊天完成注册和配置接入，实际结果以本批交付及独立验收为准。Apple控制台另有Paid Applications Schedule待持有人核对处理；不代签。AdMob归属因连接失败未知，需恢复可读访问；当前无连接真机。其他原有门槛不变。

## 正式应用 ID 确认（2026-10-22）

用户明确确认 iOS Bundle ID 和 Android applicationId 均使用 `com.pourlune.app`。该决定取代预检报告中的 `com.fishtk.pourlune` 建议；预检报告及冻结证据保留为历史记录。身份命名确认不代表已完成Apple/Google/Firebase/AdMob注册或查重。开发身份 `dev.pourlune.pourluneDev`、`dev.pourlune.pourlune_dev` 与隔离QA身份保持现状，正式配置接入时按环境核对，不直接替换现有测试安装。

## Firebase 注册与接入授权（2026-10-22）

用户已确认按建议分开发、生产项目，并授权「Pourlune ｜ App 设计 开发」完成注册与配置接入，由架构独立验收。开发项目绑定现有两端开发ID；生产项目两端均绑定 `com.pourlune.app`。优先project ID为 `pourlune-dev` / `pourlune-prod`，如已被占用可使用保留产品及环境标识的唯一后缀，以实际回读值为准。无需再请用户确认环境分离或自己代办全部注册；仅在必需登录、持有人协议、未知必填信息、权限或设备操作时反馈具体缺口。执行计划见[本批任务](../../pmpowers/plans/2026-10-22-firebase-registration-and-integration.md)。注册与接入尚待执行验收，生产发布未授权。

## 本批注册及接入验收进展（2026-10-22）

Pourlune独立Firebase项目pourlune-dev / pourlune-prod及四个双端App已建立并由架构独立核验；四份配置已由执行方取得，无需用户下载搬运。配置实现、双端可用运行与安全RC恢复已按独立报告限定范围通过。Analytics/Crashlytics实际收件仍未通过；Android运输诊断有连接/TLS失败，iOS根因待补证。Apple Developer标识注册需要恢复[已有账号登录](https://developer.apple.com/account/resources/identifiers/list)，不是新开户。Firebase生产注册不能替代Apple/Play注册；正式签名与发布仍待办。详细见[本批独立验收](../review/firebase-integration-acceptance.md)。


## 2026-10-22：Firebase 收件定位新增依赖

注册配置已验收且实现CI成功。有限实验已记录双端原生连接失败，详见 `../review/firebase-receipt-diagnosis-acceptance.md`；不需要重新建账号/项目或下载配置。需要核查当前访问路径到 app-analytics-services.com、firebase-settings.crashlytics.com、crashlyticsreports-pa.googleapis.com 的正常TLS连接，或提供已有获准可用网络再做一次dev收件复验。不关闭证书验证，不自动更改代理/安全设置；现有证据未确定具体网络根因。Android Analytics日志未暴露目标主机，不将其误标为上述某一个。控制台实际收件及可读崩溃栈仍未通过。

动效M01–M08继续执行，本外部依赖不阻塞。Apple登录等此前事项不重复列出。
