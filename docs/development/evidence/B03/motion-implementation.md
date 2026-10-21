# B03-07 局部倒水与状态一致性实现证据

日期：2026-10-22；实现基线 `c5aa1514f2f02d6b298c7baeadd5873db01fbffe`。本记录为执行证据，不是独立视觉／运行验收报告。

## 实现与接口

- `app/lib/application/game_controller.dart`：`PourMotion` 保存一次已提交合法倒水的 `token/from/to/units/before/after/instanceId/revision/reducedMotion`，仅存在内存，不进入 SQLite 或业务快照。`busy` 同时考虑持久化、导航及有效呈现。业务状态／撤销记录只由 `_change` 提交一次，结算仍在原持久化流程中执行。`completeMotion(token)` 只清理当前呈现并显示已完成结算，不写数据库或再次发奖。
- `app/lib/presentation/board_page.dart`：`BoardPage` 挂载时声明有呈现者，卸载时清理；不挂载棋盘的纯控制器流程保留即时完成行为。`BoardView` 使用本地 `AnimationController`、瓶体变换及 `CustomPainter` 水流；棋盘有 `RepaintBoundary`，背景不按倒水帧重建。无新增计时任务、求解 worker 或依赖。
- 普通倒水 900ms：先抬起，随后倾斜／向目标移动，252–666ms 连续转移液量，再回位。颜色分层使用 `List<LiquidBand>` 的小数单位，源减少量与目标增加量来自同一转移量。水流口锚点沿用局部 `(width/2,24)`，瓶体旋转中心 `(width/2,84)`。标签语义始终描述提交后的真实棋盘。
- 选中使用 140ms 轻抬；失败使用 280ms 小幅左右反馈和描边，保留可读的错误文字及 live region。减少动态时倒水为 180ms 液位变化／高亮，无平移、抬起、倾斜或水流；选中与失败也取消位移。
- 背景、离开棋盘、暂停或卸载呈现者都会对齐已提交结果。导航仍遵守失败存档必须重试／暂留的原规则。动画期间撤销、重开、第二次倒入和提示均受控制器输入锁约束；暂停可在 SQL 已完成后主动结束呈现。
- `GameFeedback {select,pour,error,complete}` 与可选构造参数 `onFeedback` 供主任务接音频；本子任务不导入音频服务。后台取消不会发出完成声音事件。

## 测试与结果

执行目录均为 `app/`，工具链沿用项目固定 Flutter 3.47.2 / Dart 3.13.2。

1. RED：新增 `test/motion_test.dart` 首项 widget 检查后运行 `flutter test --no-pub test/motion_test.dart`，在真实 SQLite 保存成功后，预期 `c.busy == true`，实际为 `false`，按预期失败。这确认了旧行为在动画阶段没有输入锁。
2. GREEN：接入实现及瓶体增量 API 后，同命令 **8/8 通过**：
   - SQLite 事务尚未完成时以及呈现期间都阻止免费棋盘动作；提前结束呈现不能结束 SQL 保存。
   - 背景及导航取消；旧 token 无法清除后续新动画。
   - 存档失败时动画结束不伪称保存成功；内存免费继续游玩可用；重试保存完整当前结果后才执行导航。
   - 明确开发 seed 的额外瓶经过动画、连续撤销和重开仍保留（AC-07；不代表真实广告发奖）。
   - 动画仍活动时，通过另一个 SQLite 连接及新控制器读取完整棋盘、步数和撤销记录；没有持久化半笔动画状态（AC-33）。
   - 通关只生成一份结算回执；重复动画完成回调及后台操作不增加发奖记录（AC-12 的幂等边界）。
   - widget 普通倒水途中实际存在倾斜和小数液位，总量守恒，语义为最终真实棋盘；完成后解除锁。非法下一步不改棋盘。
   - widget 减少动态为 180ms、无倾斜／抬起／位移且有高亮；中途 Pause 清除呈现而不改变已提交动作（AC-31）。
3. `flutter test --no-pub`：**75/75 通过**（包括本次 8 项、既有控制器／真实 SQLite／迁移／提示／离线完整旅程／320px 2x 字号和 7 瓶等尺寸布局，以及当时已加入的音频服务测试）。音频 decoder 故障测试按设计输出一次降级日志。
4. `flutter analyze --no-pub`：**No issues found**。首次分析发现本次新增一处 if 缺少花括号的 info；修正后重新分析通过。
5. `dart format --output=none --set-exit-if-changed lib/application/game_controller.dart lib/presentation/board_page.dart test/motion_test.dart`：**3 files, 0 changed**。

## 限制与后续主任务验证

本记录的 SQLite 恢复测试为新连接／新控制器，不能冒充真实 App 进程强退或冷启动验证。测试使用工程夹具和开发授予额外瓶；不代表正式题库难度、正式广告、真机性能或商业权属通过。完成／拼片揭示视觉由主任务资源与界面接入；本记录仅证明倒水呈现完成不重复结算。主任务最终分层瓶体／场景资源与音频连线完成后，仍需重新运行相关回归并记录真实模拟器主要路径、动画中生命周期、关闭音频及屏幕视觉证据。没有测量帧耗时或设备性能。
