# B02 独立验收 · 第二轮通过

日期：2026-10-22（Asia/Taipei）；验收：Pourlune ｜ 产品架构。

**当前结论：B02-01～09 在批准的离线流程／工程内容范围通过；B02-R01 已关闭。** 可以提交推送开发分支并派发 B03。第一轮原始失败程序与日志保留，第二轮新日志位于 `B02-evidence-r2/`，不以覆盖失败证据冒充初次通过。

实现、交付和本报告已作为 `c5aa1514f2f02d6b298c7baeadd5873db01fbffe` 推送开发分支 `codex/offline-foundation`。B03八项工作包已派发，执行聊天active。B02 [远端CI](https://github.com/wangyule0379-max/Pourlune/actions/runs/39662730373) 已于2026-10-22 03:45（Asia/Taipei）核验success：tests-and-android及ios-build两个job、所有步骤成功，含固定SDK、核心／应用检查与双端构建。此结论不包括远端设备交互／SDK联调。

## 第二轮独立检查

| 检查 | 结果／证据 |
|---|---|
| 修复源码 | 复用 `_afterWrite`／`_pendingNav` 第一笔意图机制，增加小型 `deferNavigationUntilSaved`；共享 `_play`／`_today`／工程入口保存成功后重新核对条件。Stay 清除意图，后续选择可重新登记；无 schema／依赖／奖励逻辑变化 |
| 核心与应用 | 本聊天复跑 core format/analyze/26 tests、app format/analyze/59 tests，全部通过。见 [检查命令及退出码](B02-evidence-r2/checks.json)和对应日志 |
| 原失败回归 | 本聊天原样执行第一轮 `replay-navigation-regression.dart`，现1/1通过；新日志 [independent-regression.log](B02-evidence-r2/independent-regression.log)，原失败日志保留 |
| iOS 原生重玩恢复 | 本聊天运行 `integration_test/replay_navigation_test.dart`，1/1通过。实际Flutter按钮＋sqflite SQLite3.51.0；覆盖Retry、Stay、重选、双击／Home竞争、候选写入回滚；结果first1、receipts4、pieces0、counter0、候选阶段调用3次（旧结算＋候选回滚＋同候选重试）。见 native-replay.log |
| 双端构建 | 本聊天 Android debug、iOS simulator debug 构建均通过，见 android-build.log／ios-build.log。iOS使用 final 工程场景、独立库 `b02_review_final_r2.sqlite` |
| 正常App最终关 | 安装本聊天正常构建，实际操作 Continue Level60→五次合法倒入→Story complete，Seaside5/5；目标错位时不通关并提示匹配标签。最终页仅每日／收藏／重玩／Home，无Next。见 [截图](B02-evidence-r2/ui-01-story-complete.png)与AX文本。该第60关是明确标注的两色别名种子，证明最终导航，不是生产第60关内容 |

第一轮本聊天已独立复跑完整 iOS flow，并实际做教学步骤／棋盘同实例不重装进程恢复、Skip、真实提示和取消。第二轮针对本次导航修复增加原生失败恢复和最终页操作；没有把作者自查、HTML、静态截图或替身当原生插件证据。

## 任务通过范围

- B02-01/02：主线／重玩入口、替换／失败保护、教学与Skip状态及恢复，依据host测试、第一轮flow和实际冷恢复；R01重玩待办已闭合。
- B02-03/04：当前局面固定标签搜索、可取消isolate、实例／修订过期结果、超时／无解区分，host测试与原生flow有证据；最短解及最差2秒／100ms、生产四色设备性能不在通过声明内。
- B02-05/06：严格日期目录、每日双槽、跨日替换／失败恢复、旧日归属与当日Replay印章去重，真实SQLite和原生flow通过。工程目录用于路径验证，生产至少30题留B03。
- B02-07：收藏归属／揭示分离、三场景映射、单次导航与最终页通过本批检查；20/40分支保留作者原生日志来源及本聊天host验证，正式场景图层尚待B03。
- B02-08/09：英文ARB、偏好持久化、真实基础语义与320px/2x host渲染检查、迁移与回归、iOS原生及双端构建通过；音乐音效尚未接实际音轨，正式隐私／反馈目的地仍待交接。

仍待：完整60＋30内容、正式资源／声音／动画、SDK、正式身份／地址、Android实际运行、真机、读屏语音、最大支持字号设备矩阵及最差性能；远端B02 CI结果已补录于上方。B02验收不是首版可发布结论。

---

# 第一轮历史记录

日期：2026-10-22（Asia/Taipei）；验收：Pourlune ｜ 产品架构。

**结论：暂不通过，修复 B02-R01 后复验。** 当前九项实现和现有自动检查已交付；发现启用的重玩导航在保存失败时被静默丢弃。本轮不提交／推送 B02 实现，不派发 B03。

依据：[B02 执行包](../../pmpowers/plans/2026-10-22-B02-offline-flows.md)、PRD §4.2、AC-11/22 及保存成功后执行一次原导航的跨流程约定。执行方交付：[B02](../deliveries/B02.md)。验收针对工作区，已提交基线 `401e170`；作者自查未作为独立验收替代。

## 1. 本聊天实际检查

| 检查 | 独立结果与证据 |
|---|---|
| 核心 | format、analyze、26/26 测试通过；[命令与退出码](B02-evidence/checks.json)，对应 core 日志 |
| 应用 | format、analyze、54/54 测试通过；真实宿主 SQLite、widget、isolate 及 B01/R01 回归包含在内；对应 app 日志 |
| 原生完整 flow | 本聊天运行 `offline_flows_test.dart`、flow、隔离库 `b02_native_review.sqlite`，iOS26.5 模拟器 UDID `4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2`，真实 sqflite/isolate，通过1项。教学→Skip→当前棋盘提示→通关／拼片→收藏→设置／演示→跨日继续／取消替换→写入失败Retry→历史／未来只读→同日Replay；结果 first4、piece1、两日印章、counter0、receipts7。见 native-flow.log |
| 提示样本测量 | 上述 flow 的响应约35–43ms，worker约1.4–29.4ms。仅这次两色 debug 模拟器样本；不代表生产四色、最差响应或真机性能通过 |
| 正常 App 构建／操作 | 独立构建 iOS flow，数据库 `b02_review_manual.sqlite`；实际 CUA 操作 Start→教学1→3。终止 PID70586，再 launch PID70638，比对期间无安装／清库；Continue 恢复同实例 `dev-1792609369240363-562532683`、moves1／revision1／教学2/3及完整棋盘 |
| Skip 与提示 | 恢复后 Skip 保留棋盘和1步，revision2；Hint 自动选瓶2、建议瓶1，无自动倒入；Cancel hint 清选择及提示，仍1步。截图与 AX 文本见 ui-01～04 |
| 针对性独立回归 | [程序](B02-evidence/replay-navigation-regression.dart)由全新上下文审查者提出，本聊天读取后复制并复跑；**退出1，断言失败，证明 B02-R01 尚未修复**，不是测试基础设施故障 |

截图：[教学落盘](B02-evidence/ui-01-tutorial-saved.png)、[进程恢复](B02-evidence/ui-02-tutorial-restored.png)、[提示不改棋盘](B02-evidence/ui-03-hint-preserves-board.png)、[取消提示](B02-evidence/ui-04-hint-cancelled.png)。均为实际 Flutter 开发 App，非 HTML；开发绘制不提升为正式视觉通过。

本轮对固定标签求解、isolate取消、旧回包、每日快照、两槽、非空迁移、教学状态和收藏事务做了源码审查。milestone/final 与 Android 构建本轮仅保留作者日志来源，未声明独立复跑；此次已发现缺陷，修复复验时按变更补检查。

## 2. B02-R01 · P2 / Important · Replay again 在保存失败时丢失意图

定位：`app/lib/presentation/game_screen.dart:114` 的 `_play` 提前返回；调用来自 `app/lib/presentation/collection_pages.dart:329`，Replay again 按钮仅检查 `busy`，失败状态仍启用。

复现：

1. 首次通关第1关，再进入 Replay1，进行到最后一步。
2. 在通关事务的 receipt 写入注入失败，实例已完成但尚未保存，显示 Retry／Stay。
3. 点击仍可用的 Replay again；没有记录待办动作。
4. 移除故障并 Retry，结算保存成功，但仍是同一已完成实例和完成页面，没有创建新重玩实例。

与 Next／Home 已有待办机制不一致，违反“保存成功后执行一次原导航”。数据没有被部分提交，但启用按钮的操作被静默丢弃，不能按本批完整流程通过。

### 修复与回归边界

- 将 Replay again 接入明确待办意图；保存仍失败时不建新局，成功后仅创建一次同关新重玩实例并导航。保持稳定关卡身份、无额外拼片／主线计数、现有已完成回执幂等。
- Stay 清除待办；之后的新选择遵守“第一笔有效意图优先”，不能被连点或其他目的地覆盖。恢复过程不能绕过现有保存阻断。
- 增加实际按钮路径回归：失败→Replay again→Retry；失败→Replay again→Stay→Retry不跳转；Stay后再选Replay again；双击及与Home竞争只执行一次；必要时新实例创建也失败后可重试。
- 检查同类 `_play`／`startLevel` 入口是否存在启用但无结果的失败导航，修复真实同类行为即可，不扩建新的导航框架或扩大B02范围。
- 保留本轮失败程序和日志作历史证据。执行方补正确行为测试与原生重玩失败恢复路径、更新交付；独立验收方再复跑。

## 3. 当前范围结论

B02-01、B02-07、B02-09 受本缺陷影响待闭合；其余功能已获得上述有限独立证据，未将整批标为通过。B01 已通过状态不被撤回。全量生产题库与美术音轨、SDK、正式地址、真机／Android运行／读屏／最差性能仍为原后续批次；不把这些依赖当作本轮额外缺陷。
