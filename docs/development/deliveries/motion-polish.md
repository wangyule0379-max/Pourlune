# M01–M08 既有实现与证据映射（仅文档收尾）

2026-10-22。本次按架构安排只读现有源码、日志及独立报告，形成原 M 计划的覆盖账本与最小残项建议。**不是新的运行验收，也不宣布 M01–M08 整批通过。** 未改生产代码、依赖、原计划、tracking 或独立报告；未构建、跑测试、新录屏、启停或输入任何设备，尤其未操作用户正在体验的 F9。未暂存或提交。

[原计划](../../pmpowers/plans/2026-10-22-motion-polish-execution.md)与[原检查点](motion-polish-checkpoint.md)保持原文。检查点的169通过/6失败、23项定向回归、尚缺 after/完整审查等，描述的是当时版本；下面的 T/FB 新证据不回写那些历史结果。原 `evidence/motion-polish/` 仍为未验历史材料，本次不移动、改写、整包追加或提交其中录像。

## 1. 版本和证据归属

|来源|实现/冻结版本|可以引用的结论|
|---|---|---|
|原 M 检查点|当时共享在途源码；`motion-polish/before/` 自述 before，未提供与后续候选一致的整套源码/安装哈希配对|只保留当时基线及 RED/定向回归历史，不能当作最终 M after 或独立通过|
|Flame 两瓶/拼片样板 S01–S06|`c529e8e2cac8afa8266cfd7a3a1b983946fcbc69`；原冻结源码 ZIP `ec0e64…6cde`；后有仅测试同步修复 `2b0d78d3ddb0448b59d77b3a19681f068649e3d9`|[样板独立报告](../review/flame-sample-acceptance.md)：双端各13项、两轮各25测试、同安装恢复；[CI修复独立报告](../review/flame-sample-ci-repair-acceptance.md)：182测试及精确修复CI成功。原容量提前显示 FS-M01 后由 FB 关闭，不将旧样板提前判为全棋盘|
|T01–T06＋T-R01|`3cc35011bb0dceff783043c91be2e03db3761a39`；页面冻结 ZIP `8cbcd2…8500`，R01正常 main ZIP `cc3be956…13013`；提交精确纳入必要 M 依赖|[T独立报告](../review/page-transitions-acceptance.md)：双端各102步/11页面；首轮17、R01再19项定向检查；原生白色启动 P2 关闭，保留 T-M01 色阶 P3。精确 T CI 已在报告终态复核成功|
|FB01–FB08＋T/FB组合|`3134637f91c0cb59c26ba6905b557f48f6179e5f`，以上已验 T 为基线；最终115源码文件与候选核对|[FB独立报告](../review/flame-full-board-acceptance.md)：219测试/analyze/format、双端各43步、各45张关键帧、真实OS后台和同安装SIGKILL/Undo；FS-M01关闭。未自动关闭 M。所读报告仅记录该精确实现CI首次 in_progress，本文不查询新终态、不用 T 的CI替代|

T 的200项全套是作者冻结候选结果；架构独立执行的是报告列出的17/19项等检查。FB219是架构独立全套。本文没有把作者核心30项说成本次或架构新复跑。对应运行与源码详细路径均由以上报告追溯；不将 Git 锚点等同于当时所有未提交文件内容。

## 2. M01–M08 逐项映射

“已有独立依据”表示该子行为在 T/FB/样板报告范围内已有支持，不是本文件替架构签署 M 项通过。

|M项及原要求|具体实现与继承证据|仍需区分/保留|
|---|---|---|
|**M01 基线、统一参数**|T纳入的 [KnitMotion](../../../app/lib/presentation/motion.dart)集中 press75/release150、page260、board290、shortFade120、success300、reveal700ms；模态220/150集中在同文件 helper。FB通过 [game.dart](../../../app/lib/presentation/flame_board/game.dart) 将有限阶段归一到控制器按单位时长，未造新导航框架。T独立源码/官方animations3.0.0审查与FB几何/动作回归支持这些实际实现。原 before 录像索引见第3节。|原M before、T、样板、FB的设备/入口/负载有差异，不能拼成全App同条件性能提升。原时长是调校起点，不把所有实际值写成同一常量。|
|**M02 启动、资源、重试**|T纳入 [main.dart](../../../app/lib/main.dart) 的真实本地初始化、当前Home图像准备和 [StartupView](../../../app/lib/presentation/startup_view.dart) 品牌壳/可访问Retry；R01同时修复iOS LaunchScreen/引擎容器、Android普通/夜间/API31+主题。T独立19项、资源27项、正常main双端明暗冷启动录像与实际Start支持连续背景/可操作与失败Retry。SDK网络不作为该资源等待的前置；图像错误回调不伪造进度。|**没有统一的“native launch→首个真实可操作控件”耗时闭环。** 原M名为interactive的字段实际是App挂载后帧代理；FB冷启也是Dart宿主帧。T-R01有系统等待超时，不能写成启动时延达标。详见第4节。|
|**M03 原生按钮反馈**|T纳入 [knitPressFeedback / knitButtonBackground](../../../app/lib/presentation/knit_components.dart) 和 [PourluneApp主题](../../../app/lib/presentation/pourlune_app.dart)：视觉缩至.96、75/150ms、release轻弹，保留原生Filled/Outlined/Text/Icon输入所有权，disabled不缩放。`motion_polish_test.dart` 的 `native press shrinks visually and dragging outside cancels start` 核对Home代表按钮目标尺寸不变、拖出不启动。FB的 [board.dart](../../../app/lib/presentation/flame_board/board.dart) 保留真实OutlinedButton/原生Semantics；`flame_full_board_widget_test.dart`实际语义激活一次、只读/加载失败禁用；`motion_arrival_test.dart`证明资源就绪后的首个输入仍处入场期。这些包含在T定向和FB独立219中。|焦点隔离≠Enter/Space激活。当前可定位测试中未见 `sendKeyEvent` / `LogicalKeyboardKey` 激活记录；[覆盖审查](../review/motion-polish-coverage-audit.md) M03对“键盘”作概括，本文将严格激活去重证据列为待确认，不改原报告。拖出实测是代表按钮，不是每个类型均另做原生矩阵。未新增“所有按钮统一音/触觉”的结论。|
|**M04 页面进入/返回**|T的 [PageMotion](../../../app/lib/presentation/motion.dart) 使用官方FadeThrough/SharedAxis，普通260ms、首次Home120ms；[GameScreen](../../../app/lib/presentation/game_screen.dart) 按页面/实例/scene身份切换。最多一张旧视觉页，IgnorePointer/ExcludeFocus/ExcludeSemantics/TickerMode关闭旧输入，旧棋盘立即销毁。T独立双端各102步/11页及滚动/快速返回/后台测试；FB在该基线上又独立各43步验证初入、恢复、暂停/Home、每日/Replay、奖励/Next，presenter1、离开后0。|可继承已有组合行为；不把T的旧渲染器候选录像当Flame after。Android主录像180秒上限后的reduced系统返回是另段补录，不拼称单段全程；VoiceOver/TalkBack实际播读未验。|
|**M05 暂停与弹窗**|T的 `showKnitDialog` / `_KnitDialogRoute` 共用官方FadeScale，220ms进入/150ms关闭；沿用DialogRoute遮罩、requestFocus、closedLoop和返回结果，Navigator级单模态门控。`page_transitions_test.dart`暂停焦点/输入恢复及一次确认，`motion_polish_test.dart`重复暂停、较快关闭与失败Retry保持。T独立原生暂停、重开、Reset取消、每日日期、隐私、加瓶说明关闭；FB独立暂停/保存失败重试组合路径。|保存失败是即时页内面板 **不是模态**，不能用其截图证明所有dialog分支。不可用/替换/待SDK原实例恢复等由共用路由及既有host分支支持，T未逐一伪造native SDK场景；不补称真实广告/UMP通过。|
|**M06 棋盘、倒水、提示**|后续用户已授权局部Flame样板再扩完整棋盘，[FB计划](../../pmpowers/plans/2026-10-22-flame-full-board.md)取代旧M“不换引擎”的这一技术范围。正式 [BoardView](../../../app/lib/presentation/board_page.dart) 保留同组290ms入场（reduced即时），Flame按真实快照/token有限表现，4/5/6/7同尺寸；单位相关预算由 `PourMotion.duration` 保留。FB独立核对靠近4/0→四单位中段2/2→落稳0/4，所有标签/在途量/数字/语义守恒，FS-M01关闭；各43步含辅助、部分转移、跨行、保存故障、后台、SIGKILL/Undo。|不是仍用旧完整CustomPainter路径，也不是流体物理。未加入逐瓶30–45ms错峰；原计划明确其为调校起点，当前采用FB已验同组有限入场，不自行添装饰。真实音效相位/物理触觉不从无声录像推定。|
|**M07 通关、拼片、Next**|T纳入 [CompletionPage / RewardPage](../../../app/lib/presentation/collection_pages.dart)、[SceneArt](../../../app/lib/presentation/scene_art.dart) 与按需预热；FB独立43步实际完成主线4本地事务→回执/拼片→Next一次。T独立102步包含普通Next、拼片→场景→已存拼片重访→Next，以及章节20/最终60路径。`completion_presentation_test.dart`验证normal/daily/replay只有clean＋receipt才出现成功动效且不重发；完整门控、重访、reduced及样板区别见第5节。|正式场景是300ms成功/700ms局部显现，**样板850ms飞行＋160ms贴合没有变成正式全场景迁移**。当前预热成功与特定奖励页资源，不等于已预解码下一关所有瓶体；未宣称相应延迟/缓存命中达标。|
|**M08 资源与实际证据**|T/FB有独立源码/安装hash、双端实际流程、原速录像/关键帧、异常与reduced/窄屏大字；FB独立219与同安装恢复补齐正式棋盘组合。图像ResizeImage按展示宽度/DPR限制，SceneArt为局部RepaintBoundary，Flame每棋盘拥有2张512宽解码图、退出释放、有限Effects后pause；[FB性能账本](../evidence/flame-full-board/performance.md)保留27倒水/阶段、3冷启/阶段和各N=1热进入。|只可继承各自版本的运行/视觉证明；没有原M全App等条件after分布，也没有代表真机profile、音轨同步/物理触觉或全App零空闲重绘。两层图并行解码、静态刻度缓存是FB非阻断Minor，未实施；不把静态分析替代真机效果。|

## 3. 原 M before 与后续材料的可比范围

|证据组|设备、版本/入口、负载|可比较什么；不可比较什么|
|---|---|---|
|原M before（未验历史）|iOS `9B172C50-E5CB-4F3F-8F16-0A3DB04F495D`；Android `5584 / Pourlune_Motion_API36`。`motion_polish_app.dart`正常main诊断库 `motion_polish.sqlite`；`motion_route_app.dart`实际指针路线库 `motion_runtime.sqlite`。debug、Firebase none、ads disabled；双端route.json各6个汇总检查点，不是T的102步或FB43步。|保留同一旧候选的首帧/挂载代理、导航、已存一步和受控main004回执/奖励/Next。没有对应原M精确候选的最终等条件after，不能声称M全App提升。|
|S样板|同9B/5584硬件与debug，但换 `flame_sample_main.dart` / `flame_sample_app.dart`、`flame_sample.sqlite` / `flame_patch.sqlite`；两个可见瓶是合法四瓶定义的投影，另有拼片页。|可以审阅动作风格、局部状态安全。入口、负载、ready端点均变，**同设备也不能直接与原完整棋盘算提速**。|
|T及R01|iOS `3497E78D-608C-415C-8326-26E46F1B6E29`；Android5586 / `Pourlune_Transitions_API36`。页面路线 `page_transitions.sqlite`；R01正常 `lib/main.dart` 独立身份 `dev.pourlune.transitionsr01`、`ui_transition_r01.sqlite`。精确冻结包与必要M依赖由T提交纳入。|支持页面/模态及原生白色→蓝色连续性的已验修复。与原M **不同设备实例、源码、库及准备状态**；同为iPhone17/API36或debug不足以证明同条件时延。|
|FB作者 before/after|iOS **F9**、Android5588 / `Pourlune_FullBoard_API36`；同专用设备/身份、`flame_full_board.sqlite`、正常main插桩、formal内容，旧正式Flutter棋盘对新Flame棋盘。before已经含T原生启动与页面修复；[来源清单](../evidence/flame-full-board/comparison-source-provenance.json)声明before/after QA的小幅诊断/恢复条件差异。|可用于此棋盘变体的有界视觉/调试对照。**不是原M before→全App after**；after更低单次值不等于稳定性能提升。F9只是引用既有证据，本次完全不访问设备。|
|FB架构独立|iOS **255890D5-B4A3-42F9-B1A2-409E77118348**；Android5588；冻结after候选，真实main/sqflite。|独立复跑43步、关键帧与恢复支持功能/视觉；独立iOS设备不是作者F9的同设备before/after性能试验。架构Android首次force-stop355.6ms被250ms门槛拒绝，随后同UID显式SIGKILL118.2ms通过；失败保留，不能改写首次为通过。|

原M [录像索引](../evidence/motion-polish/before/video-index.json)保留4个原始路径/摘要及审阅片段。此次仅检查它们仍在，没有打开/复制/重新压缩：iOS route片段约55.9MB、navigation约63.9MB、cold约4.5MB，Android navigation约33.2MB。原始大录像仍在其原索引路径；**本交付只新增本文，不将这些未验录像纳入新提交范围。** [原检查点](motion-polish-checkpoint.md)的RED、DDS连接失败和首次全套失败继续有效作为历史，不被后续通过冲掉。

## 4. M02 计时口径：不能混称“启动时间”

|字段/材料|起止与样本|实际含义/限制|
|---|---|---|
|M before `host_launch_command_ms`|宿主调用launch/start的命令返回时间；与Dart字段分开|不是native首像素，也不是首个可交互时间；不能简单加到Dart值上|
|M before `dart_main_to_first_post_frame_us`|诊断Dart Stopwatch启动→注册的首个post-frame回调，各N=3|可以是初始化壳的Flutter帧；排除native/pre-Dart，非LaunchScreen首帧|
|M before `dart_main_to_home_interactive_sample_us`|以10ms间隔发现 `PourluneApp.controller` → 等endOfFrame，各N=3|源码没有检查具体按钮enabled/hitTestable或接受第一下真实点击。应读作“Home宿主挂载后帧代理”，**不把原字段名当作严格首个可交互证明**|
|T-R01完整冷启动录像/系统等待|正常main、双端明暗。录制时有宿主准备与观察等待，不是产品强制停留|可核对原生到Flutter/Home背景衔接；无精确native首像素计时。作者Android暗色 `am start -W` timeout/UNKNOWN、WaitTime12586；架构另一次亮色13231ms/UNKNOWN保留，后续看到Home不能将超时重写成时延达标|
|S `dart_main_to_first_ready_bottle_frame_us`|样板Dart计时→两瓶资源就绪绘制，各N=3；热页从pointer-up→就绪绘制|这是样板ready端点，不是完整App Home首交互；与原M两个字段均不等价|
|FB `first_postframe_us` / `dart_main_to_first_app_host_frame_us`|前者早期post-frame；后者Dart→Bootstrap后首个PourluneApp宿主帧，各N=3|冷启主表用的是后者，排除native/pre-Dart，未等全部intro结束，更不是首个接受输入时间|
|FB热 `pointer_up_to_ready_frame_us`|触发进局/Next的pointer-up→当前实例资源已加载、已绘制/入场opacity就绪，各端点N=1|支持棋盘热进入代理；不测native冷启动到Home首交互。原生路线随后真实操作证明可用，不能反推其就是最早可交互时刻|

原M数值只作历史列示：iOS已有普通局N=3首post-frame中位302.008ms、Home代理764.732ms；iOS首次welcome为350.313/837.214ms；Android为390.162/1199.543ms。FB修复版Home宿主帧中位iOS786.549ms、Android1361.444ms，**端点与准备状态不等，不能计算M提升百分比**。详见原三个startup-samples JSON与[FB诊断表](../evidence/flame-full-board/performance.md)。

因此M02已有“启动连续性/失败重试/功能可操作”独立证据，但原要求的首帧与严格首交互分别计时尚不能据这些字段完整签署。本文不新建数据、不重新运行启动。

## 5. M07：两次落盘与两种表现不可混淆

1. **完成/所有权回执先落盘。** [控制器 `_persist`](../../../app/lib/application/game_controller.dart) 对完成动作调用 `store.settle`，刷新进度后设置本实例receipt；[CompletionPage](../../../app/lib/presentation/collection_pages.dart) 只有clean且receipt非空才挂 `_CompletionFeedback`。普通成功300ms；reduced150ms淡入、无缩放。`completion_presentation_test.dart`验证normal/daily/replay、未存不出现动效、重建不重发。
2. **声音是另一路受门控回调，不是动画发奖。** 控制器 `_presentCompletionFeedback` 核对实例/revision、clean、receipt、前台、页面、motion结束及无待导航，先消耗pending再发GameFeedback.complete。`b03_completion_audio_test.dart`覆盖SQL长于动画、事务失败/Retry、重复callback、后台/旧实例；属于FB219继承的自动证据。它证明时序门控，不证明扬声器听感或音画相位。
3. **正式拼片显现与观看确认分开。** `RewardPage` / 章节预览只从已提交的 `progress.pieces` 取物件；未 `revealed` 才传 `reveal` 给SceneArt，普通700ms透明度/缩放，reduced150ms仅淡入。点击View collection/Next再经 `acknowledgeReveal` → `store.markRevealed` 持久化观看确认，保存成功才执行待导航/Next；失败可Retry，不用动画完成代替落盘。这里不声称正式动画开始前已写观看确认；已写的是通关/所有权回执。
4. **重访不等于再领奖。** 普通Collection/Scene预览不传reveal；已确认的piece使RewardPage `unseen=false`。T实际 `saved-patch-revisit` 路线、控制器幂等及上述表现测试相互支持已看拼片重访无再次入账。未确认便离开后再呈现未看效果，不等于重复发奖；不能把单个route截图当逐帧重播次数测量。
5. **样板有更强的飞行演示，仍是独立入口。** S04以正式main1–4的受控准备产生真实回执，Place patch先保存reveal确认再开始850ms飞行/160ms贴合；其失败像素、后台旧续体、reduced、手动重播由样板独立报告支持。FB没有把它接管所有正式SceneArt页面；不能用这段样板录像证明正式App每个奖励都有飞行。
6. **预热范围有界。** Bootstrap准备当前背景、logo/框、Home当前scene；GameScreen `_warmUpcoming` 每实例准备success96宽，逢主线4的倍数准备当前scene已有/即将获得piece。`warmScene`只准备该scene底图及指定pieces，ResizeImage按显示宽/DPR限制；Flame棋盘两层各512宽、随棋盘退出释放。**未见下一关瓶体预解码/跨棋盘共享缓存，也没有逐次cache-hit或“所有下一页资源零等待”证据。** 不为补齐措辞自动扩建缓存框架。

T路线有保存成功的普通Next、拼片重访、章节和最终入口；FB有正式完整棋盘最后一倒→本地main4 receipt/唯一piece→View patch→Next main5且receipts不增。广告触发逻辑未由动效改写；测试关闭广告/受控进度不是真实SDK展示、earned或自然玩家全程。现有录像无音轨或没有独立听感证明，本文不宣布音触觉通过。

## 6. 真实残项与最小建议（仅供架构裁定，未执行）

|残项/层级|现有材料不足之处|最小建议|
|---|---|---|
|**M02严格首交互计时**|已有字段是不同宿主/ready代理；native首帧与首个实际接受输入没有同域、同端点的完整记录|若架构要求原M量化条件，另协调**一次有界补证**：独立设备、同安装3次冷启，明确native launch、Dart壳、Home enabled/hitTestable及首次接受真实手势的端点；不重跑全套、不碰F9，不把新采样倒配旧M before|
|**M03键盘激活去重**|已有焦点隔离、语义一次激活及disabled；未找到Enter/Space实际按键证据|若原M此项必须实证，补一个代表原生按钮/棋盘的聚焦case：键盘一次动作、busy/disabled无动作；可与上一项同次安排。无需先改生产按钮或搭新输入框架|
|**M06/M07音画观感**|已验证设置/回执/前后台/去重门控；无足够音轨、主观同步听感、物理触觉材料|若架构认为阻断整批体验验收，仅补一段独立QA最后一倒→成功/拼片的有声观察及开关说明；物理触觉与代表真机仍按设备条件另列，不从模拟器日志补写“通过”|
|**M01/M08全App同条件前后分布**|跨M/T/S/FB的硬件实例、版本和端点不一致；FB only棋盘A/B且有诊断差异|功能/视觉可按已有T+FB独立范围裁定，同时明确不作全App提速结论；只有确有性能目标/症状才另安排等负载、源码固定的一组基准，不为文档收尾重复大批录像|
|**非阻断既存项**|T-M01轻微蓝色色阶；FB两层串行解码和静态刻度计算；下一关瓶体未额外预热|保留原P3/Minor及当前实现事实。若无具体可观察问题，不自动新增缓存、完整场景Flame迁移或“优化已完成”标记|

上述不是本轮新派发实施清单。T/FB已经验收的行为不因收尾文档而要求重跑；原M未达到的严格计量/感知条件也不会因两个批次通过而自动补齐。架构可据本表决定沿用哪些独立结论、哪些具体缺口值得一次定向补证。代表真机profile/FPS、热功耗、系统读屏实测、真实广告/Firebase收件、商业权属和正式签名始终不由本文件通过。

## 7. 本次文档核对范围

只新增本文；只做现有文件读取、字段/源码口径核对及文档链接/改动范围检查。未修改或重编码旧M before/RED、T/FB证据与任何App文件，未查询/启停/安装/输入F9或其他设备，未占用Flutter CLI，未提交。原M最终是否逐项关闭，由架构另出裁定；本文不能替代 `review/motion-polish-acceptance.md`。
