# B04 广告、UMP 与 ATT 官方资料核验

核验日期：2026-10-22（Asia/Taipei）。范围：只读现有工程及 Google/Apple 官方资料、Google 发布的 pub.dev 包源码；没有安装依赖、改 App、构建、运行 SDK、操作模拟器、登录或改控制台。本报告是接入依据，不是政策/法律认证或原生测试通过证据。产品数值和奖励归属仍按 PRD §6，不采用文档示例中的业务频控。

## 固定版本与现有工程

建议直接依赖固定为 **`google_mobile_ads: 9.2.0`**；UMP 已包含，无须额外 UMP 包。此次查询遇到缓存差异：pub.dev versions 页仍显示 9.1.0，实时 API 与 changelog 已为 9.2.0。API 的发布时间为 **2026-10-21T19:26:18.024772Z**。读取官方 9.2.0 压缩包并在内存计算 SHA-256，与 API 完全一致：`439e018d73b47565d1cf21410e893a8f46d5fb95110c41c266a6fb78449d7106`。[实时包元数据](https://pub.dev/api/packages/google_mobile_ads)、[版本源码包](https://pub.dev/api/archives/google_mobile_ads-9.2.0.tar.gz)、[Google changelog](https://pub.dev/packages/google_mobile_ads/changelog)。

| 项目 | 9.2.0 源码约束/依赖 | Pourlune 现状和影响 |
|---|---|---|
| Dart / Flutter | Dart `>=3.10.0 <4.0.0`；Flutter `>=3.38.1` | 固定 3.13.2 / 3.47.2 满足声明约束；这不是实际依赖解析或构建通过 |
| Android | 插件 minSdk 24、compileSdk 36；默认 GMA `25.5.0`、UMP `4.0.0` | 已有 minSdk 24、Java 17；compile/target 由 Flutter 提供。AGP 9.1.0、Gradle 9.3.1 需要实际构建验证；不要为插件自身 AGP 8.13.2 自动降级主工程 |
| iOS | 插件声明 iOS 13.0；SPM GMA `from: 13.11.0`；GMA 13.11.0 也声明 iOS 13 | 已有目标 iOS 15.0；无需因本包提高该目标。官方 quick-start 正文要求 Xcode 16+，并提示 Xcode 27 的 CocoaPods 全目标至少 15.0 |
| iOS UMP | changelog 对应 UMP 3.1.0；GMA SPM 对 UMP 使用 `1.1.0..<4.0.0` 范围 | 必须记录接入后实际 `Package.resolved`，不能把 changelog 写成 native lock 精确固定的证据 |
| 传递 Flutter 包 | `meta ^1.17.0`、`webview_flutter ^4.14.1`、Android `^4.12.0`、WKWebView `^3.25.1` | 保存应用 pubspec.lock；本次未解析传递依赖 |

以上约束读取自 9.2.0 归档内 `pubspec.yaml`、`android/build.gradle`、`ios/google_mobile_ads/Package.swift`、`ios/google_mobile_ads.podspec`。可对照 [Google 源码仓库](https://github.com/googleads/googleads-mobile-flutter/tree/main/packages/google_mobile_ads)、[GMA 13.11.0 SPM 清单](https://github.com/googleads/swift-package-manager-google-mobile-ads/blob/13.11.0/Package.swift)、[iOS 官方起步说明](https://developers.google.com/admob/ios/quick-start)。9.2.0 还修复 UMP 使用 registrar viewController 呈现以支持 UIScene，和本工程已有 SceneDelegate 相关；不能把升级本身当成该流程已验证。

本次只读检查：`app/pubspec.yaml` 尚无广告依赖；Android 主 manifest 无 AdMob 应用 ID；iOS Info.plist 无 GADApplicationIdentifier、NSUserTrackingUsageDescription、SKAdNetworkItems。iOS 工程引用 FlutterGeneratedPluginSwiftPackage，当前没有 Podfile，接入时沿用现有 SPM 路径，避免重复手动安装 GMA。临时身份仍为 Android `dev.pourlune.pourlune_dev`、iOS `dev.pourlune.pourluneDev`，没有把这些当生产身份。

9.2.0 同时提供 Android Next-Gen 可选分支（`USE_NEXT_GEN_SDK`，1.5.0），默认仍是 play-services GMA。B04 最小方案保持默认，不仅因为导航文档显示 Next-Gen 就增加切换范围。

## 官方测试身份

| 平台 | 测试 App ID | 普通插屏 adUnitId | 激励 adUnitId |
|---|---|---|---|
| Android | `ca-app-pub-3940256099942544~3347511713` | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-3940256099942544/5224354917` |
| iOS | `ca-app-pub-3940256099942544~1458002511` | `ca-app-pub-3940256099942544/4411468910` | `ca-app-pub-3940256099942544/1712485313` |

App ID 使用 `~`，广告位使用 `/`。Android application 下的 metadata 键为 `com.google.android.gms.ads.APPLICATION_ID`；iOS 字符串键为 `GADApplicationIdentifier`。这是官方共享测试身份，不需要代建用户账号。[Flutter 安装说明](https://developers.google.com/admob/flutter/quick-start)、[官方 iOS App ID 示例](https://developers.google.com/admob/ios/quick-start)、[插屏测试广告位](https://developers.google.com/admob/flutter/interstitial)、[激励测试广告位](https://developers.google.com/admob/flutter/rewarded)。

开发阶段仅使用上表。模拟器/Android emulator 自动视为广告测试设备；真机也可通过 `MobileAds.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: [...]));` 配置日志给出的设备哈希。UMP 的 `ConsentDebugSettings(testIdentifiers: [...], debugGeography: DebugGeography.debugGeographyEea)` 是另一组调试设置，不能混用两种哈希或把地域模拟带进 release。`ConsentInformation.instance.reset()` 只用于测试。网络、库存、设备能力仍可能导致测试广告失败，失败不等于获得奖励。[Google 测试广告说明](https://developers.google.com/admob/flutter/test-ads)、[UMP 测试说明](https://developers.google.com/admob/flutter/privacy)。

## 请求资格、隐私入口与最小 API 形状

在稳定且前台的页面，每次启动调用 `requestConsentInfoUpdate`，成功后调用 `ConsentForm.loadAndShowConsentFormIfRequired`。广告资格使用 SDK 的 `canRequestAds()`；不以自存布尔或 `ConsentStatus.obtained` 代替。SDK 在本次启动调用 update 前始终返回 false；update/表单失败后也可询问该方法，它可能接受上一会话状态。两条完成路径可能同时返回 true，必须防止重复初始化/重复加载。隐私入口读取 `getPrivacyOptionsRequirementStatus()`，为 `required` 才显示可操作的广告隐私选项，并用 `showPrivacyOptionsForm` 打开。unknown 不当作已允许。[Google UMP 流程](https://developers.google.com/admob/flutter/privacy)。

下面仅展示已核对存在的 9.2.0 API；省略的页面门控、超时、撤回处理是应用职责，不是可直接粘贴的完整实现：

```dart
final consent = ConsentInformation.instance;
consent.requestConsentInfoUpdate(
  ConsentRequestParameters(),
  () {
    ConsentForm.loadAndShowConsentFormIfRequired((error) async {
      final allowed = await consent.canRequestAds();
      final options = await consent.getPrivacyOptionsRequirementStatus();
      // Update UI, then enter the same guarded init/load path if allowed.
    });
  },
  (error) async {
    final allowed = await consent.canRequestAds();
    // Report failure; use the SDK result and app policy, never assume consent.
  },
);

// User explicitly opens the required privacy options entry:
await ConsentForm.showPrivacyOptionsForm((error) async {
  final allowed = await consent.canRequestAds();
  // Re-check policy; invalidate previously loaded ads when choice changes.
});

// Only after the consent/request policy permits:
await MobileAds.instance.initialize();
RewardedAd.load(
  adUnitId: platformRewardedTestId,
  request: const AdRequest(),
  rewardedAdLoadCallback: RewardedAdLoadCallback(
    onAdLoaded: (ad) { /* store only if load generation remains current */ },
    onAdFailedToLoad: (error) { /* unavailable; keep free gameplay */ },
  ),
);
```

初始化不放在本地启动的必经等待链；`initialize()` 返回 Future，官方标注初始化结束或 30 秒完成，不能把 Future 完成等同某广告位已就绪。iOS 原生文档提示初始化可能预加载广告/初始化第三方 SDK，因此先处理必要资格与请求配置，再初始化，再 load。[Flutter 初始化](https://developers.google.com/admob/flutter/quick-start)、[iOS 初始化注意](https://developers.google.com/admob/ios/quick-start)。

产品推导：广告资格、Analytics 选择、Crashlytics 选择、是否跟踪是不同状态。UMP 允许广告请求不证明 Firebase 已获相应允许；拒绝个性化也不必然表示所有广告请求都禁用。隐私表单收回后应重新询问 SDK，并让既有库存失效，以新资格决定未来请求。没有真实 AdMob 项目/消息配置时，不承诺自己配置的 EEA、美国州隐私或 IDFA 消息已在控制台生效。共享测试 App ID 能展示广告，不证明用户的隐私消息配置已联调。

## 展示、确认、关闭与持久化边界

`InterstitialAd.load(..., adLoadCallback: InterstitialAdLoadCallback(...))` 与激励 load 都只产生库存。显式按钮意图重新通过业务检查后才 `show`。设置 `fullScreenContentCallback` 必须早于 show；核心回调为 `onAdShowedFullScreenContent`、`onAdFailedToShowFullScreenContent`、`onAdDismissedFullScreenContent`、`onAdImpression`。show 的 Future 结束不能冒充实际曝光；PRD 180 秒与插屏清零绑定实际展示回调，曝光统计绑定 impression。每个广告对象只能 show 一次；展示后不能用程序直接移除全屏广告。[插屏生命周期](https://developers.google.com/admob/flutter/interstitial)。

激励以 `RewardedAd.show(onUserEarnedReward: (ad, reward) { ... })` 确认为准，关闭不发奖。Google 直投广告在 Android 与 iOS 都明确保证奖励回调先于 dismiss；mediation 顺序由第三方决定。独立回归仍应覆盖乱序、重复、后来请求先到与确认持久化失败。[Android 奖励顺序](https://developers.google.com/admob/android/rewarded)、[iOS 奖励顺序 FAQ](https://developers.google.com/admob/ios/rewarded)。

应用适配要求（PRD §6.5 / AC-19～21）：展示前原子记录 attemptId、原实例与原棋盘关联。回调闭包固定该身份，不能读取“当前实例”替代；收到确认立即进入可重试的持久化路径，成功落盘才显示到账。dismiss/failedShow 只一次解锁/导航；不清除已经收到但尚未写盘的确认；新 load 的旧世代回调只能销毁库存，不能自动展示。SDK 的 RewardItem 是 SDK 奖励数据，不是 SQLite 已发瓶回执。

**迟到回调有明确 SDK 边界。** 官方 Flutter 示例建议 dismiss/failedShow 时 `dispose`。9.2.0 归档 `lib/src/ad_instance_manager.dart` 第 60–77 行按 adId 查对象后才派发事件，第 747–755 行 `disposeAd` 先从 `_loadedAds` 移除对象，因此 dispose 之后才到达的原生奖励事件无法派发给 Dart；把 closure 留在业务表里也无法补救。官方 Google 直投保证顺序可与立即 dispose 配合；不能将抽象适配器的“关闭后确认”单测说成原生 SDK 已证实能发送任意迟到奖励。未来若引入 mediation，必须按选定适配器核实资源释放与奖励顺序，而不能用任意固定延迟承诺全部回调。[已核验 9.2.0 归档](https://pub.dev/api/archives/google_mobile_ads-9.2.0.tar.gz)、[Google 源码位置](https://github.com/googleads/googleads-mobile-flutter/blob/main/packages/google_mobile_ads/lib/src/ad_instance_manager.dart)。

**进程恢复能力有限。** 检查 9.2.0 公开广告/UMP API，未发现按本地 attemptId 查询历史已赚奖励的恢复 API；SDK 广告对象和回调在内存中。官方另有 SSV 服务端回调，可附 customData，但 Pourlune 首版无业务服务器，不能把 SSV 当已有能力。由此推导：重启只能恢复本地已落盘确认/到账；若确认未收到或没成功落盘，只能显示未确认、允许结束领取意图后重试，不能凭 dismiss、播放时长或加载成功发奖，也不能虚构平台补查成功。[激励与可选 SSV](https://developers.google.com/admob/flutter/rewarded)。

## ATT：跟踪路径与不跟踪路径

Apple 要求跨公司 App/网站跟踪或访问 IDFA 前取得 ATT 允许。广告存在本身不等于已经决定跟踪；`AdRequest(nonPersonalizedAds: true)` 也不证明整个应用及其 SDK 都没有跟踪。生产配置需要核对实际数据用途，不能从一个 Dart 参数生成合规结论。[Apple 数据使用与跟踪定义](https://developer.apple.com/app-store/user-privacy-and-data-use/)、[ATT 框架](https://developer.apple.com/documentation/apptrackingtransparency)。

若选定跟踪/IDFA 路径，可使用 **UMP 的官方 IDFA 消息**：在 AdMob 配置 IDFA 消息、iOS 添加真实用途的 `NSUserTrackingUsageDescription` 并链接 AppTrackingTransparency；UMP 负责说明及系统 ATT 流程，无须为了此流程再引入一个非官方 Flutter ATT 包。不要同时从两个入口重复发起 ATT。ATT denied 时 GMA 仍可请求不带 IDFA 的广告，但仍需满足 UMP 与应用请求资格。[Google Flutter IDFA 说明](https://developers.google.com/admob/flutter/privacy/idfa)。

系统请求只在 App active 且没有另一待确认权限时呈现；restricted 可立即回调；未出现弹窗且仍为 notDetermined 不能写成用户拒绝或同意。系统记住选择，重复调用不能强制重新弹出；Google 测试说明指出重现首次 ATT 流程需要测试设备卸载重装。UMP reset 不等于重置 ATT。[Apple requestTrackingAuthorization](https://developer.apple.com/documentation/AppTrackingTransparency/ATTrackingManager/requestTrackingAuthorization(completionHandler:))。

若产品明确选择不跟踪/不读取 IDFA 路径，不为强求弹窗而补造跟踪用途说明；保持所有相关 SDK 的实际配置/数据用途与该选择一致，并继续运行适用 UMP。Google 文档另指出 publisher first-party ID 默认启用，原生可通过 `MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)` 关闭；本次查遍 9.2.0 Dart lib 没有发现该 setter，若确需此配置，要使用明确的原生接入点并验证，不能假设 `nonPersonalizedAds` 顺便关闭了它。first-party ID 本身也不能未经用途分析直接等同 Apple 跨公司跟踪。[Google iOS 隐私策略](https://developers.google.com/admob/ios/privacy/strategies)。

## 交付判定

已完成：本地声明和官方包约束核验、官方测试身份/API/回调与恢复能力研究。未完成且本报告不宣称通过：pub/原生解析锁定、AGP/SPM 构建兼容、真机/模拟器广告加载与展示、ATT 实测、正式消息控制台配置、SDK 实际网络采集、生产隐私声明和商店审核。后续记录应分别注明真实 SDK 证据与纯状态替身证据。

## Adapter integration follow-up (2026-10-22)

LoadAdError uses platform + domain + numeric code, never arbitrary SDK message: Android `com.google.android.gms.ads` network2/no-fill3 or9/invalid-request1; iOS `com.google.admob` network2/no-fill1/timeout5/invalid-request0 or12. Unknown values map to load_failed. iOS3 is a server error, not no-fill; a network code does not establish complete device-offline status. Sources: [Flutter load errors](https://developers.google.com/admob/flutter/ad-load-errors), [Android AdRequest constants](https://developers.google.com/admob/android/reference/com/google/android/gms/ads/AdRequest?hl=en), [iOS GADErrorCode](https://developers.google.com/admob/ios/api/reference/Enums/GADErrorCode).

Google's official Flutter sample combines its sample App ID and real UMP manager: [sample Info.plist](https://github.com/googleads/googleads-mobile-flutter/blob/main/samples/admob/api_demo/ios/Runner/Info.plist), [sample consent manager](https://github.com/googleads/googleads-mobile-flutter/blob/main/samples/admob/api_demo/lib/common/consent_manager.dart). iOS simulators are automatic UMP test devices; no invented physical test hash is needed. This does not guarantee inventory or prove the user's owned AdMob message configuration.

Observed integration scope is recorded separately in native evidence/delivery. Official shared sample UMP returned allowed=true/options-required=true in the available Simulator, and the actual US privacy-options form was shown/saved with completion callback. Test rewarded loads at10/30 seconds timed out in the initial probes. No SDK reward is inferred from these research facts or the eligibility boolean.
