# T01–T06：全部既有页面转场优化

2026-10-22。用户指定使用 Flutter 官方 animations 包优化每个页面切换，并明确要求新建「Pourlune ｜ App UI」承担。本聊天独立验收；原「Pourlune ｜ App 设计 开发」继续 Flame 样板。本任务只涉及既有页面/弹窗表现，不扩大为完整棋盘Flame迁移。

## 文件交接与运行排程

共享本地工作区已有大量未提交M/Flame改动，先读AGENTS.md、git状态和 `docs/development/deliveries/motion-polish-checkpoint.md`。原开发聊天已获指令保存当前M页面成果、明确共享文件及FlutterCLI/构建释放状态。**未看到明确交接前，新UI聊天只能检查源码、官方资料、页面清单和设计评估，不编辑重叠文件或运行FlutterCLI。** 写只属于本任务的交付草稿可行。架构聊天负责转达，不需要用户手动协调。

交接后UI聊天拥有页面转场层 `app/lib/presentation/motion.dart`、各页面接入和必要页面测试；main.dart/启动页/pourlune_app.dart仅在本任务确需时编辑，说明变更。Flame样板归原开发聊天；纯Dart核心、存储、服务逻辑不归UI任务。pubspec.yaml/lock的添加与FlutterCLI、原生构建串行，同一时间只由一个聊天使用。通过 `docs/development/deliveries/ui-transition-handoff.md` 记录接手范围与构建占用/释放，不凭等待时长猜测已释放。

## 组件选择与全覆盖矩阵

现有GamePage包含home/board/progress/chapters/daily/collection/scene/settings/rules/completion/reward，启动、失败重试和弹窗也须清点。不要新增底部导航或改变现有返回目的地。

|关系|推荐表现|约束|
|---|---|---|
|启动→首页/错误重试|连续背景与短淡入|复用M启动准备，无人为等待/假进度；依赖失败不阻塞离线|
|首页与章节/每日/收藏/进度等功能入口|FadeThroughTransition|背景稳定、避免默认白色填充闪屏；按真实导航关系记录返回|
|设置→规则，章节/每日/Continue→棋盘，结算→下一局|SharedAxisTransition|按前进/返回选择一致方向或深度；棋盘实例改变也要有正确key，不能因同为board而遗漏|
|收藏卡片→场景详情|OpenContainer适用性评估，或SharedAxisTransition|共享容器只在能保持现有导航/保存门控时采用；不同时构造第二个controller/游戏实例；不能点击直接绕过controller导航|
|棋盘→完成→奖励→场景，最终通关/重玩/每日结算|轻量SharedAxis或FadeThrough|不叠加Flame拼片飞行造成双重移动；保存回执先于成功呈现，奖励幂等与广告Next规则不变|
|暂停/重开/替换/保存失败/每日历史未来/通知和隐私弹窗|FadeScaleTransition或等价官方modal接入|焦点正确进入与返回，背景不透点，不把所有弹窗改成可随意关闭；遵循现有行为|

以上是按关系的默认方案，执行方逐条记录所有实际入口/出口/返回边，不留未覆盖页面。维持现有温暖编织视觉，动画借用官方模式而非重设计为Material默认页面。

## 六项任务

- T01 盘点：列出所有上述页面、真实跳转边、模态及同页面实例切换，标注当前实现、选用模式、运行覆盖位置。
- T02 依赖：核对并锁定兼容版本。2026-10-22官方页面为animations3.0.0，changelog要求Flutter>=3.44/Dart>=3.12且迁移material_ui；项目3.47.2/3.13.2满足声明下限，仍须验证实际导入/主题/依赖兼容。不得顺带升级Firebase/广告/Flame或迁移整套UI组件库。
- T03 页面：以一个轻量转场宿主统一动画，适用时PageTransitionSwitcher；使用新旧animation/secondaryAnimation及稳定页面/实例key。替换重复的自制过渡，不在旧PageMotion外再套一层造成双动画。动作变化不重建页面/FlameGame。
- T04 模态：全部既有dialog入口统一覆盖，尤其navigation_pages.dart每日日期的showDialog，防止只改主页面漏掉弹窗。保留阻塞条件、取消结果和焦点规则。
- T05 保护：出场页IgnorePointer/ExcludeFocus/ExcludeSemantics、控制非活动ticker；快速连点/返回不会堆栈或重复导航。回前台清理过期动画，返回目的地/滚动位置正确。系统与应用减少动态效果均有效；较大字号/窄屏不裁切。不会因等待转场绕过保存失败，声音和触觉遵守设置。
- T06 交付：format/analyze及相关行为测试；双端实际运行连续导航，录制代表路径及逐边验收表。对Flutter核心/存储未改动不重复全部B05；涉及控制器才增加对应回归。记录构建模式、设备、真实运行与未验证范围。模拟器debug流畅外观不是代表真机帧率证明。

默认普通页面220–300ms、模态180–240ms，关闭可更快；依据录像调校，不靠延长等待表现丝滑。包是否接入成功和用户实际体验是否改善分别判断。

## 交付与验收

执行：`docs/development/deliveries/page-transitions.md`；证据 `docs/development/evidence/page-transitions/`；交接 `ui-transition-handoff.md`。
架构：`docs/development/review/page-transitions-acceptance.md`，逐T项/页面边记录独立操作、代码审查、必要测试、缺陷与复验。重点AC-11/12/16/24/28/31/32/33/34；既有M成果可复用但不自动算已验收。

新UI聊天不自行提交其他聊天改动。架构按可归属且已验收范围提交推送开发分支并核查实现CI，不合并main/发布。Flame完整棋盘扩展仍须用户确认样板效果，与本任务所有Flutter页面优化授权区分。

官方依据：https://pub.dev/packages/animations ，https://pub.dev/packages/animations/changelog ，https://pub.dev/documentation/animations/latest/ 。
