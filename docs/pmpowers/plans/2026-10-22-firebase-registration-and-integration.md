# Firebase 分环境注册与配置接入执行计划

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task in the existing execution chat. 用户已明确授权本批直接执行，无需再次等待计划确认。

**Goal:** 在沿用的账号下建立 Pourlune 独立开发、生产 Firebase 项目及双端应用，将真实配置接入原生工程并提供可独立复验的服务证据。

**Architecture:** 开发、生产项目隔离；开发环境绑定现有开发身份，生产绑定 com.pourlune.app。采用最小明确的环境选择与构建校验，保留未配置时服务关闭、离线核心可用和现有采集选择。

**Tech Stack:** 既定 Flutter 3.47.2 / Dart 3.13.2、已锁定 FlutterFire、iOS SPM、Android Gradle、Firebase 控制台。

**Spec:** AGENTS.md；docs/pmpowers/specs/technical-architecture-v1.0.md；acceptance-and-content-readiness.md；docs/development/deliveries/account-reuse-preflight.md（历史候选 ID 已被用户决定替代）；docs/development/dependencies/user-handoff.md。

## 已确认边界

- 2026-10-22用户已授权原执行聊天完成注册与配置接入，架构独立验收。Apple/Google/Firebase沿用FishPilot账号，但不改FishPilot任何业务项目、应用、文件或服务。
- 正式双端ID均为 `com.pourlune.app`。开发iOS为 `dev.pourlune.pourluneDev`，Android为 `dev.pourlune.pourlune_dev`；B05 QA身份不注册、不改、不误用开发配置。
- 建立两个独立Firebase项目，优先 `pourlune-dev` / `pourlune-prod`。先检查已存在对象与全球可用性；若被占用，可采用保留pourlune与环境标识的唯一后缀并记录实际值，不能借用无关项目或改变用户确认的应用ID。
- 本批包含免费项目、每环境两平台App注册、独立Analytics属性/数据流、客户端配置、开发项目的RC验证模板及符号上传。不得引入账号登录、数据库、业务服务器或新SDK。
- 注册不等于生产发布；生产项目仅建立并做静态/编译配置核对，不灌测试事件/崩溃、不发布测试RC、不打开生产广告。开发项目可发布限定测试RC并恢复安全值。
- 不购买、不绑定付费方案、不接受法律条款或业务声明、不扩大IAM权限、不创建/重置签名私钥、不上传商店或发布。出现此类必经步骤保存具体入口和待办，继续其他独立项。能利用现有会话则直接完成，不反复让用户重新开户。
- Apple Developer中可注册已确认的Pourlune应用标识并核对Team；ASC/Play记录若要求协议、业务声明或未确认信息，列具体缺口，不能阻塞Firebase及本地接入。Firebase注册不证明商店包名可用。
- 保留普通App及 `b04_review_r2.sqlite`；运行验证使用独立设备/模拟器及命名测试库，不能用测试运行器覆盖普通安装。Flutter CLI与iOS构建串行并设置 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`。
- 当前任务文件由执行方修改实现、工具、README、AGENTS必要运行说明与delivery/evidence；架构负责plans、review、tracking及user-handoff。

## Review Focus

1. 环境/平台/应用ID不匹配必须在配置或构建前拒绝；不能仅以native-ready=true启用。
2. 切换生产再切回开发不能遗留旧plist、JSON或生成资源；缺配置仍能构建离线默认入口。
3. 采集默认关闭、用户撤回与未发崩溃删除保持有效；测试开关不能进入默认产品路径。
4. 符号上传成功必须与准确Firebase App ID、制品及dSYM UUID关联，配置文件存在不等于收件。
5. 注册/浏览器操作中断后先回读对象再继续，不能重复创建或误入FishPilot。

## F01 账号及目标对象注册

**Files:** 新建 `docs/development/evidence/firebase-integration/registration.json`；完成后汇总至 `docs/development/deliveries/firebase-integration.md`。
**Interfaces:** 输入上述环境与身份矩阵；输出实际project ID/number、平台App ID、bundle/package、Analytics property/data stream及注册状态白名单。

- [ ] 读取当前预检与控制台实际会话，确认目标账号、已有对象及所需权限；查看官方当前注册资料。
- [ ] 分别建立开发和生产项目；独立Analytics属性，不能选择FishPilot属性。必要地域/主体信息使用已确认真实资料，无法推断的必填项记录阻塞，不编造。
- [ ] 各注册iOS与Android应用，共四个；逐项回读确认大小写、下划线及项目一致。操作结果不明先查存在性再重试。
- [ ] Apple标识按上述边界处理；记录成功、未执行、需用户处理，不把Firebase App注册写成商店注册通过。

## F02 客户端配置取得与环境校验

**Files:** 新建本地忽略目录 `app/config/firebase/`（真实客户端文件）；修改 `.gitignore`；新增 `tools/validation/firebase_config.py` 与 `tools/validation/test_firebase_config.py`；文档为 `tools/validation/README.md`。
**Interfaces:** 校验CLI `python tools/validation/firebase_config.py --environment dev|prod --platform ios|android --config-dir <path>`；成功exit0，缺失/错配exit非0且不输出凭据。配置布局和构建用法写README。

- [ ] 下载四份真实原生配置，按环境/平台保存；只将白名单身份字段及文件摘要写证据。服务账号、私钥、令牌不读取/导出；公开客户端API key也不贴聊天或日志。
- [ ] 先建立错项目、错平台、错ID、缺字段测试，再实现原生文件与Dart Options交叉核对；以注册矩阵为准，不仅校验格式。
- [ ] 运行上述测试及四组真实文件校验；配置默认走本地受控路径、仓库提供无真实值示例和可重复说明。

## F03 原生环境选择与身份接入

**Files:** `app/android/app/build.gradle.kts`、必要的Android配置；`app/ios/Runner.xcodeproj/project.pbxproj`、`app/ios/Flutter/*.xcconfig`；`app/lib/services/service_config.dart`仅按需要修改；`app/README.md`。
**Interfaces:** 消费F02校验输出及四份配置；产生原生身份/资源/Options一致的dev、prod构建，以及无配置离线构建。

- [ ] 选择最小可重复构建方案（明确flavor/configuration或受控构建前选择），记录具体命令；生产值com.pourlune.app不得改写默认开发/QA安装身份。
- [ ] iOS把选中plist确实加入正确target产物；Android修正仅根JSON触发插件的旧条件，核验所选variant资源与Crashlytics build ID。
- [ ] 测试dev→prod→dev选择、缺配置和人为错配；静态校验拒绝错配，默认无配置离线流程仍可用。按改动范围运行format/analyze及服务回归。

## F04 Crashlytics符号配置

**Files:** iOS project build phases、Android构建配置、上述README；证据 `docs/development/evidence/firebase-integration/`。
**Interfaces:** 输入匹配Firebase配置及构建制品；输出可追溯的符号任务、dSYM UUID/适用mapping或Dart symbols和上传目标。

- [ ] 按当前SPM官方资料接入iOS脚本与沙盒输入，不硬编码临时checkout或复制Pods路径；核对默认关闭及send/delete策略未改变。
- [ ] 核对Android符号适用条件；未启用混淆则准确记录不适用，不能伪造mapping上传。
- [ ] 定向构建并保存白名单日志、制品摘要和符号关联；没真实控制台可读堆栈只能标配置/编译通过。

## F05 双端真实初始化与Analytics

**Files:** 必要的隔离 `app/integration_test/firebase_services_test.dart`；注册证据目录与交付报告。
**Interfaces:** 开发项目真实SDK与隔离运行环境；不使用生产项目或替身作为收件证明。

- [ ] 优先可用iOS模拟器；Android可使用Pourlune独立AVD并核对GMS实际可用，不清理或占用FishPilot专用设备。真机缺少不阻塞模拟器可做项。
- [ ] 正常主入口验证初始Analytics/Crash sharing关闭、离线核心和保存可用；显式选择后测试开发项目DebugView真实事件及SQLite去重。
- [ ] 验证撤回、断网和初始化失败降级；记录平台/版本/时间/事件与目标数据流，结束恢复debug标志。模拟器不算真机性能通过。

## F06 双端Crashlytics真实收件

- [ ] 隔离QA入口触发受控非致命和native crash，脱离调试器、同安装重启；显式选择共享后验证实际发送与开发项目收件。
- [ ] 核对可读堆栈/符号、准确App与版本，观察关闭共享及删除未发报告。不能只凭本地日志标通过；未收到保留一次有界尝试结果及原因。
- [ ] 不在正式默认产品路径留下测试崩溃按钮，不要求或操作生产项目测试崩溃。

## F07 Remote Config与服务回归

- [ ] 仅开发项目发布既有 `ads_enabled`、`interstitial_enabled`、`rewarded_enabled` 布尔及 `disabled_puzzle_ids` JSON字符串；测试期不请求生产广告，不新增上限/业务规则。
- [ ] 对取回/激活、非法值、缓存、离线回退和重启记录模板版本与客户端结果；必要debug fetch间隔覆盖不能影响release。
- [ ] 结束恢复开发项目安全配置（广告关闭、disabled_puzzle_ids为[]）并回读。复跑受影响服务测试，检查隐私默认关闭、离线保存及未改变游戏规则。

## F08 可复验交付与阻塞交接

- [ ] 交付 `docs/development/deliveries/firebase-integration.md`，八项逐项给出完成/部分/阻塞、对应AC-32/33/36等适用条目、改动、命令及证据。
- [ ] `docs/development/evidence/firebase-integration/` 提供白名单注册矩阵、配置摘要、构建/运行结果和控制台收件定位，不含个人页面全文、API key、令牌或私钥。真实配置本地路径单独说明供架构复验。
- [ ] 需用户处理只列新增具体入口、原因、最小动作及影响；先做完不依赖它的任务，不重复旧整份清单。
- [ ] 留实现供架构独立审查；不自行标独立通过，不提交/推送未验收实现。架构复核后统一提交推送，必要时检查新代码CI。

## 架构验收

架构写 `docs/development/review/firebase-integration-acceptance.md`：独立回读注册对象与环境、检查配置白名单及产物、复跑配置/受影响服务检查，在可用平台打开真实App并核对实际控制台证据。静态、编译、SDK运行、控制台收件、真机、签名/发布各自定结论。若仅有外部阻塞，验收可做范围并集中说明待办，不等待库存或重复轮询。

## 官方依据（2026-10-22已查，接入时复核具体版本）

- https://firebase.google.com/docs/projects/dev-workflows/general-best-practices
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/crashlytics/ios/get-deobfuscated-reports
