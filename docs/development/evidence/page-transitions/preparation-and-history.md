# T01–T06 页面转场执行记录（运行取证中）

2026-10-22。本文件是执行记录，不是独立验收。原 Flame 任务于 15:27:10 明确 RELEASED 后接手，按架构两次短窗口串行交还/接回 CLI。已完成 T02–T05 实现与 host 检查；T06 双端原生取证中。原始准备记录保留在后文，最终结果以末尾验证账本为准。

## T01 页面关系矩阵

现有 GamePage 共 11 项；共享背景位于 GameScreen 的 PageMotion 外。现有 PageMotion 为自制 fade+slide、至多一张出场页，棋盘相关跳转不保留旧页。保留其输入/焦点/语义与 ticker 隔离。主导航是 controller 状态切换，不建立第二套路由栈。

|入口→出口（包括真实返回）|选用模式|保护点／预期验证|
|---|---|---|
|启动→home；初始化失败→Retry→home|连续背景＋短淡入|无假进度或人为延迟；离线启动；失败可读可重试|
|home↔chapters|FadeThrough|保留章节 PageStorage 滚动位置|
|home↔daily|FadeThrough|当前日期刷新不触发页面切换|
|home↔collection|FadeThrough|卡片真实文本与触控保持|
|home↔settings|FadeThrough|应用和系统 reduced motion；设置写入失败门控|
|home↔progress（仅 debug）|FadeThrough|release 不增加调试入口|
|settings→rules→settings（按钮／系统返回）|SharedAxis horizontal|既有返回目的地保持；规则示例不创建业务实例|
|collection→scene→collection（详情按钮）|SharedAxis scaled|主导航仍经 controller；场景 ID 纳入 key|
|scene→home（标题／系统返回）|FadeThrough|现有返回去首页，不改为收藏|
|chapters / home Play / scene Play→board|SharedAxis horizontal|controller 保存成功后才切新实例|
|home Continue / scene Continue / daily Continue→board 或 completed→completion|SharedAxis horizontal|两个槽位分别恢复；同实例普通动作不重建宿主|
|daily Today / Replay→board|SharedAxis horizontal|日期与实例唯一 key；替换确认保留|
|board→completion（普通／拼片／章节／最终／重玩／每日）|SharedAxis scaled|旧棋盘立即销毁；保存失败即刻显示且不闪成功；不叠加倒水飞行动画|
|completion→reward（View patch）|SharedAxis scaled|按实例识别；无转场回调发奖|
|reward→scene（View collection）|SharedAxis scaled|揭示确认落盘后导航；不重复奖励|
|completion 章节→scene|SharedAxis scaled|同上；章节拼片不建立第二次领取|
|completion / reward→Next board|SharedAxis horizontal|真实广告关闭／失败与保存门控先于切页；连点一次新实例|
|completion Replay again→新 board|SharedAxis horizontal|新实例 ID；旧动作 revision 不作为页面 key|
|completion 每日→daily；最终→daily / collection / chapters|FadeThrough|最终无 Next；不增加广告检查|
|reward 最终→daily / chapters|FadeThrough|待揭示状态先落盘|
|completion / reward / progress→home|FadeThrough|保留 Home/Next 保存失败队列|
|scene→daily；completion Replay→chapters|FadeThrough|现有按钮目的地不变|
|同 board 不同实例／槽位（外部合法恢复/新开）|SharedAxis horizontal|实例 key 补齐；不得保留第二棋盘 presenter|
|同 scene 不同 selectedScene|SharedAxis scaled|场景 key 已有；按关系保持|
|board 重开／撤销／倒水／选择／提示／加瓶|不切整页|相同实例 revision 变化仅更新棋盘；保留局部 M 动效|
|settings→licenses→许可证详情→返回|原生路由转场覆盖待接入|属于现有导航，不能遗漏；系统返回保留原行为|

OpenContainer 评估：不采用。收藏卡片当前通过 `controller.navigate(scene)` 切主页面；OpenContainer 会单独 push 路由，需额外同步控制器、返回与保存失败状态。使用官方 SharedAxis 的缩放轴满足主从关系，保留单一导航源和已有编织卡片。未增加游戏实例。

## T04 模态矩阵

|入口|当前入口|计划与行为保护|实测|
|---|---|---|---|
|主线替换／每日跨日替换|GameScreen._confirm|统一 FadeScale；false/null 不替换|待执行|
|重开|GameScreen._confirm|统一 FadeScale；额外瓶权益保留|待执行|
|Reset|GameScreen._confirm|保留 Keep progress 默认焦点与危险动作次级样式|待执行|
|不可用题目／信息|GameScreen._info|统一 FadeScale；关闭只 dismiss|待执行|
|暂停（含系统返回）|showKnitDialog|统一 FadeScale；重复暂停一份；失败状态仍可 Retry / Stay；关闭返回原棋盘|待执行|
|每日历史／未来日期|DailyPage._date 当前 showDialog|改为统一 helper；只读，今日入口仍开局|待执行|
|加瓶广告前说明|showExtraBottle|统一 FadeScale；Not now 无损；关闭不发奖|待执行|
|隐私选择|showPrivacyChoices|统一 FadeScale；保留选择与原生 UMP 分离|待执行|
|恢复获奖实例确认|RewardStatus|统一 FadeScale；原实例恢复与保存门控不变|待执行|
|保存失败|页内 KnitPanel，非 dialog|不伪造模态；立即可见，保留 Retry/Stay|待执行|
|原生广告／UMP／系统浏览器|SDK/OS 所有|不替换原生 UI，不把关闭当奖励|不属转场层渲染|

## T02 官方依赖调查

官方 [包页面](https://pub.dev/packages/animations) 当前为 3.0.0，依赖 flutter 与 material_ui。[changelog](https://pub.dev/packages/animations/changelog) 明确迁移 material_ui，最低 Flutter 3.44 / Dart 3.12；本项目固定 3.47.2 / 3.13.2 满足声明下限。接手后精确固定 `animations: 3.0.0`，保留其他直接依赖版本，核对新增传递依赖及实际 analyze/运行结果。现阶段只确认文档兼容，尚未确认依赖解析或运行兼容。

官方 [PageTransitionSwitcher](https://pub.dev/documentation/animations/latest/animations/PageTransitionSwitcher-class.html) 可在快速切换时保留多个旧 child。T05 要求至多一张出场且旧棋盘立即销毁，因此拟保留既有有界 PageMotion 生命周期，替换其过渡实现为官方 FadeThrough / SharedAxis 的 primary/secondary animation；不外套第二层旧动画。明确设置透明 fillColor，保持编织背景稳定。该选择仍须行为测试与录像验证。

## T03/T05 设计约束与验证账本

- 普通切换 260ms；模态进入 220ms、退出 150ms。回退以实际旧页/新页关系驱动动画方向。
- 入场保持可操作；出场页 IgnorePointer / ExcludeFocus / ExcludeSemantics / disabled TickerMode。
- 快速切换淘汰更早出场页；系统 reduced motion、应用 reduced motion、后台/恢复清除过期转场。
- 页面 key 使用页面、适用的实例 ID、场景 ID；不使用棋盘 revision，避免每次动作重建游戏页。
- 不改 controller、存储、奖励、广告与 Firebase 服务。测试先证明官方模式与实例 key 的缺口，再适配实现；保留既有保存失败、滚动恢复、暂停防重与动作测试。
- 窄屏和大字号、模态焦点往返、真实返回、边界快速连点需实际渲染与操作验证。

## T06 当前结果与局限

尚未运行 format / analyze / Flutter tests / 平台构建 / 双端录像；未声称静态设计或运行通过。既有 M 192 项测试和 before 录像仅为交接上下文，不算本任务验证。

后续证据归档 `docs/development/evidence/page-transitions/`。逐边运行结果、设备／模式、异常与修复会更新至本文件；代表真机帧率仍须实际测量。重点对应 AC-11/12/16/24/28/31/32/33/34。独立验收由架构方写 `review/page-transitions-acceptance.md`；本任务不提交、不推送、不改 tracking/plans/review。

## 实现与 host 验证账本

- T02：精确 animations 3.0.0；锁文件仅新增 animations / material_ui 1.8.0 / cupertino_ui 1.1.4。`flutter pub get --enforce-lockfile` 成功；不升级既有 SDK 或 Flame。不迁移既有 Material 组件。包的过渡组件采用显式透明 fillColor，实际 Flutter 旧 Material 主题兼容由测试验证。
- T03：单一 PageMotion 使用官方 primary/secondary 动画合同；保留有界退出层，不叠加旧 fade/slide。首页首次 120ms 短淡入；普通页 260ms。启动、普通动作、棋盘入场与奖励局部 M 动效的原实现保留。未修改 main.dart / startup_view.dart、控制器、存储、核心或服务。
- T04：showKnitDialog 采用官方 FadeScale，220/150ms，保留 DialogRoute 的焦点闭环、取消结果、默认 barrier 与主题。每日日期也接入统一 helper；保存失败维持页内即时呈现。以 Navigator 为键防重：重复请求返回 null，不让两份确认执行同一业务动作；Expando 不强持有已销毁 navigator。
- T05：页面与实例/场景 key；棋盘 revision 不改变页面身份。出场 IgnorePointer / ExcludeFocus / ExcludeSemantics / disabled TickerMode；最早旧页随快速跳转淘汰。后台、系统和应用减少动态效果清除转场；许可证路由也遵守减少动态效果。
- RED：最初三项分别因缺少官方模式/实例 key/FadeScale 失败；模态防重测试独立复现两份 AlertDialog。见 red.log / modal-red.log。
- 首次全套：197 通过、2 失败。新增窄屏测试发现 Reset 长内容溢出，改为 scrollable；既有七瓶语义测试发现直接挂载棋盘时不应做首页启动淡入，限制 animateInitial 仅首页。修复后10项针对性通过。
- 最终 `flutter test`：**199/199通过**，见 app-tests.log。
- 最终 `flutter analyze`：**No issues found**；`dart format --output=none --set-exit-if-changed lib test integration_test`：105 files / 0 changed。
- 宽度360、高568、2倍字号：home/chapters/daily/collection/scene/settings/rules 渲染及 Reset 取消操作通过；既有320px七瓶等尺寸和读屏语义测试通过。语义、焦点隔离、重复暂停、第一下操作、保存失败到 Retry、滚动恢复和生命周期回归通过。

以上是作者执行结果，不是架构独立验收；原生、录像及逐边表将在实际完成后追加。

## 画面复核追加：新实例滚动键待修复

修正 QA 截图观察时点后，双端同一路线均102条记录、Flutter errors为空，覆盖11类页面及各结算变体。图像复核发现真实问题：PageMotion key包含实例，但ScrollView PageStorageKey仍仅按页面，新实例沿用上一局/结算滚动位置。章节恢复应保留，同实例返回应保留；新实例/不同场景应分别存储。已写行为回归并请求下一个串行CLI窗口，尚未宣称修复或完成。修复前路线表见 evidence/page-transitions/native-coverage-pre-scroll-fix.md；旧原生通过不自动覆盖最终候选。
