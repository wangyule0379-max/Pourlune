# B03-R02 音效结算时序修复证据

日期：2026-10-22。工作目录：`/Volumes/data/App Development/Pourlune/app`。工具：`/Users/wangyule/development/flutter/bin/flutter` 与同目录 `dart`。仅为开发运行证据，不代表独立验收或原生听感通过。

## 根因与改动

原 `_finishMotion` 只核对内存 completed，未核对持久化状态或回执；无 presenter 的 `_change` 更在 `_persist` 前播放 complete。因此 receipt 事务回滚、SQL 尚未完成或玩家离页均可能收到通关音效。

`game_controller.dart` 现将待播放结果绑定原 instance ID 与 revision。共用入口仅在 SavePhase.clean、同实例成功回执、该实例仍已完成、倒水表现结束、前台且当前 completion 页，并无待办导航时消费一次。消费发生在调用反馈前，避免重复回调重播。该入口同时由动画结束和保存成功调用，覆盖 SQL 比动画慢及 Retry。导航意图、后台与销毁取消待播放反馈；既有结算页切换、事务和首个导航意图的业务流程保留。

交付文件：

- `app/lib/application/game_controller.dart`
- `app/test/b03_review_audio_test.dart`：审查回归的逐字节副本；最终以 `cmp -s` 核对一致，原审查文件未修改。原样保留其既有格式，因此格式检查只针对实现与新增扩展测试。
- `app/test/b03_completion_audio_test.dart`：12 个真实 SQLite 扩展用例。

## 实际执行

| 命令 / 范围 | 结果 | 日志 |
|---|---|---|
| `flutter test test/b03_review_audio_test.dart --reporter expanded`，修复前 | 退出 1；收到 complete，预期 empty，真实 receipt 回滚后 firstClears=0 | `audio-red-review.log` |
| `flutter test test/b03_completion_audio_test.dart --reporter expanded`，修复前 | 退出 1；8 个失败、4 个通过；慢 SQL、无 presenter 和离页失败均复现 | `audio-red-extended.log` |
| `flutter pub get --enforce-lockfile` | 退出 0；没有升级依赖 | `audio-pub-get.log` |
| `flutter test test/b03_review_audio_test.dart test/b03_completion_audio_test.dart --reporter expanded`，修复后最终逐字节原样副本 | 退出 0；13/13 | `audio-green-regression.log` |
| `flutter test test/b03_review_audio_test.dart test/b03_completion_audio_test.dart test/controller_test.dart test/motion_test.dart test/completion_presentation_test.dart test/offline_controller_test.dart test/replay_navigation_test.dart test/hint_worker_test.dart test/store_test.dart test/offline_store_test.dart --reporter expanded` | 退出 0；69/69，含既有导航、提示、奖励/结算幂等、迁移与动作保存回归 | `audio-green-related.log` |
| `dart analyze lib/application/game_controller.dart test/b03_review_audio_test.dart test/b03_completion_audio_test.dart` | 退出 0；No issues found | `audio-analyze.log` |
| `dart format --output=none --set-exit-if-changed lib/application/game_controller.dart test/b03_completion_audio_test.dart` | 退出 0；0 changed | `audio-format.log` |

扩展回归覆盖：最后一步失败→Retry；动画先于真实 SQL 完成（普通/减少动态/无 presenter）；Retry 先成功而动画未结束；重复与旧 token；保存中、保存后与失败后离页；后台后返回不补播；错误当前实例。成功事件捕获并核对 clean、原实例匹配回执和 completion 页面，同时核对真实 SQLite 仅一个 receipt / first clear。

首次相关检查错误使用了不存在的 `test/flow_test.dart` 与 `test/hint_test.dart`，退出 1（其余已载入35项通过）；完整原日志保留为 `audio-check-command-error.log`，随后用实际文件名执行69项通过。该日志不是产品回归失败。

曾开始 `flutter test --reporter expanded` 全 app 检查，根任务通知即将并行编辑 UI 后主动 SIGINT 停止。`audio-app-suite.log` 保留中途83项通过和 SIGINT 导致的 replay_navigation 加载失败 / offline_ui、ui runner 清理错误；没有据此声称全 app 通过。整合 UI 后全量检查由根任务执行。

## 验证边界

本任务未使用 Simulator、真机或原生音频后端，未修改 main、UI、资源、规格、审查原件和追踪文件；没有 stage、commit 或 push。真实 SQLite + controller/Flutter host 回归通过，不代表音频中断、人耳听感、Android 操作、设备性能或 B03 整体独立验收通过。

整合状态补记（2026-10-22）：根任务交接后已格式化 `app/test/b03_review_audio_test.dart` 的运行副本，因此当前副本不再逐字节相同；上文逐字节一致描述对应音效子任务交接时点。`docs/development/review/B03-evidence/completion-audio-regression.dart` 原始证据仍保持原样，未在此任务修改。
