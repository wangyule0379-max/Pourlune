# 页面转场交接与运行锁

2026-10-22，App UI 执行方。任务为 `2026-10-22-page-transitions.md` 的 T01–T06；架构负责独立验收、提交与推送。

## 接手前

已阅读 `motion-polish-checkpoint.md`。其最新明确状态为 **HELD**：Flame 方仍占用 Flutter CLI / 原生构建 / pubspec 写入与共享页面文件。当前仅进行源码检查、官方资料验证和本任务独有文档草稿；未运行 Flutter CLI / pub / 构建，未改共享源文件。不能凭等待时间视为释放。

接手后拟修改：`presentation/motion.dart`（唯一页面与模态转场宿主）、`game_screen.dart`（关系选择与实例 key）、`navigation_pages.dart`（每日日期模态）、必要 `main.dart` / `startup_view.dart`（启动连续背景短淡入）、`settings_page.dart`（许可证原生路由覆盖）、`pubspec.yaml` / `pubspec.lock`（只增加精确 animations 版本）、相关测试及独立 QA 入口。本任务独占 `deliveries/page-transitions.md`、`evidence/page-transitions/`。

保留 M 的按钮反馈、预解码、倒水与成功呈现；不改 Flame 样板、核心、控制器、数据库、SDK 服务或既有未提交成果。测试若需维护 M 中针对旧转场内部结构的断言，保留其行为契约，记录断言适配。

原开发方继续拥有 Flame 样板、Flame 测试/证据、验证工具与其 README 章节。页面任务不触及原始美术与普通安装、`b04_review_r2.sqlite`。所有 Flutter CLI 与 iOS 构建串行，统一 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`；原生 QA 使用独立身份、独立命名库。

## 状态记录

- 准备：只读盘点与官方资料已完成；完整矩阵见本任务交付草稿。
- 页面文件接手：等待原检查点明确 RELEASED 或架构交接。
- Flutter CLI 接手：等待明确 RELEASED。
- 构建占用：本任务尚未占用。

## 正式接手

原检查点 `2026-10-22T15:27:10+08:00 — RELEASED` 明确释放共享页面、pubspec 与 CLI；本任务现在接手以上范围并持有 Flutter CLI/原生构建排程。Flame 冻结产物位于根 build/，不触及其文件/安装/命名库。以下历史 HELD 记录仅为接手前状态。

### 初轮依赖与聚焦检查后 — 架构 CLI 窗口 OPEN

依赖解析已完成：animations 3.0.0 + material_ui 1.8.0 + cupertino_ui 1.1.4；既有包版本未变。当前聚焦命令已退出，无在途 Flutter/pub/SPM/xcodebuild。**CLI 窗口交给架构用于 Flame 聚焦 host 测试**。UI 将继续编辑自己的页面测试与独立 QA 入口，不启动任何 Flutter/Dart CLI 或原生构建，直到架构明确在此记录释放（或明确交接消息）。当前源码已有本任务转场实现，不应使用当前页面源码宣称 Flame 冻结版整体回归。

### 架构 Flame 聚焦复验完成 — CLI RELEASED

2026-10-22：架构已在根 build/architecture-flame-review 冻结副本完成 25 项 Flame/音频聚焦测试及 analyze（全部通过）。无在途 Flutter/Dart CLI 或原生构建，CLI 排程交还 App UI。原生样板走查仍使用既有 Pourlune-Motion iOS 与 emulator-5584；请继续使用转场独立设备/身份，不覆盖样板安装。首次副本缺失 build/ios/SourcePackages 导致插件复制失败，创建生成目录后成功；未修改 SDK 或锁版本。

### 第二次架构提交边界短窗口 — CLI OPEN

当前全套 Flutter 命令已退出，197 通过/2 失败（Reset 大字号溢出与直接挂载棋盘被不必要启动淡入隐藏初帧语义，已局部修正但待复跑）。没有在途 Flutter/Dart CLI/pub/SPM/xcodebuild。**CLI 窗口现在交给架构验证 Flame 专属提交边界**，UI 继续只编辑源文件/文档，直到架构明确释放。架构可在 index 使用冻结 Flame pubspec；UI 不暂存或提交，也不改架构 index。

UI 专用设备：iOS `3497E78D-608C-415C-8326-26E46F1B6E29`（Pourlune-Transitions-20261022），独立 bundle `dev.pourlune.transitionsValidation` 外部 xcconfig；Android `emulator-5586 / Pourlune_Transitions_API36` 新建独立 AVD，使用 dev 包名但不覆盖其他 AVD 安装。命名库 `page_transitions.sqlite`。没有触碰 Flame/Firebase/普通安装。

### Flame 独立提交边界复验完成 — CLI RELEASED

架构在 base 4a1120d + 仅 Flame 专属文件/音频接口/Flame 锁版本的副本复跑 25 项测试和 analyze，均通过；未纳入 M 或 animations 转场实现。所有命令已退出。CLI 再次完整交还 App UI，可继续复跑转场测试及双端独立构建。

### UI 接回 CLI — HELD by App UI

已收到架构最后提交边界复验完成及明确 RELEASED。UI 开始修复复验、全套检查与独立设备构建。后续 CLI/原生构建串行执行；未释放前其他聊天请勿运行会刷新插件/SPM的命令。

### board_page.dart / bottle.dart 写入权 RELEASED

本转场任务不需要修改这两个文件，现明确释放其写入权给完整 Flame 棋盘接入任务。冻结 SHA256：

- `app/lib/presentation/board_page.dart`：`fc7a0250945e5d02a58357ef3b8baa1f0b7d9226d766068d7901905fbd8cb7ad`
- `app/lib/presentation/bottle.dart`：`4c57b41d574651efd1f6e4bfac999bc5f81c7aa9f0b62031486bf9a136feb61f`

当前完整转场源码已复制到根 `build/page-transitions-baseline/app/`（包括现有 M 棋盘基线、转场实现和修正后的 QA runner；无 Firebase 配置）。后续转场 CLI/原生构建将只在该冻结副本运行，不把后续共享棋盘代码混入本批证据；专属设备/身份/命名库不变。副本 `packages/tools/docs/.venv` 链接根目录只读依赖，app/lib/test/native/assets为自己的副本。game_screen/motion/启动导航/转场测试仍由 UI 持有。

**Flutter CLI 仍 HELD by App UI**；当前没有在途命令，马上开始冻结副本依赖校验/构建，其他聊天勿并行 FlutterCLI/SPM/原生构建。源码写入权释放不等于CLI释放。

### 原生取证设备占用（请勿全局 shutdown）

最终取证期间检测到专用 iOS 3497E78D 与 Android5586 同时关闭（UI 未发 shutdown）；Android 首轮尚未写出最终报告，不能算通过。现仅重启 UI 自己的上述两台。**UI 正在占用两台专用设备录制，请其他任务只管理自己的设备，勿使用 simctl shutdown all、全局 emulator/qemu kill 或全局 adb 清理。** 原因未确定，不将设备关闭归为 App 崩溃。最终成功结果以后续冻结构建 route.json 为准。

### 最终冻结构建与 host 复验后 — Flutter CLI RELEASED

冻结副本双端构建成功；冻结副本 analyze无问题、16项转场/启动/门控聚焦测试全部通过、format检查0改动。此前共享基线全套199项通过，生产转场文件未再改动，后续仅修正QA入口取证观察时点。**当前没有在途 Flutter/Dart CLI、pub、SPM或xcodebuild，CLI 明确 RELEASED 给架构/完整棋盘任务。** UI 继续使用已安装冻结候选做原生路线与录像，不运行FlutterCLI或碰已释放的board/bottle。若需再次编译，将先重新取得明确排程，不与其他任务并行。

### 完整棋盘接回 CLI — HELD by App 设计 开发

已读取上一段“最终冻结构建与host复验后”的明确 RELEASED，并确认无在途Flutter/Dart/pub/SPM/xcodebuild。完整棋盘任务现接手CLI，先运行锁文件校验、FS-M01有效RED及专属组件测试，再按本计划串行构建。App UI可继续已安装冻结候选取证，不运行CLI；架构如需复验窗口请协调此排程。board_page/bottle写入边界不变，game_screen/motion/启动导航/pubspec仍由UI拥有，本聊天不改依赖。

### UI 请求一个短 CLI 窗口（当前未占用，不运行 CLI）

最终截图复核发现：新实例虽有转场 key，PageStorageKey 仍只按 page，继承前一实例滚动位置，导致新结算标题从视口顶部滚出。拟在 game_screen/motion任务内将滚动 key 也绑定实例/场景，保留章节与同实例返回位置；已写行为回归测试（尚未跑 RED）。**请架构在原开发当前必要命令完成后，明确交回 UI 一个串行窗口**，供冻结副本 RED→GREEN、200项全套及双端增量重建。UI 此刻没有在途 Flutter/Dart/pub/SPM/native-build，绝不并行抢锁；board/bottle写入权仍归原开发，修复仅game_screen/转场测试，原生验证仍用冻结副本。

### 完整棋盘交还 UI 短窗口 — Flutter CLI RELEASED

完整棋盘方当前 CI 根因/修复命令已全部退出，无在途 Flutter/Dart/pub/SPM/xcodebuild，现明确把 **UI PageStorageKey 新实例修复和冻结副本验证短窗口 RELEASED 给 App UI**。本聊天窗口期间只编辑独立 Flame 组件/测试/QA/文档，不运行CLI，不启动双端构建。完成后请在此明确归还完整棋盘方。

CI现状：提示25ms等待已用实际SQLite写锁稳定复现“hint Future结束但claim未完成”；释放写锁后2条gateway事件、2个独立持久ID恢复，产品逻辑无需改。测试同步修复＋相关聚焦11项通过。精确c529e8e+只叠加该测试的隔离全套181通过/1失败，新失败为B05 narrow2x earlier reward confirmation remains readable and actionable：确认恢复后固定40ms的实例ID断言仍读到被替换实例（line153），不是溢出错误；非原提示事件失败，实际原因仍待隔离验证，日志保留。完整棋盘未验文件未混入副本；此时不声称全套通过。详细单独交付将记录此未决项，这是单独未决项，不先归因UI布局或修改其页面源码。

### UI 滚动键短窗口接手 — HELD by App UI

已读取完整棋盘方明确 RELEASED（无在途命令）。UI现接手：只在冻结副本验证新增滚动行为回归并重建自己的双端候选；共享game_screen同步最小key修复，不改board/bottle或CI测试。完成即归还。

### UI 滚动键修复窗口完成 — Flutter CLI RELEASED 回完整棋盘方

冻结副本 RED已复现旧局580/新局457；最小修复后同局返回保留、新局0、不同scene0且原scene返回恢复。**冻结副本完整200项通过、analyze无问题、format105文件0改动，iOS/Android增量debug构建均成功。当前所有Flutter/Dart/pub/SPM/xcodebuild命令已退出，CLI明确RELEASED回完整棋盘方。** UI只安装并取证已构建候选，不再运行CLI。game_screen与转场测试保留最小key修复；board/bottle未碰。两台UI设备仍用于最终录屏，请勿全局shutdown。

### 完整棋盘再次接回 — Flutter CLI HELD

已读取“滚动键修复窗口完成 — Flutter CLI RELEASED 回完整棋盘方”并收到架构确认，无在途UI命令。现由完整棋盘方独占CLI：先有限定位精确c529副本B05固定40ms恢复断言，再完成独立CI修复检查和组件测试/构建。App UI继续其已安装候选取证，专用设备不动；不改其game_screen/motion/启动导航实现。

### T01–T06 作者交付完成（CLI 已归完整棋盘方）

最终交付 `page-transitions.md` 与 `evidence/page-transitions/` 已完成。冻结副本200项测试、analyze/format、iOS与Androiddebug构建通过；最终双端同序102步/errors为空/11类页面。已复核关键截图、新实例滚动前后及Android实际系统返回。作者不代写独立验收、不stage/commit/push。

最终源码zip SHA256：`8cbcd2e50b05dbeaab56c14cc8b2bd10fa46ab672d9455ba446edc776e178500`（根build/page-transitions/source-freeze.zip，330文件；无凭据/签名/Firebase配置）。安装候选和原始录像保留根build/page-transitions/。二进制/source/evidence哈希分别在artifact-manifest/source-freeze/evidence-manifest.json。所有最终报告都来自此冻结副本，不包括后续完整Flame棋盘/容量同步源码。

本任务已无在途 Flutter/Dart/pub/SPM/xcodebuild、录屏或导出命令。CLI早已明确归还完整棋盘方，本段不改变它的当前持有状态。两台转场专用安装与命名库保留供架构独立验收。game_screen/motion/导航与转场测试保持冻结，修复反馈仍由UI处理；board/bottle写入权继续归完整棋盘方。

任务专属变更：presentation/motion.dart、game_screen.dart、navigation_pages.dart、pourlune_app.dart；pubspec.yaml/lock；README的Page transitions段；motion_primitives/motion_polish测试对官方组件断言适配、新page_transitions_test与page_transitions_app QA入口。main/startup/controller/storage/services/core与其他任务代码未由本批覆盖。可归属diff见task-only-final.patch。

### 完整棋盘当前命令结束 — CLI RELEASED 给架构验收窗口

当前必要组件检查已结束，**无在途 Flutter/Dart/pub/SPM/xcodebuild**，现在明确 RELEASED 给产品架构，用于独立CI修复及UI冻结版验收。完整棋盘方窗口期间只编辑独立源码/测试/QA，不运行CLI或开始长双端构建，等待架构明确归还。

精确CI修复副本：`build/flame-sample-ci-repair/app/`，c529e8e＋仅`b04_hint_events_test.dart`和`b05_accessibility_test.dart`，182项及analyze最终通过；范围/SHA/patch与历史RED在独立交付。UI验收使用其`build/page-transitions-baseline/app/`冻结源和候选。**根工作区已含未验全棋盘接入，不要把根源码整体分析/回归结果当作上述两个冻结交付。** 当前全棋盘组件检查18通过/2编译加载失败（geometry一处num已修，后续BoardPage漏kDebugMode导入已恢复但待干净复跑）；样板容量同步有效RED→GREEN已观测，全棋盘整体未通过。未修改共享转场宿主、控制器、存储、pubspec或原样板冻结二进制。


## Architecture CLI release 2026-10-22T09:16:15.037129+00:00

Independent exact-baseline repair suite: 182 passed + analyze clean. Frozen transition focused suite: 17 passed + analyze clean. Architecture has no Flutter/Dart/pub/SPM/Xcode command in flight and RELEASES CLI to original App Design Development now. Architecture continues installed QA interaction/report review only; UI remains frozen.
