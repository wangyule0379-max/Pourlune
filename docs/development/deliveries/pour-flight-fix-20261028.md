# 实际倒水大小与前后层级修复（验收中）

范围：正式 0.5.0(18) 用户反馈的主线第4关下排瓶3→上排瓶2变小，以及第6关上排瓶2→下排瓶4被固定读数贴住。当前基线408214f，独立分支codex/pour-flight-size-fix；本修复尚未总控实际验收、尚未发行新构建，不重复上传18。

## 原因与实现

- 旧运输缩放只要求倾斜瓶在画布内，没有视觉大小下限；真实第4关合法动作复现最低缩放0.14144。
- Flutter固定目标/容量读数位于GameWidget上方，实际第6关经过原读数位置时，旧绘制结果有43.8%的瓶身不透明采样被覆盖。
- 保留原静止布局、读数位置与358×470六瓶宽度至少78的已有门槛。仅输入锁定期间，下移需要空间的上排接收瓶；必要时局部下移相交的下排瓶，均在原画布内并随原时间线复位。源瓶倾倒、液面、瓶口和有限水柱仍沿用同一几何计算；不延长动作，不改存档和奖励。
- 移动瓶与水柱单独绘于原生读数上方。按总控明确选择，短动画允许经过并短暂遮挡固定读数，结束后完整恢复；没有全局隐藏或移动读数，也没有临时整条读数栏。
- 快速连续操作时，仍在回落的旧选中接收瓶先完成原回落，再在对齐阶段借用空间，保留原选择连续性约定。

## 检查与证据

证据目录：`../evidence/pour-flight-fix-20261028/`。

- 新增4项实际定义/运输几何回归与1项真实BoardView像素层级回归。第4关复现使用8次合法核心动作，不编辑题目；第6关使用真实初始定义。
- `final-analyze.log`：flutter analyze无问题。
- `final-app-tests.log`：应用全套482项通过、1项已有opt-in夹具跳过。
- `selection-and-space-final.log`：快速选择回落、几何和真实层级8项通过。
- `local-space-green.log`：原静态宽度、运输、水线、瓶口等26项聚焦回归通过。
- `final-widget-layer.log`与`layer-actual.png`/`layer-source.png`：真实Flutter栅格层级回归通过，源瓶原读数交叉区域的不透明像素保持前景。
- Dart格式检查：相关5个实现文件和3个新增测试/夹具文件无改动。

失败历史保留：首次尝试永久预留两行运输空间导致静止瓶过小，已完全撤销；`app-tests.log`为该方案479通过/1跳过/2失败，`geometry-green.log`、`layer-green.log`与`rejected-static-small-widget.png`仅是被否决方案的中间证据。`pre-selection-full-suite.log`记录局部方案481通过/1跳过/1个快速选择回落失败，随后修复并以最终全套日志覆盖结论。`geometry-red.log`与`layer-red.log`记录原问题的失败复现。其他中间日志不得代替最终状态。

## 专用实际验证安排

正常lib/main.dart，独立身份dev.pourlune.pourFlightValidation、独立库pour_flight_fix_20261028.sqlite；Firebase none、广告disabled、GM disabled，声音/触觉仅QA静音。五份真实定义/核心动作/SQLite准备夹具覆盖4/5主反馈与6/7/8代表，8瓶为明确核心加瓶QA状态，不是广告奖励或自然进度。夹具工具`app/test/support/pour_flight_fixtures.dart`需显式opt-in且拒绝覆盖已存在输出。

实际安装、正常字号同尺寸短视频与关键帧、动作前后SQLite回执仍待Use Computer执行，并由总控实际验收。F9及原应用、库、测试设备状态不得修改。此包不构成真实广告、物理设备或新TestFlight通过；发布由总控验收后安排。

## 已冻结原生QA候选

源5220a23a22ea0d99c2b5ce4a1c1d68cdad9dfb38，正常main的iOS Simulator debug编译成功（qa-build.log）。只读副本build/pour-flight-fix-20261028/ios-qa-1/Runner.app共361文件；完整qa-manifest.json SHA256为0ccda5400edd0de90f5a4fb97a9a6f39a1da0faf36b8b9014e5a188f3d197936，记录身份、实际defines及五份夹具hash。已交由Use Computer验证，当前尚未实际通过。第一次QA编译因临时defines把GM环境写为空串被guard拒绝（qa-first-build-rejected.log）；将仅该忽略配置改为显式disabled后编译通过，未修改guard或生产实现。


## 实际验收工具状态（未通过）

Use Computer已独立核验冻结包361/361文件与manifest SHA、无额外文件/GoogleService plist、Info.plist身份/版本/显示名，并通过Xcode设备管理观察2894A85E-04FC-4857-A856-3BEFF2CCB565为iPhone17 Pro / iOS26.5。尚未安装QA包、未写新库、未产生原生录像或动作回执。

当前CUA文档要求“Do not use other technologies besides cua_repl for computer interactions”；因此不使用simctl、终端或另一执行方绕开。单窗口截图/AX/窗口列表未提供mac跨窗口bounds，尚无法可靠定位Finder到Simulator的拖放终点。Simulator菜单已实见Record Screen，Xcode当前无工程target，Run Without Building不可用。总控正在协调合法GUI安装路径；未要求本人操作。此为验收工具阻断，不是原生运行失败，也不能以Widget像素测试代替实际通过。父明确本阶段不再新构建、测试、签名或上传。
