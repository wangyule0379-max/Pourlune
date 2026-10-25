> **最终集成更新（2026-10-23）**：以下为原开发交接历史。架构接手后完成R02/R03/R04生产修复及QA就绪/异步拆卸同步，独立UI27+2、功能19、双端最终各14阶段整体exit0。LY本地验收通过，当前准确结论及限制以[独立验收](../review/one-screen-layout-acceptance.md)为准；新精确CI/新正式签名候选/商店提交仍待后续执行，旧build6不含修复。原交接未完成状态保留供追溯。

# LY01–LY06 一屏布局交付

2026-10-23；**CLI RELEASED给架构，LY05/LY06未完成。** 无Flutter/Dart/pub/SPM/iOS命令在途。架构现接手QA harness/host driver及独立Android5590；本作者不再并发重试或编辑其文件。完整交接见 `../evidence/one-screen-layout/CLI-RELEASED.json` 与 `native-handoff.md`。

当前194项源/QA fingerprint：`fc336052ca53a805ab4ac01edba36980604c59e132b476914993adba4852a96c`；其中192项App/core/assets/manifest+lock fingerprint：`7fee8c543972767564a96955d9ed2e095de3cc281d07657c9a280d4c001e109e`，与73项通过后完全相同；后续差额仅QA显式无广告门控、官方host driver和有界等待诊断。

作者执行记录，架构独立验收尚待进行。源代码修改不更新冻结 BR06 build 6。本报告不表示新版本已经签名、上传或提交商店。

## 修改与要求

|要求|本批实现与证据|
|---|---|
|LY01 有界布局|游戏、结算、拼片奖励页接收 SafeArea 的真实剩余高度；棋盘和信息区伸缩，主要操作固定在外；列表/收藏场景保留滚动。Level10 原始未滚动失败见 `first-red.log`：Extra bottle 下边界724超过667。|
|LY02 几何/动画|同一 BoardLayout 生成绘制、标签、点击和动画几何；4–7瓶等尺寸，点击区不相交且至少48；压缩行距并按高度计算瓶体，保留完整飞行路径与上下标签。每15ms检查全部起终点、1/2/4单位、三个宽度/高度/字号的画布、标签、液流与守恒；既有 FS-M01 同步/过期token/输入锁回归保留。|
|LY03 结算分支|普通/拼片/章节/最终/每日/重玩，以及普通/最终 RewardPage、正式main010七瓶完成状态；只读紧凑预览不连接 presenter、不启动实例或写奖励，也无入场/倒水留白；所有主要分支按钮先于任何滚动检查 bounds/hitTestable。回执未落盘不播放成功反馈；Retry原事务和导航门控不变。|
|LY04 适配|375×667(上20/下0)、390×844(47/34)、430×932(59/34)、360×640(24/24)、320×568(20/0)，均在实际 Flutter 测试 viewport + Nunito +解码瓶图中运行1.0/1.3/1.5/2.0。1.0/1.3全盘/容量及操作直接可见，棋盘滚动范围为0；大字号优先文字和48+区域，必要时仅局部棋盘/说明可滚动，主要操作固定。教程、提示取消、无可行步、七瓶保存失败、未落盘通关回执均有额外检查。|
|LY05 运行验证|聚焦页面、几何、FS-M01、连点/返回/实例替换、回执失败和SQLite恢复；双端原生执行状态见下。未重跑无关全量内容/SDK套件。|
|LY06 集成边界|只交付本任务源码/测试/相关说明和证据；作者不stage/commit/push。架构独立验收和精确实现CI后，再生成新版本签名候选，复验后按既有授权推进TestFlight与Google Play closed。旧build6及F9保持不动。|

## 文件

- `app/lib/presentation/{game_screen,board_page,collection_pages,knit_components,service_views}.dart`：有界页面、局部说明、紧凑结算、48+操作及错误优先提示。
- `app/lib/presentation/flame_board/{board,geometry}.dart`：高度适配、固定尺寸命中区、只读预览；保持 GameWidget 祖先稳定，避免调整 viewport 时重复销毁同一个游戏对象。
- 新增 `app/test/one_screen_layout_test.dart`、`one_screen_geometry_test.dart`、`app/integration_test/one_screen_layout_test.dart`、官方适配 `app/test_driver/one_screen_layout_driver.dart`；调整 `app/test/page_transitions_test.dart` 将已删除的整页棋盘滚动契约改为每实例说明区滚动，原有新实例/场景偏移断言仍保留。
- `app/README.md` 与本报告/证据。
- `docs/design/production-candidates/runtime/ui/manifest.json` **仅**更新 `geometry_source.sha256`：先确认全部10图、裁切、来源、权属和状态完全相同，且旧hash确实对应HEAD旧源码，再显式刷新已授权修改的布局源码hash。审计为 `ui-source-hash-update.json`；未刷新visual manifest或修改美术像素，不新增视觉/权属通过。

## 检查

工作目录 `app/`，所有 Flutter/Dart/pub/SPM/iOS 串行，`FIREBASE_ANALYTICS_WITHOUT_ADID=1`。工具链根 `.flutter-version` 固定；应用/核心锁文件保留。

- `flutter pub get --enforce-lockfile`：通过，`pub-get.log`。
- 最终11文件聚焦命令/退出码见 `final-checks.json`，`tests-final.log` **73/73通过**；包含32个布局场景（五种viewport/四种字号/九个结算分支矩阵、七瓶失败/提示/回执/奖励确认警告），以及原几何、容量同步、实例/页面过渡、重放保存失败、B04行为回归。`dart format --output=none --set-exit-if-changed lib test integration_test`与`flutter analyze`通过，后者无问题。
- Python `visual_manifest.py --check`、`ui_manifest.py --check` 及assets 27项通过；分别见 `visual-manifest.log`、`ui-manifest-final.log`、`asset-tests.log`。
- 合法失败/修正证据：原始页面溢出、结算按钮离屏、容量标签2px布局不足；紧凑几何真实压标签后修正；真实事务失败显示与Retry；`receipt-priority-red.log`→`receipt-priority-pass.log` 保证失败回执提示优先于恢复通知。无效测试设置（如不存在的关卡61、QA替换未显式确认）不当成产品缺陷或有效通过。

双端原生：`native-inventory.json`列出独立设备/身份/库。iOS使用外部 `POURLUNE_BUNDLE_IDENTIFIER`，安装前核对plist为`dev.pourlune.layoutValidation`；Android使用全新`Pourlune_Layout_API36`与独立Gradle测试身份。仅本轮明确的`ly_runtime.sqlite`可被清理。iOS先前11阶段正常main流程通过：402×874、安全区上62/下34、scale1.0，含1–4通关/拼片/Next、SQLite同进程关闭重开、七瓶未滚动命中。该轮未显式传广告disabled，实际是debug官方测试广告默认值；因此不能称最终无广告复验。最新harness已拒绝缺失disabled/Firebase非none配置，但该最终iOS轮仍待串行执行。

Android独立身份构建安装成功。默认flutter test在DDS getVersion112断开；--no-dds test遇到工具自定义golden stream不支持；改用SDK自带integration_test官方host driver（无截图逻辑）后连接成功，进入正常main首页/controller，但初始pumpAndSettle在25秒上限内超时退出1。最后完整日志 `android-drive-steps.log`；没有Android游戏/结算全流程通过，未修改SDK/版本/关闭安全验证。旧无限等待运行均安全结束，不能当通过证据。SDK工具失败与页面产品缺陷尚未等同，后续由架构亲自诊断。

本轮未操作受保护 F9 及其窗口、旧审查/Firebase库、BR06冻结文件、签名私钥或商店；没有截图/录屏/录音，也未重试或绕过既有 Cocoa513/EPERM 限制。原生自动点击、bounds和SQLite证据不等于人工视觉、读屏实听、真机性能、SIGKILL或商店验收。

## 执行裁定

1. 小屏1.5/2.0保留可读文字和48+目标，通过局部棋盘/说明滚动处理实际空间不足；代价是极大字号可能分段查看棋盘，不会通过整页滚动发现主要按钮。正常1.0/1.3明确验证无棋盘滚动。
2. 结算只读预览允许瓶图缩小至32逻辑像素宽，不缩放整页或文字，仍显示真实目标/容量；代价是预览的装饰瓶体较小。交互棋盘瓶宽下限48，按钮下限48。
3. 保存失败紧凑提示使用带完整Tooltip/语义标签的Retry/Stay图标按钮，完整错误文字保留；代价是视觉图标文案可通过Tooltip检查，原回调/落盘门控不变。
4. 原整页棋盘滚动测试改验每实例说明区偏移；代价是已删除的整页滚动不再被当作必需行为；原有返回保留、新实例清零、场景互不污染继续断言。
5. UI清单只更新已变更布局源码的审计hash，先证明像素/裁切/来源/状态零差异；代价是清单仍不能证明独立视觉或权属通过。


当前收尾边界：源页面与73项聚焦检查已完成；Python资源检查27项通过，图像/裁切/来源/状态未变。QA诊断源码已format，最后guard/step日志编辑后尚未再次全量analyze（运行编译已成功；最终诊断轮有界超时）。一次作者fresh终审尚未派发；架构正在按用户要求运行其独立副本探针，不能把本交接说成LY整体通过。iOS最终disabled轮、Android完整运行、独立验收/新CI/新候选及商店提交仍未完成。CLI与Android QA写权现已明确交架构，无需用户手动处理。


后续 LY-R02/R03 安全检查点：独立UI19项17通过2失败及22处状态/场景裁切已实读。原作者仅新增更严格的测试，**尚未写入生产修复**；R02聚焦命令4项均RED（2.0初始裁切、1.5滚动带走操作），R03状态/场景/七瓶章节与最终关断言已备，尚未运行。按用户后续总控交接，board_page、collection_pages、相关布局测试及CLI现全部RELEASED给架构直接修复；作者不并发修改/运行。精确源hash/命令/测试快照/未完成项见[本次交接](../evidence/one-screen-layout/R02-R03-handoff.json)。既有73通过只对应此前源码，不代表新增测试或修复通过。QA harness/driver/5590继续架构专属，未动。
