# Pourlune 现有账号沿用预检

2026-10-22（Asia/Taipei）。执行起点 `2a80f47`；B05 已由架构方验收并提交 `be25ca0`，跟踪提交 `e264343`，本批不重做 B05。本报告及同名证据目录供架构独立复核，不写 tracking、plans、review 或 user-handoff。

## 结论与已确认边界

用户已确认 **Apple、Google、Firebase 沿用 FishPilot 现有账号**，不需要新建这三个账号。本批实际可读会话也能看到 FishPilot 对象。账号、Apple Team、Firebase 项目、注册 App、广告位和签名是不同对象：沿用账号没有授权把 Pourlune 接到 FishPilot 的业务项目或复用其应用配置。

本次仅只读访问与本地准备报告；没有下载/注入 Provider 配置、运行 `flutterfire configure`、注册项目/App、接受条款、扩大权限、创建/重置密钥、签名、安装/启动 App、上传或发布。生产源码、SDK/锁文件、FishPilot 工作区未改。无需因文档检查重复 Flutter/核心全量回归。

本批实际确认了三项接入缺口：Pourlune 尚无匹配身份的 Firebase 原生配置；iOS 尚无 plist 资源引用及 Crashlytics 符号上传阶段；工程尚无 dev/prod 原生配置选择和正式签名。AdMob 控制台连接被关闭，账号归属仍 unknown，不能推断为不存在或要求另行开户。

## 1. 来源、账号与签名的证据等级

|对象|本次事实与来源|能证明／不能证明|
|---|---|---|
|FishPilot 当前源码|旧目录 AGENTS 指向 `/Users/wangyule/.codex/worktrees/fishpilot-testflight-build12/FishPilot AI`；已读当前 AGENTS、PROJECT_STATUS、DECISIONS、相关 manifest。当前 main `154470266e4b66602129f3753cbd554a36bc52e6`，工作区 clean；本次 `git ls-remote origin refs/heads/main` 同 SHA|确认当前引用源；旧 checkout 不作为现状。历史发布状态使用各 manifest 原核验日期，没有重新查 FishPilot 审核/发布结果|
|Apple 账号 / Team|已登录 [Developer 账户](https://developer.apple.com/account) 显示 Apple Developer Program、个人、Team `T7U878Z8H6`、续订日 2027-09-17；[ASC App 列表](https://appstoreconnect.apple.com/apps) 可见 FishPilot App `6812821975`。FishPilot 与 Pourlune pbxproj 均记录此 Team|确认团队来源和可读会话；不是 Pourlune App ID 已注册、开发/分发签名成功或全部权限已获验证|
|Apple 协议提示|ASC 列表显示 Paid Applications Schedule 待 Account Holder 审阅/接受的横幅|保留为账号持有人后续操作；本批不代签。没有据横幅推断已接受或已具备新 App 提交条件；具体适用性以持有人控制台核实为准|
|Google Play 账号|实际 [App 列表](https://play.google.com/console/u/0/developers/8719288384645399837/app-list) 显示个人开发者账号 `8719288384645399837`、FishPilot `com.fishtk.fishpilot`；与当前 Android manifest 归属记录一致|确认可读既有开发者对象；不继承 FishPilot 的包名、签名或该 App 的测试/发布状态。当前可见列表未见 Pourlune，不作跨团队/权限的穷尽证明|
|Firebase 账号与项目|现有 Google 会话能列出并打开 `fishpilot-staging` / `fishpilot-production`，各见 Android、Apple iOS App。开发项目 General 页白名单读到 Android App `1:886887483711:android:55198a53b2c055c55f6b8a`，包名 `com.fishtk.fishpilot`|证明既有账号可读这些项目，不能作为 Pourlune 的注册或 Options。当前可见项目列表未见 Pourlune；没有核验写权限，也未复用 FishPilot 后端、Analytics property 或 RC 模板|
|Apple 本地签名材料|`security find-identity -v -p codesigning` 识别 3 个有效身份：开发证书 2 个属 `34F7HC5DJR`，分发证书 1 个属 `T7U878Z8H6`（SHA1 `13362E4AF31A860FA6B705DB5192AF78613F7A58`）。两处标准目录共 6 个描述文件均为 FishPilot / GetDoneFrame Store 身份；未见 Pourlune 或开发设备描述文件|钥匙串列出身份不等于本批签名/验签成功；没有可据以确认的 Pourlune development profile。保留已有材料，不导出私钥、不为另一团队自动新建证书|
|Android 签名材料|Pourlune `android/key.properties` 不存在，Gradle 无 release signing config。FishPilot 当前签名登记属于 `com.fishtk.fishpilot`|没有把旧上传证书或 keystore 复制给 Pourlune。正式密钥管理/是否复用由签名负责人决定，本批不生成或重置；上传密钥与 Play 应用签名密钥需分别登记|
|CLI / AdMob|PATH 未发现 firebase、flutterfire、gcloud、asc；已有 adb/xcrun。AdMob 官网可访问，点击既有 sign in 入口后的 `https://apps.admob.com/` 返回 `ERR_CONNECTION_CLOSED`|浏览器已完成三类账号只读核验，CLI 缺失不是账号缺失。AdMob 归属/可用权限仍未知，不绕过连接错误、不注册、不重复轮询|

可重查的非敏感字段与源文件 SHA 在 [local-facts.json](../evidence/account-reuse-preflight/local-facts.json)；浏览器事实在 [browser-observations.json](../evidence/account-reuse-preflight/browser-observations.json)。最后一次合并回读遇到 CDP 超时，记录沿用本任务此前成功的页面观察，没有伪称最后刷新成功。原始账号页包含个人资料，未把其全文或截图留进仓库。Provider 文件均在程序内白名单筛选；未记录 API key、令牌、私钥、账号电话或地址。

## 2. Pourlune 目标身份单（正式值尚未分配）

|用途|iOS Bundle ID|Android applicationId|状态与处理|
|---|---|---|---|
|现有开发 / 真实服务首次接入|`dev.pourlune.pourluneDev`|`dev.pourlune.pourlune_dev`|工程实际值，先保留；Firebase 注册须逐字匹配，大小写/下划线不能自行“统一”。注册状态尚未证明|
|正式发行建议|`com.fishtk.pourlune`|`com.fishtk.pourlune`|**仅供审核的建议，未确认、未查重、未执行注册、未写入工程；注册状态 unknown。** 沿用 FishPilot 已有命名前缀不代表自动取得该新身份或共用 App；负责人也可给出另一组正式值|
|B05 隔离 QA|`dev.pourlune.b05Validation`|无对应已建立身份|只用于已验 B05 沙盒，不能用开发身份的 Firebase plist/Options 去启用它；本批不为它追加注册，不动普通审查库|
|Apple Team / Play 开发者|`T7U878Z8H6`|`8719288384645399837`|账号沿用及来源已确认；Pourlune 独立 App ID / ASC record / Play record / profile 的建立是后续外部动作|

建议在**同一个现有 Firebase 账号**下为 Pourlune 选择独立开发与生产项目，每个环境各注册 iOS、Android 两个 App。可审查名称为 `Pourlune development` / `Pourlune production`；候选 project ID `pourlune-dev` / `pourlune-prod` 仅为命名建议，全球可用性未核实，实际值以后续控制台回读为准。本批不创建项目或把它们写成存在。

这是隔离业务数据和测试流量的建议，不是要求新 Google/Firebase 账号。Firebase 官方说明同项目的 App 共享资源及 Analytics property，并推荐按环境分项目；因此本次账号沿用不应静默变成与 FishPilot 共项目。[Firebase 项目与环境最佳实践](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)

## 3. 原生配置、Options 与符号接入缺口

|接入点 / 现有路径|当前事实|收到目标配置后的最小工作与判据|
|---|---|---|
|iOS Firebase plist|`app/ios/Runner/GoogleService-Info.plist` 不存在；Runner Resources 也没有该引用|从**对应 Pourlune 环境/iOS App**取得文件；白名单核对 `PROJECT_ID / GOOGLE_APP_ID / GCM_SENDER_ID / BUNDLE_ID`，`BUNDLE_ID` 与最终编译产物一致；加入正确 target 的资源阶段。检查安装包内实际 plist，不能仅放进目录|
|Android Firebase JSON|`app/android/app/google-services.json` 不存在；`build.gradle.kts` 仅在此文件存在时 apply google-services / Crashlytics。插件版本已固定在 settings|先给匹配当前开发包名的文件；白名单核对 project_id/project_number、所选 client 的 mobilesdk_app_id/package_name。文件到根路径才能触发当前条件；**只放 src/dev/JSON 不会触发**。正式采用 flavors 时须同步修改这一条件并检查所选 variant 的合并资源及 Crashlytics build ID|
|Dart Options / 启用门|`service_config.dart` 读取 `POURLUNE_FIREBASE_OPTIONS` JSON 字符串及 `POURLUNE_FIREBASE_NATIVE_READY`；只接受 apiKey、appId、messagingSenderId、projectId、storageBucket、iosBundleId。未提供/无效则 disabled；不会自动读取 `lib/firebase_options.dart`|按“环境×平台”分别准备受控本地 define 文件，Options 与原生文件逐字段一致；`iosBundleId` 对 iOS 实际 Bundle ID；Android 验证 package 与所选 client。Options 自身不能证明已选对项目/包名；不能只把 native-ready 改 true。客户端 API key 属公开配置但也不需粘贴进聊天/日志，服务账号 JSON 绝不能当 Options|
|dev/prod 原生选择|Android 无 productFlavors；iOS Runner 当前 Debug/Profile/Release 都使用开发 Bundle ID，Debug/Release xcconfig 引入同一 Services，Profile 使用 Release 配置|最小开发联调可先接当前开发身份；正式身份确认后再做必要的 build configuration/flavor 或受控构建前配置选择，不提前搭大框架。单纯 Dart define 不会更改 Bundle ID/applicationId、plist 或 Gradle variant。每次构建须证明原生身份与 Options 同环境，未选择时保持 disabled|
|iOS Crashlytics / SPM|当前只有 Flutter build/embed 脚本，没有 Crashlytics run/upload-symbols 阶段。Profile/Release 有 dSYM 格式设置；本地 SPM checkout 的 Crashlytics/run 与 upload-symbols 存在|用当前 SPM 来源接符号步骤，不照抄 `$PODS_ROOT`。当前可见路径为 `app/build/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/`，生成目录不可硬写成永久来源；按实际 Xcode build/解析目录配置。为 Xcode 脚本沙盒声明 dSYM、DWARF、dSYM Info.plist、包内 GoogleService plist、可执行文件等 inputs；适用 debug dylib 时补该 input。记录 archive UUID、上传目标 App ID 与收件结果，不能把有脚本/有 dSYM 当可读崩溃通过|
|Android Crashlytics 符号|原生文件未到位，产品插件未 apply；B05 未证明该 App 的 build ID/符号收件|配置匹配的 JSON 后定向构建验证 Crashlytics 任务、资源和收件；若启用 R8/minify，保留/上传对应 mapping；若使用 Flutter `--split-debug-info`/obfuscate，额外保留并向**Firebase Android App ID**上传该次 Dart symbols。不要把包名或 Play 上传证书当 Firebase App ID|
|隐私 / 默认关闭|两端原生 Analytics / Crashlytics 采集默认 false；Dart 两个选择独立，Crashlytics 自动上传保持关闭，通过显式 send/delete 管理未发报告。iOS 使用无 AdID Analytics SPM 环境变量|保留默认关闭、撤回和缓存报告披露，不照搬官方示例把所有 error 无条件上传。真实初始化/收件验证必须遵守玩家选择。继续统一 `FIREBASE_ANALYTICS_WITHOUT_ADID=1` 并串行 Flutter CLI，不变更锁定 SDK|

[configuration-paths.json](../evidence/account-reuse-preflight/configuration-paths.json) 记录了实际存在性、资源/脚本检查与源码 SHA。现有工程已提供可用入口，当前没有真实目标文件可校验，因此本批无需补占位 Options、生成代码或新验证框架。后续 CLI 工具安装需固定版本；`flutterfire configure` 可能注册 App、修改工程，不是只读探测，本批未运行。[FlutterFire 配置说明](https://firebase.google.com/docs/flutter/setup)

符号接入分别依据 [Flutter Crashlytics](https://firebase.google.com/docs/crashlytics/flutter/get-started) 与 [Apple dSYM 和 Xcode inputs](https://firebase.google.com/docs/crashlytics/ios/get-deobfuscated-reports)。配置完成后还必须实际制造专用测试异常并在正确 App 收到可读堆栈；不复用 FishPilot 的历史缺口或收件作 Pourlune 证据。

## 4. AdMob / UMP 精确缺口

- **归属**：尚无已确认的 AdMob 账号、Pourlune iOS/Android App、隐私消息或广告位。Google/Firebase 账号沿用不自动包括 AdMob。当前连接失败只记录 unknown；后续先恢复访问并只读确认已有账号/负责人，不点 signup。
- **原生 App ID**：iOS `app/ios/Flutter/Services.xcconfig` 是 Google 官方 sample App ID；可由 ignored `Services.local.xcconfig` 覆盖 `POURLUNE_ADMOB_APP_ID`。Android 通过同名 Gradle property 覆盖 manifest placeholder；**它不是 Dart define**。两端 App ID 使用 `~`，广告位 ID 使用 `/`，不得混用。正式注册值需由对应平台 App 回读。[官方平台配置](https://developers.google.com/admob/flutter/quick-start)
- **广告位 / 模式**：当前 debug 的 `POURLUNE_AD_MODE=test` 固定选择分平台官方插屏/激励测试位；release 默认 disabled。production 模式要求两种自有位且拒绝 Google 测试 publisher。首次真实 SDK 奖励与 SQLite 验证可继续使用官方测试位；不需先申请生产位，不把共享 sample App 当成自有 UMP 消息配置。[官方测试广告](https://developers.google.com/admob/flutter/test-ads)
- **UMP**：在已确认 Pourlune 自有 App 上配置适用地区消息、实际政策地址、供应商与选项入口，然后用自有原生 App ID + 官方测试广告位检查实际消息。`POURLUNE_UMP_TEST_REGION=eea` 及 `POURLUNE_UMP_TEST_DEVICE` 是当前仅 debug/test 的 EEA 探针；它不是广告 SDK 的全部测试设备配置，也不能覆盖 US 州规则测试。当前没有 US debugGeography 输入，后续若需要仅补具名 QA probe。不能伪造同意或在常规产品流程 reset consent。[UMP 官方流程](https://developers.google.com/admob/flutter/privacy)
- **适用边界**：现有代码按 canRequestAds 控制广告资格、必要时提供 privacy options，Analytics/Crashlytics 选择不由它推导。NPA 不代表无数据采集或自动免除 ATT/商店披露；当前无 ATT 请求、无追踪文案，iOS plist 无 SKAdNetwork 项。后续按最终广告来源、无追踪策略及官方配置检查适用项，不为了套用 FishPilot 登录/购买能力添加无关权限。隐私政策/支持 URL/邮箱仍须实际批准与部署，本报告不替架构维护 user-handoff。

## 5. 操作顺序与一次性交接

以下是**待后续授权执行**的顺序，不是本批外部操作回执。准备工作的负责人不再要求新建 Apple、Google 或 Firebase 账号。

1. **先冻结对象**：负责人确认正式两端身份（可采纳上表建议或给定值）、Pourlune 开发/生产项目方案、AdMob 是否已有账号及归属。保留开发 ID 与现有审查存档。签名负责人声明使用现有材料的管理方式，不传私钥/密码；本批没有“先新建密钥”的前提。
2. **处理真实账号门槛**：Apple Account Holder 自行核对并处理 ASC 协议提示；恢复 AdMob 可访问性。已有会话足够做本批读取，无需现在重新登录；如果会话失效，一次使用下表列出的官方入口登录原账号，不给代理密码/验证码。
3. **独立注册与回读**：在现有 Team 注册 Pourlune 明确 App ID，再按已确认身份建立独立 ASC/Play App 记录及必要描述文件；在选定的独立 Firebase 环境注册对应双端 App；在确认的 AdMob 账号下建立对应 App/适用消息。创建/注册/权限扩大/条款均需后续明确操作授权，不能运行配置命令时顺带完成。Apple App ID 与 Xcode Bundle ID 必须匹配。[Apple App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id/)、[ASC App record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
4. **开发配置先落本地**：受控交接匹配的 plist / JSON 与公开身份摘要；如已包含所有 Options 字段，可直接生成本地 define，无需再索要另一份重复资料。核对四元组“环境、平台、native ID、Firebase App ID”以及 project/sender。保留采集 false、广告 test/disabled，完成原生绑定与符号链路。随后才设置 native-ready 并定向编译/运行。
5. **完成下节开发服务收件**：双端独立证据不互相替代。开发环境闭环后，按已核准正式 ID 和独立生产配置准备签名候选；签名验证分“材料可读、制品签名验签、与目标控制台证书/权限一致”。Android upload key 与 Play App Signing 证书分开登记，不复用 FishPilot 指纹作为 Pourlune 事实。[Android 签名官方说明](https://developer.android.com/studio/publish/app-signing)
6. **正式渠道验证另行执行**：TestFlight/Play 内测上传和生产配置发布有单独授权/回读；不把必须渠道安装后才能取得的设备证据反过来当成首次内测上传前必须已经存在。不增加账号登录、云存档、业务服务器、商城或 IAP。

|一次需核对/交接的结果|入口（已有账号）|交接形式|
|---|---|---|
|Pourlune 身份、当前团队与适用协议、后续 profile|[Apple Developer](https://developer.apple.com/account)、[ASC Apps](https://appstoreconnect.apple.com/apps)、[ASC Business](https://appstoreconnect.apple.com/business)|公开 Bundle ID/Team ID/App record ID 与状态；私钥/验证码留在负责人受控环境|
|Pourlune Play 对象与签名管理人|[现有 Play 开发者入口](https://play.google.com/console/u/0/developers/8719288384645399837/app-list)|公开包名/应用对象与证书指纹；不复制 FishPilot keystore，不自动生成/重置|
|目标 Firebase 开发/生产项目及匹配 App 配置|[Firebase Console](https://console.firebase.google.com/)|project ID、每平台 App ID、匹配的公开客户端文件；沿用既有访问，无需为本批扩大权限或提供服务账号|
|AdMob 归属及自有 App / UMP 状态|[AdMob Console](https://apps.admob.com/)|恢复可读会话后确认已有账号，提供公开平台 App ID/适用消息；生产位可后置，开发不点生产广告|
|代表真机与连接条件|本机 USB/已信任网络设备；后续 Developer Mode / USB 调试按设备所有人操作|型号/OS、受控测试设备标识与连接状态，不发送硬件私密资料|

## 6. 可连接设备与可独立推进范围

实际 `xcrun devicectl list devices` 没有列出物理 Apple 设备；`adb devices -l` 为空，当前没有可用 Android 真机/已启动模拟器。`simctl` 有 iOS26.5 模拟器，`4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2` 正在运行；本批没有触碰其 App、存档或设置。不能把本次清单当作真机性能/听感/读屏通过。

本机有 4 个 Android API36 arm64 AVD。三个为 google_apis；`FishPilot_Play_Internal_Build10` 的镜像路径是 google_apis_playstore，但其 `PlayStore.enabled=no`，所以**名称或镜像标签不能证明 Play 商店/服务可用**。当前均未连接，不启动/清理已有 FishPilot 或 GetDoneFrame AVD。后续可在隔离测试环境核对实际 GMS/Play 能力，或使用连接真机；不把 SDK/AVD 目录存在当 Android 服务联调成功。[Firebase Flutter Android 前置条件](https://firebase.google.com/docs/flutter/setup)

设备完整只读记录见 [devices.json](../evidence/account-reuse-preflight/devices.json)。账号资料到位前仍可独立推进：审核目标身份单、准备分环境公开配置清单和安全注入方式、核对 target/variant 与符号脚本方案、安排双端服务验收与代表设备；本批已完成这些准备，不重跑 B05，不为消除外部等待造新功能。

## 7. 配置到位后的双端真实服务与设备验收

|阶段|具体执行与保留证据|通过判据 / 限制|
|---|---|---|
|静态匹配 / 编译|分别对 dev iOS/Android 白名单核对原生文件、Options、bundle/package、project/sender/App ID；记录源码 SHA/配置摘要/版本。定向编译受影响平台，iOS 串行且用无 AdID 环境；看安装包 plist / Android 合并资源与 Crashlytics build ID|只能标静态/编译通过；任一串项目、串平台、身份不匹配或缺原生符号步骤，native-ready 不启用。不得只拿 B05 旧产物或 Options 证明已接入|
|真实初始化 / 默认关闭|隔离数据库、无 scenario 的正常主入口，双端各启动，记录 Firebase ready/失败降级；初始两采集选择 off，免费玩法/本地保存可用|本地 ready 与正确项目控制台证据分开；未选择时不新增业务埋点/显式崩溃发送，失败不阻塞核心|
|Analytics / AC-36|专用开发设备显式开启 Analytics；iOS Xcode 启动参数 `-FIRDebugEnabled`，Android `adb shell setprop debug.firebase.analytics.app <Pourlune开发包名>`；走教学、首次完成、拼片与广告事件，在目标 App 的 DebugView 核对 `pl_` 事件、身份去重、检查/曝光/确认/到账区别|console 收件证明与 SQLite 去重证据关联；断网/撤回后不继续发新的业务事件，不承诺召回既已发送数据。结束使用 `-FIRDebugDisabled` / `adb shell setprop debug.firebase.analytics.app .none.` 恢复测试标志。[官方 DebugView](https://firebase.google.com/docs/analytics/debugview)|
|Crashlytics / 符号|双端专用 QA 入口，显式启用独立 Crash sharing；一条受控非致命异常及一次测试崩溃/重启收件，记录 build、Firebase App ID、平台、时间与堆栈。iOS 脱离 debugger 运行以免截获 crash，核对 dSYM UUID；Android 按实际 minify/obfuscate 配置核对 mapping/Dart symbols|正确环境/App 收到可读堆栈且无 Missing dSYM；关闭共享后删除未发报告路径与重启设置需实际观察。保留当前 send/delete 策略，非致命一条成功不能代替 native crash；不要在产品默认路径留下 crash 按钮|
|Remote Config|仅在获准的 Pourlune 开发项目发布 `ads_enabled / interstitial_enabled / rewarded_enabled` 布尔值及 `disabled_puzzle_ids` JSON 字符串；默认 `[]`。对实际取回、非法值拒绝、缓存/超时/离线回退与重启做定向验证；当前最小 fetch 间隔12小时，若需即时测试用单独 debug override，不改 release 规则|读到的项目/模板版本/生效值可追踪；不在 FishPilot 项目发布测试 RC，不把控制台保存成功当客户端已激活；不放开远程任意逻辑或清除存档|
|真实插屏 / 激励 / AC-13～21、32|正常 UI、官方测试广告位、真实 SDK 回调，明确 UMP canRequestAds；验证13资格/16先揭示再Next、显示/曝光/关闭/失败、179/180秒、后台/返回/连点、受奖后真实 SQLite 原实例加瓶、无奖关闭、落盘失败重试/强退恢复。用 receipt/instance/request 和实际回调时间关联证据|不得以关闭、控制回调或无库存当 earn；无法自然出现的迟到/重复次序沿用受控合同测试并标注，不能强称实 SDK 已出现。一次具名有界无库存/网络失败后收束到原因，不重复等待同一30秒超时|
|UMP / 地区 / 撤回|自有 Pourlune App 的真实消息；debug 测试设备下验证 EEA required/同意/拒绝、privacy options 和重启；实际目标地区另按配置测试（US 需补具名 QA 地理探针）。广告授权、Analytics、Crash sharing 三者保持独立|记录实际表单/状态/请求资格；sample App、NPA、SDK callback 成功都不能替代自有消息与适用隐私验收。只有专用可丢弃 QA 环境允许 reset，不改变普通玩家同意|
|真机 / 网络 / AC-31、34|连接 iOS 与 Android 代表设备及选定最低/当前 OS，记录型号/OS/制品 SHA/真实安装身份。检查大字/标签/VoiceOver或TalkBack、静音/音效/触感、弱网/物理断网冷启动、前后台与存档；profile 模式测首帧、帧耗时、RSS/长测|真实断网操作和设备日志，不能凭图标猜断网；首次/后续运行、debug/profile 分开。既有 B05 Simulator 诊断不转成真机达标；未有设备保持 pending|
|签名 / 渠道 / 升级|在另行授权后使用已确认正式 App/签名构建；核验安装签名与渠道 app signing 指纹，完成独立 TestFlight / Play 测试安装及非空旧存档覆盖升级；保留原审查安装|正式渠道步骤取得相应授权后执行；不能用 B05 unsigned iOS/AAB 或 Android Debug profile 当分发通过，不把开发身份的全新安装当正式升级|

## 8. 本批检查与未验证范围

实际完成：工作区/远端只读核对、当前事实源阅读、程序白名单提取、security identity/profile 公共元数据解码、原生配置/脚本存在性核对、浏览器账号/项目可见性、设备与 AVD 清单、当前官方资料核对；没有新增生产代码或工具，无需跑 Flutter/核心/内容全量测试。最终文件/证据一致性检查另记 `checks.json`。

未验证：Pourlune 正式身份可用/注册、写权限、账号协议处理、AdMob 归属/实际消息、真实 Firebase/广告收件与符号、签名验签/商店接受、连接真机与运行/性能、正式支持站点/法律与资源权属。本报告完成的是账号沿用准备，不是这些门槛通过，也不修改已验收 B05 的结论。
