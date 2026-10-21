# Pourlune UI 增量自查 · R06

最终状态（2026-10-22）：D01–D09 的静态设计及有限原型已通过独立验收，R01–R06 关闭；以下自查记录保留交付时状态。最终依据见 [独立验收报告](../review/ui-addendum-acceptance.md) 第 9 节，App 运行验证尚未进行。

final result: passed

这是执行方对本轮CSS修复的自查。第二轮独立复验已将R01–R05通过并关闭；**R06仍待产品架构聊天独立复验，D01/D05/D09不在此自行改为独立通过。** 不编辑独立报告、tracking或原件。

## 来源与比较

独立报告第7节及`../review/ui-addendum-evidence-r2/24-unsaved-320-200-retry-wrap.jpg`、`23-pending-undo-320-200-top.jpg`已读取并实际查看。仅处理共享状态横幅的Retry断词，视觉仍沿用原天蓝／奶油针织组件，未生成或替换素材。

`revision-r06/index.html`为同路径、同视口、同字号／对比的Before / After。所有截图来自实际交付HTML。320×700和390×700、DPR1，100%／200%，对比增强开／关；无缩放归一。并排证据为`revision-r06/unsaved-320-2x-contrast-comparison.png`、`pending-320-2x-contrast-comparison.png`、`compound-320-2x-contrast-comparison.png`。整个视图中Retry与横幅均清晰可读，无需另作局部放大代替原尺寸证据。

## 问题、修复与五项检查

P2 R06：82px固定按钮宽度叠加全局anywhere，导致200%下Retry被拆成Retr / y，复合状态的reward也断词。改为内容宽度和局部normal断词，flex行允许换行，按钮在必要时独占下一行。

- 字体／文字：200%仍28.16px，100%仍14.08px。通过DOM Range逐字符确认同一单词只有一行，Retry、Retry save、Retry reward无裁切；未隐藏或缩小文字。
- 间距／布局：仅状态行布局与按钮左右padding调整。最小点击高度48px；每种组合滚动到按钮后核对完整按钮位于可见容器内，中心命中该按钮；87状态无水平溢出。
- 颜色／令牌：天蓝、奶油针织、深蓝与增强对比规则未改，开关两种对比均检。
- 资产／质量：未修改app.js或瓶体素材。七瓶在320宽200%下对比开／关均同尺寸，4+3、末排居中；R05素材检查回归仍通过。
- 文案／行为：原文案不变；未保存、pending和复合状态经过Undo、Hint取消、暂停Resume仍保留。Retry模拟成功才清对应标记；复合状态分别检查两种先后顺序，不禁用免费辅助。

## 检查结果

`tools/check-r06.cjs`修复前24组合中12失败（200%组合），修复后24/24通过、页面脚本异常0。真实按钮点击、字体／单词行数／裁切、命中与标记持续性检查记录在`revision-r06/after/results.json`；sevenLayouts记录七瓶几何。

原R01–R05 41项回归全部通过，新结果位于`revision-r06/regression/results.json`，未覆盖旧R1证据。全图册87状态和适配截图重新导出，详情见verification.json。独立验收、生产分层、字体许可、真实反馈目的地及SDK范围均未扩张。

## 变更与边界

唯一产品呈现改动在style.css；app.js业务模拟逻辑不变。其他变更是本轮检查脚本、前后截图与交付说明，完整清单见REVISION-R06。

Retry仍是原型事件，不是SQLite、SDK或真实奖励发放；未执行Flutter/Dart构建、真机、读屏、系统最大字号、性能或强退恢复测试。当前self passed仅表示本轮呈现自查通过，R06关闭以独立复验为准。
