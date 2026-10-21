# Pourlune 项目协作约定

适用于本目录及其子目录。用户当前明确指令优先于本文；不要把本文变成重复询问许可的理由。常规、可逆且已获授权的实现和修复应直接推进。

## 项目基线

- 海外 iOS / Android 单机解谜游戏；Flutter、纯 Dart 游戏核心、SQLite / sqflite。
- 分层静态美术＋局部 CustomPainter 动画；提示在可取消、有时限的 isolate 中求解。
- Firebase Crashlytics、Analytics、Remote Config；AdMob；静态支持网站和反馈邮箱。
- 首版题库内置，本地存档，离线核心玩法。不增加账号、云同步、业务服务器、商城、订阅、排行榜或新货币。
- 原始 UI 已存在，复用既定视觉。不得因为附件不易读取就推断 UI 未设计，或重新生成整套页面。

## 开始任务时读取

按任务范围阅读相关章节，不必每次重读所有资料：

1. [产品规格补充稿](docs/pmpowers/specs/PRD-supplement-v1.1.md)：产品行为和对旧规则的修正。
2. [首版技术方案](docs/pmpowers/specs/technical-architecture-v1.0.md)：技术边界和数据一致性。
3. [验收与内容交付清单](docs/pmpowers/specs/acceptance-and-content-readiness.md)：AC 编号、内容门槛。
4. [UI 原稿审查](docs/design/review/original-design-review.md) 和 [UI 交付约定](docs/pmpowers/specs/UI-design-handoff-and-review.md)：D01–D09 增量范围。
5. [开发准备清单](docs/pmpowers/specs/development-readiness.md)：阶段依赖和未决事项。
6. [数据与状态契约](docs/pmpowers/specs/data-contracts-v1.0.md)：题库格式、索引方向、实例与奖励数据边界；适用于内容和核心逻辑任务。

原始包位于 `docs/design/original/Pourlune_Design_Pack/`，保持原件不改动。原始包作为视觉和历史来源；已明确修正的产品规则以补充稿为准，技术选择以技术方案为准。文档之间出现影响玩家行为的真实冲突时，定位冲突并解决，不自行把待定建议当成确认要求。

UI 增量目录 `docs/design/ui-addendum/` 中的原型、截图和自查仅是交付证据；通过状态以独立验收报告为准。静态 UI 验收不能替代 Flutter、SDK 或真机验收。

## 实现约定

- 游戏核心不依赖 Flutter、数据库、广告 SDK 或网络；界面不直接发奖或写通关记录。
- 固定目标标签参与胜利判断；目标瓶满且匹配标签、所有缓冲瓶为空才胜利。标签不限制临时接收其他颜色。
- 一次动作提交一次完整状态；动画不承担业务提交。异步提示结果必须核对实例和棋盘修订，丢弃过期结果。
- 存档按动作保存，通关相关记录原子提交；保存失败不得假称成功或继续需要成功落盘的导航。
- 奖励绑定原实例并去重；关闭广告不等于获奖。不得承诺恢复从未收到且未落盘的奖励确认。
- 题目使用稳定 ID 和版本，活动实例保存原题定义。升级迁移不能默认清空存档。
- 保留免费提示、撤销、重开与离线玩法；联网服务失败不得阻塞核心流程。
- 使用真实文字、按钮、语义及点击区域；不要用整屏图片冒充可交互页面。正式资源需明确图层、尺寸和使用权。
- 保持结构适合首版，不为假设中的云端扩展提前建设框架。新增依赖须有具体用途，避免重复状态管理和抽象层。
- 工程建立后固定 Flutter / Dart 与依赖版本，提交应用的锁文件。最低系统版本由依赖兼容性和目标设备验证决定。

## 工作与文件边界

- 修改前查看当前文件与已有变更，不覆盖其他任务的交付；并行任务避免编辑同一文件。
- 原件、产品规格、增量 UI、正式客户端资源分别保留明确用途。原型素材不能未经检查直接标为生产素材。
- 任务只授权 UI 时，不扩大为完整 App 开发；需要另一个聊天执行时遵循用户已有授权，不擅自创建或派发无关聊天。
- 常规代码变更同步更新相关说明；产品行为变化需要明确记录，不能通过实现悄悄改规则。
- 私钥、签名凭据、服务账号和访问令牌不进入仓库或日志。区分客户端公开配置与服务端秘密；开发使用测试广告。
- SDK 版本、平台能力和发布政策在实际接入时查官方资料；文档中不写未经测量的性能结果。

## 验证与交付

Flutter 应用位于 `app/`；纯 Dart 核心位于 `packages/pourlune_core/`。工具链固定 Flutter 3.47.2 / Dart 3.13.2（根目录 `.flutter-version`）；应用与核心的 `pubspec.lock` 均须保留。工程和运行说明见 `app/README.md`。B03 默认读取 `app/assets/puzzles/` 的60主线＋30每日候选及 `app/assets/catalog/daily.json`，并使用独立运行美术层、Nunito与本地音频。候选资源不等于独立视觉或商业权属通过。B02 调试场景的别名和测试时钟仍仅用于隔离库；release入口忽略这些场景。

目前已有独立 Git 仓库，origin 为 `https://github.com/wangyule0379-max/Pourlune.git`，主分支 `main`；Python 内容准备工具已建立。在项目根目录使用 Python 3.11+ 的 .venv，依赖固定在 `tools/content/requirements.txt`；命令为 `.venv/bin/python -m unittest discover -s tools/content -v` 和 `.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json`。`--release --catalog ...` 用于正式内容完整性检查；当前工程夹具不能通过发布门槛。具体用法见 `tools/content/README.md`。这些检查不等于 Dart / Flutter 测试。

正式资源和账号交接见 `docs/pmpowers/specs/production-handoff.md`。`docs/design/production-candidates/` 仅是待接入验证的资源；不要把候选状态改成视觉/运行通过。早期工具链现状见 `docs/pmpowers/specs/toolchain-check-2026-10-21.md`：CocoaPods 已安装，Android doctor 的旧输出解析仍有兼容警告，须以实际构建进一步核验。

在 `packages/pourlune_core/` 运行 `dart pub get --enforce-lockfile`、`dart format --output=none --set-exit-if-changed .`、`dart analyze`、`dart test`。在 `app/` 先运行 `flutter pub get --enforce-lockfile`，再运行与改动相关的检查。基础命令为 `dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test`；明确工作目录和测试范围。平台构建、集成测试、真机或性能检查按改动风险增加，不把所有平台全量测试套在每次小修改上。

平台命令（工作目录 `app/`）：`flutter build apk --debug`、`flutter build ios --simulator --debug`；真实插件集成命令见 `app/README.md`。临时身份为 iOS `dev.pourlune.pourluneDev`、Android `dev.pourlune.pourlune_dev`；正式签名未建立。CI 配置位于 `.github/workflows/flutter.yml`，配置存在不等于远端运行通过。B01/B02 执行证据见 `docs/development/deliveries/B01.md`、`B02.md`，独立验收由验收方记录。B02 真实插件集成使用 `flutter test integration_test/offline_flows_test.dart -d <device-id> --dart-define=POURLUNE_SCENARIO=flow --dart-define=POURLUNE_DATABASE=b02_native_flow.sqlite`；测试会清理自己的命名库。`milestone`/`final` 场景及普通 App 冷启动方法见 app/README，不能把测试运行器重装当进程恢复。SQLite 当前 schema3、快照 schema2，必须保留非空 B01 迁移测试。

规则、参考解、撤销、事务、奖励幂等、迁移及异步过期结果必须有有效的自动验证；UI 则检查实际渲染、操作路径与适用设备条件。沿用 AC 编号记录证据，避免只镜像实现细节的测试。

交付说明包含：改了什么、对应要求、实际运行的检查及结果、未验证范围。明确区分“文档确认”“静态设计通过”“运行测试通过”。未完成项保留真实状态，不以占位内容、模拟 SDK 或自查截图冒充正式通过。

工程路径、构建命令和 CI 建立后更新本文，使约定与实际项目保持一致。

B03资源与表现检查：候选题库须运行上述Python严格release＋catalog90检查与核心production_content_test；图像在根目录用带Pillow的Python运行 `tools/assets/visual_manifest.py --check`、`-m unittest discover -s tools/assets -v`，音频用 `.venv/bin/python tools/assets/audio_generate.py --check` 和 `audio_verify.py`。显式资源变更才可用visual_manifest `--write`刷新，不能用刷新掩盖漂移。B03原生无种子集成：`flutter test integration_test/b03_runtime_test.dart -d <id> --dart-define=POURLUNE_DATABASE=b03_runtime.sqlite`；仅清理该命名测试库。原生音频与校准命令分别为 `b03_audio_native_test.dart`、`b03_visual_calibration_test.dart`。运行器可能卸载测试App，截图须在结束前复制沙盒；它不构成进程恢复。最终证据／已知轻微待办／外部未验证范围见 `docs/development/deliveries/B03.md`，独立验收仍由架构方确认。

B03-R01/R02修复：UI新增10图有独立命名空间与校验，根目录同时执行 `tools/assets/visual_manifest.py --check` 和 `tools/assets/ui_manifest.py --check`（带Pillow的Python），再运行assets单元检查。UI人工显示几何在 `knit_components.dart`，明确改变时才可刷新UI清单。原生配对命令为 `flutter test integration_test/b03_r01_design_test.dart -d <id> --dart-define=POURLUNE_DATABASE=b03_r01_runtime.sqlite`，只清理该命名测试库；七瓶为明确的核心权益QA状态，不是广告发奖或题库main021定义。成功音效必须等待本实例成功回执并通过前台／页面／动画／去重门控。最新执行边界、轻微待办见 `docs/development/evidence/B03-R01/repair-report.md`，整体通过仍由独立验收决定。
