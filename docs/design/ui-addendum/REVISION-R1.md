# R01–R05 修复交付

2026-10-21（Asia/Taipei）。本文为R1历史修复交付。后续第二轮独立复验已将R01–R05通过并关闭；当前新增R06修复见[REVISION-R06](REVISION-R06.md)，待独立复验。本文历史自测记录不替代独立报告。

依据只读：[独立验收报告](../review/ui-addendum-acceptance.md)。本轮写入全部在 `docs/design/ui-addendum/`。D08已通过的4+3布局、窄屏／200%字号滚动方案和D09保留；没有扩做SDK、数据库、题库、正式分层或反馈发送。

## 修复及实际复现路径

| 项目 | 根因与修复 | 修复后实际点击检查 | 证据 |
|---|---|---|---|
| R01 / D07 | `collectionPage` 写死3；按钮及顶栏Back改为携带相同n。详情底部返回收藏，收藏返回首页；首页无无意义Back。 | 分别选择 `home-3` / `home-4` / `home-5` → Collection → View Color Studio → 顶栏Back → 顶栏Back → Collection → View Color Studio → Back to collection → Back to home，全程保持n和对应下一关。 | `revision-r1/after/R01-progress-{3,4,5}.png`；结果JSON的3条R01 |
| R02 / D01/D03/D04/D05 | 原辅助页无实例上下文，调用默认Level12。现保留最小内存显示上下文：模式、关卡／日期、四/六/七瓶布局、教学指引、已加瓶、未保存、待奖励、冷却。辅助／取消／暂停返回不重建该对象。 | `reward-pending`→Stay here→Undo仍pending＋Retry、无可用Extra；`pause-stay`→Undo仍未保存＋Retry；`daily-old-board`→Undo仍Daily·Oct20；`replay-board`→Undo仍Replay·Level3。五种起点（含seven）各查Undo、Hint→Cancel、Back暂停→Resume。另查待奖励与未保存长链，仅显式Retry成功才清相应标记。 | `revision-r1/after/R02-*.png`、结果JSON；其中 `R02-daily-reward-retry-keeps-origin.png`为旧日题领瓶后仍属Oct20 |
| R03 / D02/D05 | 重开按钮原写死seven。取消改回当前上下文；确认只显示同实例重开回执，不更改模式／日期／已有瓶权益／待处理标记。只有确有额外瓶才出现“Your extra bottle stays.” | 六瓶 `hint-timeout`→Restart→Keep playing与确认Restart，仍6瓶且无到账提示。七瓶→Undo→Restart→取消或确认，仍7瓶。另覆盖待奖励、未保存、旧每日、重玩起点的取消／确认。 | `revision-r1/after/R03-six-{cancel,confirm}.png`、`R03-seven-{cancel,confirm}.png`、`R02-R03-*.png` |
| R04 / D06 | Skip原跳新建Level12。新增 `tutorial-free`，仅关闭guided；Level1、原四瓶、图像层序保持。首关无Extra bottle，Undo/Hint继续可用。 | `tutorial`→Skip：Level1、4瓶、相同4张瓶图、无Skip／Extra；再Undo、Hint→Cancel仍Level1四瓶。 | `revision-r1/after/R04-tutorial-skip.png`；图册 `#tutorial-free` |
| R05 / D06/D08 | 五瓶原片直接等分时裁线穿过轮廓，裁入邻瓶且截断自身。现按原片每瓶不重叠轮廓范围重新提取，并置回同一396×793透明画布。未重画瓶体、未改颜色／刻度或RGBA像素。 | 五张均为396×793 RGBA，主体与画布边缘有余量；alpha≥32的明显主体组件仅1个，没有可见的相邻瓶竖条。放大查看单瓶及最新六瓶／七瓶／原框架导出。 | `assets/bottle-crops.json`、`tools/split-bottles.cjs`、`screenshots/board.png`, `seven.png`, `seven-fidelity.png`；旧裁片存 `revision-r1/before/assets/` |

[修复前后真实截图对照](revision-r1/index.html)。图册主入口 `index.html`，全状态导出与文案已重新生成。新增上下文状态为 `puzzle-board`、`pause`、`restart-confirmed`、`tutorial-free`、`reward-applied`；图册共87状态。这些是复用组件的状态视图，不是新增App导航层级。

## 自测方法及结果

`tools/check-revision.cjs`在隔离的Chrome测试页中操作真实DOM按钮，断言屏幕身份、瓶数、文字与按钮禁用状态，没有mock导航或存档。素材部分检查真实RGBA连通区域与画布。不是只对静态状态截图点名。

- 修复前28项：27失败、1通过，重现全部R01–R05。原始结果及当时截图保存在 `revision-r1/before/`。
- 修复后41项：41通过、页面脚本异常0。除原28项外，补了其他模式重开、长链标记及旧每日奖励归属等13项，见 `revision-r1/after/results.json`。
- 同一工作区重新导出全部87状态、窄屏320×700、200%字号、增强对比和顶部／底部证据。D08组件CSS尺寸与D09样例没有改动，素材重提取保持图片画布尺寸。
- 在Codex内置浏览器另点查 `reward-pending`→Stay here→Undo，确认pending及Retry仍可见，领取按钮禁用。

复现命令（依赖路径沿用原交付）：先启本地4173服务，再 `node docs/design/ui-addendum/tools/check-revision.cjs after`；导出 `node docs/design/ui-addendum/tools/export.cjs`；素材重提取 `node docs/design/ui-addendum/tools/split-bottles.cjs`。

## 准确边界

- 上下文只存在当前打开的原型内存中。**评审下拉选状态、直接改URL／浏览器历史或重新加载**表示打开一个独立、确定的样例，会重置样例上下文；**页面内按钮**沿当前实例保留上下文。不是跨进程／数据库／存档恢复。
- Undo、Hint和Restart仍是交互呈现模拟：不执行真实求解、液体倒入或撤销栈。Restart回执不冒充算法或写盘验证。
- `pause-saved`和`reward-applied`是明确的成功模拟事件，分别只清未保存标记、或将待奖励转成该实例1瓶权益。没有SDK真实奖励、磁盘成功或幂等持久化证明。
- 原框架静态图只作视觉证据；交互验证以自适应组件页面的实际按钮为准。
- 本轮仍未验证真实SDK／计时／强退／后台、全题库、原生触控／读屏／字体授权及正式反馈目的地；独立验收报告与specs均保持只读，36条App验收仍待执行。
