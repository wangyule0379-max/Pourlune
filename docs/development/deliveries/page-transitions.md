# T01–T06：全部既有页面转场

2026-10-22，App UI 作者执行记录；架构另行独立验收与提交。

**独立首轮结论：页面内已测通过，整批因 T-R01 原生冷启动白底未通过。T-R01作者修复及双端正常main明暗冷启动补证现已完成，等待架构独立复验；旧作者完成结论不代表整批通过。** 见独立验收报告和 evidence/page-transitions/T-R01/。使用官方 animations，保持既有编织视觉和单一 controller 导航。T01–T06 作者执行完成：冻结副本200项测试、analyze、format与双端debug构建通过；最终双端均102步、errors为空。此结论不替代架构独立验收。

## T01 页面关系矩阵

现有 GamePage 共 11 项；共享背景位于 GameScreen 的 PageMotion 外。PageMotion 已使用官方 FadeThrough / SharedAxis，至多一张出场页，棋盘相关跳转不保留旧棋盘。保留输入/焦点/语义与 ticker 隔离。主导航是 controller 状态切换，不建立第二套路由栈。

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
|settings→licenses→许可证详情→返回|SharedAxis，已接入|属于现有导航，不能遗漏；系统返回保留原行为|

OpenContainer 评估：不采用。收藏卡片当前通过 `controller.navigate(scene)` 切主页面；OpenContainer 会单独 push 路由，需额外同步控制器、返回与保存失败状态。使用官方 SharedAxis 的缩放轴满足主从关系，保留单一导航源和已有编织卡片。未增加游戏实例。

## T04 模态矩阵

|入口|当前入口|实现与行为保护|实测|
|---|---|---|---|
|主线替换／每日跨日替换|GameScreen._confirm|统一 FadeScale；false/null 不替换|统一 helper 已接入；范围见验证账本|
|重开|GameScreen._confirm|统一 FadeScale；额外瓶权益保留|统一 helper 已接入；范围见验证账本|
|Reset|GameScreen._confirm|保留 Keep progress 默认焦点与危险动作次级样式|统一 helper 已接入；范围见验证账本|
|不可用题目／信息|GameScreen._info|统一 FadeScale；关闭只 dismiss|统一 helper 已接入；范围见验证账本|
|暂停（含系统返回）|showKnitDialog|统一 FadeScale；重复暂停一份；失败状态仍可 Retry / Stay；关闭返回原棋盘|统一 helper 已接入；范围见验证账本|
|每日历史／未来日期|DailyPage._date → showKnitDialog|改为统一 helper；只读，今日入口仍开局|统一 helper 已接入；范围见验证账本|
|加瓶广告前说明|showExtraBottle|统一 FadeScale；Not now 无损；关闭不发奖|统一 helper 已接入；范围见验证账本|
|隐私选择|showPrivacyChoices|统一 FadeScale；保留选择与原生 UMP 分离|统一 helper 已接入；范围见验证账本|
|恢复获奖实例确认|RewardStatus|统一 FadeScale；原实例恢复与保存门控不变|统一 helper 已接入；范围见验证账本|
|保存失败|页内 KnitPanel，非 dialog|不伪造模态；立即可见，保留 Retry/Stay|统一 helper 已接入；范围见验证账本|
|原生广告／UMP／系统浏览器|SDK/OS 所有|不替换原生 UI，不把关闭当奖励|不属转场层渲染|


## T02 依赖与兼容

精确锁定 animations **3.0.0**，仅新增传递 material_ui **1.8.0** / cupertino_ui **1.1.4**；其他包版本未变。`flutter pub get --enforce-lockfile` 通过。官方 [changelog](https://pub.dev/packages/animations/changelog) 声明最低 Flutter3.44/Dart3.12，本项目3.47.2/3.13.2满足；实际旧 Material 主题兼容由 host、双端编译及原生运行验证，无整套 Material UI 迁移。所有应用构建串行并设置 FIREBASE_ANALYTICS_WITHOUT_ADID=1；Firebase none、广告 disabled。

## T03 页面与启动

GameScreen 按真实关系选择 FadeThrough / horizontal SharedAxis / scaled SharedAxis。PageMotion 内使用官方 primary/secondary 动画，不外套旧 fade/slide；普通260ms，首页首次短淡入120ms。透明 fillColor 使原背景保持稳定。保留既有启动预解码、失败 Retry、局部按钮/倒水/成功与拼片效果，不增加人为产品等待。main.dart/startup_view.dart/控制器/存储/服务/核心未由本任务修改。

保留有界宿主而不直接使用 PageTransitionSwitcher：官方 switcher 快速切换可保留多张旧页；本项目只允许一张出场且旧棋盘立即销毁。正向与返回使用同一 PageRoute primary/secondary 合同；无动画回调发导航、写通关或发奖。页面身份包括适用的实例ID和sceneID，不使用动作revision，因此普通操作不重建游戏页。

## T04 模态与原生许可证

所有自绘对话框入口共用 showKnitDialog，官方 FadeScale 进入220ms/退出150ms。保留 DialogRoute 原有取消结果、barrier、闭环焦点和主题；以 Navigator 的弱键阻止重复打开，重复请求返回null，不重复执行确认动作。每日历史/未来日期也接入 helper。Reset等长文本确认框可滚动，保留默认 Keep progress 焦点。保存失败仍是页内即时 Retry/Stay，不伪造为模态。

许可证列表/详情保留真实 Material 路由，通过 PageTransitionsTheme 使用 SharedAxis，系统或应用减少动态效果时跳过动画。SDK广告、UMP和外部浏览器仍由原生拥有，不用自绘弹窗冒充。

## T05 安全、无障碍与滚动

出场 IgnorePointer / ExcludeFocus / ExcludeSemantics / disabled TickerMode；快速切换淘汰更早旧页。后台清理未完转场，系统与应用减少动态效果均有效。第一下输入可操作，保存失败立即可见；无第二个业务实例或第二个棋盘 presenter。

滚动修复按实例/scene分别存储：返回同实例/同scene恢复offset，新的实例/不同scene从顶部开始；章节等功能页继续保留自己的位置。回归实际 RED 为旧局580、新局457（应0）；修复后旧局返回保持580，新局0，不同scene0且原scene返回恢复。见 scroll-red.log / scroll-green.log。修复前后关键画面见 scroll-before-after/。

## T06 最终验证与证据

|检查|实际结果|证据|
|---|---|---|
|滚动回归 RED→GREEN|旧局580/新局457失败 → 同局保持580、新局0，不同scene0且原scene返回恢复|scroll-red.log / scroll-green.log|
|完整应用测试|冻结副本 **200/200通过**|final-app-tests.log|
|静态分析|No issues found|final-analyze.log|
|格式|105文件，0改动，退出0|final-format.log|
|iOS debug Simulator 构建|成功，独立bundle，无AdID|final-ios-build.log|
|Android debug APK 构建|成功；保留现有Kotlin迁移warning，无SDK升级|final-android-build.log|
|最终iOS原生路线|**102步，errors=[]，11类页面**|ios/run/route.json|
|最终Android原生路线|**102步，errors=[]，11类页面**，序列与iOS一致|android/run/route.json|
|Android真实系统返回补充|减少动态已开启：How to play → KEYCODE_BACK到Settings → KEYCODE_BACK到Home；实际截图复核|android/system-back-reduced.mp4、system-*.png|

上述Flutter/Dart命令工作目录均为 `/Volumes/data/App Development/Pourlune/build/page-transitions-baseline/app`，固定Flutter3.47.2/Dart3.13.2，串行执行且设置 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`。纯核心/题库/资源未改，不重复全部B05或发布检查；没有运行或宣称远端CI通过。

宽度360、高568、2倍字号：home/chapters/daily/collection/scene/settings/rules渲染与Reset取消通过；既有320px七瓶尺寸/语义、保存失败/幂等/返回/暂停防重/章节滚动/系统减少动态/销毁回归均在200项中覆盖。普通动作保持页面身份，新实例切换重建边界正确。

实际原生入口是独立 debug LiveWidgetController（Flutter pointer events +真实sqflite），不是integration_test运行器通过。驱动在业务busy结束后额外观察320ms才截图；观察时间及开始录屏前QA停留均只在测试入口，不影响产品输入/导航。受控主线002/004/020/060、每日/重玩参考解和SQLite故障hook明确标注，不称自然玩家进度、真实磁盘满或SDK成功。

逐步/逐边记录见 [native-coverage.md](../evidence/page-transitions/native-coverage.md)，摘要与页面集合见 native-summary.json。主录像 iOS109.4秒、Android受screenrecord180秒上限约180秒；Android路线尾部减少动态/返回已另补录实际系统按键和截图，不能称单一录像覆盖全部185秒左右运行。两端contact-sheet.jpg、18张关键PNG及scroll-before-after/comparison.jpg已打开复核。完整原始录像保留根build/page-transitions/，压缩审阅版在evidence目录。视频无音轨，不从视频声称音效/触觉通过或帧率达标。

T04分支验证区分：暂停、重开、Reset取消、每日历史/未来、隐私、加瓶说明关闭及保存失败重试已双端实际操作；信息不可用、主线/跨日替换、待SDK确认奖励实例恢复使用共用官方模态路由和既有host分支覆盖，未逐一伪造native SDK场景。原生广告/UMP/外部浏览器不属于本层自绘动画。

旧流程和QA入口修正历史保留 preparation-and-history.md、runner-*-error.json、native-coverage-pre-scroll-fix.md；旧失败不算通过。设备意外关闭导致Android早期取证中断已重跑，未归因为App崩溃。最终以run/route.json和当前manifest为准。

## 冻结、职责与验收边界

原开发15:27明确释放后接手；后续按 ui-transition-handoff.md 串行交换CLI窗口。board_page.dart/bottle.dart 未由本任务修改，已按哈希释放给完整棋盘任务。后续全部转场验证只使用根 build/page-transitions-baseline/app 冻结副本，不混入其新代码。源码/资源/core/native快照在 build/page-transitions/source-freeze.zip，候选安装包在 build/page-transitions/，清单见 source-freeze.json / artifact-manifest.json；已在最后修复后刷新匹配；仅供本次转场冻结基线。后续完整Flame棋盘/容量同步代码不在本候选内。

iOS：Pourlune-Transitions-20261022 / 3497E78D-608C-415C-8326-26E46F1B6E29，bundle dev.pourlune.transitionsValidation；Android：独立AVD Pourlune_Transitions_API36 / emulator-5586，dev包名但独立安装；仅清理 page_transitions.sqlite。普通/Firebase/Flame安装和b04_review_r2.sqlite未触及。原生入口会受控准备main002/004/020/060、解完每日/重玩参考解；不称自然玩家进度或真实SDK奖励。

这是作者运行交付，不是独立验收。重点AC-11/12/16/24/28/31/32/33/34。代表真机帧率、物理触觉、视频音频、真实广告/UMP与商业权属未由本批验证；debug模拟器录像和无错误记录不构成性能达标。静态设计/文档确认、运行通过、架构验收分别记录。不stage/commit/push，不改tracking/plans/review，不合并main或发布。

## 审阅入口

- [iOS关键画面](../evidence/page-transitions/ios/contact-sheet.jpg) / [Android关键画面](../evidence/page-transitions/android/contact-sheet.jpg)
- [滚动修复前后](../evidence/page-transitions/scroll-before-after/comparison.jpg)
- [iOS录像](../evidence/page-transitions/ios/navigation.mp4) / [Android主录像](../evidence/page-transitions/android/navigation.mp4) / [Android系统返回补录](../evidence/page-transitions/android/system-back-reduced.mp4)
- [冻结哈希](../evidence/page-transitions/source-freeze.json) / [候选清单](../evidence/page-transitions/artifact-manifest.json) / [相对M检查点的任务专属diff](../evidence/page-transitions/task-only-final.patch)

## T-R01 追加修复交付

原生启动白底已修复为既有#82DFF1与居中针织字标，Flutter初始化壳同色，不增加产品等待或假进度。正常lib/main.dart的独立身份候选已双端构建，并完成iOS/Android明暗模式四段同安装进程冷启动录像、正常首页与命名库核对；19项聚焦测试、analyze、format及27项assets单元检查通过。Android夜间系统等待命令超时后实际进入首页，未记为启动性能通过；最终旧资源清单只有几何源码文件SHA漂移，未刷新掩盖。完整范围、异常、原始证据和哈希见[T-R01修复报告](../evidence/page-transitions/T-R01/repair-report.md)。本段为作者补交，整批独立验收仍由架构方记录。
