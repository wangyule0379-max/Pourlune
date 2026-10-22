# Firebase 分环境接入执行交付（2026-10-22）

本批已自主下载四份真实客户端配置，建立独立开发/生产项目及四个 App，完成双端配置构建、真实 SDK 初始化、离线保存、采集选择和开发 Remote Config 验证。**Analytics DebugView 与 Crashlytics 控制台收件尚未通过**；Android 原生日志有 Google 服务连接关闭及 Crashlytics settings TLS 握手失败。不能据此确认 iOS 的同一根因，更不能把初始化、发送 API 返回或符号脚本退出成功当成收件。

本文件为执行证据，留待架构独立审查；未提交、未推送、未操作商店/正式签名。计划为 `docs/pmpowers/plans/2026-10-22-firebase-registration-and-integration.md`。基线 `d57f577`，共享执行分支 `codex/offline-foundation`；其他聊天的 tracking、motion 审查交付保持原属主。

## 注册与本地配置

| 环境 | project / number | iOS Firebase App ID | Android Firebase App ID |
|---|---|---|---|
| dev | pourlune-dev / 309263048936 | 1:309263048936:ios:176391f479157c675ca95d | 1:309263048936:android:46b23c29ec2729e25ca95d |
| prod | pourlune-prod / 499362682046 | 1:499362682046:ios:30475ed4d28b0f72c0baef | 1:499362682046:android:213e6189a7d6f853c0baef |

开发 iOS `dev.pourlune.pourluneDev`、Android `dev.pourlune.pourlune_dev`；生产双端 `com.pourlune.app`。B05 QA 未注册，FishPilot 项目/应用/文件未改。

两项目均 Spark 免费，创建时关闭可选 Gemini。沿用 Analytics **账号容器** 407469534（现有名称 FishPilot），分别新建属性：dev560151748、prod560150083。实际回读的数据流：dev Android16178472667、iOS16177185477；prod Android16178507769、iOS16178347289。没有选择/改写 FishPilot 原属性。详见 `../evidence/firebase-integration/registration.json` 及 dev/prod-analytics-registration.png。

真实配置仅在本机忽略目录 `app/config/firebase/{dev,prod}/{ios,android}/`，每平台原生配置＋options.json，权限600。源文件从 Firebase 正常下载按钮取得；浏览器实际下载位置为 `/Volumes/data/download/`，逐份按 project/App/native ID 匹配后复制，没有让用户搬文件。客户端 API key 未贴入日志/聊天/仓库，未使用服务账号或导出令牌。四组真实校验结果在 `config-real-validation.json`，摘要在 `configuration-summary.json`。

Apple Developer Identifiers 入口转到登录页，当前仅加载页脚，不能完成应用标识注册或重新核对 Team。历史预检的 Team T7U878Z8H6 仍是参考，**本批不宣称 Apple/ASC/Play 注册或包名可用性通过**。

## F01–F08 状态

| 项 | 执行结论 | 证据/边界 |
|---|---|---|
| F01 | Firebase/Analytics 注册完成；Apple 标识未执行 | registration.json、项目/属性截图；Apple 登录阻塞 |
| F02 | 完成 | 四份真实原生文件与 Options/注册矩阵交叉核对，错项目/平台/ID/字段失败且不输出配置 |
| F03 | 双端编译及环境切换通过 | *-dev/prod/none-artifact.json、构建日志；生产仅编译，未安装/运行 |
| F04 | iOS 实际符号工具退出0；控制台可读堆栈未验证 | ios-qa-symbol-receipt.json 与 ios-dev-restored-symbol-receipt.json；Android debug 不混淆，无 mapping/Dart symbols 上传适用项 |
| F05 | 双端初始化/默认关闭/选择/本地去重/撤回/保存通过；Analytics 收件未通过 | 首次 ready、consent、hint、revoke、saved-proof、final-state/board；Analytics 属性560151748最终0调试设备/0事件 |
| F06 | 双端受控非致命/native crash、脱离调试器同安装重启已执行；收件/可读堆栈未通过 | crash-on/restarted/pending、控制台截图、transport-diagnostics；关闭共享后另做 crash/重启观察删除，不把 pending bool 当传输证明 |
| F07 | 开发 RC 实际取回/非法值拒绝/缓存/恢复完成；Android 离线验证通过 | v1安全→v2非法JSON→v3安全，双端 valueRemote；Android 断网强制fetch失败仍可冷恢复、撤销/倒入/保存；iOS 未隔离系统网络 |
| F08 | 本执行包完成，独立验收待架构 | 本报告、README、白名单证据；外部未通过项保留真实状态 |

## 实现与复验

`tools/validation/firebase_config.py` 使用 stdlib，核对实际注册矩阵、原生文件、Dart Options、目标原生 ID 与构建定义。none 拒绝仅开启 native-ready，选中环境拒绝错平台、错项目、错 App、重复 Firebase 参数。iOS 验证后才写目标 `.app`，none 删除旧 plist；Android 仅明确选中时应用 Google Services/Crashlytics 插件，并覆盖该次构建的真实 JSON 输入。

`firebase_build.py` 使用临时私有 define JSON/Xcode override/input lists 和每进程 Gradle 属性，不交换仓库配置文件。广告在本批受控命令中关闭；生产仅允许默认入口 build，不接受测试入口/run/test，禁止符号上传。SDK defaults/隐私 gateway/产品规则没有改动，正常入口没有测试按钮。iOS 选中构建生成 dSYM 并关闭 debug dylib，默认离线构建保持原设置；SPM uploader 路径由当前 BUILD_DIR 推导。符号收据绑定准确 Firebase App、Mach-O 与 dSYM UUID、二进制/DWARF/原生配置摘要，**不代表控制台已可读**。Android prod mapping 上传明确关闭。

完整配置布局、四组校验与受控构建命令见 `tools/validation/README.md`。本机 Flutter 为 `/Users/wangyule/development/flutter/bin/flutter`。所有 Flutter CLI/原生构建串行，iOS统一 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`，未修改共享 SDK 源码或升级依赖。

实际验证：

- 根目录 `.venv/bin/python -m unittest discover -s tools/validation -v`：最终24通过（configuration/build gate/wrapper/symbols）；记录 final-review-target-green.log，原validation-suite-final.log为修复前21项。RED→GREEN 包括错配、原生 XML 错误、wrapper、符号 UUID/禁用/错误输出，以及 Flutter flat BUILD_DIR。
- app/ `flutter analyze`：0问题，flutter-analyze-final.log；`dart format --output=none --set-exit-if-changed integration_test/firebase_services_app.dart`：0修改。
- app/ `flutter test test/b04_services_test.dart test/b04_policy_test.dart test/b04_hint_events_test.dart test/b04_metrics_test.dart test/b04_review_regressions_test.dart test/b04_architecture_regression_test.dart`：23通过，services-test-final.log。没有重跑未受影响的全套 B05/全部平台验收。
- Android none/dev/prod/none/dev、iOS dev/prod/none/dev 实际 debug 构建通过。最终 dev 制品回读正确 App/project，none 制品没有 Firebase plist/Google App ID/Crashlytics build ID。Android 保留既定 FlutterFire built-in Kotlin 兼容预警，当前编译成功不等于未来版本兼容。
- `plutil -lint`、shell语法检查及 `git diff --check`通过。configuration-safety-check.json 记录真实客户端值/编码定义泄漏检查；本机配置保持忽略状态。
- 初次 services-test.log 使用了不存在的旧测试名而失败，最终运行改为实际 B04 文件，保留历史失败，不能以旧日志判定当前测试。早期 Android JSON 输入时序失败和 iOS SPM 路径失败保留各自 RED，修复后真实构建成功。

## 真实运行与适用 AC

独立 iPhone17/iOS26.5 Simulator `7C054CE1-CCA7-405E-A884-886A859D6968`；独立 AVD `Pourlune_Firebase_API36` / emulator-5582，API36 arm64 Google Play image，实际 GMS 已核对。使用 standalone `integration_test/firebase_services_app.dart` 委托正常 main/Bootstrap、正式60+30内容，命名库 `firebase_dev_native.sqlite`，无场景/种子。诊断命令是明确 QA 输入，不冒充玩家手工操作。

双端首次 off/off、automatic Crashlytics false、真实开发 App 初始化 ready；关共享仍可实际倒入并保存。开启后同一 hint identity 记录两次，仅一个 SQLite claim；关闭后 denied-event 不新增 claim。真实 nonfatal 后 native crash，分别从旧 PID97834/7004 到同安装新 PID98711/7790，未连接 Flutter 调试器或中途重装来代替该比较。早期诊断读取错 slot `main` 显示 saved=null，已改为 current.slot；原库只读核对及新诊断均确认普通实例/修订保存成功。此错误属于诊断取样，不是丢档。

RC v1全部广告false、列表[]；双端实际取回 valueRemote。v2仅将列表设为 not-json，SDK成功激活非法原值，ServiceHub拒绝且保留v1本地有效策略。v3恢复false/false/false/[]并在控制台和双端回读。Android专用模拟器临时 airplane-mode 后强制RC请求失败，冷启动仍使用有效缓存，撤销和倒入后修订从1至2至3；已恢复网络。QA强制0间隔只在测试入口，产品仍12小时。

AC-36：本地去重及既有事件/指标单测有证据，服务端分析收件未通过，不能整体标通过。AC-33：本批证明真实SDK下普通快照/native-crash冷恢复，不代替动画中强杀的B05专项证据。AC-32：既有广告控制器回归23项组合中的适用测试通过；本批没有新增真实广告展示/奖励结论。没有变更游戏胜利规则、奖励/迁移契约或发奖边界。

原普通安装和审查库未触碰；`protected-review-before.json`、`protected-review-after.json` 的 b04_review_r2.sqlite SHA256均为 `dc94bbfd1e8b10cda675f139a822c39e83dcc38bdf830c3a245d2221da9978c6`。原生SDK测试结束恢复双端采集 off/off、开发RC安全值、Android调试属性/网络、iOS -FIRDebugDisabled。

## 尚未通过与最小后续动作

1. Analytics：独立属性 DebugView 最终仍0设备/0事件。Android日志同时观察到 measurement已启用与GMS CONFIG请求ERR_CONNECTION_CLOSED，未证明事件已到服务端。后续在能正常访问Google测量端点的网络复验开发流，不能改TLS校验或扩大权限来绕过。
2. Crashlytics：双端控制台仍未给出issue/可读堆栈；Android settings请求有SSLHandshakeException。符号uploader退出0与准确UUID已留证，但收件仍需正常网络/服务端回执。send/delete是原生异步排队，期间pending=true不能当成功或实时删除证明；关闭共享后的同安装受控 crash：首次重启 pending=true，等待原生异步删除后再启动（期间不重装、不再崩溃），双端第二次重启 pending=false；见 off-crash-first-restart/off-crash-second-restart JSON。既有“已经排队传输不可撤回”的UI边界不变。
3. Apple标识：仅当继续Apple侧注册时，需要本人恢复 [Apple Developer登录](https://developer.apple.com/account/resources/identifiers/list)，随后仍可由代理处理已确认ID。配置文件下载和Firebase本地接入不依赖此动作；不重复要求用户下载或新开户。
4. 真机、生产签名、ASC/Play记录、商业权属、真实广告、生产发布未验证；本批没有接受法律条款、绑定付费方案、扩大IAM或操作生产RC/测试事件。

官方接入依据：[环境隔离](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)、[Flutter接入](https://firebase.google.com/docs/flutter/setup)、[SPM/dSYM及Xcode输入](https://firebase.google.com/docs/crashlytics/ios/get-deobfuscated-reports)。浏览器内部下载管理页曾被自动安全检查拒绝，已改用正常Firebase下载按钮和实际落盘文件核对；没有绕过被拒绝入口。模板文件上传需要未开通的扩展权限，改用同一控制台参数表单，不调整扩展权限。

## 本批实现取舍

- 沿用共享执行分支，保护其他聊天工作；代价是必须用明确文件清单检查并发变更。
- F01–F08按原计划标题逐项记账，不改写为脚本编号；代价是人工核对接口与覆盖范围。
- 复用Analytics账号容器、为Pourlune各新建独立属性；若混淆将影响统计归属，已用属性/流ID回读约束。
- 按下载文件实际身份选择本机同名文件；若选错会串环境，已逐份跨原生文件/Options/注册矩阵检查。
- 用户要求未验收不提交；提交范围脚本拒绝空range，改为明确文件清单的工作区审查包，代价是必须包含新建未跟踪文件。


## 最终代码审查与稳定交接

唯一一次fresh-context独立代码审查发现1项Important（生产目标的两种参数写法可绕过旧检查），已由作者复现RED、一次修复并使完整24项主机检查GREEN。生产最终target固定lib/main.dart，拒绝外部位置入口、附着短参数等冲突；其他生产参数值用--flag=value。dev诊断入口不受影响。真实Flutter CLI参数解析exit0，无第二次评审。完整记录 `../evidence/firebase-integration/final-code-review.md`；无轻微待办。架构独立验收仍未由执行方代标通过。

最终源码范围（相对项目根目录 `/Volumes/data/App Development/Pourlune`）：

- `.gitignore`、`AGENTS.md`、`app/README.md`、`tools/validation/README.md`。
- `tools/validation/firebase_config.py`、`firebase_build.py`、`firebase_symbols.py`、`test_firebase_config.py`。
- `app/android/app/build.gradle.kts`。
- `app/ios/Runner.xcodeproj/project.pbxproj`、`app/ios/Flutter/Services.xcconfig`、`Firebase.none.xcfilelist`、`firebase_config.sh`、`firebase_symbols.sh`。
- `app/integration_test/firebase_services_app.dart`。
- 本交付报告及 `docs/development/evidence/firebase-integration/`。tracking/motion/plans/user-handoff属于其他聊天，不纳入本批源码。

现有设备/制品供架构复验：

| 项 | 当前路径/身份 |
|---|---|
| iOS专用模拟器 | iPhone17/iOS26.5，7C054CE1-CCA7-405E-A884-886A859D6968 |
| iOS当前dev制品 | `/Volumes/data/App Development/Pourlune/app/build/ios/iphonesimulator/Runner.app` |
| iOS当前data container | `/Users/wangyule/Library/Developer/CoreSimulator/Devices/7C054CE1-CCA7-405E-A884-886A859D6968/data/Containers/Data/Application/9AE111AA-9529-4087-9A3B-89C93F6B9C27`；更新安装后应重新simctl get_app_container，不能硬用旧UUID |
| Android专用AVD | Pourlune_Firebase_API36，emulator-5582，dev.pourlune.pourlune_dev |
| Android当前dev制品 | `/Volumes/data/App Development/Pourlune/app/build/app/outputs/flutter-apk/app-debug.apk` |
| Android QA证据 | run-as dev.pourlune.pourlune_dev读取databases/firebase-evidence；存档databases/firebase_dev_native.sqlite |
| 本地忽略配置 | `/Volumes/data/App Development/Pourlune/app/config/firebase/`；供本机校验，不复制到聊天/仓库 |

当前同路径的最后制品均为dev诊断构建；prod/none的历史产物已由后建覆盖，对应原始校验/摘要/日志保留。需要重新检查二进制时按README串行重建，不把历史摘要当成当前文件身份。iOS同安装native crash重启取样发生在重装前；报告中标明的比较没有用重装代替进程重启。

最终取样中专用Android AVD出现“System UI isn't responding”（系统界面进程提示，见android-system-ui-anr.png）；执行方仅重启该AVD，保留存储，继续检查当前进程/存档/实际画面。它不构成游戏进程ANR或性能通过结论。

补充裁定及代价：生产参数用inline值以避免复制Flutter解析器（需要改变命令写法）；Apple/服务端收件继续未通过（服务验收未完）；真机/签名/商店/广告继续未验证（非发布准备通过）；其他任务改动保持所属审查（本次不覆盖）；双端第二次重启pending=false仅证明本地观察（不能推出服务端收件）。

AVD有界恢复结果：重启后PID3591，实例dev-1792640111597855-1553023926、修订3与落盘完全相同；双采集关闭、SDK ready、缓存策略安全；avd-reboot-restored/board.json与重新读取的android-real-board.png显示恢复后实际棋盘、无系统弹窗。未清数据或重装。最终运行/检查摘要见result-summary.json。源码已稳定，无Flutter CLI或原生构建运行；专用设备保留供架构复验。
