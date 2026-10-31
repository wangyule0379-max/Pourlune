# 点另一瓶直接换选 · 2026-10-26

状态：源1da13c6实现、64项聚焦检查和正常main实际操作完成；父已独立实际验收通过，限用户确认的普通点击换选范围。本轮不发布，TestFlight14不变。

## 对应要求

按已确认spec/plan 2026-10-26-tap-to-reselect：普通选中A后，点满瓶或顶色不匹配的有水B，直接换选B；不显示普通Can't pour/Bottle full、不错误抖动或播放错误音。合法A→B仍倒一次，同瓶取消、未选中点空瓶忽略。

GameController.tapBottle仅加11行：普通不合法非空目标直接_cancelHint、设selectedSource、选择反馈与notify；不调用失败的controller.pour。首次选择也清旧Hint/拒绝。核心pour、_change及落盘、奖励、动作锁没有改；教学active仍交核心产生Follow guided约束，不允许借换选跳过。RulesPage练习仅在教学不再active时同步普通换选，仍独立于活动存档。

沿用既有selectedSource抬落呈现，没有改绘制或加状态机。上批已通过的橙色、口圈间距和时序保持9006a25；其独立冻结二进制和证据未覆盖。

## 检查

- 7项真实FFI控制器回归先5项因保留旧源RED、动作锁/教学两守卫已绿，后7项全绿；覆盖完整状态与snapshot写0、full/partial mismatch、紧接合法只提交一次/Undo、同瓶/空瓶/无效索引、已得Hint及取消搜索的迟到结果、动作锁/教学/保存失败状态保留。
- 练习教学结束后换选，先RED（仍选旧0、预期2），后GREEN。旧board_feedback只更新被新规则覆盖的普通tap错误断言；显式c.pour真正full/empty拒绝及其信息、旧故障门控仍保留。
- app/固定Flutter3.47.2和NoAdID串行运行8个相关文件64项通过26秒：tap_reselect、flame_full_board_controller、board_feedback、p05_hint_feedback、p05_selection_live、controller、offline_controller、offline_ui。沿用已有快速选择/回落连续性测试，不新开字体或题库矩阵。
- enforce-lockfile/5文件format成功，5文件局部analyze无问题1.7秒；正常lib/main.dart iOS Simulator debug构建34.7秒成功。锁、核心/题库/存储schema未改。

## 正常main实际证据

目录docs/development/evidence/tap-to-reselect-20261026/。native-source.json和runtime-inputs.json记录提交1da13c6387e3530fe5edb0cb6cc79449a3cbfcf7、508输入（含测试）与已安装Runner/kernel，另在ignored build/tap-reselect-frozen/保留同字节副本。
专用D79 iPhone17/iOS26.5；dev.pourlune.tapReselectValidation、tap_reselect.sqlite；正常字号1206×2622、Firebase none/ads disabled。QA为历史隔离快照只读克隆到新命名库，使用正式main31初始盘，非自然解锁或人类首玩。

真实操作（0起索引）：

1. 选0，点满1直接换选1；full-reselected.png为1抬起、0复位，无旧拒绝条。初始与换选后的完整活动payload SHA相同、步数/revision/history均0。下一次点击5，从新源1倒G2，仅变为1/1/1。
2. 选0，点有G2且未满的5，因顶色不匹配直接换选5；mismatch-reselected.png。与第1次合法动作后payload相同、仍1/1/1。下一次点6合法倒G2，仅变为2/2/2。
3. 点0选中、再点0取消，未选中时点空5忽略；cancel-empty与second-legal payload相同、仍2/2/2。
4. 真Hint得0→1，hint-before.png有箭头/两端提示高亮；手点满2换选2，hint-reselected.png旧箭头/建议消失、新瓶上抬，旧0复位，完整payload仍与second-legal相同。下一次点5从手选2倒O1，仅变为3/3/3，最后final.png归位可操作。

native-state-check.json验证上述payload等值对及计数。原生相同payload说明存档未改变；零snapshot调用另由自动回归fault计数证明，不能把一次只读SQL查询当“绝无任何同值写盘”的证明。Hint取消指标可能正常写service metadata，不改变棋盘存档。

七个原速passthrough短片，完整原片保留工具/SQL等待，未变速/插帧：

| 短片前缀（均-original-speed.mp4） | 原片区间 |
|---|---|
| full-reselect | selection-original.mov 13.15–15.25s |
| full-next-pour | selection-original.mov 42.6–44.7s |
| mismatch-reselect | selection-original.mov 87–89.1s |
| mismatch-next-pour | selection-original.mov 120.05–122.15s |
| cancel-empty | selection-original.mov 193.2–197s |
| hint-reselect | hint-original.mov 45.35–47.45s |
| hint-next-pour | hint-original.mov 69.3–71.4s |

“下一次合法操作”没有夹取消或其他游戏动作；中间包含截图/读库等待，不称人工亚秒级连点。actions.json是点击前主机时间估计，实际原片/提帧时间为准。clips.json有区间/hash，video-metadata.json映射1:1，VFR不是性能保证。
作者实际看满瓶/不匹配选中图、Hint前后图，full13.65/14.00/14.30、mismatch87.95、Hint45.40/45.95关键帧；旧瓶落下/新瓶抬起可辨，无普通拒绝条或残箭头。未声称完整连续观看两个长片。

## 边界与留存

迟到Hint、教学/锁/保存故障、练习路径以有效自动检查覆盖；本次正常原生实际得Hint并清理，未强造迟到线程。未验物理手机、所有题目/特殊字号、生产遥测或新商店包。user-before.png仅用户反馈外观，版本未推定。

父已实际看13张同源原生图/时间对应帧，核56证据、508提交输入及冻结二进制，独立比较四对payload摘要/board计数并重放三次合法动作，均符合；详docs/development/review/tap-to-reselect-20261026-independent.md、parent-source-check.json、parent-receipt-check.json。父未重跑工具链、操作设备、重新查SQLite或完整连续观看长片。author-report保留冻结送审pending历史，以独立报告为最终结论。完整2MOV与独立QA库本地保留；Git只收有限短片、帧、日志、来源与报告。F9及窗口、普通2AE、旧QA数据库均不动，无新签名/上传。
