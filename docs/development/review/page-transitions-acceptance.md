# T01–T06 页面转场独立验收：当前环境通过

2026-10-22。最新结论：T01–T06 在当前模拟器/模拟设备范围通过；T-R01 白色原生启动阶段已关闭，保留轻微色阶与启动性能未验证。允许精准提交冻结候选及必要 M 依赖；完整 Flame 棋盘与组合回归仍未通过。以下保留首轮发现及复验记录。

## 精确候选与独立证据

源码冻结zip SHA256 `8cbcd2e50b05dbeaab56c14cc8b2bd10fa46ab672d9455ba446edc776e178500`；本聊天核对归档和冻结源码清单无漂移。不是当前包含全棋盘未验代码的主工作树。iOS安装候选35个关键文件全部与artifact-manifest匹配；Android安装base.apk SHA256 `5144557ba16e30f65573094a9f25bdfebd3974da1c7b6e5c3e5de2534e0d5ba4` 匹配。

独立在 build/page-transitions-baseline/app 运行 page_transitions_test、motion_primitives_test、motion_polish_test、startup_motion_test：17 passed；analyze无问题。日志在 page-transitions-evidence/。测试覆盖旧页输入/焦点/语义隔离、快速返回、后台与销毁、模态防重、应用减少动态、窄屏大字号、保存失败、实例与场景滚动位置。

本聊天重新启动两端已安装独立QA，实际跑102步/11个GamePage，各errors=[]；读取新route报告并比较动态dev实例ID，确认本轮新运行，四个固定进度夹具ID不应被解释为旧报告。iOS设备3497E78D-608C-415C-8326-26E46F1B6E29；Android emulator-5586 / Pourlune_Transitions_API36。只有page_transitions.sqlite被runner重置。

人工iOS操作：设置/减少动态关闭/规则/重复返回、重置确认取消、返回首页保留收藏与重玩、继续重玩/暂停/Home。真实语义树、按钮和显示状态均核对。作者双端录像由本聊天抽取关键时段审阅，和独立实际操作相互补充，不能称本聊天录制。独立录屏一次被系统Cocoa513/-12204权限拒绝，未绕过或重试。

## 逐项结论

|任务/关联AC|结论|独立依据|
|---|---|---|
|T01 页面/模态盘点|页面内通过，启动覆盖缺口|代码清点、11页面102步、T-R01|
|T02 官方animations依赖|通过|精确3.0.0锁文件、实际官方FadeThrough/SharedAxis/FadeScale、17测试与analyze；未顺带升级服务SDK|
|T03 页面接入；AC11/12/16/24|当前候选通过|控制器权威；页面/实例/场景key而非动作revision；不保留旧棋盘双实例；两端新流程|
|T04 模态；AC31/32|当前候选通过|暂停/重开/重置/替换/每日日期/隐私/额外瓶/许可证路径；返回值门控保留，旧页不透点，单模态门控|
|T05 生命周期/保护；AC28/31/32/33/34|已测范围通过|独立17测试+保存失败Retry原生流程；人工取消保持状态；不冒充VoiceOver实测|
|T06 启动衔接、双端交付|需修复|双端实际流程正常，但录像及native源码证实系统白色启动页跳到蓝色Flutter启动；正式main冷启动仍需补证据|

## T-R01（P2）：原生冷启动仍白屏

iOS `ios/navigation.mp4` 在约2.6–3.8秒为白色启动页，4秒才出现蓝色品牌画面。Android `android/navigation.mp4` 约3–4秒为白底图标，5秒仍在跨色衔接。这里是录像位置，不是性能计时或设备达标结论。独立抽帧：page-transitions-evidence/ios-launch-frames.jpg 与 android-video-frames.jpg。

冻结 `app/ios/Runner/Base.lproj/LaunchScreen.storyboard` backgroundColor RGB全1；Android `res/drawable/launch_background.xml` 使用white，NormalTheme又用系统背景。Flutter StartupView的蓝色页面不能覆盖引擎首帧前的原生阶段。原有问题仍属于本次“启动→首页连续背景”的要求，不应按新增范围搁置。

修复给App UI：保持现有美术，以匹配Flutter首帧的原生品牌底色和允许的静态资源衔接iOS及Android（包括Android12+系统启动主题、普通主题和夜间配置）。不得加延时/假进度，不改核心规则或服务。实际查官方平台资料，双端重新取原生冷启动到首页证据；须包含正常main入口的专用QA身份/库，不只测试runner。保留当前页面内路线结果，仅复跑受影响检查，再由架构独立复验。

## 共享M与后续提交边界

审查了冻结候选依赖的M启动资源预热、按钮反馈、成功入场、旧BoardView入场和单位相关倒水时长；本轮未把M01–M08整体标完成。T候选task-only.patch相对M检查点，并非可直接套HEAD。通过后需按冻结版本明确纳入必要已验依赖，不能git add整个app夹带原开发正在写的Flame全棋盘、容量修复或控制器变更。

完整棋盘FB01–FB08、FS-M01容量同步与两批组合回归均仍待独立验收。模拟器debug不证明代表真机FPS、音触觉或读屏质量。受控进度/参考解/sqflite故障hook不等于自然通关、磁盘满、SDK成功或进程恢复。Firebase none与广告disabled；普通审查库、原UI及FirebaseQA未操作。


## T-R01 独立复验（2026-10-22）

### 实际范围与来源

复验正常 `lib/main.dart`，源码归档 SHA256 `cc3be956884486381aab47208aa330b5becab67110882e46ab1ffb4f85113013`，在 R01 冻结副本运行检查。正常主入口仅通过独立 QA 身份 `dev.pourlune.transitionsr01` 和 `ui_transition_r01.sqlite` 隔离，不使用路线测试 runner 代替启动。源码校验发现的三个差异已解释：归档含 3.47.2 的 `.flutter-version`，展开构建目录遗漏该文件；两项 Android 文件是已记录的 QA applicationId/activity overlay，生产提交保持 HEAD 身份配置。没有凭差异列表直接宣称全源码一致。

本聊天核对安装 iOS 346 个文件哈希均与交付候选一致；Android 已安装 base.apk SHA256 `6182ed96de58ca3e583276b36efb4954ed0ad1516bf5747bc44abda780e9591c` 与候选相符。独立 iOS 同安装 terminate/launch PID 54079 后实际点击 Start 进入 Level 1/tutorial，正常主入口可交互。独立 Android 同安装 force-stop/start 后 `am start -W` 超时（13231ms，UNKNOWN），当时仍显示蓝色品牌页；随后实际截图已进入 Start 首页。该异常未通过重跑覆盖，不作启动耗时达标结论；也不据此推断永久启动失败。

### 检查结果

- 本聊天在冻结副本独立运行 startup_shell、startup_motion、motion_primitives、motion_polish、page_transitions：**19 passed**；analyze 无问题。新增启动错误 Retry 在窄屏 2 倍字号可达，原转场输入/语义/返回和保存门控回归通过。
- 独立资源/native 检查 **27 passed**，startup assets check 通过。两份清单与原清单逐字段核对，仅 scene_art/knit_components 源码 SHA 更新，资源、几何数字与原图保持一致；不会通过全量刷新掩盖漂移。
- 本聊天检查双端明/暗四段完整冷启动录像及抽帧。白色原生阶段已被蓝色品牌页替代，接入 Flutter/Home；原生普通和夜间背景一致，无额外计时或假进度。Android API36、iOS Simulator 现有环境范围通过。录像为作者提供，本聊天独立审阅；iOS 额外关键帧由本聊天抽取。未重新尝试先前被权限拒绝的录屏。
- Android 原生实现与 Flutter 官方启动文档的系统 splash 退出和 WindowCompat 接法一致；没有更改 SDK 安全设置。参考：https://docs.flutter.dev/platform-integration/android/splash-screen 。

### 保留问题和结论边界

**T-M01 / P3：iOS 原生→Flutter 蓝色仍有轻微色阶。** 同一录像独立抽帧的背景采样约 (81,223,245)→(118,219,239)，虽然源码都声明 RGB(130,223,241)，不能据此声称最终像素完全一致；合成/编码贡献尚未分离。此项不再是原来的白屏跨色闪跳，记录为后续打磨。Android 启动等待超时（作者暗色一次、本聊天亮色一次）保留为调试环境启动性能待定位，未宣称真机性能通过。

T-R01 P2 关闭；T06 的已有双端明暗模式正常主入口衔接通过。T01–T05 沿用首轮独立 102 步/平台、11 页面及本次 19 项回归结果。API31 精确版本、Android12以前实际设备、代表真机启动时间/FPS、VoiceOver/TalkBack、真实音触觉不在本次通过范围。

### 精准提交

`T-R01/precise-submit-manifest.json` 的 55 个文件逐项哈希核对；生产实现来自冻结包，不覆盖原开发工作树。纳入 T 依赖的 M 资源预热、按钮/页面入场和倒水时长，不将 M01–M08 整批标完成。保留 HEAD 已修复的 b04_hint_events/b05_accessibility 测试；不纳入 QA 身份 overlay、完整 Flame 棋盘/样板容量修改、FB 测试或未验控制器改动。两批组合回归仍待完整棋盘交付。

独立证据：`page-transitions-r01-evidence/`；作者修复证据：`../evidence/page-transitions/T-R01/`。通过后精确实现 CI 需另核对，旧 CI 成功不能代替。

提交回读：实现及证据 `3cc35011bb0dceff783043c91be2e03db3761a39` 已推送 origin/codex/offline-foundation；对应 push CI39764795397 在 2026-10-22T10:40:18Z 为 in_progress，尚未远端通过。完整棋盘工作树保持未提交状态。
