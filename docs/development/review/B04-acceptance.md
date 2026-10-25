# B04 独立验收

**最新结论：第二轮可独立验证的实现范围通过，R01/R02/R03已关闭；真实广告展示/获奖、Firebase及正式发布条件未通过，详见文末。允许推送并启动B05不依赖这些条件的工作。**

## 第一轮历史记录

2026-10-22（Asia/Taipei）。验收方：Pourlune ｜ 产品架构。基线HEAD `1b6b477`；对象为B04未提交工作区及 deliveries/B04.md。**结论：退回修复。B04-R01（P1）与B04-R02（P2）关闭前不提交推送，不进入B05。** 不把作者自查、SDK替身或测试库存超时当作真实展示/到账通过。

## 主审实际检查

- 阅读九项执行计划、交付与外部依赖台账，核对未跟踪源码、配置与锁文件；以新上下文独立审查复核广告/隐私/奖励边界。
- `B04-evidence/checks.json`：app源码格式退出0；flutter analyze退出0；主审完整Flutter 147项通过（55.75秒）；核心Dart30项通过（0.74秒）。它们不包含随后新增的两条失败用例。
- `B04-evidence/source-hashes.json`记录受审源码指纹。原始设计包未修改。所有命令实际工作目录见checks.json。
- 主审新增真实SQLite文件＋生产AdCoordinator的最小回归，源码留存 `B04-evidence/architecture-regression.dart`，运行副本 `app/test/b04_architecture_regression_test.dart`，日志 `architecture-regression-red.log`，退出1、2项失败。广告运输层为可控制替身，未称原生广告已复现；SQLite是真实ffi事务。新增用例交由执行方正式整合。
- 读取已锁定google_mobile_ads9.2.0实际源码的MethodChannel派发与dispose实现，并核对[Google Flutter激励广告官方说明](https://developers.google.com/admob/flutter/rewarded)（2026-10-22读取）。已展示广告不能由程序移除；正常关闭后的dispose是官方建议，不列为缺陷。这里的问题是尚未关闭就被计时器dispose。

## B04-R01 · P1 · 已展示广告被120秒watchdog提前释放

定位：`app/lib/services/ad_coordinator.dart:295`，`finish`的269/283/285，以及shown的298–303；实际适配器 `google_ads_transport.dart` dispose调用真实ad.dispose。

复现：成功load→show→实际shown→切后台→超过showTimeout，尚无closed/failed回调。现代码仍finish(timeout)，showing变false、handle被dispose、show Future结束。主审用40ms注入同一生产定时器分支并等待80ms，预期仍持有展示所有权，实际false；详见失败日志。

影响：真实广告覆盖层可能仍在显示；控制器会提前结束等待并安排导航。插件9.2.0 `ad_instance_manager.dart:747–755`先从_loadedAds删除adId，事件入口60–77随后找不到该广告，因此之后真正赚得的奖励可能不再到达业务层。后台两分钟后回来或长互动广告均会触发风险，不依赖mediation关闭后乱序假设。替身保留回调函数会掩盖这一实际路由问题。

要求：区别“尚未收到展示确认”的有界等待与“已实际展示”的原生生命周期。shown后不可仅凭时限解除原生所有权、dispose或导航；等待真实关闭/展示失败，后台/前台切换保留正确归属。保留未展示/平台调用不回的超时降级；disposed页面/进程能力按真实SDK边界处理，不凭时长发奖。

复验：shown后跨越超时与后台/前台，仍未dispose、未导航；后续真实earned事件仍按原attempt落盘一次，再closed；无earned仅closed不奖；预展示timeout与双击/旧回调保持原有防护。至少用模拟真实dispose会移除回调路由的适配器契约测试，原生测试广告获得库存后补相同路径。

## B04-R02 · P2 · 旧展示写入重试清除之后的新首通资格

定位：`app/lib/data/game_store.dart:726–746`（740–743无条件清零）、`game_controller.dart:945`及随后advance。pendingTiming只有kind/millis，没有展示时的计数边界。

复现：11/12/13首次完成累计3；13关插屏实际展示，但fullscreen事务写入失败回滚；系统允许免费继续，完成14后计数4；重试保存旧展示记录，当前代码将计数设0，预期保留14的1。主审真实SQLite故障回滚测试失败为expected1/actual0。控制器在retryTiming失败后继续advance，使这不是无法到达的存储层输入。

影响：重试消耗了实际展示后新增的通关资格，后续展示节奏偏移。没有实际展示不得清零、实际展示只消费此前累计，不能等到重试时抹去后续进度。

要求：为实际展示保存可重试、幂等的资格消费边界，只消费该次展示前的累计；之后的首次完成继续累计。保留免费玩法可用、实际展示才计数、共享180秒、已有迁移数据和重复showId不重复消费。不要用阻塞整个离线玩法来掩盖。

复验：上述真实SQLite回归＋完整Controller：13shown写失败→进入14并完成→故障解除→旧记录重试→保留1；重复重试仍1；后续15/16正确计数；rewarded不消费插屏资格；旧版本迁移和重启保守恢复边界明确。

## 本轮未完成与真实依赖

由于两项明确逻辑缺陷，本轮尚未复跑作者双端构建、UMP原生及布局回归，不将它们写为独立通过。修复后继续本批必要原生复验与最终构建。作者记录的真实官方UMP表单完成不等于用户所属应用配置通过；测试广告库存超时不等于展示/奖励验证通过。

Firebase项目与公开匹配配置、正式身份、AdMob消息归属、支持URL/邮箱、商用权属与代表设备仍依台账处理。可继续独立开发，尚未到只能等待用户的阶段。正常Google直投保证奖励先于关闭、正常dismiss后dispose与官方文档一致；mediation未接入，任意迟到原生回调未获保证，不要求用任意延迟虚构保证。


## 第二轮独立复验（2026-10-22 08:12 Asia/Taipei）

结论：**B04实现与已具备环境的内部验证通过；真实服务联调仍为部分完成，不构成发布通过。** 本轮检查共享工作树，受审最终源码指纹见 `B04-evidence-r2/source-hashes-final.json`。R01/R02通过后，另发现并修复R03；最终可提交。后续B05八项工作包见 `docs/pmpowers/plans/2026-10-22-B05-release-candidate-validation.md`。

### 缺陷闭环

|编号/严重性|实际复验与结果|结论|
|---|---|---|
|B04-R01 / P1|生产shown取消预展示计时器；插件9.2实际Dart AdInstanceManager路由测试在Android/iOS事件协议下跨deadline、前后台输入仍保留adId，earned只发一次、仅closed无奖，实际closed后才dispose。主审整套159测试包含这4项；iOS原生sqflite+Flutter受控运输流程验证停在13直到关闭，见 native-repairs/native.json。|实现缺陷关闭。受控事件不等于真实广告跨后台/获奖通过。|
|B04-R02 / P2|schema5展示前持久化资格边界；只实际show消费水位，Reset不回拨total。主审真实sqflite非空4→5保留双槽/待确认权益/旧资格；13写失败→14累计4→旧记录Retry剩1→重复仍1→15为2→16为3→展示后0、进入17。|关闭；旧v4未知展示仍保守，不伪造历史确认。|
|B04-R03 / P2|本轮静态发现 nextLevel 广告关闭后读取异常会跳过advance/finally遗留_adFlow。执行方构造真实SQLite SELECT溢出，确保广告前读成功、关闭后读失败；修复前4项在目标异常断言失败，补容错后通过。主审复跑17项包含前/后台×下一快照成功/失败，失败仍停原局，Retry落盘才前进。|关闭；这是受控数据库故障验证，未声称物理磁盘损坏。|

### 主审实际执行

所有新日志在 `B04-evidence-r2/`。命令、目录、退出码和时长见 checks.json、final-checks.json、asset-checks.json、ios-*-result.json。

- app/core `pub get --enforce-lockfile`，app/core格式与analyze均退出0。R03前完整Flutter **159项通过**，核心 **30项通过**；R03后针对性 **17项通过**（含4项新增读故障和相邻广告控制器/资格回归）。不把不同快照合称一次163项全套执行。最终app格式/analyze再次通过。
- 两份图像manifest check与23项assets单元通过，权属仍UNCONFIRMED；原设计包未修改。轻微项：Restart320/2x宽度及无异常由本轮widget测试验证，另人工查看作者native-design/15-qa-7-bottle-actions-320-text2.png作补充，未将作者运行计为主审原生复跑；Rules返回Settings已在主审普通App操作验证；连续同色单标记已查实际绘制代码及主审普通App截图。
- 主审iOS `b04_repairs_native_test.dart`：1通过，退出0，79.03秒；真实sqflite与Flutter，广告/前后台为受控输入、关卡为工程别名。截图与native.json已在runner结束前复制；这个测试本身不证明进程恢复。
- 主审iOS `b04_services_native_test.dart`：1通过，退出0，111秒。真实插件返回UMP allowed=true、failed=false、options_required=true；Extra说明显示，点击前reward_attempts=0；官方奖励测试位加载30秒timeout，fullscreen/entitlements/attempts均为空；免费动作已保存，独立privacy选项可见。**没有真实广告展示或获奖成功证据。** Firebase disabled。
- 最终Android `flutter build apk --debug`退出0（9.77秒）；最终iOS `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --simulator --debug --dart-define=POURLUNE_DATABASE=b04_review_r2.sqlite`退出0（65.72秒）。实际普通入口、独立审查库；没有为本轮伪造Firebase配置/广告库存。debug构建不是商店产物/真机验证。

### 普通App人工操作与视觉证据

使用既有 iOS26.5 Simulator `4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2`。最终普通App构建后安装一次，经CUA实际操作，无HTML替代：

1. Start→教学第1步瓶1倒向瓶3→第2步、1 move。固定标签/单段符号可见，保存提示存在。
2. 同一安装执行simctl terminate，再launch（PID5640→5800），Continue恢复同棋盘、1 move、教学第2步。见 manual-before-terminate 与 manual-restored 的PNG/AX；无卸载/重装夹在中间。这只证明本次已保存动作冷恢复，不能替代通关写入中断矩阵。
3. Home→Settings→How to play，返回按钮语义为Settings，操作返回设置；见manual-rules.txt。
4. Send feedback在未配置邮箱时显示“The support address has not been configured. No message will be sent.”；未发送消息。见manual-feedback-unconfigured。
5. Privacy choices两独立开关默认0、无项目时明确diagnostics unavailable。见manual-privacy-defaults。
6. 从App打开真实官方UMP隐私表单，选择Don't sell or share my data→Save and close，返回设置。见manual-ump-options/selected/returned。此为官方共享测试App的本机US表单，不是发布主体的配置归属、全球地区合规或ATT认证。

### 任务/AC通过边界及遗留门槛

|任务|本轮可通过范围|仍未验证|
|---|---|---|
|B04-01/09|版本/锁文件、dev身份、默认关闭的公开配置边界、双端debug编译、host/native存储回归|正式签名/身份、Android实际运行、远端本提交CI（提交后另查）|
|B04-02/03，AC13–18/32|集中互斥/Next节奏/资格水位/180秒时钟/失败降级的控制器与存储测试、iOS受控流程|真实插屏展示、真实广告OS中断与实际SDK冷却链|
|B04-04/05，AC19–21及AC07/18|原实例权益、事务去重/恢复与替换、UI说明/免费降级、实际插件Dart路由契约|真实SDK earned→SQLite端到端、原生极端回调时序；未收到未落盘确认不能恢复|
|B04-06|独立选择默认关闭/持久化host验证、官方UMP资格与表单人工操作|正式归属的地区配置、代表设备与未来如需跟踪时的ATT流程|
|B04-07，AC34/36|可选初始化/RC严格验证/本地事件去重的host测试、无Firebase配置disabled真实启动|Firebase原生初始化/网络撤回/DebugView/Crashlytics收件及符号/RC控制台|
|B04-08及AC31局部|三项轻微UI修复、设置入口、未配置支持提示、英文DRAFT资料|真实域名/邮箱/负责人、法律文案批准、全设备/读屏及商用权属|

外部依赖沿用 `docs/development/dependencies/B04-external-handoff.md`。没有新增产品范围，没有应用未确认广告会话/24h上限。可继续B05内部候选工作；**B04完整真实服务联调与首版发布门槛仍未全部通过**。不可把本次推送描述成可上架或全平台验收完成。
