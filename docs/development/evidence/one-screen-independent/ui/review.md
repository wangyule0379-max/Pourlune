# LY 独立页面交互审查：静态与独立Host探针

**最新结论：已获架构串行窗口并执行19项独立Host探针，17通过、2失败，退出码1、无超时。确认P2：320×568/2.0字号下Cancel hint和Skip的有效可视触控区域被局部说明区裁切。生产192文件指纹保持7fee8c543972767564a96955d9ed2e095de3cc281d07657c9a280d4c001e109e；CLI已明确RELEASED给架构。以下静态部分保留为先前阶段，最终运行裁定见本文末尾。**

2026-10-23，App UI 审查。范围仅 LY 新增有界布局，不为本聊天旧 T 实现重新盖章；不复审事务、恢复、去重或 SDK。使用 game-ui-ux 的安全区、缩放、焦点与真实输入区域检查项，保留项目原单一导航方式，不增加框架。

结论：**静态审查完成，尚不能给 LY 独立运行通过。未确认产品级 P1/P2 缺陷；以下是必须补实证的验收缺口，不把推测记成复现失败。** 当前 CLI/原生设备归原开发；本方没有运行 Flutter/Dart/pub/SPM/iOS、安装、设备控制或采集。没有触碰 F9/用户窗口，没有绕过 Cocoa513/EPERM。作者日志仅作既有证据阅读，不能冒充本方运行、人工视觉或真机性能通过。

## 冻结基线

只读 `build/ly-independent-review-20261023-0720/`。逐文件 SHA 校验 280/280 相符；对文件摘要字典执行 sorted compact JSON 后的集合 SHA256 为 `cfe5d213715fe783d9d5af3cda125ad4325d40edb137c1bd7bdafbd04d3620f7`，与架构 snapshot.json 相同。它是中途快照，最终还须核对源码/测试差额，不能把作者后来日志自动绑定到这版。

## 已证实的实现与测试覆盖

- `game_screen.dart:544` 起将 board/completion/reward 作为有界内容，SafeArea 内给 body Expanded；列表仍滚动。`board_page.dart:273` 起固定头部，`321` 棋盘伸缩，Extra/Undo/Hint/Restart 在棋盘局部滚动外。
- `flame_board/geometry.dart:284` 起按可用高度与字号计算同尺寸瓶体，绘制、命中、标签使用同一 BoardLayout；`board.dart:147` 起 Flutter 原生按钮和语义覆盖画布，48 最小按钮、按焦点绘制边框，容量标签 IgnorePointer/ExcludeSemantics，避免重复空白节点。静态预览 `onTap:null / preview:true`，不创建 presenter 或业务实例。
- `one_screen_layout_test.dart:27–39` 的 visible helper 同时检查四边界、48×48 与 hitTestable；`116–214` 检查4–7瓶、五套真实view padding、1.0/1.3/1.5/2.0；正常字号先检查按钮与所有瓶/容量，再断言棋盘 maxScrollExtent<.01。大字号才显式 drag，随后再次核查固定主要操作。没有用 ensureVisible 把正常游戏断言变成“滚后可见”。
- `one_screen_layout_test.dart:500–624` 构造普通、拼片、章节、最终、每日、重玩、普通Reward、最终Reward、正式七瓶完成九分支，逐屏逐字号验证按钮边界/48/hitTestable。正常字号额外核查所有预览瓶及容量位于主要操作上方。
- 暂时信息检查在 `221–497`：320×568/1.3，七瓶落盘失败 Retry、教程 Skip、寻找提示 Cancel、无可行步、奖励确认失败警告。保存失败和提示取消有真实按钮动作验证。事务结果由功能审查方进一步负责。
- `one_screen_geometry_test.dart:8–91` 检查全部源/目标组合、1/2/4单位、15ms运动采样、宽296/351/406、高305/380/480、字号1/1.3/2：旋转瓶四角在画布内且不与任何标签相交，流线避开标签，命中区不重叠且≥48。它是几何采样，不能扩写成每帧人工画面/所有实际可用高度通过。

## 必须补验证的缺口

### LY-UI-G01 / P2验收缺口：完整首屏内容覆盖不足

来源：`collection_pages.dart:462–489` 对正常字号也使用 completion-details 局部滚动，`info` 在最小高度的棋盘预览之后；info 包含持久化说明、最终故事正文、章节完成文字与紧凑场景。Reward details 也始终可滚动。作者 `one_screen_layout_test.dart:589–605` 只对按钮/瓶/容量做 bounds；Reward 分支完全跳过预览内容检查，没有断言这些说明/ScenePreview 在各自局部 viewport 完整可见，也没有检验正常 completion/reward 的实际滚动偏移与必要内容滚动范围。

因此，不能从“按钮首屏可点”直接得出“结算各分支主要内容完整一屏”。优先检查320×568、360×640/1.3的 chapter/final/reward-final，以及七瓶完成。游戏矩阵也应补 level/move-count/save-status 的真实边界与文本未裁切断言。这里尚未实测是否离屏，不能称复现产品缺陷。计划对大字号允许说明滚动，正常字号哪些次要长说明可以滚动由架构按原需求判断，不擅自扩成一律禁止全部说明滚动。

### LY-UI-G02 / P2验收缺口：大字号暂时信息未覆盖

来源：`board_page.dart:146–191` 将提示文字与 Cancel hint、教程文字与 Skip 放同一 Row；`300–317` 把整个信息区限定为56高后局部滚动。长文字增高时，Row的居中按钮可能部分落在裁切区外。现有临时信息用例仅1.3字号；通用1.5/2.0矩阵没有激活这些状态。

需在320×568/2.0、360×640/1.5中分别检查 pending hint、教程、写入失败、恢复奖励：主要Undo/Hint/Restart/Extra始终可见；Cancel/Skip/Retry等当前必要操作的整个真实点击区域必须处在其说明 viewport 的交集内，并真实点击一次。仅外层 SafeArea bounds+中心 hitTestable 不足以证明整个48区域未被内层Clip裁切。此风险尚未复现，不能因源码存在56高度直接判失败。

### LY-UI-G03 / P2验收缺口：新增有界布局的焦点/语义未实证

LY矩阵没有 ensureSemantics、SemanticsAction、键盘焦点或焦点矩形断言。既有 `flame_full_board_widget_test.dart:56–104` 确实检查七瓶语义与一次语义激活，但测试 shell 是未有界滚动容器且先 ensureVisible；`motion_supplement_keyboard_test.dart` 的辅助也调用 ensureVisible。它们证明已有能力，没有覆盖 LY 小屏与新局部滚动的焦点首屏位置、固定操作遍历或只读完成预览。

需针对小屏七瓶布局检查语义节点与视觉命中框对应、disabled不暴露可用动作、Enter/Space/语义动作各只触发一次、聚焦当前可见目标不靠测试辅助滚屏；只读预览不暴露可激活瓶按钮。真实VoiceOver/TalkBack遍历依旧未验，不能用host语义树代替实机读屏。

## 作者原生记录的适用范围

阅读时 `ios-native-final.log` 有通过的 LY_NATIVE_REPORT，11阶段，402×874、padding上62/下34、字号1.0，包含正常Bootstrap→main1–4→通关/拼片→Next、SQLite同进程重开、受控七瓶。是作者实际原生自动操作证据，未包含所有字号/九种结算或截图，不证明人工视觉、SIGKILL或真机性能。

阅读时 `android-native.log` 是加载阶段 Some tests failed，没有成功 LY_NATIVE_REPORT。仅记录证据状态，不把加载失败归为布局缺陷；待原开发最终Android证据和最终源码差额。两份日志读取SHA在 readiness.json，后续更新须重新读取。

## 下一步与边界

具体补测设计及可复跑命令见 test-design.md / readiness.json。静态阶段不空转等待、不抢锁；架构分配窗口后，在独立可写副本执行聚焦验证，并核对最终差额后更新本报告。只读既有快照、只写本 ui 目录，未改实现/共享文档、未stage/commit/push。

## Probe preparation update (not execution)

The requested independent G01/G02/G03 probes are prepared in `build/ly-ui-independent-review/app/test/ly_ui_probes_test.dart`, with an identical source copy in this ui directory. Nineteen cases: nine settlement branches; eight large-font temporary-information cases; seven-bottle focus/semantic geometry and read-only completion semantics. Every core-control assertion occurs before any scroll; inner scroll clips are included. Long branch descriptions/ScenePreview bounds are observations for architecture classification, not new blanket no-scroll requirements. No captures or device calls.

All192 shipping entries match fingerprint `7fee8c543972767564a96955d9ed2e095de3cc281d07657c9a280d4c001e109e`. Interim-to-final production delta is one line wrap in board_page.dart, without behavioral change. Final author layout tests and support were copied with hashes in final-source-delta.json; architecture native QA/driver modifications are outside shipping and are not run by this probe. Production, original snapshot and other reviewers remain unchanged. No Flutter/Dart commands executed; source remains unformatted, unanalyzed and uncompiled until architecture allocates the execution window.

## 独立Host执行结果与当前裁定

执行位置为 `build/ly-ui-independent-review/app/`，精确保留最终shipping192项指纹。没有操作原生设备、窗口、采集或共享实现。`flutter pub get --enforce-lockfile`退出0；只格式化独立probe；运行命令为：

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/ly_ui_probes_test.dart --reporter expanded
```

最终 `probe-final.log`：**19项，17通过、2失败，6秒测试时间，命令退出1；120秒外层上限未触发**。实际字体为FontLoader加载的Nunito，棋盘原图通过waitForFlameArt/settleFlameBoard边界。探针最终源码SHA256 `c7c3b2cc35063f054beb8f6ca262ebf3064b65dc9b708db9bda369b4eca2026c`。命令/退出码见probe-final-status.json，逐次来源和首次日志均保留。

### LY-UI-R01 / P2：2.0字号当前操作的有效可视触控区域不足48

前提：320×568、上安全区20/下0、真实Nunito、字号2.0，说明区尚未滚动。局部说明viewport为y76–132。

|状态/按钮|按钮真实bounds y|实际可见高|结果|
|---|---|---|---|
|pending hint / Cancel hint|92–140，48高|40|底部8px在clip外；中心可命中不能证明整个48区域有效|
|教程 / Skip|112–160，48高|20|底部28px在clip外，中心y136也在clip外；首屏不能按正常按钮中心操作|

静态对应 `board_page.dart:146–191,300–317`：长文本与操作在同一Row，整体置于56高局部scroll viewport。位置证据是实际Flutter getRect与祖先scroll clip交集，不是预估字体。相同两例在首轮和最终轮均失败。底部Undo/Hint/Restart、Home/Pause等主要控件在这两例均仍可见；问题限定于当前Cancel/Skip的有效操作区域，不夸大为所有大字号页面失败。依计划保留48目标的要求提出P2，未修改实现；由架构统一安排修复/裁定。

### G01：按钮/瓶/容量通过，必要反馈主次留架构裁定

九个结算分支在五种view/SafeArea与1.0/1.3下，所有主动作bounds/≥48/hitTestable均通过，未先滚动；只读瓶及容量位于各自局部clip和操作区上方。所有记录scroll offset为0。G03七瓶小屏/1.3实际焦点、Enter/Space与语义动作、节点全局rect对应、disabled Undo和只读预览无可用瓶操作均通过。没有用旧T结论代替本次新增Host执行。

同时实测22条次要内容/场景局部裁切观察，未用断言将全部长文强行变为禁止滚动。例如chapter/320×568/1.3中：保存文字y316.2–368.2、Scene complete y368.2–394.2、ScenePreview y394.2–490.2，而completion-details clip为y109–361；Scene complete及场景首屏看不见。final分支亦有场景/长文局部裁切。它们是已测事实，是否属于正常字号必须完整展示的主要反馈由架构按LY原需求裁定，不能仅凭九个按钮用例通过声称“全部内容完整一屏”。完整记录见bounds-findings.json。

### 首败、探针修正与未扩大要求

1. `probe-first.log`已记录上述两处有效裁切。随后一个1.5字号教程点击触发真实异步保存，探针只pumpAndSettle后直接close导致自身收尾SQLite锁等待。本方约60秒后SIGINT仅自己的确切Flutter进程；工具返回0，但首轮没有完整结束，**绝不记通过**，见probe-first-status.json。修正仅为探针在真实点击后等待SavePhase离开saving，未改生产代码或断言。首轮源码另存probe-first-source.dart。
2. 第一完整轮 `probe-complete-first.log`为15通过4失败，exit1。另两项是本方把大字号奖励长说明的Retry也错误要求首屏完全展开，超出已允许的局部滚动例外。保留原断言与源码/日志；最终只将这个次级说明操作改为记录首屏位置，再允许其局部滚动，验证Retry完整48可达且固定主要操作仍可见。该两项最终通过，不称产品修复。
3. 最终轮17/19，余下Cancel/Skip裁切断言保留失败。未重跑无关全套，未以日志当人工视觉、真机读屏或性能通过。成功的实际1.5 Cancel/Skip与2.0/1.5错误提示、受控奖励说明例外的范围见完整日志。

**CLI状态：Flutter/Dart/pub/SPM/xcodebuild均已退出，明确RELEASED给架构；见cli-release.json。** 后续仅维护本ui证据，未stage/commit/push。LY整批仍未通过，Android/事务/恢复由对应审查方处理，本报告不代裁定。
