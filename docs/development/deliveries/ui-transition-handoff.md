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
