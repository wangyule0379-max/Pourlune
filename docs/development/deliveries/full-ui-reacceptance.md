# 2026-10-24 当前实际验收与 TestFlight build10 完成

用户已明确解除专用测试设备截图/录屏重试限制，F9及其窗口继续完全保护。原开发按本人授权接手实际验收到TestFlight；下面历史“等待采集授权/视觉0页”已被本节取代。没有操作F9，没有修改TLS/代理、安全设置或普通用户库。

当前正常lib/main.dart在三台专用iOS模拟器上实际运行：常见手机255890D5、小屏375×667 FC9E05C9、大屏440×956 3D88FCFE；身份dev.pourlune.layoutValidation、full_ui_parent.sqlite、Firebase none、ads disabled。逐页P01–P21对原稿观察，独立reviewer实际查看66张图（含末条新文案复核）及七原稿，主要Critical/Important全部关闭，可进入精确CI/签名核包。P16/P17只核广告关闭说明/不可用合并状态；P18为明确受控七瓶权益，不是SDK奖励证明。详细[实际矩阵](../evidence/full-ui-reacceptance/actual-20261024/actual-page-matrix.json)和[独立报告](../review/actual-ui-independent-20261024.md)。末条Bottle added文案也已获独立新图复核，528项最终冻结无漂移。

本轮修复：暂停透明Dialog继承外边框；普通手机提示理由裁切；小屏1.65×提示挤掉底排容量（按真实14px辅助按钮字体判换行，瓶子/flight几何不改）；P15今日直接Replay且不重发stamp/进度/拼片；P09 Keep playing主操作；失败SaveFailureNotice移出旧offset的滚动区，使Retry/Stay固定可见。最后补已获七瓶的Bottle added+check文案，原广告/奖励门控不改。

实际连续提示发现level13旧DFS在4→3/3→4循环，新增连续至通关回归先RED。最终使用有界A*：标准库SplayTreeMap，未锚定颜色组合法下界，固定目标保位置，仅无标签缓冲归一，best-g替换open；出队goal后返回最短剩余路径首步。2秒/50000预算、isolate取消、实例/revision/generation过期门控保留；没有扩大预算或套用参考解。中间BFS在extra预算失败已弃用，日志保留。

实际八代表13/20/21/28/40/41/53/60从初盘完成114次提示后手动目标点击，步数17/13/13/14/15/14/14/14，全部真实SQLite回执；20→21、40→41实际Continue衔接。其他此前进度仅隔离库明确seed，不能称自然全60首玩。独立reviewer按记录重放114动作，无重复盘面且与8份SQL收据完全一致。实际每日完成后Replay新实例、单stamp、不重奖；失败Home被拦→Stay→Retry→同安装SIGKILL/重开恢复已保存move1。原QA库已备份并恢复，小屏系统字号恢复large。

本轮实际检查（日志在actual-20261024/checks/）：完整核心38通过，含八代表有/无extra连续提示、90初/中、60四位置、旧非空及独立188有序盘BFS最短距离oracle；完整应用280通过；build工具Python57通过；app130/core14格式无变化；analyze clean；正常main原生build/install成功。文案差额后51相关UI/广告/布局回归、静态分析和build10原生重建/安装通过，已实际核对Bottle added+check；Settings实际AX读到0.5.0(10)。未改依赖与锁。设置进退/帮助/隐私有36.76秒原生录像，1103个30fps精确时刻抽帧、36个明显变化帧联系图，实际未见纹理损坏；不外推全帧或设备性能。

当前0.5.0(10)已完成精确05220d7 CI40053916204、签名候选3及Organizer变体独立核验、Apple上传/处理与出口技术问卷，已进入现有Pourlune Beta内部组（原1测试员），服务端显示正在测试/90天后过期。测试说明已保存并完整读回，没有重邀、公开发行、符号上传或运行生产App。首个本地10被核包拦住native integration-test，已在构建工具修复并新目录重建；原始包与首包阻断记录保留。新包/哈希/回执及未验见[build10分发交付](ads-disabled-build10-submission.md)。旧build5–9冻结。Play/AdMob继续暂停。真机安装升级/音触觉/性能、人类首次难度、美术商业权属及真实广告仍未验，内部Beta不等于公开商店发布通过。

---

# 2026-10-24 原开发重新接手

已按最新委派承接完整60关及父R05–R07修复，复核当前523文件SHA无漂移。完整应用275、核心36、内容45、工具57等已通过检查沿用原证据，本轮没有无差额重跑。当前实际视觉仍0页；既有专用QA采集例外问题未获明确回复，没有重试采集或操作F9。Apple登录完成的历史回复不等于解除采集限制；本轮只读打开ASC后返回登录页（authResult=FAILED，iframe空白），未输入凭据或修改后台。旧build9分发凭证保留，未声称新修复已更新TestFlight。待前述采集授权后继续实际逐页/动态/代表关验收，再按已授权路径更新。

本轮[接手核对回执](../evidence/full-ui-reacceptance/developer-resumption-20261024.json)；详细已完项与顺序见[最新交接](parent-to-development-testflight-handoff-20261024.md)。当前无需为尚未到达的上传步骤提前重复登录。

# 父接手最新状态

原开发R01–R04检查点已由父接手继续R05–R07；本文件下方为历史交付。当前修复、实际运行与未验范围以 [父重新验收记录](../review/full-ui-reacceptance.md) 和 [独立整批审查](../review/parent-combined-review-20261023.md) 为准。60新题已集成、父相关UI61+3通过，仍没有当前实际画面验收；不更新TestFlight。

# UI-R01–UI-R04 全页面复查与修复交付

2026-10-23。**本批源码修复与自动回归已交付，实际视觉验收仍未通过，不能发布新TestFlight候选。** 已逐张查看7组原稿、复查P01–P21及主要异常变体；当前无法合法取得修复版本的实际画面。父必须逐页看过效果后才可验收，不能用作者自查、几何矩形或270项测试替代这一步。没有重试/换路径绕过Cocoa513/EPERM，没有操作F9。旧0.5.0(9)包与分发事实保持冻结。

## 已确认问题与实现

- **R01**：真实主题/Nunito/SQLite探针在320×568下得到Extra底边498、Undo顶边498，源码显式零间隔；旧测试没有检查组间分隔。现仅在Extra存在时保留10px；辅助按钮不缩小，仍至少48。说明区多余4px与棋盘标签后多余4px空白移除，保留瓶子/容量标签尺寸、七瓶4+3、完整跨行倒水。新增装饰变换边界/按钮互斥命中与分隔检查。**用户手机实际重叠像素尚未复现，不能声称所有设备绘制问题已解决**，详见[根因与边界](../evidence/full-ui-reacceptance/r01-diagnosis.md)。
- **R02**：普通/拼片/重玩完成恢复双排只读棋盘；完成标题与成功图、章节进度卡、主操作分别组织。成功图依可用高度为72或短屏40，不再全机型固定36。章节/最终完成按产品要求展示完整场景，日完成按P15展示日期与成功标记。主按钮始终独立全宽，次操作在其下有间隔；保存/奖励门控不变。大字长说明可滚，核心操作固定。
- **R03**：新拼片场景按剩余高度和宽度作为主体展示，取消无条件96px compact列表缩略布局；拼片/场景进度用针织卡组织，主次按钮上下分明。首次揭示/重访仍依已持久化归属，动画不发奖。
- **R04**：章节恢复分章场景/完成数与关卡网格；设置开关恢复针织分组，使用透明Material保留真实墨水反馈；场景页/设置操作增加间隔；对话框统一奶油边框、圆角及Nunito；额外瓶说明复用已有空瓶图层，未生成新美术。欢迎短屏缩减logo/装饰占用以保留Start。P08沿用内联救援反馈，P20保留实际可滚动选项表单，这些与原图模态/装饰的差别仍列在矩阵中，未声称逐像素复刻。

完整[逐页/变体矩阵](../evidence/full-ui-reacceptance/page-matrix.md)、[机器可读矩阵](../evidence/full-ui-reacceptance/page-matrix.json)、[修复前初审](../evidence/full-ui-reacceptance/initial-matrix.md)。每页均标当前实际视觉未验。保存失败Retry/Stay、搜索取消/过期、奖励待保存及迟到原实例恢复保持真实边界；广告测试为受控运输，不是AdMob真实成功。

## 实际验证

工作目录均为`app/`，Flutter3.47.2/Dart3.13.2；所有Flutter命令串行并设置`FIREBASE_ANALYTICS_WITHOUT_ADID=1`，首先`flutter pub get --enforce-lockfile`成功，未改锁文件/依赖。

| 检查 | 结果/范围 |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 128文件、无变化 |
| `flutter analyze` | No issues found，见analyze-final.log |
| `flutter test --reporter expanded` | **270项通过**，见flutter-test-all-final.log；覆盖保存/奖励/迁移/恢复/动画/页面与本批布局 |
| 加强后的`one_screen_layout_test.dart` | **40项通过**；5尺寸×1.0/1.3/1.5/2.0、4–7瓶及结算变体；SceneArt实际几何可见检查代替已不存在的compact预览检查，见one-screen-final.log |
| 新`full_ui_reacceptance_test.dart` | 3项通过；R01分隔/装饰边界/命中，P10双排与主操作，P11主体场景，初始失败与修复成功日志均保留 |
| 新`full_page_inventory_test.dart` | 真实90题目录、SQLite、Nunito；320/390/430与1.0/2.0下主要页/对话框，6组×13状态=78记录；按钮互不相交、无框架异常。不是原生main或视觉证明 |
| 根目录资源manifest `--check` | visual23资源/22运行副本通过；UI10资源/10副本通过。使用内置带Pillow Python，项目venv缺Pillow的首次失败已记录，无新增依赖 |

资源原图/裁切没有变化；`KnitPanel`新增可选margin使清单记录的整个源码hash变化。已先逐字段核实**唯一差额为`/geometry_source/sha256`**再显式刷新，见[清单差额](../evidence/full-ui-reacceptance/ui-manifest-delta.json)，没有用write掩盖资产漂移，rights仍UNCONFIRMED、visual acceptance仍NOT_ASSERTED。

验证曾捕获并修正：加间隔后极小屏剩余空白导致滚动、进度卡重复文案挤占预览、设置纹理遮蔽ListTile墨水的框架错误、每日成功反馈遗漏。完整270项成功后，进一步加强了SceneArt几何断言并定向40项通过。旧单行缩瓶断言随明确恢复双排而更新；旧完整保存文案移到成功图的可访问语义，普通界面保留Saved，独立组件测试改验真实语义；回执门控及幂等测试未删除。

## 冻结、未验与交接

[修复前源码](../evidence/full-ui-reacceptance/source-before.json)、[修复后冻结/检查结果](../evidence/full-ui-reacceptance/source-after.json)。主入口、控制器、数据/SDK、题库、原设计资源及锁文件未改；没有构建/运行生产、上传符号或商店上传，没有stage/commit/push主仓。Play/AdMob继续暂停。

**发布门槛仍打开**：所有P01–P21在当前修复版本上的实际绘制/视觉、正常main独立QA原生运行、手机触控/字体/读屏、用户所报设备特有重叠，均未完成实际观察。父须对照原稿逐页实际看过，并确认无问题后才能提交新版本、独立核包与更新TestFlight。不能把旧build9或历史截图当本批效果。

新增题库问题DC-R01已另行[只读测量与阶段方案](difficulty-curve-followup.md)，包括代表关调整方向、求解/试玩证据缺口及稳定ID/递增版本/旧活动快照兼容措施；本批未替换任何题目，难度设计未宣称通过。
