# Flame 完整棋盘执行与窗口边界

2026-10-22。已直接读取产品架构聊天当前用户消息：“样板效果可以，安排「Pourlune ｜ App 设计 开发」扩展到完整棋盘，容量数字和动画也同步修好。页面转场继续推进，你负责验收，通过后提交并推送。” 按 FB01–FB08 执行，无须重复确认；作者不stage/commit/push，不改架构tracking/计划/review。

## 已确认的文件交接

架构已确认 board_page.dart / bottle.dart 写入权释放，交接时基线 SHA：

- board_page.dart：fc7a0250945e5d02a58357ef3b8baa1f0b7d9226d766068d7901905fbd8cb7ad。
- bottle.dart：4c57b41d574651efd1f6e4bfac999bc5f81c7aa9f0b62031486bf9a136feb61f。

本批写入范围：presentation/flame_board/、上述已释放两文件、样板容量问题所需 development/flame_sample*、专属测试/QA/工具及本批证据/说明。保持 BoardView 公共参数；game_screen.dart、motion.dart、启动/导航与pubspec/lock不写。现有Flame1.38.2够用，不新增依赖。控制器仅补充表现 owner 引用计数，修复同页实例替换时新登记被旧页清除的有效RED；存储未改。

## 历史：首轮窗口需求

Flutter/Dart CLI、pub/SPM、原生构建仍由App UI独占，**本聊天未运行上述任何命令**。当前按TDD先准备专属测试、读取真实接口和轨迹/布局边界；不能把未运行测试记为RED或通过。

需要架构安排一个明确的**首轮host检查窗口（预计2–3分钟）**，用于现有样板FS-M01与新显示帧/布局测试的有效RED，随后组件实现及聚焦GREEN；不做pub升级、不做原生构建。可在App UI已冻结原生QA单独录制且没有在途Flutter/Dart命令时交接。若只能一次性交还CLI，则在UI取证完成后接回；未明确释放前继续独立测试/API/素材审查，绝不凭时间推定。之后正式native构建另按窗口串行。

## 表现契约

复用样板瓶体/水平面积液面/有限水流，抽入生产目录，正式入口不导入development夹具；保留4/5/6/7瓶两行布局、同尺寸和O/G/P/B形状。游戏核心与SQLite按完整动作及时提交；原生Flutter按钮/文字/语义保持真实可操作。

容量采用同一表现帧的共同转移量，以流出/抵达量中点四舍五入为整数单位，两端使用同一个整数增减，从而计数总和不变；不是分别对两瓶液量取整。流线中的量另参与连续视觉守恒。靠近/对准阶段保留动作前数字，结束/减少动态及中断同时对齐完整权威状态；语义只随离散读数变化，不逐帧live播报。样板同步修复，不改原冻结二进制/录像。

旧技术方案“不引入Flame”的历史限制已被用户最新明确授权覆盖；本批不扩展物理引擎、全场景拼片系统或产品规则。

## CLI 已明确交接：HELD by 本聊天

已读取 UI 交接文档“最终冻结构建与host复验后 — Flutter CLI RELEASED”，现在完整棋盘任务接回CLI，已在共用排程文档记录占用。没有凭等待时间推定。先锁文件校验与FS-M01 RED，然后专属组件/布局/生命周期检查；所有命令串行。UI继续已安装冻结候选取证，本聊天不改其转场源文件。

## 架构验收短窗口：RELEASED

当前必要检查已结束，无在途命令，已在共享排程明确释放给架构；本聊天只写源码/QA，不启动下一段构建。独立CI小修复已在精确c529＋两TESTS副本182项与analyze通过，可先验收，不等全棋盘。当前根全棋盘首次组件检查18通过/2编译加载失败（遗漏kDebugMode导入已恢复，待干净复跑）；样板容量同步有效RED→GREEN已观测。请勿以根工作区未验全棋盘覆盖冻结CI/UI结论。

## 最新状态：完整棋盘继续执行，尚未最终交付

FS-M01 已用实际 SQLite 样板验证 RED→GREEN；组件/几何及原 motion 适配完成。206通过/8失败的首轮全套发现真实的大字号标签溢出和教程结束时棋盘被重新创建，均已修复，相关14项及真实UI/教程/全部转场组合12项已通过；最终全套仍待执行。架构已窄交接 page_transitions_test.dart 的实例替换用例与专属 support，本方只按实际资源/动作完成有界等待，未改其余 UI 用例或转场实现。

已建立专属 iOS F9C16DE7-01D8-4740-B796-A3A2DB8C3265（dev.pourlune.fullBoardValidation）和 Android emulator-5588（Pourlune_FullBoard_API36），只使用 flame_full_board.sqlite。双端 before 正常 main/Bootstrap 候选已构建，iOS取证脚本的启动/旧动画提前结束边界仍在修正与重录，不能算双端原生通过；after 尚未构建。原样板、Firebase、UI审查及普通设备/库未操作。

最新 CLI 排程已在 ui-transition-handoff.md 明确 RELEASED 给架构 T-R01 19项/analyze短复验，本方等待明确归还再继续串行命令。文件归属与禁止 stage/commit/push 不变。最终 flame-full-board.md 尚未创建，不能据此执行独立整体验收或提交。

最新补充：必要 owner 计数修复已有效RED→GREEN，26项聚焦与修复后全套216项全部通过，analyze无问题；纯Dart核心锁/格式/analyze/30项也通过。最终原生证据仍在进行，未创建最终交付。before生产源逐项匹配UI提交3cc3501，after仅本批BoardView/新Flame组件、表现owner计数及样板容量修正不同，受保护UI/启动/依赖哈希一致（comparison-source-provenance.json）。

2026-10-22 12:18 UTC progress: AFTER 双端正常 main/Bootstrap 独立 QA 构建＋route-v2 各43步；27次无PNG倒水采样；真实 OS 后台 samePID 与同安装进程强退恢复/原生 Undo 均通过。两槽、收据、设置、权益与历史逐字段比对。Android320×568/font2 与 iOS accessibility-large 棋盘图已人工检查，设备覆盖值已还原。核心30、应用216、analyze通过。仅本批F9/5588；普通审查库仍待最终只读hash核验。当前 baseline 最终双端构建严格串行中，CLI仍HELD；未创建最终 flame-full-board.md，未提交/暂存/推送。

2026-10-22T13:13:43.253350+00:00 — CLI RELEASED by full-board. FB01–FB08实施/自测交付完成；最终源码115哈希与候选/录像校验通过，应用219、核心30、双端route-fixed各43步＋真实OS后台＋同安装早期流水强退/Undo均通过。一次最终只读审查3个P2已在一次修复pass验证；Minor并行解码/静态刻度缓存保留。最终报告 docs/development/deliveries/flame-full-board.md 可开始架构独立验收；整体视觉与FS-M01关闭仍由验收决定。当前独立F9/5588均装修复版7瓶；仅停本任务caffeinate，不关闭设备。未暂存、提交、推送，未改tracking/计划/独立review及共享production UI。
