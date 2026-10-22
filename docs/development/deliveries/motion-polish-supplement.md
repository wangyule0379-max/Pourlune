# M 定向补证 MS01–MS03（执行交付）

2026-10-22，独立验收待架构；不宣布 M 整批通过。生产代码、产品规则和 SDK 配置没有修改。新增两个 QA/test Dart 文件；来源/候选散列见 [freeze.json](../evidence/motion-polish-supplement/freeze.json)，原始样本及日志均在同目录。沿用已验 T/FB，不重复整批或拼接旧端点作性能提升。

MS01：专属 debug QA 入口实际调用正常 product.main/Bootstrap，使用正式60题库、真实 Flutter 指针及原生 sqflite。新身份 iOS dev.pourlune.motionSupplementValidation / Android dev.pourlune.motion_supplement，精确 motion_supplement.sqlite；iOS255890/iPhone17/iOS26.5、Android5588/Pourlune_FullBoard_API36。未操作用户F9或其窗口。每端安装一次，先作一次不计数准备，再三次 terminate/force-stop 后启动；PID均不同，安装路径/内核/安装时间不变，旧FB数据库SHA均不变，见 native-summary.json。

每轮测量前为同一已建schema的空进度/Home欢迎状态；手势后必须 board+clean、main001、revision0、真实保存完整快照一致、一个新实例和一次snapshot写入，之后仅重置新QA库以准备下轮。不是新安装首次启动、物理设备或发布性能预算验收。

下表单位ms，从同一 Dart Stopwatch 入口起算。宿主launch命令耗时单列，没有加减或冒充 native 首像素；iOS命令返回PID，Androidstart命令返回启动请求，两者不可横向比较。

|样本|初始化壳post-frame|Home post-frame|按钮enabled/hitTestable|首次控制器响应|首次接受并落盘导航|宿主launch命令|
|---|---:|---:|---:|---:|---:|---:|
|ios 1|290.502|583.521|599.676|725.511|739.983|204.262|
|ios 2|288.116|582.568|597.945|721.165|771.824|182.716|
|ios 3|255.761|608.066|622.390|741.098|839.716|214.174|
|android 1|709.464|1703.089|1727.938|1785.840|2152.925|133.292|
|android 2|772.441|1846.431|1874.615|1956.936|2322.867|116.794|
|android 3|393.919|2341.299|2367.078|2425.417|2875.260|77.612|

探测请求间隔5ms，实际间隔见每份home_probe_timestamps_us；该阶段可能仅一个采样（Home出现已满足），不是5ms精度保证。探测包含widget查找/命中测试/监听器开销，未测量其独立成本；Dart起点包含guard/binding/观察器建立。首post-frame只证明Flutter提交回调，不是像素呈现。enabled/hitTestable只是代表按钮几何与回调条件；此时祖先FadeTransition含0.0，不能称Home已完全可见。实际注入一次pointerdown、请求16ms保持后up，之后观察控制器/SQLite导航；首次观察接受不是理论最早可交互。before_gesture保留尺寸/DPR/字体与设置条件。

MS02：motion_supplement_keyboard_test.dart四项（iOS/Android × Enter/Space），使用实际原生按钮、Flame棋盘、GameController和SQLite，hold真实写事务令busy持续。一次Start只创建一个实例；一次有效瓶动作只提交一个revision/history/snapshot；busy/disabled、重复按下、release及焦点转移请求后均不增加提交；焦点请求未另断言primaryFocus实际转移，因此实际焦点变化覆盖仍有限。Flutter默认Shortcuts实际支持这两键；不是物理键盘或读屏设备验收。没有发现需要改生产代码的失败。

MS03：一次能力核查完成，具体见 [audio-capability.md](../evidence/motion-polish-supplement/audio-capability.md)。没有实际音轨/听感/音画同步或物理触觉证明。未重试既有Cocoa513/EPERM，不截图、录屏、录音或改权限；未用日志冒充实际声音。不得据此阻塞后续Beta工程准备。

实际检查（app工作目录，串行 FIREBASE_ANALYTICS_WITHOUT_ADID=1）：新增两文件dart format通过；flutter analyze --no-pub无问题；flutter test --no-pub test/motion_supplement_keyboard_test.dart 4/4；隔离git-archive副本flutter pub get --enforce-lockfile、双端debug构建均通过。两端三次原生样本全部满足实际接受/存储断言，native-host.log以MS01_BOTH_PLATFORMS_PASS结束。build-candidates.py/run-native.py是本次精确路径的执行记录，不是通用重装工具；勿在未核验身份/安装状态时盲目重跑。

失败记录：初次相对路径错误及selected字段编译错误均为新测试编写问题，已改正，保留原日志；未造生产RED。初次宿主执行发现独立iOS255890已Shutdown，断言在安装前停止；仅headless boot本专属设备后继续，未查明外部关机原因、不归为App崩溃。旧FB库、普通审查库和用户F9无写入操作。没有新视觉/音轨证据，也没有扩大缓存、全场景Flame或产品行为。

作者未stage/commit/push；计划/tracking/独立review归架构。当前补证构建与设备命令均已结束，CLI RELEASED；继续BR01时将明确领取同一串行窗口。

一次fresh只读终审：Critical0/Important0/Minor1。Minor为键盘用例发出焦点转移请求但未直接断言primaryFocus变化；保留为证据覆盖限制，不扩成生产缺陷或重复T/FB。当前其余once/busy/持久化断言有效。

## MS-R01 独立复验后的最小修复

独立4失败暴露真实的测试时钟边界：宿主3秒到期时仅推进31×16ms Flutter虚拟帧，动画尚在正常前进。仅新增键盘测试改为同样16ms/3秒Flutter测试时钟的pumpAndSettle，并显式断言motion=null/busy=false；其余once/持久化断言不减。原冻结不覆盖，新隔离副本与根工作区各4/4通过。具体RED、观测、修复及新SHA见[MS-R01报告](../evidence/motion-polish-supplement/MS-R01/repair-report.md)。生产Dart/原生QA入口未变，整体仍待架构独立验收。
