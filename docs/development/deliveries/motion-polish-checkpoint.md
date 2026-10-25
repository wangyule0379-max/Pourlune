# M01–M08 检查点（非完成交付）

2026-10-22。按用户新指示优先切换 Flame 两瓶倒水与拼片样板，现有工作保留；M 批次未完成、未独立验收，不能以本文触发通过。

已保存改造前同模式证据：`evidence/motion-polish/before/` 的双端三次冷启动 JSON、双端实际完整导航/一次落盘倒水/受控 main004 最后一倒→奖励→Next 的 route.json、录屏，以及 iOS 人工操作和冷启动录屏。独立设备 iOS `9B172C50-E5CB-4F3F-8F16-0A3DB04F495D`、Android `emulator-5584 / Pourlune_Motion_API36`，数据库分别 `motion_polish.sqlite` 与 `motion_runtime.sqlite`；Firebase none，广告 disabled，debug 模式。受控合法三关结算及 main004 临近胜利是明确 QA 准备，不是玩家自然进度或正式内容验收。

当前未提交改动：品牌启动及当前 Home 所需图像预解码；原生按钮视觉反馈；260ms 页面进入与有界退出层、滚动恢复；220/150ms 原生 DialogRoute 和重复暂停防护；290ms 棋盘入场；按单位倒水时长；普通成功300ms、拼片700ms及按需预热。业务保存/奖励规则未扩大，动画不能提交动作。棋盘离开立即销毁，避免旧棋盘和新棋盘争用单一 motion presenter；其他页面至多保留一张不可点/不可聚焦/无语义的出场视图。

已有 RED→GREEN：缺少按压反馈、缺少过渡、重复暂停两个弹窗；入场不得阻塞第一下操作；弹窗160ms内关闭；真实 FFI 初始化失败后 Retry；保存失败阻止回首页直到 Retry、章节滚动恢复；转场中的系统减少动态效果、后台及销毁。焦点/语义隔离与现有 motion/完成展示针对性16项通过。完整测试首次169通过/6失败，定位为新增滚动 PageStorageKey 与未分配状态键的两处工程 ExpansionTile 共用存储标识，已隔离两处状态键，针对回归23项通过，见 `checkpoint-regression.log`；不得引用首次全套为通过。analyze 初次6项信息已修正，尚待重跑。

尚未完成：改造后双端构建/实际完整录像、前后分布分析、音画观感复验、完整新代码审查及最终M验收；代表真机性能未验。Flame 样板也不能自动补齐这些缺口。旧 Flutter 原生测试运行器出现 DDS 连接失败；最后成功基线使用 Flutter 官方 LiveWidgetController 驱动独立原生调试入口，实际指针、真实 SQLite，不能称 integration_test 运行器通过。

原始录像为本地大文件，后续生成可审查压缩片段并保留原始路径/摘要；不会把超大原始文件直接提交。未暂存、提交或推送，tracking/plans/review 由架构方维护。

## 2026-10-22 页面转场职责交接检查点

M01–M08 仍未整体完成。当前共享页面成果全部保留为未提交修改，不回退。后续 `animations` 页面转场由独立 App UI 聊天承接，本聊天继续收尾 Flame 两瓶/拼片样板，不扩展页面转场范围。

可交接的现状：`app/lib/main.dart` 启动渲染、`app/lib/presentation/motion.dart` 有限离场/入场与 modal helper、`startup_view.dart`、`pourlune_app.dart` 原生按钮反馈，以及 `game_screen.dart` / `board_page.dart` / `navigation_pages.dart` / `collection_pages.dart` / `knit_components.dart` / `scene_art.dart` / `service_views.dart` 的现有 M 修改。请先读本检查点的已知边界、此前23项回归结果和新的全套测试记录；不要将 M 的原有 before 录像或本次 Flame 两瓶录像当成 M after 验收。

本聊天目前仍需写入的文件范围：`app/lib/development/flame_sample*`、`app/test/flame*`、`app/integration_test/flame_sample_app.dart`、`tools/validation/flame_sample.py`、Flame 证据/交付，以及必要的 `app/README.md`。共享 `GameAudio.finishEffect()` 与对应测试已定稿，全套 Flutter192项通过；`GameController` 只有此前 M 的 PourMotion 时长修改，本聊天无新增共享控制器/页面修改计划。若实际故障要求改共享文件，先在本检查点记录协调。

**Flutter CLI / 原生构建 / 依赖写入锁：HELD。** Flame 已精确锁定1.38.2及 pubspec.lock（仅新增 ordered_set8.0.1 传递依赖），不会加入 animations。正在做最终双端原生取证；当前 iOS 构建与后续 Android 时序复核期间，请新 UI 聊天只读，勿运行 Flutter CLI、pub、SPM生成或编辑 pubspec.yaml/lock。待本段追加明确 **RELEASED** 后，页面/导航共享文件与 Flutter CLI 才正式释放。原生证据应用和命名库须保留，勿覆盖普通/Firebase安装。

### 2026-10-22T15:27:10+08:00 — RELEASED

**Flutter CLI / 原生构建 / pubspec.yaml 与 lock / 共享页面导航文件：RELEASED。** 本聊天当前没有在途 Flutter、pub、SPM、xcodebuild 或录屏命令，最终 iOS/Android 样板均已构建安装并完成13项native路线、各3次启动及同安装进程恢复。Flame1.38.2锁定已定稿；新App UI聊天现在可以添加官方animations并承接上述页面转场，不需等本聊天再确认。

本聊天不再修改 main.dart、presentation/ 页面/导航/motion.dart、pubspec或共享控制器/音频；Flame后续修复优先局限 development/flame_sample*、对应测试/工具/证据，确需共享改动先在检查点协调。完整Flutter192项、核心30项通过对应的是冻结版；后续UI改动须自行验证，不能继承本批的全套通过结论。

Flame作者交付：flame-sample.md（待架构独立验收）。为避免共享UI和pubspec继续修改导致验收失去对照，当前源码/测试/依赖快照、可安装候选和原始录像已移至**项目根build/flame-sample-candidates及build/flame-sample-raw**（Git忽略、不会被app/下flutter clean删除）；SHA和源码基线见evidence/flame-sample/source-freeze.json与artifact-manifest.json。请保留这些文件和既有Flame命名库/设备供架构验收；新UI取证使用自己的命名QA库/设备，避免覆盖普通/Firebase/Flame样板。作者未stage/commit/push，原owner tracking/plans/review未改。
