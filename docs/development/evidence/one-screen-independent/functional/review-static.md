# LY 独立功能／异常静态审查

2026-10-23（Asia/Taipei）。裁定：**静态部分已交付；独立 App 运行未执行，不构成 LY 最终验收通过。** 未发现能由此次静态检查确认的 LY 功能缺陷；下列待执行项属于证据缺口，不冒充已复现问题。

## 审查对象与执行边界

唯一代码审查源为只读冻结副本 `build/ly-independent-review-20261023-0720/`，base `98bc236cf8e6151960df65a7aa1c1cf4118bf972`。Python 独立重算 280 文件 SHA256，零不匹配；按清单 canonical JSON 重算集合 SHA256 为 `cfe5d213715fe783d9d5af3cda125ad4325d40edb137c1bd7bdafbd04d3620f7`，与授权目标相同。逐文件代码／测试哈希和作者日志观察时点保存在 `static-audit.json`。这是中途快照；最终候选仍须核对差额，不能将本结论套用到后续代码。

已阅读项目 AGENTS、LY01–LY06 计划、交付初稿及产品／技术／AC 中涉及保存、异步提示、回执和导航的要求。生产工作树只读；仅新增本目录记录和待执行探针。未运行 Flutter/Dart/pub/SPM、构建、安装、原生测试或设备管理；未截图、录屏、录音或接触 F9 窗口。CLI 仍由原开发持有，本报告不释放其窗口。无实现修复、stage、commit、push。

## 静态结果与作者断言核对

以下行号全部指冻结副本内相对文件，不指仍在变化的生产工作树。

| 风险／要求 | 静态证据 | 可支持的结论与限制 |
|---|---|---|
| LY03／AC-11 保存失败 Retry/Stay | `app/lib/presentation/service_views.dart:25` 的紧凑提示使用真实 `KnitIconButton`，`:40`／`:46` 分别连到 `retry`／`stayHere`；`application/game_controller.dart:824`／`:828` 重试原写入并清除待导航 | 控件没有换成只改变 UI 的替身；`one_screen_layout_test.dart:222` 只点击 Retry，`:308` 回执失败用例也只点击 Retry。Stay 可见不等于取消待导航已经过操作验证。 |
| LY03／AC-09、11 未持久化回执 | `collection_pages.dart:402` 未 clean 或无 receipt 时显示 pending；`:431` 只有 clean 且有 receipt 才创建成功反馈；`game_controller.dart:123` 检查当前实例／修订、前台、回执、动作、页面和导航门控；`:743` 接收实际事务返回回执 | 静态看不到此次布局绕过原门控。既有 `b03_completion_audio_test.dart:88` 等测试涵盖 SQL 晚于动画、失败、重复回调；作者 LY 回执测试不独立证明真实音频播放或导航尝试行为。 |
| LY01/04／AC-05、08 提示取消与迟到结果 | `board_page.dart:167` 取消绑定 `c.cancelHint`；`game_controller.dart:1166` 起依次检查 alive/generation、instance/revision/page/foreground；`:1192` 增代并取消任务 | LY hint 用例取消时模拟任务立即返回 cancelled，未让有效旧结果穿过取消边界。既有 `offline_controller_test.dart:387`、`:418` 有身份和 generation 的对抗测试，但本审查未执行。 |
| LY03/05／AC-32 连点 Next 与实例替换 | `collection_pages.dart:389` Next 仍调用控制器；`game_controller.dart:890` 在失败时只排首个 continuation；`:913` 设置 `_adFlow`；advance 再核 source.id；`board_page.dart:64` 以实例 ID 隔离入场对象 | 原权威与 busy 门控保留。`offline_controller_test.dart:326` 有首意图与幂等旧用例；未独立从紧凑 LY 失败提示依次操作 Next/Next/Home/Stay/Retry。 |
| LY02/04 同一 Flame 对象尺寸／字号变化 | `flame_board/board.dart:211` 起固定滚动容器祖先，GameWidget 以 game 对象为 key；`flame_board/game.dart:111` 起 resized 时取消旧 motion 并释放 token | LY 矩阵每个字号创建独立测试，同字号跨尺寸重建；未覆盖同一对象从 1.0→2.0→1.3 且正在倒水。既有 reduced-motion 切换不等于字体/约束跨阈值。需探针验证未 dispose／重复释放／残留锁。 |
| LY05／AC-10、33 SQLite 恢复与 OS 恢复 | `integration_test/one_screen_layout_test.dart:108` close 卸载 widget 并等 DB 关闭；`:164` 保存后重开 Bootstrap；`:212` 附近 report 明确同进程、非 SIGKILL/真机 | 这是同进程真实 SQLite reopen，不能称 OS 杀进程恢复、同安装冷启动或动画中强退恢复。无需为布局重跑全部 B05；若要求新 LY 二进制的 OS 恢复证明，要另有明确窗口、隔离身份／库及最小生命周期检查。 |

## 对作者运行证据的只读解析

这部分是**独立日志核对**，不是本审查者独立执行测试，且日志来自生产证据目录而非冻结代码清单；每个观察版本的 SHA256 已存档。

- `focused-suite-final.log` 结束标记为 `+66: All tests passed!`；`final-matrix.log` 为 `+30`；`receipt-priority-pass.log` 为 `+1`。可以支持作者对应命令当时报告通过，不能证明最终代码与运行目标完全一致。
- `ios-native-final.log` 有 `+1: All tests passed!`。Python 解码其 `LY_NATIVE_REPORT`，11阶段全部 `scroll_before_action=false`，报告中按钮均处于所报安全区且尺寸至少48（容差0.01），零几何违规。此日志为402×874、1.0字号的作者原生执行；控制七瓶是显式存档权益 QA，未测广告发奖；七瓶结算不在该原生路径内。hitTestable 为测试源码断言，日志解析不能重新执行命中测试。
- `android-native.log` 在加载时以 VM service disappeared 失败，无有效 App 场景通过证据；由原开发继续处理，不定位为 LY 已复现业务缺陷，也不催促或替代其任务。
- `tests-final.log` 在观察时尚无 All tests passed 终止标记；不能把仍在运行的日志算最终统一检查通过。`final-checks.json` 仅记录 format/analyze exit 0。

## 最少独立探针与待执行方式

本目录 `ly_failure_probes_test.dart` 提供三个**未格式化、未分析、未编译、未运行**的测试草案（两个参数分支＋一个生命周期探针）；其状态不得标为 green。相对 imports 设计为在获准的隔离执行副本 `app/test/ly_independent_failure_probes_test.dart` 内使用。不得复制到只读快照或生产工作树。

1. **FP01，AC-11/32，两个分支**：320×568／1.3字号，真实 SQLite 在 receipt 阶段抛错。先完成再挂 LY 页面；无回执、无成功反馈、数据库回执数0；从屏幕实际点击 Next、Next、Home，确认未导航。一个分支直接 Retry，应一次进入11；另一个先点 Stay 再 Retry，应仍在10结算。再次 Retry 不得重复实例或结算。失败时记录最后实例ID、页、phase及首通/回执行，精确区分提交与呈现。
2. **FP02，LY02/04，生命周期**：七瓶、真实解码美术，同一 BoardView 在倒水中途将字号1.0→2.0、可用高度400→240，再回1.3／400。对象保持相同且 closed=false；token只释放一次；内容／容量等于完整 after；之后仍可点瓶，无 disposed notifier 异常。该探针不做 UI 人工外观结论，与 UI 聊天职责不重复。
3. **FP03，AC-08，复用有效对抗测试**：聚焦运行既有 offline_controller 的 `unchanged token` 与 `quick repeated requests`，并在需要验证新取消按钮时补一个 widget 注入：任务 cancel 只计数、不完成；点 Cancel 后启动第二请求，先完成第二条有效结果，再送第一条合法旧结果；新选中源不得改变、棋盘不移动。LY现有 immediately-cancelled替身不足以证明此路径。这里只给设计，未新增第二套重复求解器测试。

仅在架构明确分配 Flutter/Dart 窗口、准备**可写独立执行副本**并核对其源/lock与目标快照一致后，工作目录该副本 `app/`，依序执行：

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter pub get --enforce-lockfile
FIREBASE_ANALYTICS_WITHOUT_ADID=1 dart format --output=none --set-exit-if-changed test/ly_independent_failure_probes_test.dart
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/ly_independent_failure_probes_test.dart --reporter expanded
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/offline_controller_test.dart --plain-name 'B02-04 unchanged token' --reporter expanded
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/offline_controller_test.dart --plain-name 'B02-04 quick repeated requests' --reporter expanded
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/b03_completion_audio_test.dart --reporter expanded
```

草案 format 可能先报差异，由审查者仅在自己的隔离副本中格式化再复查；失败不能通过改生产实现／共享测试来掩盖。真正观察到功能失败时再追加源行、输入/时序、期望/实际、日志和影响；当前没有此类复现证据。不要将这些命令与原开发 Flutter 或原生构建并行。

## 最终候选交接门槛

架构收敛最终源后，重算280文件清单差额，重新读取发生变化的源和测试及原生日志，再决定聚焦探针窗口。本报告不替代 UI 未滚动可见性验收、Android原生正常路径、独立运行、最终CI或商店/手机验收；不扩大为全量B01–B05/SDK重验。OS进程恢复仍明确未验，原有B05证据保持其原范围。
