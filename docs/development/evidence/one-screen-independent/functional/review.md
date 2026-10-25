# LY 独立功能／异常运行审查

2026-10-23（Asia/Taipei）。本轮独立聚焦运行完成：**19项通过，最终探针 format/analyze 通过；CLI RELEASED。** 未发现本轮已验证路径中的生产功能缺陷。此结论不等于整体 LY、UI、Android 原生或 OS 杀进程恢复验收通过。先前静态报告原样保留在 `review-static.md`，其中“未执行”描述只代表当时阶段；本报告与 `readiness.json` 是当前状态。

## 审查对象和窗口

架构收到原开发释放后，将唯一 Flutter/Dart 窗口明确交给本审查者。所有命令串行，仅在可写副本 `build/ly-functional-review/run-20261023-01/app/` 运行，统一 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`。执行结束已明确通知架构 CLI RELEASED，之后仅整理文本/Python证据；CLI现归UI。

初始只读快照280文件及集合hash已独立匹配，详见 `static-audit.json`。执行前从当前候选按该清单复制280文件，另复制版本文件和QA driver，没有复制原生目录、秘密、配置、凭据或生成build。`final-delta.json` 记录相较中途快照的三处差额：`board_page.dart` 只有换行、`one_screen_layout_test.dart` 只有条件块括号；原生 integration QA 增加 disabled ads/Firebase none/无scenario校验及超时诊断。新driver只输出JSON，未运行。

执行后副本280文件哈希零漂移，两份pubspec.lock保持原值；新增/调整的只有本审查探针与隔离生成物。生产源的 integration QA 在本轮末另有诊断改动，已在 `runtime-checks.json` 标出；该后续QA诊断差额由架构另交复核，不纳入本轮通过范围，不因此重跑本轮探针。实现源在复制后未发现漂移。

## 实际运行结果

| 检查 | 实际结果 | 证据 |
|---|---|---|
| FP01 失败回执直接Retry | Next/Next/Home连点期间无回执、无成功反馈、无提前导航；清除故障后Retry一次进11；再Retry不重复结算/实例 | `probes-final.log`，第1项 |
| FP01 Stay后Retry | 同样失败状态排入导航，点击真实紧凑Stay后Retry，留在10结算；回执只提交一次 | `probes-final.log`，第2项 |
| FP02 同一Flame对象 | 七瓶倒水中字号1.0→2.0→1.3和高度400→240→400；game保持同对象、closed=false，token只释放一次；内容/容量为完整after，恢复后可点瓶，无框架异常 | `probes-final.log`，第3项 |
| FP03 实际Cancel与旧结果迟到 | 320×568/1.3、真实Nunito、七瓶；点Hint→真实Cancel→再Hint；第二有效结果先返回，再送第一条合法旧结果，选中源/提示仍为第二条，内存和SQLite棋盘未变 | `probes-final.log`，第4项 |
| AC-08 hint实例/修订错配 | 2项通过 | `hint-identity.log` |
| AC-08 hint generation、重复请求 | 1项通过 | `hint-generation.log` |
| AC-11 通关反馈 | 12项通过：SQL晚于动画、回执回滚、Retry、重复token、离页、后台及实例替换均保留门控 | `completion-feedback.log` |
| 独立探针质量检查 | 最终format exit0；analyze No issues found | `probe-format-final.log`、`probe-analyze-final.log` |
| 依赖/锁文件 | enforce-lockfile exit0，app/core lock零漂移 | `pub-get.log`、`runtime-checks.json` |

新探针4项＋复用聚焦测试3＋12＝19项，不把重复执行轮次或setUp/tearDown当额外用例。SQLite为真实文件/FFI，美术为实际解码资源；本轮不是原生sqflite、真实音频输出、读屏或视觉外观测试。完成反馈12项检查回执与回调，不冒充耳听音效通过。

## 首次失败与探针适配

原草案保存在 `ly_failure_probes_draft.dart`，最终实际执行源在 `ly_failure_probes_test.dart`，SHA256为 `2430e5ce675344691b2f7bd294695279edfc3cba50894744643326fd7e39ea22`。

1. 初次format检查exit1，保留 `probe-format-first.log`；仅格式化自己副本里的探针。FP01/FP02首轮3项通过，`probes-first.log`。
2. 新增FP03后首败，保留 `probes-fp03-first.log` 和两份 `fp03-diagnostic*.log`。提示搜索为true、Cancel存在，但命中失败。诊断显示Cancel y215–263落在说明视口y148–204之外；替代测试字体将“Looking for a hint…”撑至182高。此时未改生产实现。
3. 对照项目真实字体用例，仅增加FontLoader加载Nunito，未改断言/输入/生产代码。`probes-real-font.log` 4项通过；Cancel变为y90–138，处于y90–146说明视口。故该RED分类为审查探针缺少真实字体，不报告成LY产品缺陷。原RED保持不覆盖。
4. 首次analyze只有两条条件块括号info，保留 `probe-analyze.log`；仅修自己探针后最终analyze无问题。最终实际源再运行4项，通过 `probes-final.log`。

所有命令的绝对argv、cwd、统一环境、exit code及日志SHA256见 `runtime-checks.json`。没有隐藏首败、放宽命中断言或修改共享测试；本轮没有生产修复。

## 当前边界与交接

CLI RELEASED，已通知架构并由UI接后续串行窗口。本审查者不再启动Flutter/Dart或原生命令。

未操作任何模拟器/设备、F9窗口、截图/录屏/录音、SDK、签名、商店或Git提交；未改生产代码、共享测试、pubspec/lock、tracking/plans。未验：Android原生正常路径、独立UI外观/读屏、原生音频、OS进程恢复、真机性能及最终CI/分发。作者同进程SQLite reopen仍不能升级为OS恢复；静态日志核对的原有限制见 `review-static.md`。

本轮只关闭已分配的功能异常探针缺口，不重跑B01–B05/SDK全套。整体接受与最终候选差额由架构总控汇总决定。
