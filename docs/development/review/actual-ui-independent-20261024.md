# 2026-10-24 当前原生 UI 独立复核

复核者为受委派的独立只读 reviewer。依据 `requesting-code-review`、七张原稿 boards 01–07、`docs/pmpowers/plans/2026-10-23-full-ui-reacceptance.md`、PRD 补充稿与父冻结清单进行。没有操作模拟器、浏览器、F9；没有运行 Flutter / Dart / pub / 原生构建或测试，没有修改实现或父报告。本文件是获准新增的独立报告。

## 当前结论

**本轮独立复核通过：已发现的 Critical / Important 均已关闭，可以进入下一精确 CI / 签名核包门槛。** 本结论针对下列已冻结源码、所看原生画面与已核对运行证据；它不替代后续新提交 CI、签名包检查，也不直接宣称新 TestFlight 已完成。

本轮暂停重复边框、普通字号提示理由、小屏 1.65× 提示容量、P15 直接 Replay、P09 主次操作和保存失败操作隐藏，均已从提供的当前真实原生截图中看见相应修复效果。连续提示循环经最终 A* 修复、最终运行日志和八代表关从初盘完整实际 UI 操作证据关闭。静态几何 / widget 测试与作者日志没有被当成视觉通过证明。

## 发现与关闭状态

### Critical

本次已读差额与已看图中未发现 Critical。

### Important

1. **已关闭：保存失败 Retry / Stay 被说明区滚动位置隐藏。** `large-save-failed.png` 实际只露出失败面板顶部，未显示 Retry / Stay。原说明区保存旧 offset 后切换为失败信息，属于影响恢复操作的 P2。当前 `board_page.dart` 已将 bounded `SaveFailureNotice` 提到说明滚动区域之外，保留原 `retry` / `stayHere` 回调。新回归先滚动到说明底部、触发真实持久化故障，再要求 Retry / Stay 命中和底部容量可见，覆盖该根因。追加实际打开 `small-save-failed-actions-fixed.png`、`small-save-failed-large-text-fixed.png`（1.65×）与 `small-save-retried-fixed.png`：失败文案与 Retry / Stay 图标完整，七瓶容量、Extra 与三辅助操作保留；重试后同盘 moves 1 且恢复 Saved on this device。父记录实际 Home→Stay→Retry 原地成功。该已看条件下视觉关闭，业务未改。

2. **已关闭：P15 缺直接 Replay。** 原 `P15-daily-complete.png` 与 `collection_pages.dart` 的每日分支只有 Daily puzzle / Home，违反 PRD 补充稿 8.2 保留 P14 / P15 Replay 的要求。P14 本来已有 Replay，因此从未认定整个每日重玩能力缺失。新增 Replay 只在 `s.puzzleDate == c.today.date` 且题库目录可用时出现，调用既有 `startToday`；该控制器重算日期、拒绝 busy / 保存失败、创建新实例并依印章设置重玩身份。`large-P15-daily-replay-fixed.png` 显示直接入口，`large-P15-replay-new-instance.png` 显示新盘，`daily-replay-receipt.json` 记录新 ID、`replay: true`、2026-10-24 单枚印章、主线首次完成 1 / 拼片 0；新增 widget 回归还检查原记录不变及旧日期隐藏。静态与上述视觉范围内可关闭。

3. **已关闭：小屏 1.65× 提示时底部容量消失。** `small-P07-hint-large-text.png` 缺少底排 5–7 标签 / 容量。当前 104px 提示说明只适用普通字号且可用高度至少 600；bounded 辅助按钮按实际 14px 字号决定换行，1.65× 保持三列，恢复一整行高度。未修改瓶宽、flight gutter 或几何。`small-P07-hint-large-text-fixed.png` 底排容量、Extra bottle 与 Undo / Hint / Restart 均完整，长提示保留在可滚动说明区。该明确条件下可关闭。

4. **已关闭：Level 13 连续提示循环。** 已看 `large-level13-hint-cycle-red.png`；独立读取旧失败动作记录（现保存在 `actual-hint-cycle-red.json`），实际提示序列前五步之后反复 4→3 / 3→4，瓶子内容描述第 5 / 7 / 9…步相同、第 6 / 8 / 10…步相同，循环成立。旧 DFS 每次求一个任意可解路径首步，单次 found 不保证连续调用趋近终局。中间 BFS 虽能排除循环，但父实测 extra21 触及 50000 状态后 timeout，故已弃用；BFS 不是最终交付。

   最终 `packages/pourlune_core/lib/src/hint.dart` 使用标准库 `SplayTreeMap` A*，按最小 `(g+h, serial)` 出队才验 goal。启发式 h 计全部颜色连续组，仅豁免已在自身固定目标底部的组；合法 pour 最多消除一个未锚定组，且 h(goal)=0，因此是 admissible / consistent 下界。`seen` 保留 best g，发现更短路径会替换 open 中旧优先键；不存在将旧差路径锁死或同一 key 多份积压的问题。目标瓶按原位置顺序保持，只有 null 目标缓冲瓶排序归一；缓冲瓶接收规则与胜利约束相同，其排列是保目标与代价的图对称，不会错误合并目标。节点仍保具体 board 与原 root 的实际 first move，因此不需要将归一后的索引反映射回玩家盘面。返回最短路径首步使剩余最短距离严格减一，排除连续 found 来回循环。

   2 秒 / 50000 状态预算未提高；先查预算再出队目标更加保守，超预算仍为 timeout，只有 frontier 耗尽才宣称 provenUnsolvable。seen / open 具有有限状态上界，实际峰值内存与设备速度未测，不写性能通过。`hint_worker.dart` 与控制器取消 / 过期门控未变：外层 deadline 和 cancel 终止 isolate；响应仍核对 generation、实例 ID、revision、前台、页面与动作合法性。

   新增八代表关无 / 有 extra 连续至终局且禁止重复盘面测试；完整核心套件还包含 90 题初始 / 中点、60 题四位置、目标位置、不可能 12 状态图、预算及旧非空定义检查。已读最终核心日志 38 项通过及新增 `hint_test.dart` 的 188 个完整瓶位 BFS 图 oracle：独立枚举 53 / 135 个有序盘面，再从真实胜利盘逆向 BFS 求距离，要求每个 found 的实际下一盘距离减少 1；它不复用 A* 启发式或缓冲归一，属于有效独立验证。本 reviewer 未亲自运行 Dart 测试。

   最终实际打开 `large-level{13,20,21,28,40,41,53,60}-final-astar-complete.png` 八图，另看 28 拼片、全收藏及小屏 1.65× 七瓶最终提示图。八结算的瓶子 / 场景、进度、主次按钮均清楚，无新可见重叠或安全区遮挡。只读独立核对 `actual-hint-ui-moves.json` 的全部 114 条实际动作：按八份收据依次分组 17 / 13 / 13 / 14 / 15 / 14 / 14 / 14 步，使用当前题目初盘逐步重放这些记录动作（没有调用 solver、没有操作 UI、没有运行 Dart）；所有动作合法、每关无重复盘面、最终精确目标胜利且与收据 board / moves / revision 完全一致。20→21、40→41 按收据为实际 Continue 新局；其他前序解锁进度明示为隔离 QA 库 seed，没有将它冒充人类首玩通关。最终 A* 的循环 Important 可关闭。

### Minor

1. **已关闭：P09 危险操作层级偏离原稿。** 原截图以 Restart 为绿色主操作；当前默认确认恢复 Keep playing 为绿色主操作并 autofocus，Restart 为次操作，false / true 返回语义保持；Reset 专用分支未改变。`small-P09-keep-playing-primary.png` 实际确认无重叠。

2. **已关闭：暂停双层外框。** `P06-pause.png` 实际存在 KnitPanel 外额外描边；透明 Dialog 单独覆盖无边 shape / elevation 0 后，`P06-pause-fixed.png` 仅保留 KnitPanel 一层边框。

3. **已关闭：常见手机提示理由截断。** 修前 `P07-hint.png` 理由仅露出顶部；`P07-hint-fixed.png` 操作说明与理由完整显示，取消提示仍可见。普通字号高度增至 104 并省去提示状态下重复 goal，未删除 `hintReason`。大字号的长文滚动不等同于此普通字号缺陷复发。

4. **已关闭 P3：已获加瓶后的入口状态文案。** `small-seven-hint-final-astar.png` 明确已获 extra，旧入口仍固定为 Extra bottle，未按 PRD / 原 P18 改成 Bottle added。控制器原来已正确拒绝再次获奖，因此从未认定为重复奖励漏洞。最终仅新增本地化 bottleAdded、按 `extraBottleGranted` 切换标签和 check 图标，原 `onExtra` 与奖励门控不变。已实际打开 `small-seven-bottle-added-final-build10.png`：1.65× 的 Bottle added 和 check 清楚，七瓶容量、三辅助操作、提示目的地均保留，无新重叠；已读先 RED 后 51 项 GREEN、analyze clean 与 build10 Simulator build 成功日志。末条 P3 可关闭。独立读取当前原生 Info.plist 确认为 0.5.0 / build 10；尚无签名 / 上传结论。

## 已实际看过的证据

原稿：`docs/design/original/Pourlune_Design_Pack/boards/01_Entry_and_Chapters.png` 至 `07_Settings_and_Privacy.png`，共七张。

当前图均位于 `docs/development/evidence/full-ui-reacceptance/actual-20261024/`。共实际打开 66 个不同 PNG：

- 入口 / 菜单：`P01-welcome.png`、`P02-home.png`、`P03-chapters-top.png`、`P03-top-boundary.png`、`P03-bottom-boundary.png`。
- 玩法 / 弹窗：`P04-tutorial.png`、`P05-daily-board.png`、`P05-after-chapter-21.png`、`P06-pause.png`、`P06-pause-fixed.png`、`P07-hint.png`、`P07-hint-fixed.png`、`P08-no-legal-moves-controlled.png`、`P09-restart-confirmation.png`、`P16-extra-info.png`、`P18-seven-bottles-controlled.png`。
- 结算 / 收藏 / 每日：`P10-normal-completion.png`、`P10-patch-completion.png`、`P10-chapter-complete.png`、`P10-final-completion.png`、`P11-new-patch.png`、`P12-collection.png`、`P12-all-scenes-completed.png`、`P13-scene-locked.png`、`P14-daily.png`、`P14-daily-stamp.png`、`P15-daily-complete.png`。
- 设置：`P19-settings-top.png`、`P19-settings-bottom.png`、`P19-how-to-play.png`、`P19-how-to-play-bottom.png`、`P19-how-to-play-bottom-drag.png`、`P19-feedback.png`、`P19-licenses.png`、`P20-privacy.png`、`P21-reset-confirmation.png`。
- 过渡：`settings-exact-motion-1.png`、`settings-exact-motion-2.png`、`settings-exact-motion-3.png`。所列采样帧显示正常淡入淡出，未见纹理损坏；未独立连续播放完整录像。
- 小屏：`small-P01-welcome.png`、`small-P04-tutorial.png`、`small-P18-seven-standard.png`、`small-P18-seven-large-text.png`、`small-P07-hint-large-text.png`、`small-P07-hint-large-text-fixed.png`、`small-P09-keep-playing-primary.png`、`small-save-failed-actions-fixed.png`、`small-save-failed-large-text-fixed.png`、`small-save-retried-fixed.png`。
- 大屏 / 追加：`large-P15-daily-replay-fixed.png`、`large-P15-replay-new-instance.png`、`large-save-failed.png`、`large-save-retry-process-recovered.png`、`large-level13-hint-cycle-red.png`。
- 最终 A*：`large-level13-final-astar-complete.png`、`large-level20-final-astar-complete.png`、`large-level21-final-astar-complete.png`、`large-level28-final-astar-complete.png`、`large-level40-final-astar-complete.png`、`large-level41-final-astar-complete.png`、`large-level53-final-astar-complete.png`、`large-level60-final-astar-complete.png`、`large-level28-new-patch-final.png`、`large-all-scenes-final.png`、`small-seven-hint-final-astar.png`。
- 最终 build10 文案：`small-seven-bottle-added-final-build10.png`。未将仅含设置顶部的截图当成版本号可见截图。

P10 / P11 的成功反馈、场景主体、进度与主次按钮组织清楚；章节 / 最终结算及所看七瓶图未见可见重叠或安全区遮挡。各可滚动长页的内容在截图边缘被 viewport 截断，不据此将整个长页判成不可达；本 reviewer 没有亲自操作这些滚动路径。

## 差额与验证边界

父冻结清单含 523 项。初次核对只有 `game_screen.dart`、`board_page.dart`、`full_ui_reacceptance_test.dart` 漂移；追加 P15 后只有上述三项加 `collection_pages.dart`。Dialog 与首次新增 UI-R08 测试可逆还原到父冻结哈希。追加提示循环修复后，另读 `hint.dart`、`hint_test.dart` 与 `main60_v2_test.dart` 新差额。几何仍未改；SaveFailure 最终只将写盘失败 notice 移出说明滚动区，没有更改 RewardStatus。当前工作树包含已获授权的 60 题及父 UI 成果，没有将这些旧差额当作本轮新增缺陷重做。

本 reviewer 只读测试与源码，没有亲自运行检查。父报告的聚焦测试结果支持其测试范围；本报告的视觉结论只来自逐张实际打开的 PNG。

主要验收核查点（Bottle added 文案追加前，现保存在 `native-source-before-caption.json`）的 523 项已逐项重算 SHA256，当时与工作树全部匹配，无漂移。当时 Runner 的 SHA256 与旧冻结记录的 `05f2e478fbb9159acddfb8012a0d0ba3ce68dbf8f40110f1a3974d41fc4f3c11` 匹配，QA 版本为 0.5.0(9)。

最终 build10 `final-native-source.json` 的 **528 项**再次逐项重算，当前全部匹配，无漂移。相对旧 523 项，仅三份本地化文件、`board_page.dart` 的 label / icon 与已有回归的 Bottle added 断言变化；额外纳入冻结 `app/pubspec.yaml`、应用 / 核心两份 lock、SPM Package.resolved 和 `.flutter-version`。核心算法与 114 条实际动作记录没有变化。当前 `app/build/ios/iphonesimulator/Runner.app/Runner` 匹配新冻结 SHA256 `03918c3f3464a3a6096f88d3eb00dc581d6b97f4a8294fb3f011b6da383dfc4b`；Info.plist 独立读取 `dev.pourlune.layoutValidation` / `0.5.0` / `10`。记录 normal main、ads disabled、Firebase none；这仍是独立 QA 二进制，不是签名分发候选。

已读最终检查日志的完成结果：core 38 通过，whole app 280 通过，analyze `No issues found`，Simulator native build 成功。为固定此次已审阅字节，记录以下 SHA256（路径均相对此证据目录）：

| 文件 | SHA256 |
|---|---|
| `native-source-before-caption.json` | `a5fe65cfcf4919e59e2594c45a95f2f6201f1d7e3b96b5047f8c2eb42c13b723` |
| `final-native-source.json` | `10b7c1d58c1ab2396b570e2ff69ea47a64e6a8377377e37637399b74ddfc5c85` |
| `actual-hint-ui-moves.json` | `cb3015ff6275ab4082c0a7fa8e6090ad9a18bff91ce5f1c396b9336e217f1c05` |
| `eight-representative-summary.json` | `8f161d93e51719e4e8be8806333007982b3bd0c6d61e9bb73ff4341bf1ae8b0d` |
| `checks/ui-actual-core-final-green.log` | `362bcca9e6aec63a9babeeba5ec6408683a115155b77c781aa78916fe1d9f164` |
| `checks/ui-actual-whole-app-astar-final.log` | `b50ad5b6811a8bb675b50fea29ec1314a8a20cb9fdf356294ecbeef9ac0a6a18` |
| `checks/ui-actual-final-analyze.log` | `581c8077fc1cb6746b77bec82b829b938093a56e00b019caebb026cac4592289` |
| `checks/ui-actual-native-build-astar-final.log` | `03173ded1b56a11eefb32e84a78d470a1af3682cadcc1db97abfb85b9f7e7525` |
| `checks/ui-actual-added-label-red.log` | `aa7504b2adcb90a15faaeb7284e27548cdb68dde716ae675a35b0cee744303a4` |
| `checks/ui-actual-added-label-green.log` | `11ec7e5d46d7f279e33aeb07316a10a6feb7343c648d43b72770a7ca8c1d1ce0` |
| `checks/ui-actual-added-label-analyze.log` | `e488ed39bccc248a5dc27fee7a8ccfb9ce34c05a361c3a46422aa87640910faf` |
| `checks/ui-actual-native-build10-caption.log` | `cc4f7030f98538e06a3584d7a3e371636a72c21818330141bcafd6254ed64b1a` |
| `level-013-actual-ui-receipt.json` | `1946cebe7222fd746e3a9babe285071f8be7bc34e9bc8900706a3ef7ab22cad6` |
| `level-020-actual-ui-receipt.json` | `bab3e66be326e69e8046cbf7e4a09a6332b71828e6db7b05eaa01eaafe81ed77` |
| `level-021-actual-ui-receipt.json` | `b579fd94fe07e364f9bc16a056b1e4cf8ebe0b23837e09a341da3f75868061e9` |
| `level-028-actual-ui-receipt.json` | `a306f9404fbe96fd8337ae5be8ccd4b9286caa7fd8c8faa6b5a4465b0031d578` |
| `level-040-actual-ui-receipt.json` | `d28ed6695750b002365f1d23bef404744967ed1f9d81b3cab22ff801abab5b88` |
| `level-041-actual-ui-receipt.json` | `d4515122136b8ce965010e37c6021812e3236163f34f703eb9e46799f78b6d11` |
| `level-053-actual-ui-receipt.json` | `4fe9523e623980ab48be0b7aec15b0991fa9cd0790315dd1b4716c66e3184a6d` |
| `level-060-actual-ui-receipt.json` | `3c22e524eaf7bead7d011bbc922ad05158a759efe5dd52e52859730f5552ae97` |

以下行为明确未作通过判断：

- 保存失败与恢复：可见性已按上述三张小屏绿图关闭。另已看恢复图和 `save-retry-kill-recovery.json`，其记录同安装 SIGKILL、实例 `dev-1792803728599782-1292055753`、moves / revision 1、snapshot unchanged / SQLite quick_check ok / retried move present；它支持该实际保存与恢复条件，不能外推所有故障类型。
- 最终 A* 提示：上述 core 38 日志和八关实际 UI 114 pours 范围已核对，不外推所有可能盘面、物理设备的性能或人类无需提示的难度。
- 奖励优先条的全面可见性与真实 SDK 奖励：广告暂停，本次没有真实获奖证据；七瓶只代表受控核心权益 QA。
- 完整录像所有帧及动态手感：只读三个联系图的指定采样，不能证明每个时刻。
- 所有页面 × 所有设备 × 所有字号组合：只看上列真实截图，不由单一条件外推。
- 人类首次游玩的实际难度、美术商业权属、真机、签名候选、商店与 TestFlight：均不属于本轮只读视觉复核通过范围。

当前没有未关闭的 Critical / Important，末条 P3 也已关闭。本报告允许推进下一精确 CI / 签名核包门槛；实际生产配置、签名新包、分发或商店步骤仍须按各自门槛核验，不用本地 QA 通过代替。
