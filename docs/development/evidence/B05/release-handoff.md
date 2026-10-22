# B05 internal candidate and release-owner handoff

2026-10-22（Asia/Taipei）；执行资料。使用 App Store preflight 的 all-apps/games 清单作静态检查，没有商店账号/metadata pull、上传、签名或法律批准。没有替游戏新增账号、业务服务器或付费能力。

## 候选身份与产物

- 源码基线 ba78a62726754634788f9b3a70f90acf0eefeb33，internal version **0.4.0+4**，Flutter3.47.2 / Dart3.13.2，应用和核心锁文件保留。B05没有凭空确定正式版本或发布主体。
- Android身份 `dev.pourlune.pourlune_dev`；iOS `dev.pourlune.pourluneDev`；显示名Pourlune Dev。原生B05测试独立身份 `dev.pourlune.b05Validation`，不可用于正式服务归属。
- `artifacts.json` 记录最终源版本的实际bytes/SHA256/90题逐字节一致性。当前产物如下（路径均相对项目根；build目录被忽略，不入库）。初轮artifacts-initial数字属于修复前快照，不作为最终大小。iOS设备目标的默认输出被后建覆盖，单列preserved_path保留两种候选；最终以JSON为准。

|模式|实际bytes|最终/保留路径|签名|
|---|---:|---|---|
|android-profile|149696782|app/build/app/outputs/flutter-apk/app-profile.apk|Android Debug, verified APK v2|
|android-release|104207275|app/build/app/outputs/bundle/release/app-release.aab|unsigned, jarsigner English output verified|
|ios-release-unsigned|79560782|app/build/b05-candidates/ios-release-unsigned/Runner.app|unsigned; codesign exit1|
|ios-profile-unsigned|89711812|app/build/b05-candidates/ios-profile-unsigned/Runner.app|unsigned; codesign exit1|

- `android-profile-signature.log`：APK v2签名验证有效，证书明确Android Debug。AAB无JAR签名；iOS两种codesign退出1，明确unsigned。均不是可上架产物。没有上传二进制、导出密钥或创建签名资产；产物仍在被忽略的build目录。
- profile默认官方测试广告配置；release Dart广告默认disabled。原生仍嵌入Google共享sample AppID，Firebase native-ready=false、无真实Options/plist/json。不能称正式广告/生产隐私配置。默认目标main.dart不引入B05命令入口、屏障或受控回调。

现有B04提交的[GitHub Actions run39698416205](https://github.com/wangyule0379-max/Pourlune/actions/runs/39698416205)为success，公开只读API结果留于remote-ci.json。该次是已提交B04，不是本次尚未提交B05的远端结果。现有CI已固定SDK并跑core/app/debug双端编译；本轮没有为重跑相同检查修改CI。B05的profile/release和Simulator流程均为本地证据。

## 权限、数据与SDK清单

精确合并结果/24份嵌入iOS SDK privacy manifests见 `privacy-and-permissions.json`，来自实际构建而非仅扫描应用主清单。清单存在和编译成功不证明商店隐私报告、签名验证或用户配置合规。应用原生自有代码仅委托Flutter注册插件；没有为了消除警告臆填Required Reason理由。正式归档后仍需Xcode聚合privacy report并与实际启用配置核对。依据：[Apple privacy manifests](https://developer.apple.com/documentation/BundleResources/privacy-manifest-files)、[required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)。

|能力/固定SDK|数据与当前门控|发布负责人还需核验|
|---|---|---|
|SQLite sqflite2.4.5、本地纯Dart核心|棋盘、撤销、每日日期、随机实例/请求、拼片/权益、偏好本地保存；核心无账号/服务器|卸载/清数据/换机丢失风险、备份行为和商店披露；不能承诺云恢复|
|google_mobile_ads9.2.0 / UMP|广告设备/app/network/交互；NPA不等于零数据。UMP资格与Analytics/Crash选择独立。release广告disabled|归属App/地区消息、实际库存展示/earned与OS中断、正式隐私声明，未来启用tracking前的官方ATT验证|
|firebase_core5、Analytics13、Crashlytics6、RemoteConfig7|native-ready默认false；analytics和crash独立默认off；RC可能使用installation基础设施；native可缓存崩溃，自动上传false|匹配真实项目配置、DebugView、Crashlytics符号/收件、RC有效/坏值/离线及网络撤回；不能把关Analytics写成Firebase零处理|
|audioplayers6.8.1|随包音频、本地偏好；Android合并manifest包含FOREGROUND_SERVICE/WAKE_LOCK，不能仅据此声称实际后台播放|物理听感、中断/静音；逐SDK确认其服务用途与目标Android行为|
|url_launcher6.3.3|用户选择后打开外部浏览器/邮件App；不自动发送反馈或上传棋盘|真实HTTPS支持/隐私URL、邮箱和处理责任人|

Android实际合并权限含INTERNET、ACCESS_NETWORK_STATE、WAKE_LOCK、AD_ID、ACCESS_ADSERVICES_AD_ID/ATTRIBUTION/TOPICS、安装referrer、FOREGROUND_SERVICE与私有receiver权限。应用没有位置、相机、麦克风、通讯录或存储读取权限请求。SDK自动合并的广告权限不能因Dart disabled或NPA就从披露中忽略。Data safety必须依据发布配置填写，不能预填“全部不收集”。依据：[Google Play developer policy](https://support.google.com/googleplay/android-developer/answer/18258653)、[Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248)。

## English copy package — DRAFT, not store metadata or published policy

**App name:** Pourlune (owner must confirm identity/trademark). **Short description draft:** Match each bottle to its color tag, one calm move at a time.

**Description draft:** Sort the colors into bottles with matching fixed tags, and leave every buffer empty. Play60 main puzzles and a rotating set of daily puzzles, uncovering three cozy scenes as you progress. Hint, Undo and Restart are free, and core play works offline. Main and daily puzzles keep separate local saves. Optional rewarded ads can add one empty bottle to their original puzzle after a confirmed reward; ad availability varies. Progress is stored on this device. There is no account or cloud sync; uninstalling or clearing app data may remove your progress.

Existing complete English drafts are reused: [help](../../../support/help-draft.md) and [privacy](../../../support/privacy-draft.md). They remainDRAFT/not deployed/not legally approved; operator identity, contacts, regions, retention/request procedures and final disclosures must be filled by the owner from actual configuration. Current unconfigured in-app links show accurate unavailable copy. No example domain/email was configured.

Screenshots are actual Flutter renders, but B05 QA/native screenshots include seeded states, controlled callbacks, dev labels and enlarged text. They are verification evidence, **not final store screenshot exports**. Select and capture clean production-identity gameplay on supported devices after identity/config approval. Existing candidate art manifests retain UNCONFIRMED commercial rights; Nunito OFL/source records and local audio provenance are available, but they do not establish rights to the original/derived visual pack. No original design or rights status was modified.

## 最小外部交接（集中一次，不收秘密）

|需交接|负责人|阻塞子项／后续判据|
|---|---|---|
|发布主体、账号负责人、最终BundleID/applicationId、受邀协作方式及签名管理人|产品/发布负责人|正式注册、签名、TestFlight/Play内测与上架；凭据不入repo或聊天日志|
|Firebase开发项目受邀访问＋匹配客户端公开配置，生产项目另列|服务负责人|真实初始化、分析/崩溃/RC收件和撤回；受控结果不补作收件证明|
|AdMob归属App/地区消息配置；可用测试库存与代表设备|广告/隐私负责人|真实插屏/奖励→SQLite、无奖关闭、OS中断/冷却；当前30秒timeout已由B04主审确认，无意义重复轮询停止|
|真实HTTPS支持/隐私URL、有效邮箱、来信/隐私请求处理人和法律批准|产品/隐私负责人|实际支持入口、政策发布和商店声明；不替用户部署或签条款|
|原视觉/派生资源商业使用权依据，最终发布图标/截图审核|美术/发布负责人|商用素材门槛；运行视觉自查不能改变权属|
|Android运行设备、iOS/Android代表真机/最低系统、读屏与物理音频条件|QA/设备负责人|profile性能、内存长测、离线/弱网、VoiceOver/TalkBack、广告覆盖层/系统中断、真实升级安装与真机音频|

其余既定范围可独立工作已按B05推进；只剩外部门槛时集中交接后等待资料，不自动创建账号、购买、上传商店或生产发布。

最终iOS release保留重编译见ios-release-preserve.log（Flutter53.8s；包括准备/复制的wall time见artifacts.json）；profile先复制到独立目录，release再保留，避免互相覆盖。两目录最终hash与各自AOT已再次核对，90题逐字节一致。普通Simulator手动App另为QA身份，不能误装这些unsigned设备产物。
