# Flame 两瓶倒水与拼片入藏样板交付

2026-10-22。S01–S06 样板实现及下述运行取证已交付，**待产品架构独立验收**。本文件不是独立通过报告，也不是用户对动效效果满意的确认。完整棋盘扩展仍须等用户确认；M01–M08 是独立的未完成检查点。没有提交、暂存、推送、合并或发布。

## 先看效果

- [iOS 最终录像，38秒](../evidence/flame-sample/ios/route-review.mp4)
- [Android 最终录像，44秒](../evidence/flame-sample/android/route-review.mp4)
- [iOS 四单位倒水关键帧](../evidence/flame-sample/ios/screens/u4-lr-pour.png)、[Android 反方向倒水](../evidence/flame-sample/android/screens/u4-rl-pour.png)
- [拼片飞行](../evidence/flame-sample/ios/screens/patch-flight.png)、[实际贴合](../evidence/flame-sample/android/screens/patch-attached.png)
- [全部证据索引与复现说明](../evidence/flame-sample/README.md)

录像来自实际运行的 debug Simulator/Emulator；正常速度，仅裁掉尾部空闲。已从导出 MP4 解码并检查关键帧，不以视频编码帧率代替应用帧率。

## 已下载、入口与隔离

Flame **1.38.2** 已实际下载并精确锁定 pubspec.yaml / pubspec.lock；唯一新增传递依赖为 ordered_set8.0.1，没有升级其他包。该版要求 Dart≥3.11 / Flutter≥3.41，项目保留既定 Flutter3.47.2 / Dart3.13.2。[官方版本](https://pub.dev/packages/flame/versions/1.38.2)。未加入物理引擎或新音频框架。

普通可操作入口，在 app/ 下：

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter run -t lib/development/flame_sample_main.dart -d <专用QA设备> --dart-define=POURLUNE_DATABASE=flame_sample.sqlite --dart-define=POURLUNE_AD_MODE=disabled
```

自动取证入口为 `integration_test/flame_sample_app.dart`，相同 defines，debug 构建。使用真实 Flutter 指针事件、Flame 与 native sqflite；不是 DDS 集成测试 runner 通过。默认 main.dart 不导入样板。

|项目|实际值|
|---|---|
|iOS|Pourlune-Motion-20261022，iPhone17 / iOS26.5，UDID `9B172C50-E5CB-4F3F-8F16-0A3DB04F495D`|
|Android|Pourlune_Motion_API36，emulator-5584，Android16/API36，1080×2400，420dpi|
|身份|iOS `dev.pourlune.pourluneDev`；Android `dev.pourlune.pourlune_dev`，仅安装到上述专用设备|
|本地库|`flame_sample.sqlite`（两瓶）、`flame_patch.sqlite`（正式奖励QA）|
|取证协议|各自 getDatabasesPath()/flame-sample；iOS 位于 Documents，Android 位于 databases|
|SDK范围|广告 disabled，未初始化本样板的 Firebase 服务；既有 Firebase 验证安装未动|

已安装的最终样板可直接操作：选 1–4 units、切方向、点源瓶再点目标、点空白/同一源瓶取消；Reset sample / Replay pour 只改变隔离QA实例。Patch placement 页先 Complete prepared level，再 Place patch；Replay visual 只重放表现。Reset QA reward 只清本样板奖励库。QA: fail next save 可验证 Retry 门控。

构建候选与源码冻结位于项目根 `build/flame-sample-candidates/`，原始录像在根 `build/flame-sample-raw/`，均被 Git 忽略，独立于 app/build，后续 App UI 的 flutter clean 不会清掉它们。[二进制哈希](../evidence/flame-sample/artifact-manifest.json)、[源码冻结信息](../evidence/flame-sample/source-freeze.json)、[逐文件哈希](../evidence/flame-sample/final-source-manifest.json) 可用于共享页面继续修改后的复核。冻结包不含签名、Firebase配置或凭据。

## S01–S06 对应实现与证据

|编号|实现与实际验证|边界|
|---|---|---|
|S01|独立 debug 入口、命名库/设备、重置/重放/手动按钮；依赖锁定；双端实际构建。原 Flutter 同设备/debug 的 before 录像及启动数据保留于 motion-polish/before/|原 Flutter 对照是完整棋盘，负载及 ready 端点不同；没有等负载两瓶性能基准，不能推断提速|
|S02|75/150ms 按下反馈、130ms 抬升、200ms 弧线接近、90ms 对准、按单位变长的倒流、210ms 回正及100ms落稳。瓶体前后图层不变；世界水平液面按多边形面积裁切；水流首端与源瓶口共用同一变换、末端落在目标口内；在流液体也计入守恒。完成态取自原核心快照|自定义液面/流线/坐标实现；Flame只组织 loop/effects，不是流体物理模拟|
|S03|双端左右各1–4单位，共8例；取消、非法动作、有限220ms错误反馈、短液面回荡及3个有限流光；保持编织图层、同尺寸、容量刻度与符号。每端20张分阶段倒水关键帧|两个可见瓶是合法四瓶QA定义的0/2投影；隐藏瓶保留在核心状态；replay不授予首次通关奖励|
|S04|真实内置main1–4：标明QA的前三题合法结算，main4最后一步由原控制器真实倒入并原子结算。奖励回执、reveal确认均保存后才飞行；850ms曲线飞行＋160ms局部贴合回应，位置按原SceneArt slot等比contain；重访不重飞、不重发奖|QA准备不是两瓶夹具通关；动画完成只释放表现/声音，不写奖励、不再提交动作|
|S05|双端native路线验证保存失败/Retry、取消旧实例回调、减少动态、声音/音乐/触觉开关后免费操作；host验证连点、实例/revision/token、后台、销毁、窄屏2x字号、语义和Back保存失败门控。真实SQLite阻塞写入覆盖待保存拼片后台取消。减少动态未揭示/保存失败用实际渲染像素对比确认仍在来源处|native后台往返未另作完整平台场景矩阵；强退恢复实测见下。iOS原生AX仅两条瓶按钮无空白重复；Android无障碍服务遍历、真机听感/物理触觉仍未验|
|S06|最终双端各13项native操作路线、26张PNG及绘制时状态、录像、各3次同安装进程冷启、热切页、同安装强退/重启、UI/raster/资源诊断；每游戏仅拥有2张解码图，销毁释放至0，空闲暂停|debug模拟器诊断，不是60fps、真机性能或相对原渲染器改进通过。独立视觉/运行验收由架构另出报告|

## 实际检查

全部 Flutter CLI、pub/SPM及 iOS 构建串行；iOS 使用 FIREBASE_ANALYTICS_WITHOUT_ADID=1。执行目录明确如下。

|工作目录与命令|结果|
|---|---|
|app/：`flutter test`|**192项通过**，77秒；包括12项Flame widget、2项几何、2项隔离会话、9项音频及原有业务/页面回归。不是把输入轨迹伪装成集成runner结果|
|app/：`flutter analyze`|No issues，最终4.0秒|
|根目录：`dart format --output=none --set-exit-if-changed app/lib app/test app/integration_test`|103文件，0修改；未格式化生成依赖目录|
|packages/pourlune_core/：`dart test`|**30项通过**，含原正式90题参考重放/求解边界；不等于难度或真机验收|
|根目录：`.venv/bin/python -m unittest discover -s tools/content -v`|27项通过|
|根目录：`.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json`|3个工程夹具验证通过，release_gate=false；不代表内容发布门槛|
|app/：双端debug build，target及defines如上|最终iOS25.6秒成功、Android成功；Android保留现有FlutterFire未来Kotlin迁移警告，没有因此升级SDK|
|根目录：`flame_sample.py <平台> route --id final-ready-route`|iOS **13项/1523个FrameTiming**；Android **13项/1609个FrameTiming**；actual native gestures＋SQLite|

仅最终 `final-ready-route.json` 为这版双端最终路线。历史失败保留：PNG编码错过短阶段、复用指令ID读旧响应、重置后按钮尚未可点击等均在证据索引说明。最终驱动等待原生按钮 onPressed/onChanged 可用与50ms绘制稳定后只发送一次手势；没有靠重复点击掩盖问题。修复后的 instrumentation 又经 analyze、双端构建和最终native路线；业务代码与192项套件验证版本一致。

一次全量新上下文只读审查发现3项Important；空白取消一项由Minor提升为Important。四项都先观察有效失败，再修复并由192项完整套件验证：减少动态失败入藏像素、旧保存续体后台取消、双库偏好分歧、空白取消。无延期Minor；没有重派审查。[完整处理、裁决和审查未判断范围](../evidence/flame-sample/final-review-dispositions.md)。作者修复测试不是架构独立验收通过。

## 状态恢复与数据保护

最终同安装强退：iOS 在倒水约301.9ms、已保存干净状态时 SIGKILL，PID78090→78153；Android 约316.7ms时 force-stop并核对进程消失，PID21840→22064。均未在中间重装/清库。重启后比较两库完整 instance、saved、puzzle、棋盘、步数、撤销历史、设置、首通、回执、拼片与revealed，全部精确一致；表现无motion、不busy、显示完整已保存状态。未承诺恢复任何未收到/未落盘的奖励。

原普通安装与 `b04_review_r2.sqlite` 未启动、重装或清理；结束时只读SHA256仍为 `dc94bbfd1e8b10cda675f139a822c39e83dcc38bdf830c3a245d2221da9978c6`，与开始一致。[保护核验](../evidence/flame-sample/protected-database.json)。Firebase专用安装和诊断结论保持原状。

## 启动、帧耗时与释放：仅诊断

完整原始样本见 [diagnostics-summary.json](../evidence/flame-sample/diagnostics-summary.json)。进程冷启为同一次安装重启3个新PID，系统缓存未清理；从Dart main计时，排除native/pre-Dart开销，采样分辨率10ms。热进入各只有1次，端点是pointer-up→首个资源就绪绘制帧。

|数据|iOS debug Simulator|Android debug Emulator|
|---|---|---|
|首个就绪双瓶帧，3次范围/中位数|939.8–1329.5ms / 967.3ms|1836.6–2105.5ms / 1888.7ms|
|热切入拼片 / 回双瓶，各n=1|128.3 / 98.6ms|224.6 / 131.3ms|
|UI build p50/p95/p99/max，ms|5.467 / 16.821 / 23.217 / 48.299|7.479 / 29.834 / 61.074 / 184.199|
|raster p50/p95/p99/max，ms|0.762 / 1.325 / 2.103 / 6.991|11.741 / 20.548 / 33.154 / 149.445|
|build / raster 超16.667ms样本|78 / 0，n=1523|319 / 311，n=1609|
|约2.2秒空闲窗口|Flame update/render增量0/0、paused、2张图|Flame update/render增量0/0、paused、2张图|

这些统计混有debug/JIT、录屏、滚动、SQL、截图及指针脚本；**Android的本次p95已超16.667ms，不能判定帧预算达标**。图像、effect、订阅退出释放有测试与native路线断言；单次RSS波动不是泄漏排查。Android空闲仍收到133个framework FrameTiming回调（iOS为0），所以只确认Flame画面没有继续update/render，不宣称整个App无空闲帧或低功耗通过。

## AC覆盖与待验边界

|AC|本批证据覆盖|
|---|---|
|AC-01/02|原核心容量/颜色/标签规则保持；左右1–4倒入、守恒、同瓶/空白取消、拒绝不记步；没有把投影当正式关卡|
|AC-09/12|真实正式关卡QA回执与reveal保存，重放/重访无重复；双库同安装强退后奖励保持|
|AC-11|保存失败不假称已存，Retry；Back延后一次退出；reduced失败不显示已贴合。不是完整Next/广告路径复验|
|AC-31|320×568、2x字号主路径、符号/文字/真实按钮/语义、reduced像素、开关门控；不是全设备最大字号、TalkBack/VoiceOver遍历或真机感知通过|
|AC-32|只覆盖本样板连点与取消不重复动作/发奖；广告不在本批，不重新判广告AC整体通过|
|AC-33|双端实际同安装进程强退恢复完整棋盘/步数/撤销；过期token与实例/revision回归|

## 交接及裁决

继续共享checkout并保留未提交M成果，代价是按显式清单区分审查范围；四瓶投影保护核心契约，代价是不证明全棋盘；standalone原生取证保留实际手势/SQLite，代价是自定义instrumentation且不算runner通过；未提交源码/patch/SHA冻结替代作者提交范围，代价是架构需按冻结包审核。审查设置的其他边界与成本均已完整记录在审查处理文档中，没有静默丢弃。

页面/导航的后续 animations 工作交由 App UI 聊天，M交接记录见 [motion-polish-checkpoint.md](motion-polish-checkpoint.md)。本聊天不承担新页面转场，不回退原修改；Flame后续修复应优先限定 development/flame_sample*、对应测试/工具/证据。交付前核验源码/视频哈希后释放CLI和共享页面，释放状态以该检查点末尾为准。根build下冻结包/候选应用/原始录像及既有设备库请保留供独立验收。
