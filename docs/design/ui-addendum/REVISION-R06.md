# R06 修复交付

2026-10-21（Asia/Taipei）。第二轮独立复验已将R01–R05通过并关闭；D02/D03/D04/D06/D07与D08相应设计／原型范围通过。**本轮R06修复已完成自测，D01/D05/D09当前待独立复验。** 不改独立报告或tracking结论。

## 打开与复现

- [同条件修复前后截图](revision-r06/index.html)：本机服务为 [R06证据入口](http://127.0.0.1:4173/revision-r06/index.html)。所有HTML与PNG都在项目内，可直接离线打开。
- 原型：`/Volumes/data/App Development/Pourlune/docs/design/ui-addendum/index.html#pause-stay`；待奖励选 `#reward-pending` → Stay here → Undo。
- 先在桌面评审栏选择200%和Stronger contrast，再将浏览器改为320×700。390宽、100%／200%、两种对比均有配套证据。
- 复合状态沿已有路径：pause-stay → Extra bottle → Watch ad for +1 bottle → Stay here，能看到Retry save与Retry reward。没有新加产品功能或更改原型业务逻辑。

## 改动与实测

仅修改横幅布局规则，取消`.status .row button`固定82px：

- 横幅行启用flex-wrap；正文有弹性宽度，空间不足时操作按钮另起一行。
- 按钮按文字宽度排版，局部使用normal断词规则，避免继承全局overflow-wrap:anywhere把Retry拆开。最小点击高度48px，保持1em字号，没有隐藏或裁切按钮。
- 左右padding改为12px；按钮max-width为横幅可用宽度，保持清楚边距。

320宽、200%与增强对比实测：

| 文案 | 修复前宽×高 | 修复后宽×高 | 字体 | 修复后单词 |
|---|---|---|---|---|
| Retry | 82×87.19 | 101.86×50.59 | 两版均28.16px | 完整一行 |
| Retry save | 82×123.78 | 171.81×50.59 | 两版均28.16px | 两词均不拆分 |
| Retry reward | 82×160.38 | 205.36×50.59 | 两版均28.16px | 两词均不拆分 |

## 实际检查及结果

`tools/check-r06.cjs`以真实浏览器控件设置字号／对比，然后调整视口，操作真实按钮。用DOM Range读取每个单词各字符所在的行，核对完整单词、未裁切、字体大小、按钮尺寸与滚动后命中；没有用CSS字符串或截图文件存在代替渲染检查。

- 24组合＝未保存、待奖励、已有复合状态 × 320/390宽 × 100%/200%字号 × 对比开/关，视口高度700。
- 修复前12通过、12失败，全部200%组合复现断词；修复后24/24通过、页面脚本异常0。
- 每个组合都执行Undo → Hint → Cancel → 暂停 → Resume，标记持续保留，免费辅助可操作；显式Retry才清除标记。复合状态分别检查先保存、先写奖励两种次序，另一标记不被清除。
- R01–R05的41项回归全部通过，记录保存在本轮 `revision-r06/regression/`，未覆盖旧R1证据。
- 320×700、200%下七瓶在对比开／关均同尺寸、4+3、末排居中；读数见 `revision-r06/after/results.json` 的sevenLayouts。
- 全图册87状态及窄屏／大字号证据重新导出，见verification.json；原件、产品specs、独立报告和tracking未编辑。

检查命令（项目根目录、本机原工具依赖）：

```
node docs/design/ui-addendum/tools/check-r06.cjs after
node docs/design/ui-addendum/tools/check-revision.cjs after docs/design/ui-addendum/revision-r06/regression
node docs/design/ui-addendum/tools/export.cjs
node docs/design/ui-addendum/tools/r06-evidence.cjs
```

## 变更文件

| 文件／目录 | 用途 |
|---|---|
| `style.css` | 唯一产品呈现改动：状态横幅flex换行、按钮按内容宽度及局部断词规则 |
| `tools/check-r06.cjs` | 24组合、单词行数／字号／点击可达、状态路径和七瓶布局检查 |
| `tools/check-revision.cjs` | 仅新增可选输出目录参数，保留原41项检查内容与旧证据 |
| `tools/r06-evidence.cjs` | 同条件前后截图索引及并排比较图 |
| `revision-r06/` | 前后24组真实PNG、度量／结果JSON、41项回归截图及本轮入口 |
| `DELIVERY.md`, `STATE-COVERAGE.md`, `COMPONENTS.md`, `design-qa.md`, `REVISION-R06.md` | 当前独立状态、自查、修复范围及尺寸说明 |
| `index.html`, `tools/compile-evidence.cjs`, `evidence.html` | 评审入口增加R06链接，更新已关闭／待复验状态 |
| `screenshots/`, `verification.json`, `UI-copy-addendum.csv` | 当前87状态重新导出，文字与产品规则未改 |

`app.js`、瓶体素材和已通过的七瓶布局CSS均未修改。本轮没有依赖变更或Flutter工程命令。

## 未验证范围

这是静态设计与有限原型修复。Retry仍为原型成功事件，不是实际SQLite写入、SDK奖励或幂等持久化验证；Undo／Hint／重开仍未接真实游戏核心。Flutter/Dart、SDK、强退恢复、真机读屏、平台最大字号、性能和正式资源接入仍未验证。最终R06关闭以产品架构聊天独立复验为准。
