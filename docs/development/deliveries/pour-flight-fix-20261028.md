# 当前状态：R01/R02均已撤回，R03恢复原盘仅修源瓶（待原生验收）

用户否决接收瓶下沉及整盘下移/缩放后，当前已逐字节恢复发布build18的BoardLayout，恢复原静态坐标、大小、行距、标签和动作区域。R03只修源瓶实际屏幕绘制范围与运动层裁切，不挪静止盘。代码/像素检查不等于实际通过；当前细节见[R03实现与证据](../evidence/pour-flight-fix-20261028/r03/implementation.md)。未更新TestFlight，F9未动。

以下均是被用户退回的历史方案，不代表当前接受。

# 当前状态：接水瓶固定 R02已通过独立实际验收

用户指出接水瓶不能动后，5220a23的下沉/借位方案已撤回，保持REWORK。新实现源 **d7ec5d7f7d75ade1e5c6ccfefd7d32c58d3c36af** 已删除目标和邻瓶位移；只在初始页面为第一排上方一次性分配实测倒水空间，动作中仅源瓶移动。总控已实际核五组正常main原生录像的40关键帧及46媒体hash，接受接收/其它瓶固定、源瓶正常比例、口部水柱、前景图层与约9%有限初始适配。

最新权威结论见[固定接收瓶R02独立报告](../review/pour-flight-fixed-receiver-R02-independent.md)及[同名JSON](../review/pour-flight-fixed-receiver-R02-independent.json)。当前实现、18项针对性检查/4个正常字号矩阵/分析、尺寸差额、QA2冻结和安装来源见[R02交付](../evidence/pour-flight-fix-20261028/stationary/implementation.md)；新媒体见[native-r2来源索引](../evidence/pour-flight-fix-20261028/native-r2/source-index.json)。40幅受审帧和联系表入版本管理，完整原始视频及抽帧保持原本地路径并按hash索引，不覆盖旧拒绝证据。

五条实际路径为4/L4 3→2、5/L6 2→4、6/L11 5→2、7和8/L21 5→2；6瓶回位后进入成功页。5瓶源瓶短时经过右侧读数前方，回位恢复，已接受。五局修订/步数回执来自Computer实际读取，本轮不声明父独立逐表存储复算。准备局面/模拟器不等于自然游玩、物理手机或SDK奖励。

本轮没有新的TestFlight发布，手机上的18未包含本R02；SDK/统计默认、存档/奖励未改，F9与其它应用/库未动。旧全套482项通过属于已撤回方案历史；本R02只使用上述有差额检查，不冒充全量重跑。

以下为已撤回方案的历史交付和验收证据，不可作为新实现通过依据。

# 历史R01：接水下沉方案的原通过已撤回

2026-10-28。实现源 **5220a23a22ea0d99c2b5ce4a1c1d68cdad9dfb38**，基线408214f，分支codex/pour-flight-size-fix。正式0.5.0(18)反馈的第4关下排3→上排2微缩，以及第6关上排2→下排4被固定读数贴住，当时曾通过总控对正常字号4—8瓶指定原生路径的验收，随后因用户拒绝接水瓶下沉而撤回为REWORK。旧记录及范围见[历史验收报告](../review/pour-flight-fix-20261028-independent.md)和[来源/hash索引](../review/pour-flight-fix-20261028-independent.json)。本轮未发行新构建、未重传18；现有TestFlight 18保持原状态。

## 原因与实现

- 原运输缩放只保证倾斜瓶在画布内，没有视觉大小下限；真实第4关合法动作复现最低缩放0.14144。
- Flutter固定目标/容量读数位于GameWidget上方，第6关原问题栅格复现有43.8%的交叉区瓶身不透明采样被覆盖。
- 保留原静止布局、读数位置与358×470六瓶宽度至少78的已有门槛。仅输入锁定期间，下移需要空间的上排接收瓶；必要时局部下移相交的下排瓶，在原画布及原时间线内复位。不延长动作，不改核心规则、存档或奖励。
- 移动瓶与水柱单独绘于原生读数上方。短动画可经过并自然遮挡局部固定读数，结束后全部恢复；不全局隐藏或移动读数，不增加临时整排读数栏。七、八瓶接收瓶暂时遮住自身读数已由总控明确接受，不再因此返工。
- 快速连续操作时，仍在回落的旧选中接收瓶先完成原回落，再于对齐阶段借用空间，保留选择连续性。

## 最终检查

证据位于[本轮目录](../evidence/pour-flight-fix-20261028/)。本次最终结果已被总控读取，无差额重复检查未再执行。

- `final-analyze.log`：flutter analyze无问题。
- `final-app-tests.log`：应用482项通过、1项已有opt-in夹具跳过。
- 新增4项实际定义/运输几何回归和1项真实BoardView像素层级回归；第4关使用8次合法核心动作复现原图，不编辑题目；第6关使用真实初始定义。
- `selection-and-space-final.log`：快速选择回落、几何和真实层级8项通过。
- `local-space-green.log`：原静态宽度、运输、水线、瓶口等26项聚焦回归通过。
- `final-widget-layer.log`、`layer-actual.png`/`layer-source.png`：真实Flutter栅格层级回归通过；这是Widget证据，原生通过另外记录如下。
- 相关实现与新增测试/夹具的Dart格式检查无改动。

## 原生实际结果

Use Computer在既有专用iPhone17 Pro / iOS26.5模拟器2894A85E-04FC-4857-A856-3BEFF2CCB565，以正常lib/main.dart运行独立身份dev.pourlune.pourFlightValidation、独立库pour_flight_fix_20261028.sqlite。五段录屏均为1206×2622，与用户反馈图同像素尺寸。总控实际看五个稳流全图及前后关键帧；未宣称逐帧观看全部录像。

| 瓶数/真实题目 | 实际动作 | 修订/步数前后 | 结果 |
|---|---|---|---|
| 4 / 主线4 | 3→2 | 8→9 / 8→9 | 源瓶不再微缩，局部接收/下排瓶让位后归位。绿色转移，橙色缓冲仍满，未通关。 |
| 5 / 主线6 | 2→4 | 0→1 / 0→1 | 两格橙色转移；移动瓶在固定读数前景，结束读数完整。 |
| 6 / 主线11 | 5→2 | 10→11 / 10→11 | 四格绿色转移；原生Beautifully sorted成功页实际出现。 |
| 7 / 主线21 | 5→2 | 11→12 / 11→12 | 正常比例稳流、原布局及全部读数恢复。 |
| 8 / 主线21 | 5→2 | 12→13 / 11→12 | 同样恢复；额外空缓冲保留。准备时核心加瓶已增加一次修订，不是额外倒水。 |

五个路径的SQLite端点由Computer实际读取。总控独立将留存的5/7/8回执与准备库合法倒水结果比对，确认棋盘、同实例、修订和步数各增一。4/6完整端点数据库未单独保留供总控复核，状态归Computer读取记录；第6关首通回执和成功页不扩大为全数据库独立审计。

[原生观察](../evidence/pour-flight-fix-20261028/native/observation.md)、[媒体/来源索引](../evidence/pour-flight-fix-20261028/native/source-index.json)与留存回执记录实际来源。29幅代表及前后补充帧纳入版本管理，其中包含独立审查看过的稳流与前后采样。约181MB原始录屏和全量0.25秒抽帧继续保留在原本地路径，由该目录的精确.gitignore排除；未删除、改写或以重构画面替代，完整hash在索引中。精选帧是这些原始记录的逐字节副本或正常视频解码，不是Widget或模拟画面。

## 冻结QA包与安装来源

源5220a23正常main的iOS Simulator debug编译成功（`qa-build.log`）。原只读包build/pour-flight-fix-20261028/ios-qa-1/Runner.app共361文件；qa-manifest.json SHA256为0ccda5400edd0de90f5a4fb97a9a6f39a1da0faf36b8b9014e5a188f3d197936，绑定身份、实际defines和五份夹具hash。Use Computer逐项核验包后才安装；原冻结包保持不变。

最初GUI拖放受CUA跨窗口坐标能力限制，后来已通过标准Xcode界面自行解决，不再等待本人操作。ignored目录xcode-frozen-launch-1内仅有标准application运行描述，零源文件、构建阶段、依赖或包，无shell/pre/post动作；Products/Runner.app为既有361文件副本，目标、产品路径、arm64/iphonesimulator经静态解析核验。Computer选择准确2894和唯一NoBuild方案，仅执行Run Without Building。

首次GUI安装因IXCopyItemAtURL / NSPOSIX13权限错误失败，错误图文保留。仅将安装副本从继承的只读权限恢复为标准目录/可执行0755、数据0644后，一次GUI重试安装并启动成功；原包继续只读，两个包在安装前后均361/361 hash不变。没有设备命令行替代、设备权限/TCC更改或重新编译App。完整路径/hash和过程见[安装来源](../evidence/pour-flight-fix-20261028/native/installation-provenance.json)。

## 历史失败与验证边界

首次永久预留两行飞行空间使静止瓶过小，已完全撤销。`app-tests.log`记录该方案479通过/1跳过/2失败；`geometry-green.log`、`layer-green.log`与`rejected-static-small-widget.png`只属于被否决的中间方案。`pre-selection-full-suite.log`记录局部方案481通过/1跳过/1个快速选择回落失败，随后修复并以最终482通过日志确认。`geometry-red.log`与`layer-red.log`保留原问题的失败复现。第一次QA编译的忽略配置将GM环境写为空串，被guard拒绝（`qa-first-build-rejected.log`）；只将配置改为显式disabled后通过，未修改guard或生产实现。这些历史记录均不替代最终状态。

五份输入为真实题目/核心动作/SQLite准备夹具，不是自然游玩进度。8瓶是核心加瓶QA状态，不是SDK奖励。QA关闭Firebase、GameMunchies与广告，声音/触觉静音；本轮不证明统计、广告、物理设备、声音、触觉、全部字号或全部动作组合。统计同意默认值未改。F9、旧应用/库和原冻结发行包未动；此次通过仅覆盖上述倒水反馈，本轮没有新的TestFlight发布操作。
