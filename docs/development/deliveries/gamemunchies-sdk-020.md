# GameMunchies SDK 0.2.0 游戏端升级

日期：2026-10-28。工作分支 `codex/pour-flight-size-fix`，实现基线 `1f077ce7bb280b212add141be2f40a2f352e8b17`。SDK 接入阶段已完成 iOS 实际验证。用户随后明确授权先更新 iOS TestFlight，确认无问题后提交正式审核；截至本记录尚未上传新构建。原有倒水 R03 修复、棋盘位置、广告策略、题库、存档与奖励事务不变。

## 实现

- 继续使用本地依赖 `gamemunchies_client`，固定 Dart 0.2.0，私有源提交 `6dac35372fb07cb0325e198792e4adf09dc75e29`；归档 11554 字节，SHA-256 `70effde1c9150b416b34f4dd4b6d95912ef836b5f429c98ea5a8cbf98fd0c167`。归档及全部 7 个文件已验证。SDK 源码不进入游戏 Git 仓库。指纹位于 `tools/validation/gamemunchies-sdk.json`，锁文件仅 SDK 0.1.0→0.2.0。
- `gamemunchies_reporting.dart` 为一次加载和一次展示机会创建独立随机关联 ID，每阶段使用稳定事件 ID 和首次时间。SDK 负责队列、重试和去重；没有另写上报 SDK。
- `google_ads_transport.dart` 将真实 AdMob 加载、加载结果、调用展示、展示失败、impression 和奖励回调分别接入新阶段事件。关闭、showed、load success 不冒充 impression；不再并用旧曝光方法。失败只发送协议允许的固定原因，不发送原始 SDK 错误或广告单元。
- `ad_coordinator.dart`、`game_controller.dart`、`service_views.dart` 只在实际机会记录阻止原因；UI 重建和库存轮询不生成机会。奖励仍由原控制器与 SQLite 去重提交。上报不被加载、展示或发奖路径等待。
- `service_hub.dart` 仍共享单个客户端。保存的 Analytics 选择与默认关闭政策保持，撤回不入队/补报期间事件；广告配置与真实插屏冷却不依赖统计同意，AdMob 资格由原 UMP/服务门控决定。
- 运行代码、构建选择和探针统一 `https://api.gamemunchies.com`。旧后台域名仅存在历史文档/管理回读证据，不是客户端请求目标。游戏 ID、平台与 AdMob 配置未重新登记或替换。
- GitHub Actions 两个 job 改用独立私有归档 secret `GAMEMUNCHIES_DART_SDK_ARCHIVE_V2`。Computer 已通过 GitHub 界面保存并看到确认，V1 保留；私有包的远端消费由本次新精确提交 CI 验证，不能复用旧 SDK 的成功记录。

## 构建及自动验证

版本保持 `0.5.0+19`，不代表已分发。实际测试游戏 `566121d2-a3f5-4950-8bd9-6ff2f673a0ac`，显式 `environment=test`，AdMob 官方测试 App ID/unit。Firebase 为 none，不发送生产 Firebase 测试事件。

- 聚焦 43 项通过；全应用一次运行 488 通过、1 跳过（仅手工夹具生成器，正常测试默认不生成）。后补旧 SDK 状态兼容验证，与既有漏斗/撤回验证合计 4 项通过；随后补统计关闭期间开始加载、开启后晚到回调不补报的守卫，5 项运输测试通过。没有因此重复全量。
- Python GameMunchies 配置/私有包/探针守卫 15 项通过；Flutter 分析通过；QA 回执归档小修单独分析通过。
- 原生 QA 和正常 `lib/main.dart` 入口均完成 iOS simulator、Android debug 构建。正常入口不导入 QA 代码。构建配置与二进制 hash 见 `evidence/gamemunchies-020/builds.json`。
- 自动验证包括加载/曝光分离、重复曝光、晚到与重复奖励、加载/展示失败分类、权益/隐私/后台/配置阻止、离线队列/丢 ACK 重试、撤回清队列、关闭统计后的冷却保存、旧 0.1 五字段队列保留 ID/首次时间/安装标识。故障回调的自动注入不是声称广告网络真实发生该故障。

## 原生和后台证据

电脑操作全部由已有 Use Computer 聊天执行；父复核源码、二进制清单、实际图片及回执。

### iOS 专用模拟器

`Pourlune GM QA 20261028`，iPhone 17 Pro / iOS 26.5，UUID `2894A85E-04FC-4857-A856-3BEFF2CCB565`，身份 `dev.pourlune.gamemunchiesValidation`。

- 更新同一安装，旧命名库保留；从升级前偏好与升级后 SDK 状态独立对比，安装标识相同、缓存配置 v4 保留。实际旧队列原本为 0；非空旧协议队列由自动测试另验，不冒称原设备带有旧待发记录。
- 真实 Google 官方测试插屏与激励已显示，奖励回调后 `extraBottle=true`，重启仍保留、无待提交奖励。实际图片已父查看。统计关闭时配置 v4、UMP 资格和库存仍可用，冷却期间阻止展示，冷却重启保留。
- 首轮诊断文件在后续重启被 QA 工具覆盖，限制保留在原报告。已修复为每进程独立归档并用新隔离库补验：离线入队 2 条，同安装正常停止/重开，同实例/原事件恢复 true；真实服务端首批 3/3 接收，丢一次 ACK 后重传 0/3 新增接收，原 ID/首次时间逐字段相同，队列归零。原始私密字段仅存 ignored 受限目录；公开独立结论见 `ios-recovery-independent.json`。
- 正常 `lib/main.dart` 入口实际运行：新隔离库统计默认关闭，开启后新 Level 2 使开局 16→17；Home/Continue/前台恢复仍 17，开始每日新局后 18。每日真实测试激励显示并关闭后新增第六缓冲瓶。父检查 SQLite integrity=ok、一次 confirmed/done 奖励、一次 entitlement、一次 rewarded 展示、每日 extra=true，普通槽不受影响。SDK 队列0、配置v4、冷却已持久保存。
- 最终服务端按 test/iOS/appVersion=0.5.0+19：机会4、阻止1（entitlement）、加载请求10、加载成功8、加载失败1（实际no_fill）、展示尝试3、曝光3、奖励2、乱序0。真实展示失败未发生，不能将自动故障回调测试称原生失败验证。原生统计开启时冷却阻止事件未专门观察，自动测试覆盖。
- 按 interstitial/next_level/admob 和 rewarded/extra_bottle/admob 分别回读，维度与实际调用一致。后台有1个 unstarted flow；关闭统计时的请求不回填，开启后的回调可独立记录，自动守卫已确认这种边界。聚合接口不能定位该具体流，不能强行声称已确定原因或补造起始事件。
- `totals` 只按游戏/平台/环境过滤，不支持版本/广告维度；test iOS合计活跃2、开局18、旧新曝光5、加载失败29，含旧测试记录，不能全归本次19。版本19的广告漏斗是上面的3次曝光。
- production iOS仍为活跃1、开局9、旧曝光1、失败0；production漏斗全0，Android production无记录。本次测试未进入正式统计。收入仍not_applicable/mapping_required，没有接OAuth或模拟收入。详 `backend-independent.json`。

### Android 专用模拟器（未完成设备验收）

`Pourlune_GM_QA_20261028` / API36 / emulator-5554，身份 `dev.pourlune.pourlune_dev`。初始 APK 已通过 Android Studio 安装且未清存储，首进程实际配置v1、离线队列2条已有图片及私密原件。普通 main APK亦构建成功，但设备点击未可靠送达。用户恢复停靠后仍失败；专用AVD冷启动/独立窗口方案均未解决，IDE设置已恢复，不用命令行绕过电脑操作约定。

Android同安装补传、真实广告、撤回/冷却及正常main实机流程未验；test Android既有合计2活跃/2开局，本次版本19漏斗0，不当作本次成功。用户最新要求优先iOS，不为此重复Android操作或阻塞已验证iOS的发布准备。

## 环境切换与边界

当前两端 QA 均显式 test，现有 ID/platform 不变。已获得iOS分发指令，正式构建的准确切换位置是 `tools/validation/beta_build.py --gamemunchies-environment production`（或 `firebase_build.py` 同名参数）；它选择既有正式游戏 `8feaf0dc-ec12-4308-ac58-16b2180f2d63`，按实际 ios/android 平台，正式原生身份 `com.pourlune.app`。客户端 `GameMunchiesReporting.environment()` 校验 ID/environment 配对。API 不变、不加 `/api`；`--ad-mode` 是独立已有选择，不因切统计环境自动改变广告策略。

未做物理手机/正式流量/官方 AdMob 收入报表验收。OAuth、Google 密钥及后台凭据未进入客户端。此前“仅验证、不发布”的任务限制已由最新iOS发布指令覆盖。TestFlight上传、处理、可安装及正式送审分别以平台回执为准；正式审核后手动发布。现有19尚未被占用，App Store草稿版本需匹配0.5.0。正式广告模式/销售地区/审核联系人为实际待填项，不能凭空填写。

操作偏差另保留事实：Xcode 曾未成功切换所选专用设备，向默认 iPhone17 Pro/iOS26.2 开始安装后被立即停止；只读发现该 QA 身份容器，没有清理或启动其数据的后续动作。F9 未触碰。后续运行前已按实际目的地核实专用 UUID。详 `native-ios-recovery/computer-report.md`，不能将该误目标当作已验设备。
