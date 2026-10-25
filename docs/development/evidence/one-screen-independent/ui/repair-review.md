# LY-R02/R03 修复独立审查（已执行Host复验）

**最新：已取得架构唯一CLI窗口，准确新源独立27/27通过、exit0、无超时；CLI再次明确RELEASED给架构。原静态段保留为过程，下文执行结果为当前裁定。**

2026-10-23。本轮只读当前三份生产文件，对比本方此前19探针使用的冻结副本。CLI当前仍归架构，本方未运行Flutter/Dart/pub/SPM/原生命令、未控制设备或采集，未刷新/修改隔离副本。本报告不继承旧源17/19或作者38项的运行结论；新源必须在明确窗口内实际重跑。

## 静态结论

当前差额针对原问题的结构性原因，**未发现可直接确认的新阻断缺陷**。R02把按钮从scroll子树移到受56高约束的同级Row；R03只压缩只读预览和操作装饰空间，正常字号优先必要状态/场景、最后才放长故事正文。待运行确认的风险集中在小屏七瓶的文字实际可读尺寸、所有分支内层clip，以及说明滚动前后按钮坐标不变。没有把源代码合理当成运行通过。

## R02：固定Cancel/Skip与错误优先级

- 原来的bounded分支在可滚说明Row里放Cancel/Skip，长文字把按钮垂直居中到clip外。新分支用外层 `Row(crossAxisAlignment: stretch)`，说明 `Expanded(SingleChildScrollView(details))` 与Cancel/Skip同级；56高约束作用在外层，不再将操作随说明滚动。它针对裁切原因而非仅把按钮上移几像素。
- `hasPriorityNotice`包含保存失败、奖励保存失败/issue/pending；showHintAction及showTutorialAction与原details的else-if顺序一致。错误/奖励提示优先时不额外显示无关Cancel/Skip；提示优先于教程。没有变更控制器、回调、保存规则或奖励权威。
- bounded下details原来的按钮移除，防止重复key/焦点和两份回调；unbounded保留原布局。Cancel仍调用c.cancelHint，Skip仍受c.busy禁用并调用c.skipTutorial。底栏/棋盘主要操作未随说明一起变成滚动。
- 小屏2.0时按钮的水平宽度会减少说明可用宽度，长文字更需要局部滚动，这是允许的说明滚动代价。需实测按钮完整>=48区域和实际点击，且拖动说明不改变其global rect；只有代码中的56高不能替代命中证明。

## R03：单行只读预览、结算按钮与必要信息

- `BoardLayout`新增分支仅适用于preview && bounded && textScale<=1.4。4–7瓶同一row，cellWidth=width/count，所有shape为min(48,cellWidth-8)，标签在各自瓶上方，height为瓶底+4。交互棋盘、普通PourGeometry/量守恒/标签目标逻辑没有变化。
- 在本任务最窄320屏/左右12padding下，width296、七瓶cell42.286、瓶宽34.286。它低于交互目标48但这里只读预览不接受操作，符合既有预览>=32的边界；不能将此套几何用于实际可操作棋盘。4–7瓶与标签仍同尺寸/同列。
- CompletionPage的正常previewHeight与该单行公式对应：标签高度+单个瓶高+4；大字号仍采用两行最小预览和局部说明滚动。没有整体缩放页面、文字或按钮。需要实测render字体及标签FittedBox后的宽度，不能只看getRect完整就宣称字清楚。
- `_SettlementActions`从现有theme样式copyWith，仅调整minimumSize48、水平8/垂直4padding和Nunito16/w900，保留backgroundBuilder、原背景、前景/disabled、shape与状态反馈。原横向两列/大字号单列Wrap规则保持。文字可令按钮实际高度超过48，没有硬裁文字高度。
- final长故事正文移到保存/场景完成/ScenePreview之后，有利于必要反馈优先首屏。真实ScenePreview仍是96高场景加文字/progress；受控长文是否局部滚动与必要状态/场景完整可见要分开断言。奖励页同样继承紧凑操作样式，不新写奖励。

## 测试检查与运行窗口准备

只读看到了增强后的测试：fullyVisible与所有祖先SingleChildScrollView求交；R02测拖动说明前后按钮rect完全相等并实际点击/等待保存；R03正常字号严格检查saved/chapter状态、ScenePreview、Reward文字，并加入正式chapter-seven/final-seven；几何增加只读单行4–7瓶等尺寸和标签关系检查。它们实际对准原缺口，未见通过删除旧断言来掩盖问题。本方尚未运行这些新源测试，作者/架构的38项和后续聚焦结果另由其日志负责。

架构明确释放CLI后：

1. 核对并记录准确新shipping192集合和三文件SHA，再将**仅已验差额**刷新到独立可写副本；保留旧probe失败日志与旧源，不覆盖它们。
2. 在新源运行本方独立19探针。G01除原有核心动作/瓶/容量外，将必要saved/chapter/Reward状态及ScenePreview升级为正常1.0/1.3的严格local-clip断言；长故事正文仍观察，不强加全部长文一屏要求。
3. R02明确验证drag说明之前/之后Cancel/Skip global rect完全相同、完整>=48且hitTestable，再真实点取消/跳过；覆盖原2.0裁切及1.5的滚动稳定，不以初始bounds通过代替固定。
4. R03补七瓶ordinary/patch/chapter/final/daily/replay及Reward/Reward-final可构成的全部结算分支；题目和权益为明确QA状态，走真实settle/receipt，不伪装广告发奖。首屏未滚动、真实Nunito/原图。必要文字、全部标签与瓶、场景、主要动作分别核对其最近scroll clip；大字号保留已允许的说明局部滚动例外。
5. 如发现FittedBox导致标签文字缩小，记录实际变换/字号和用途，按原可读性要求判断，不自行增设新的最小系统/新视觉规范。结束立即释放CLI，不操作原生设备或F9。

## 此次只读来源摘要

审查时生产集合192文件SHA256：`fada4bfb1da4d329c512f009d81896d31ad8a2a7b336aeed4f433a015aa5e123`。相对旧7fee8c…仅下列三项不同；此为审查时点快照，不保证后续改动无需再核。

- `app/lib/presentation/board_page.dart`：旧 `f7759cddfa77030e91e986b32ac1595cea8a0ad614a06e96979916ae36d7b276`；当前 `54c81226dbd1b66be252ce6725aa19bc3ceca619bb7977d37041246237221623`。
- `app/lib/presentation/collection_pages.dart`：旧 `a77fecb0b6fbb2d439d94b43c46b8094ee55259ec3353e1bc16289ee36152afe`；当前 `6677beb1d1d78b6d0e18093a81742b2b80df337f434e9c76414a5ca0a6e4961e`。
- `app/lib/presentation/flame_board/geometry.dart`：旧 `5dadf296f237e2b26ba6b13392466d2cdc196280e2970b97b003f4e83c64d6c6`；当前 `ef41c84c76260a7e1daf57688aad53496662d5aadb3d2f48f4ca4a8dffb2ff7f`。

本轮仅写ui/repair-review.md。所有运行判断仍待明确分配窗口；不新增成功构建、设备、性能、发布或权属结论。

## 准确新源的独立运行结果

在架构明确释放后，仅刷新父冻结 `build/ly-parent-r02-r03-20261023` 的三生产文件和两测试，逐文件核对 `R02-R03-parent-source.json` 的5个SHA。独立副本仍为 `build/ly-ui-independent-review/app/`，其他189生产文件与之前7fee8c…相同；新的192生产集合指纹是 `fada4bfb1da4d329c512f009d81896d31ad8a2a7b336aeed4f433a015aa5e123`。旧RED日志、旧19probe源码均保留，刷新前的三文件/测试/probe另存repair-predecessor-source.zip，不把旧源通过冒充新源。

实际命令：只格式化独立probe，随后 `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/ly_ui_probes_test.dart --reporter expanded`。测试约8秒，**27/27通过、exit0、outer_timeout=false**；无编译/夹具失败或重复调参，没有第二轮以改预期消除产品失败。命令与退出码在repair-probe-first-status.json，完整首轮GREEN是repair-probe-first.log。增强probe源码单独保存在本目录ly_ui_repair_probes_test.dart，SHA256 `084e47901e7c748fe4c3dc7b25506ca25cb0976b5fe794a1cc9594dcd24dae0a`。

### 本方实际独立断言

- 原19case保留并升级：真实Nunito、原图就绪，五种viewport/SafeArea，正常1.0/1.3的结算主要动作、全部预览瓶/容量、保存状态与ScenePreview，均在滚动前与所有祖先局部clip求交。saved/chapter/Reward必要文字升级为严格mustFit，最终长故事正文仍只观察，不强加长文一屏。
- 新增八种七瓶QA变体：ordinary、patch、chapter、final、daily、replay、reward、reward-final；连同原9结算case为17case。使用四颜色六瓶参考解+明确extra entitlement，所有七瓶变体先断言board.length==7，走真实settle/receipt；并保留正式main010七瓶case。它们是明确QA布局状态，不冒充广告发奖或实际玩家进度。
- R02原2.0裁切/1.5信息滚动共四个hint/tutorialcase：初始Cancel/Skip整个按钮位于信息区域垂直跨度且>=48/hitTestable，drag说明后global rect精确不变，其他固定操作仍完整可见；随后真实点击Cancel/Skip，分别验证hintSearching=false或tutorial inactive并等待真实保存结束。没有靠ensureVisible把这四项滚到可用。
- 七瓶320×568/1.3的实际键盘Enter/Space、语义tap、语义全局rect与视觉rect对应、disabled Undo、只读预览无瓶tap/action通过。大字号奖励次级说明仍可受控局部滚动到Retry，并证明固定主要操作未离屏；不重引入之前越界的首屏全部长文要求。

总计2495个必须完整可见的bounds观察全部在各自clip内；旧22条必要Scene/status风险中，已提升为严格断言的状态/场景现均通过。剩余4条仅为允许次要长故事正文在小屏的观察，不是新必要反馈失败。七瓶容量文字实际测得最小global高度17逻辑像素；这提供了真实布局尺寸，不能当作人工小图视觉/读屏检查通过。

### 裁定与限制

本方先前确认的Cancel/Skip裁切已在新源得到真实关闭；正常字号必要状态/场景和所有七瓶分支的本Host覆盖通过，没有发现本轮新增P1/P2产品问题。这里只给UI Host修复复验结论；整批LY仍由架构结合其最终显式disabled双端原生、功能证据及精确CI统一裁定。未新增设备运行、F9操作、截图/录屏/录音、真机性能或商店结论。

**本窗口全部Flutter/Dart/pub/SPM/xcodebuild命令已退出，CLI明确RELEASED给架构，见cli-release.json。** 后续只整理本ui证据，未改共享生产实现、未stage/commit/push。

## LY-R04 保留旧页的布局快照：独立只读核查（待窗口复跑）

新增原生saved-result路径的真实109px溢出，与Host RED相同机制一致：PageMotion保留的是旧child Widget，其中LayoutBuilder闭包可能在新约束/动画期间再次执行。旧闭包虽然捕获旧Home body，却实时读c.page；当控制器转到completion时，旧Home错误进入bounded Column/Expanded政策，失去原整页滚动。Home Column会在新有界高度溢出。这不是“首页未设计”或主题资源问题，也不能靠忽略FlutterError关掉。

已只读核对修复：ListenableBuilder每次构建时final renderedPage=c.page；只有内部延迟LayoutBuilder的页面策略/头部/notice/底栏/scroll key条件改读这个当次快照。外层仍按实时c.page构造正确body、PageMotion key、方向及转场保留策略。新入页每次构建取得新值，旧出页回调保留旧值，符合其布局身份；保存状态和动作回调依然读取控制器/原门控，没有新业务副本或更改控制器。

PageMotion源码未改：旧页仍IgnorePointer、ExcludeSemantics、ExcludeFocus、TickerMode(false)，进入页仍独立FocusScope。retainPrevious和真实转场未关闭；与棋盘相关的去留政策也未改。因此静态未发现修复削弱旧页输入/焦点/语义隔离。它仅固定页面身份，不声称冻结整个控制器状态；本次故障所需是防止旧页被新页面类型重新分类，无需引入新导航框架。

只读看了父两项LY-R04测试：20/60真实store.settle后initialize停在Home，真实ensureVisible(saved-result)并tap，每20ms检查20帧无框架错误，随后检查completion、id/receipt、旧出页消失。父RED日志0/2且有RenderFlex溢出；本方还未重跑，不继承父GREEN。下一窗口会在隔离副本只刷新game_screen及该测试，独立执行两项真实Home→已完成章节/最终入口，并在过渡期间检查出页仍为scroll-home及隔离包装，覆盖根因而非只等到末帧。

本段无Flutter/Dart/pub/SPM/设备执行，不重跑R02/R03的27项。新生产指纹与最终独立运行结论待获得明确窗口后追加。

只读时点：旧game_screen SHA `633396775a48804970fc624ee61beb996d76310249a085c711443b07910c66ec`；新SHA `0b577272f9d19a45226c461a54694f4ac822f699c6894331b97430072e023cce`；父布局测试SHA `a5a5d214b1392f16d965b63a8b781b7bb3c5a82e8edfec598325335b8707e573`。

## LY-R04 独立实际复跑（当前结论）

已获得明确串行窗口，仅刷新game_screen与one_screen_layout_test，逐字节匹配R04-source.json；R02/R03三生产文件保持父冻结SHA不变，未重复27全套。

独立探针另写ly_ui_r04_test.dart：使用正式main020/main060参考解+明确extra entitlement形成七瓶completed QA存档，真实SQLite settle后initialize停在Home，加载Nunito；从真实Home可滚到saved-result并实际tap，之后不滚动结果页。每项20×20ms逐帧检查框架异常，同时必须实际观察到page-outgoing，不能靠关闭retainPrevious或直接跳到末帧过关。旧Home实际保留scroll-home，且仍IgnorePointer、ExcludeSemantics、ExcludeFocus、TickerMode(false)；最后断言completion、原实例id、receipt、旧页退出，并检查主要按钮完整48及hitTestable。

实际命令 `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/ly_ui_r04_test.dart --reporter expanded`，**2/2通过、exit0、约2秒测试时间、无90秒外层超时**。390×844、SafeArea上47/下34、字号1.0，共40帧检查无错误。R04-probe.log / R04-probe-status.json / R04-probe-summary.json保存实际记录。只有初次准备命令误用副本相对路径造成文件未创建的setup-error加载退出1，已保留R04-setup-path-error*并注明为准备错误；修正路径后两项首次实际编译运行均通过，未修改生产或放宽断言。

这关闭了本方R04的真实saved-result跨帧布局/隔离验证，不等同于最终双端新原生路径通过；受控完成状态不冒充自然闯关、广告发奖或SIGKILL恢复。CLI已明确RELEASED给架构，后续仅整理ui证据。

R04后192生产集合SHA256：`6260033bed815e271c6e8de32d4d06781c05823226a3dbbb3c2baf537d2cadf3`；独立probe SHA256：`e414984c17f81757128d6f52869bb0f41323e2ca1820d0866a60def7eecd3eb8`。20/60观察到旧出页的帧数分别为14/14。
