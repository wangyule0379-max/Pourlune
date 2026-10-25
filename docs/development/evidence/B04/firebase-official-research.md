# B04 Firebase 官方接入研究

研究日期：2026-10-22（Asia/Taipei）。范围：B04-01/06/07，AC-34/36。此文件是官方资料与发布源码核对，**不是 Firebase 初始化、设备收件或控制台验收通过**。研究仅读取工程、公开文档与 pub.dev 发布档案；未使用账号，未运行 Flutter/pub/build/Simulator，未创建或关联 Firebase 项目。

## 工程现状与版本选择

研究起点的 `app/pubspec.yaml` 尚无 Firebase 依赖；`git ls-files '*firebase*' '*Firebase*' '*google-services*' '*GoogleService*'` 无结果。`production-handoff.md` 的项目归属仍为未核验；未发现可供接入的 `firebase_options.dart`、`google-services.json`、`GoogleService-Info.plist`。这里的“未发现”仅指仓库及已交接记录，不推断用户账号内没有项目。

当前 Android minSdk=24、Java17、AGP9.1.0、Gradle9.3.1；iOS deployment target=15.0，Xcode 项目已使用 `FlutterGeneratedPluginSwiftPackage`，无 Podfile。工具链基线 Flutter3.47.2/Dart3.13.2；B03 交付记录的 Xcode 为26.6，本次没有重新测量环境。

2026-10-22 直接读取下列官方发布 API 的 `latest`、`published`、`pubspec.environment` 和依赖，并在内存中展开对应 tar.gz 核对源码。四个版本均在2026-10-15发布，无 prerelease 后缀；建议在应用 pubspec **精确固定**，由执行方生成并保留锁文件。

|插件|固定版本|Dart / Flutter 要求|与 Core 的关系及发布来源|
|---|---|---|---|
|firebase_core|5.0.0|^3.6.0 / >=3.27.0|[发布 API](https://pub.dev/api/packages/firebase_core)、[版本说明](https://pub.dev/packages/firebase_core/versions/5.0.0)|
|firebase_analytics|13.0.0|^3.6.0 / >=3.27.0|core ^5.0.0；[发布 API](https://pub.dev/api/packages/firebase_analytics)、[版本页](https://pub.dev/packages/firebase_analytics/versions/13.0.0)|
|firebase_crashlytics|6.0.0|^3.6.0 / >=3.27.0|core ^5.0.0；[发布 API](https://pub.dev/api/packages/firebase_crashlytics)、[版本页](https://pub.dev/packages/firebase_crashlytics/versions/6.0.0)|
|firebase_remote_config|7.0.0|^3.6.0 / >=3.27.0|core ^5.0.0；[发布 API](https://pub.dev/api/packages/firebase_remote_config)、[版本页](https://pub.dev/packages/firebase_remote_config/versions/7.0.0)|

这些约束与项目工具链匹配，**不代表已执行依赖解析或构建兼容性验证**。原生版本不能仅凭 changelog 概括为同一个 Apple SDK：

- [Core5.0.0发布源码](https://pub.dev/api/archives/firebase_core-5.0.0.tar.gz) 的 `android/gradle.properties` 固定 Firebase BoM35.0.0，`android/local-config.gradle` minSdk24 / Java17；各插件通过 Core 获取 BoM。现有 Android24 无需因本组插件再提高最低版本。Core Android 实现明确兼容 AGP9 内置 Kotlin 的判断，但与本工程 AGP9.1 的实际构建仍须验证。
- 同一档案的 `ios/firebase_core/Package.swift` exact Firebase13.0.0、iOS15；其 CocoaPods `ios/firebase_sdk_version.rb` **仍固定12.19.0**，podspec 同样 iOS15。Analytics13 / Crashlytics6 / RC7 的 SPM manifests 也固定13.0.0。当前工程应沿用 SPM，不混装两份 Firebase。[Core changelog](https://pub.dev/packages/firebase_core/changelog)
- Firebase13.0.0 已停止 CocoaPods 新版本发布；SPM 需要 Xcode26.2+、Swift6.2.3 编译器与 Swift tools6.2.1。iOS最低15.0。项目所记 Xcode26.6 满足文档要求，实际解析仍须执行方验证。[Apple发行说明](https://firebase.google.com/support/release-notes/ios)、[CocoaPods迁移说明](https://firebase.google.com/docs/ios/cocoapods-deprecation)

## 配置缺失、可选初始化与离线

官方入口是拥有者在正确开发项目注册匹配的 iOS bundle / Android package，再由 FlutterFire CLI 生成平台配置。`firebase_options.dart` 的标识是客户端公开配置，不是服务账号；不因此把私钥或 CLI token 放入仓库。[Flutter设置](https://firebase.google.com/docs/flutter/setup)、[Firebase项目与配置](https://firebase.google.com/docs/projects/learn-more)

建议实现边界（项目设计建议，不是 Firebase 的自动保证）：

1. 未配置时返回明确 `disabled / missingConfiguration`；配置非法时返回 `disabled / invalidConfiguration`。不要用 `demoProjectId`、示例项目或格式正确的占位值冒充真实接入。也不要无条件调用 `Firebase.initializeApp()` 去赌原生资源存在。
2. 可选 `FirebaseOptions` 只从已交接的平台配置构造。最低检查必填 apiKey/appId/messagingSenderId/projectId 非空、无示例占位、平台 appId 类型一致，并核对原生 app 注册身份。格式检查只能减少错误，不能证明账号归属、项目存在或网络服务可用。不要打印整套配置或外部错误文本。
3. 先加载本地题库和 SQLite 并运行稳定页面，再异步启动可选服务；Firebase/RC 的成功不是进入本地游戏的条件。给初始化设有限应用超时，例如5秒；超时继续本地并报告 unavailable，不无限重试。
4. Dart `Future.timeout` **不会取消原生初始化**。使用启动代号/单次在途 future；晚到完成必须重新核对当前隐私状态、服务代号和配置，不得启用过期采集或触发广告。给原始 future 保留错误处理，不让晚到异常成为未处理错误。
5. 不把 `Firebase.initializeApp` 的完成当作网络/控制台成功。Analytics与Crashlytics上传、RC fetch各自有独立结果。无配置不建立实例，不取产品 singleton；缺失配置和失败可用替身/纯状态测试验证，收件不可验证。

尤其要防止原生早于 Dart：Android FirebaseInitProvider 可根据 google-services 生成资源自动配置；iOS Core5 的 `FLTFirebaseCorePlugin.swift` 在存在默认 plist 配置时会调用 `FirebaseApp.configure()`。因此仅在 Dart 同意页后调用开关，不足以证明首次启动前没有自动上传。原生默认必须先关闭。

## Analytics 与 Crashlytics 分别授权

UMP 的可请求广告状态不能代替这两个选项。分别持久化 unknown/denied/granted 和版本；unknown当未允许。不要在允许后补发未授权期间事件，也不要在 UI 重建时重发历史通关。Android与iOS均先加下表原生值，再接入 SDK。原生开关用 boolean，不能用字符串 `"false"`。

|用途|Android `<application>` meta-data|iOS Runner Info.plist|
|---|---|---|
|首次启动关Analytics|`firebase_analytics_collection_enabled=false`|`FIREBASE_ANALYTICS_COLLECTION_ENABLED=false`|
|首次启动关Crashlytics自动上报|`firebase_crashlytics_collection_enabled=false`|`FirebaseCrashlyticsCollectionEnabled=false`|
|默认拒绝分析存储|`google_analytics_default_allow_analytics_storage=false`|`GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE=false`|
|默认拒绝广告存储|`google_analytics_default_allow_ad_storage=false`|`GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE=false`|
|默认拒绝广告用户数据|`google_analytics_default_allow_ad_user_data=false`|`GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA=false`|
|默认拒绝广告个性化|`google_analytics_default_allow_ad_personalization_signals=false`|`GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS=false`|

原生Analytics关闭与持久化优先级见 [Android采集配置](https://firebase.google.com/docs/analytics/android/configure-data-collection)、[Apple采集配置](https://firebase.google.com/docs/analytics/ios/configure-data-collection)；默认同意项及更新顺序见 [Android basic consent](https://developers.google.com/tag-platform/security/guides/app-consent?consentmode=basic&platform=android)、[Apple basic consent](https://developers.google.com/tag-platform/security/guides/app-consent?consentmode=basic&platform=ios)。不要用 permanent deactivated 开关实现可在设置里重新打开的授权。

Analytics允许后，先 `setConsent(analyticsStorageConsentGranted: true, adStorageConsentGranted: false, adUserDataConsentGranted: false, adPersonalizationSignalsConsentGranted: false)`，再 `setAnalyticsCollectionEnabled(true)`；这只授予产品分析，广告用途另有对应流程。每次事件发送前重新核对有效选择。撤回时先在应用内关事件门、保存选择，并调用 collection=false 与四项 denied；若原生调用失败，保留“同步失败待重试”，不能宣称 SDK 已停止。原生运行时 collection/consent值会跨启动覆盖 plist默认，后续启动应协调本地与原生状态。

可关闭自动screen reporting减少额外页面事件：Android `google_analytics_automatic_screen_reporting_enabled=false`；iOS `FirebaseAutomaticScreenReportingEnabled=false`。这不关闭其他SDK自动事件，不能在隐私说明写成“只有手工白名单事件”。[屏幕事件文档](https://firebase.google.com/docs/analytics/screenviews)

Apple若仅做无广告标识分析，Analytics13的SPM manifest支持环境变量 `FIREBASE_ANALYTICS_WITHOUT_ADID`（**判断是变量是否存在**，因此设成字符串false也会选择无AdId版本），依赖 `FirebaseAnalyticsCore`；CocoaPods另用 `$FirebaseAnalyticsWithoutAdIdSupport`。这只影响Analytics依赖，不能推断AdMob也无IDFA或无需适用ATT。[Analytics13发布源码](https://pub.dev/api/archives/firebase_analytics-13.0.0.tar.gz)

### Crashlytics 的重要限制

官方默认会自动处理原生崩溃；关闭自动上报后仍可能本地保存崩溃。启用会上传缓存，包括启用前捕获的报告；运行时true跨启动保存。官方Android与Swift API对false均注明下一次运行才应用。因此“同意时true、撤回时false”不能保证当前会话即时阻断原生自动上传。[Flutter opt-in与缓存说明](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)、[Android API](https://firebase.google.com/docs/reference/android/com/google/firebase/crashlytics/FirebaseCrashlytics)、[Swift API](https://firebase.google.com/docs/reference/swift/firebasecrashlytics/api/reference/Classes/Crashlytics)

为B04提供一个保守可实现方案：**自动上报始终false，不调用true**；Dart `recordError` / `recordFlutterError` / custom logs / keys 和 `sendUnsentReports()` 都经Crashlytics专用许可门，撤回立即停止这些应用调用。需要上传缓存时显式说明并取得该范围同意；拒绝时调用 `deleteUnsentReports()`，不要把之前未知/拒绝时缓存的报告悄悄包含在新许可中。若选择普通自动上报模式，必须在交付里记录撤回下一启动生效及缓存上传范围，不能称即时撤回已通过。

`sendUnsentReports`与`deleteUnsentReports`的Dart Future只表示原生调用完成/请求排队；当前插件Android和iOS包装都没有网络送达或磁盘删除完成回执。**不能靠await delete后立即send，声称已按同意时代精确切割缓存**。永久自动关闭方案也不能撤回已排队上传，不能声称不会有原生本地捕获；如果产品要求连本地捕获也禁止，则需延迟/控制原生Firebase配置，并另做两端验证，不由这组开关自动满足。[Crashlytics6发布源码](https://pub.dev/api/archives/firebase_crashlytics-6.0.0.tar.gz)

错误钩子应保留Flutter原始错误呈现/既有handler，异步handler不吞掉未处理异常。传入Crashlytics的异常文本需有固定类别；不要直接上传含SQL绑定值、棋盘dump、支持邮箱、反馈正文或URI的任意 `error.toString()` / `FlutterErrorDetails.toString()`。可保留经过审查的stack和有界上下文（operation/error_category/app version），不设置用户ID或邮件。安装/设备信息由SDK自带，不能因业务字段少就称零个人数据。[Firebase隐私资料](https://firebase.google.com/support/privacy)

## Remote Config：默认、严格验证与生效边界

官方要求内置默认值；fetch与activate分开，网络不可用使用已激活值/默认值。Analytics是受众和用户属性条件的依赖，不是开启Analytics采集的授权。B04采用固定参数和无用户属性条件即可；不为条件命中绕开分析拒绝。RC仍使用FirebaseInstallationID，不能把Analytics拒绝写成“Firebase完全不处理设备数据”。[Flutter RC设置](https://firebase.google.com/docs/remote-config/flutter/get-started)、[参数与条件](https://firebase.google.com/docs/remote-config/parameters)、[隐私数据清单](https://firebase.google.com/support/privacy)

项目建议参数仅包含预实现功能：广告总开关、插屏开关、激励开关、问题题目ID/版本列表；内置默认显式定义，配置缺失/坏值不能改变现有产品频控规则。按项目当前是否允许测试广告选择总开关内置值，不能用远端值绕过本地SDK能力、授权、前台、冷却或真实就绪条件。首版无需把180秒/3首次通关/保护关等已确定规则做成远程任意可写数值，更不要引入未确认4次/8次上限。

- `setDefaults`只接受bool/string/number；JSON需字符串传输。`getBool/getInt`不是严格校验：RC平台接口3.0.7源码里bool只认true/1，其余字符串静默false；非法int/double静默0。因此读取raw string/source，按参数白名单严格解析true/false、有限整数范围、受限JSON结构与已知题目ID，任何非法字段保留对应上次有效值/内置值，拒绝不完整危险更新。未知键忽略，有效应用快照与原生激活缓存分开，以免重启加载坏缓存。[RC7源码](https://pub.dev/api/archives/firebase_remote_config-7.0.0.tar.gz)、[平台接口3.0.7源码](https://pub.dev/api/archives/firebase_remote_config_platform_interface-3.0.7.tar.gz)
- 例如SDK `fetchTimeout=5s`、production `minimumFetchInterval=12h`，并另设应用层超时；这两个数字是项目建议，不是已测量的性能结论。**不能设0以为不等待**：RC7会把 `fetchTimeout.inSeconds==0` 改为60秒。一次fetch失败/超时保留上次有效值，不清空进度。不需要为首版增加常驻实时连接；需要时也在安全边界activate。[RC加载策略](https://firebase.google.com/docs/remote-config/loading)
- 远程关闭广告立即阻止未来load与show，销毁尚未展示缓存并使在途load过期；不能自动展示迟到load。已经开始展示的会话保留回调关联；已获奖励确认及待写入重试必须继续按原实例、request去重落盘。关广告不是撤销已经确认奖励的条件，既有奖励恢复仍可操作。
- 题目停用只影响新的开启入口；不给进行中实例换题、删瓶、清进度、自动跳关。新参数也不得扩大题库或执行远程代码。

## 最少事件与去重口径

字段以 `PRD-supplement-v1.1 §11` 为准；不用任意Map扩展，定义固定事件/字段白名单与有限枚举。事件名/参数应遵守Firebase命名规则，标识与字符串有长度上限，计数/耗时有范围，布尔参数转0/1，不传嵌套业务对象。[Analytics13事件API与限制](https://pub.dev/documentation/firebase_analytics/13.0.0/firebase_analytics/FirebaseAnalytics/logEvent.html)

|事件|最少字段与发送时机|应用层幂等键|
|---|---|---|
|puzzle_start / puzzle_complete|mode,puzzle_id,version,instance_id,first/replay；complete另含有效前台时长、步数、辅助计数、extra_bottles；业务提交后|event+instance|
|tutorial_complete / tutorial_skip|tutorial_version,step|event+tutorial_version|
|hint_result|有界result与duration_ms；结果过期不误记为新局提示|event+hint task|
|interstitial_check|completion_id,累计资格,有限原因|event+completion|
|ad_impression / ad_dismiss / ad_error|request_id,format,result；实际展示回调才算impression|event+request；error可另带固定阶段|
|reward_confirmed / reward_granted|request_id,原instance_id；确认与到账分开，granted在事务成功后|event+request/实例权益|
|save_failed / save_recovered|operation,error_category；恢复对应一次实际失败|event+save operation|
|collection_piece_granted|scene_id,piece_id,first|event+归属业务记录|

仅发匿名业务随机ID与静态题目标识，不发完整棋盘、存档、邮箱、反馈、原始SDK error message、用户账号或自由文本。按稳定业务ID做应用去重并有持久化边界；SDK的logEvent完成不证明服务端收到，也不提供跨崩溃“严格恰好一次”业务保证，禁止把事件上传放进通关/奖励事务的成功条件。未允许时直接丢弃统计意图，不保存待授权后补发队列。

若同时启用Analytics与AdMob，SDK集成也可能自动产生广告事件；需在真实项目检查，避免把手工同名ad_impression与SDK自动事件混作两次实际展示。AC-36应检查业务事件来源与幂等键，而非仅看调用次数。

## 原生配置要求与实际可验证范围

Android真实接入应在正确variant包含匹配的google-services.json，应用Google services与Crashlytics Gradle插件；目前官方示例固定Google services4.5.0、Crashlytics3.0.8（其文档最低AGP8.1、Google services4.4.1）。不要照抄示例把本项目AGP降成8.1.4。无配置的本地构建不无条件应用会要求JSON/上传的任务，不伪造配置和build ID；未来真实Crashlytics需要完整build ID/符号映射，不是只有Dart Options就算接好。[Android Crashlytics原生设置](https://firebase.google.com/docs/crashlytics/android/get-started)

iOS沿当前Flutter SPM解析插件；真实Firebase注册的GoogleService-Info.plist需与开发身份匹配并进对应target。Crashlytics还需dSYM产生/上传脚本与正确inputs，符号上传与玩家报告上传是两类行为；无配置构建应跳过关联项目的上传，不把SDK能link当作符号已上传。真实配置到位后用FlutterFire重新核对原生改动。启用obfuscation/split-debug-info还须按官方Flutter符号步骤处理。[Flutter Crashlytics设置](https://firebase.google.com/docs/crashlytics/flutter/get-started)、[Apple dSYM设置](https://firebase.google.com/docs/crashlytics/ios/get-started)

|现在可独立实施/验证|必须等真实交接后的证据|
|---|---|
|缺失/非法配置disabled；异步超时/迟到隔离；事件schema/许可/幂等；raw RC严格解析；关广告不取消确认奖励；原生默认静态检查；真实插件依赖构建/无配置离线启动（由执行方运行）|双方应用注册身份与项目权限；真实初始化和授权前后网络行为；Analytics DebugView/控制台事件；真实测试崩溃且符号可读；缓存报告授权/撤回时序；已发布RC有效值/坏值/离线缓存生效；控制台正式设置与数据披露|

本研究没有运行上述应用检查。没有真实Firebase配置时，可以交付disabled降级和真实插件编译证据；不能写成Firebase真实联调通过，不登录其他项目、不借用样例配置、不把替身收件冒充控制台收件。
