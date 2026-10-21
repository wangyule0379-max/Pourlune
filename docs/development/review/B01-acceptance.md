# B01 独立验收 · 第二轮通过

日期：2026-10-22（Asia/Taipei）。验收方：Pourlune ｜ 产品架构。

**当前结论：B01-01～08 在已批准的工程与离线切片范围通过；B01-R01 已关闭，可以提交并推送开发分支，推进 B02。** 第一轮失败证据原样保留于下方及 `B01-evidence/`，本轮证据独立存放在 `B01-evidence-r2/`。

实现与本报告已作为 `d15b5967e79bb394043eef45b647444ea704a040` 推送 `origin/codex/offline-foundation`。B02 九项整体执行包已派发，执行聊天已进入 active。首次远端 [CI](https://github.com/wangyule0379-max/Pourlune/actions/runs/39642700975) 当前 queued，尚无通过结论；后续按 tracking 继续核查。

## 本轮复验

| 项目 | 独立结果与证据 |
|---|---|
| 修复审查 | `instance.dart` 拒绝任意已完成历史帧，并要求首帧符合实例内嵌原棋盘，允许已有额外空瓶；无数据库结构、SDK 或原设计变更。未扩大为全部历史可达性／防篡改承诺 |
| 纯 Dart | format、analyze、18 项测试通过，包含加瓶前／中、重开和旧定义兼容 |
| 应用 | format、analyze、19 项测试通过；真实宿主 SQLite 验证主档与备份均坏时只隔离本槽，另一每日槽、拼片、印章、解锁、计数和回执保持 |
| 独立缺陷回归 | 从第一轮独立复现程序另存正确预期版本并执行通过：损坏历史被拒绝、恢复有效备份、Undo 不完成、不增加首次通关或回执。[程序](B01-evidence-r2/history-corruption-regression.dart)与同名日志（independent-regression.log） |
| iOS 原生 sqflite | 本聊天复跑 `integration_test/history_recovery_test.dart`，已完成帧及非原始首帧两例通过；测试实际恢复提示、Undo 禁用、继续动作修复主档、两份都坏时不可恢复，以及已有 10 次首通／2 块拼片等记录不变 |
| 双端构建 | 本聊天实际运行 Android debug APK 与 iOS simulator debug 构建，均退出 0；不等于 Android 已实际运行或最低系统验证 |
| 正常 App 进程恢复 | 集成测试结束后安装本聊天构建的正常 App，独立数据库 `b01_r2_review.sqlite`。创建 main-001，0→2 一次动作后终止并启动进程，期间无重装／清库。恢复实例 `dev-1792603028677329-1911883504`，1 步、revision 1、相同完整棋盘；Undo 回初始局面 0 步、revision 2，Undo 禁用 |

全部命令、目录、退出码及日志见 [本轮检查记录](B01-evidence-r2/checks.json)。实际操作见 [重启前](B01-evidence-r2/ui-01-before-restart.png)、[重启恢复](B01-evidence-r2/ui-02-restored.png)、[恢复后撤销](B01-evidence-r2/ui-03-undo-after-restore.png)，对应 AX 文本同目录。截图为实际 Flutter App 开发绘制，不是 HTML 或正式美术验收。

## 逐项结论与边界

- B01-01：工程、固定依赖、双端本机构建通过；CI 配置存在，远端运行结果另记。
- B01-02～04：样本解析与参考解、容量／标签规则、实例、撤销、额外瓶和旧定义通过；历史修复回归闭合。对应 AC-01～03/07/23 与 AC-35 样本部分。
- B01-05～06：SQLite 槽隔离、备份、迁移、原子结算和幂等、失败阻断通过。本轮原生损坏恢复验证补充第一轮事务失败与重试实际操作。AC-09～11/24/33 为本批已执行部分，不扩称所有强退时间点穷举通过。
- B01-07～08：真实切片操作、进程重启、自动检查与两平台构建通过；CI 实际运行、Android 运行、真机和最低系统仍独立记录。

**未验证／后续范围：** 完整提示、每日、教学、收藏呈现与设置由 B02 实现；正式 60＋30 内容、正式资源／声音及视觉由 B03；Firebase/AdMob 由 B04。完整设备、读屏、性能、发布构建和五条端到端由 B05；本批不等于首版全部完成或可发布。正式账号、签名、支持域名及授权资料仍按依赖交接。

---

# 第一轮历史记录

日期：2026-10-22（Asia/Taipei）。验收方：Pourlune ｜ 产品架构。

**结论：暂不通过，需修复 B01-R01 后复验。** 工程切片已可实际运行，核心／应用现有测试通过；恢复校验仍有一个可复现的数据一致性缺陷。本轮不提交或推送实现，不提前派发 B02 实现。

依据：开发总计划 B01-01～08、PRD §2.3/3.1/4.2、数据契约 §3、AC-07/09/23/24/33。执行方交付见 [B01](../deliveries/B01.md)，其自查与代码审查不是本报告的替代证据。

## 1. 实际独立检查

| 检查 | 本轮结果 | 证据与限制 |
|---|---|---|
| 纯 Dart 核心 | format、analyze、13 项测试通过 | [执行记录](B01-evidence/checks.json)、core-format/analyze/tests.log；包括原参考解和规则测试 |
| Flutter 应用 | format、analyze、15 项测试通过 | 同记录中的 app 项；真实宿主 SQLite、控制器与 widget 测试，不冒充 Android 插件验证 |
| 实际 iOS 开发 App | 选样本、无效倒入、合法倒入、撤销、真实事务失败、Home 阻断、Stay、Retry 均完成 | 在已启动的 iOS 26.5 Simulator 上操作执行方正常构建的 App；未把 HTML 原型当客户端。无 XcodeBuildMCP 工具，使用 CUA 操作 Simulator，simctl 仅用于进程终止／启动 |
| 原生进程重启 | 不重装、不清库，terminate/launch 后恢复同实例、同 revision、同棋盘 | `dev-1792601929992989-2170496361`，main-001，1 move，revision 3；[重启前](B01-evidence/ui-04-retry-saved-board.png)、[重启后](B01-evidence/ui-05-process-restart-restored.png)，AX 文本同目录 |
| 平台构建与 native integration | 已读取执行方成功日志，本轮未重复构建及集成测试运行器 | Android debug、iOS simulator 和作者集成测试证据保留其来源；本轮新增的是实际模拟器操作及冷启动证据，不扩称双端独立运行通过 |
| 额外故障复现 | 损坏撤销历史被正常加载，并可造成错误首次通关 | [复现程序](B01-evidence/history-corruption-reproduction.dart)、[本聊天复跑日志](B01-evidence/history-corruption-reproduction.log)。程序断言的是缺陷存在，退出 0 不代表该产品行为通过 |

操作截图按顺序：

1. [两色初始局面](B01-evidence/ui-01-two-color-start.png)：清楚标注 3 份工程夹具与开发绘制，不作为正式美术。
2. [满目标无效倒入](B01-evidence/ui-02-invalid-full-target.png)：0 步、revision 0、Undo 禁用，保留源选择并显示原因。
3. [失败后 Home 被阻断](B01-evidence/ui-03-failure-blocks-home.png)：内存 1 步、revision 3，未宣称已保存；Stay 留在当前界面。
4. [Retry 成功](B01-evidence/ui-04-retry-saved-board.png)：同实例同棋盘转为 Saved，未重复执行倒入。
5. [冷启动恢复](B01-evidence/ui-05-process-restart-restored.png)：仍为同实例、1 步、revision 3 与完整瓶体内容。

完整界面观察见 [UI 记录](B01-evidence/ui-observations.json)。B01 的局部开发绘制不适用先前静态 UI 的正式视觉通过结论。

## 2. B01-R01 · P2 · 不可能的撤销历史可触发错误结算

定位：`packages/pourlune_core/lib/src/instance.dart:114–124`，继而 `GameStore.load` 与 `GameController.undo`。

复现使用临时真实 SQLite 数据库：

1. 保存 main-001 初始状态，再保存一次合法 0→2 倒入；数据库已存在有效备份。
2. 只将当前 payload 的 `undo_history[0].board` 改成两目标满且匹配、缓冲为空的已通关局面；其他字段及有效 backup 不变。
3. 加载返回 `recovered=false`，接受该主存档。
4. 控制器 Undo 后出现 `completed=true`、`moveCount=0`，并实际新增首次通关及结算回执。

根因是历史帧仅验证瓶数／容量／颜色守恒／步数，接受了“已完成局面还能作为下一步倒入前历史”这一不可能状态。产品规定一旦胜利立即锁定倒入和撤销，因此这种帧不应成为有效撤销目标。存在有效备份时应拒绝损坏主存档并恢复备份，不能将 Undo 变成通关动作。

### 必需修复边界

- 对历史增加便宜且确定的业务不变量校验：历史不得包含已通关帧；第一帧应对应本实例原始棋盘（兼容已授予的额外空瓶）。保持加瓶前后撤销、重开后历史及旧题定义兼容。
- 增加预期正确行为的回归：损坏 primary＋有效 backup → recovered；Undo 不产生错误完成／拼片／回执／计数；无有效备份时明确不可恢复并保留其他槽和全局进度。
- 不要求密码学防篡改、重新求解每份快照或证明整段历史的全面可达性；这不是反作弊功能，也不应扩大为新的存档框架。
- 复跑核心、store/controller/widget 检查，按改动重跑原生恢复路径并更新交付。修复后的测试应验证拒绝和恢复，不应仅使本次“证明缺陷存在”的程序继续退出 0。

本问题由 fresh-context 代码审查提出，本聊天读程序后再次运行确认，并将修复要求收窄到业务必然成立的不变量。没有把正式题库、提示、SDK、完整每日等 B02–B04 已批准延后项当作本批缺陷。

## 3. 当前逐项状态和后续

- B01-01～04：已有实现与有效基础检查；存档历史解析受 B01-R01 影响，仍待修复后的回归闭合。
- B01-05～06：真实 SQLite 与事务测试有证据，故障恢复／结算仍需 B01-R01 关闭。
- B01-07：本轮实际开发切片操作及进程重启通过；正式视觉、完整内容与功能不在此通过范围。
- B01-08：本轮 format/analyze/test 通过；平台构建保留作者证据来源，最终验收时按变更重新核验。

Android 实际运行、真机、最低系统、全生命周期故障、性能、读屏语音、远端 CI、正式资源、60＋30 题、Firebase/AdMob 均未因此通过。修复交回原执行聊天，由本聊天复验，再提交、推送并派发下一批。
