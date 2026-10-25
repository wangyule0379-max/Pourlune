# Build 10 iOS 独立核包

## 当前结论：首候选阻断，尚不允许上传

独立核包对象为只读镜像 `build/package-review/0.5.0-10/ios-ui-content-1`，IPA SHA256 `343e01632fa83eb19608c33144caed3ce01e499a7f980251f9dcb8da9ebc4378`。原候选保持冻结，本轮没有 build、sign、run、upload、操作 UI / F9 或读取私钥。解包与独立检查脚本仅写新的 ignored `build/package-review-work10/independent-ios-1/`，公开结果在 [package-independent-ios.json](../evidence/beta-build10/package-independent-ios.json)。

**Critical：未发现。Important / P2：原生 integration-test 组件与注册器残留，首候选不通过“无测试注册器”门槛。** 不能用旧 build 9 通过结论代替本包，也不能以正常 Dart main 没有 QA 入口为由忽略原生组件。

父已取消 Xcode 中首候选的上传工作副本并确认未 Upload。首候选不得进入后续上传；新构建工具修复的源码审查无阻断，可推进新 exact commit / 精确 CI 与新目录构建，但新包须重新独立核验实际字节后才能解除此门槛。

## Important 证据

- 从原 IPA 独立解包的实际 `Payload/Runner.app/Runner` 含 `IntegrationTestPlugin`、`IntegrationTestIosTest`、`FLTIntegrationTestRunner`、`plugins.flutter.io/integration_test` 以及测试方法 / 属性的 Objective-C 元数据。AOT 不含这些测试入口、已知 QA 数据库名或调试故障按钮，说明正常 Dart main 与原生测试组件必须分别核验。
- 首候选实际 build.log 有 76 行 integration_test 编译 / 链接标记；当时生成的 `GeneratedPluginRegistrant.m:78` 明确执行 `[IntegrationTestPlugin registerWithRegistrar:...]`，生成的 SPM Package.swift 包含 integration_test package 与 integration-test product。
- 独立读取旧 build9 IPA Runner，也存在相同十项类 / 通道 / 测试方法字符串。因此它是此前漏检的上游生成行为，不能把旧结论当成当前免责依据，也不能武断归因于 `--no-pub` 缓存。父已从本机固定 Flutter 生成器源码确认 iOS release 仍包含此 dev plugin。
- 未运行生产二进制，不宣称测试通道已经被实际调用或存在已证实的外部攻击路径；阻断依据为本次明确要求的发布包纯净性及实际原生注册器残留。

## 首候选其他已核事实

1. **来源和冻结。** 537 个输入文件逐项 SHA256 与 candidate-freeze.json 完全匹配，files 444 / dirs 555；检查结束再算一次仍未变化。candidate.json 自列 533 项全部匹配，sources.json 自身哈希匹配；417 项 source 每一项均从 Git exact commit `ff25d43fb4253268aa7f2cbcb43f85a04cf000a7` 重新读取并核哈希，没有用旧 build9 来源代替。
2. **精确 CI 终态证据。** 已读本批 ci-final.json，run `40051402505` 对上述 exact SHA，tests-and-android / ios-build 两 job 均 completed / success。本次是核对该终态记录，没有重跑 CI 或将 Simulator CI 当成签名包实测。
3. **IPA 与资源。** 新 IPA ZIP 无重复项、CRC 正常，独立解包后每项与原 ZIP 字节一致。136 项 `app/assets` 全部与当前受验来源相同，60 主线、30 每日、catalog 均匹配；没有打包 `.sqlite` / `.db` QA 库。名称编码按 ZIP URL 转义归一后逐字节比较字体等资源。
4. **身份。** 实际 IPA Info.plist 为 `com.pourlune.app` / `Pourlune` / `0.5.0` / build `10`。实际 archive Dart definitions 与 prod / native-ready true / ads disabled / iOS / version 10 / 正常 `lib/main.dart` 选择一致；没有 QA 场景或 QA 库定义，也没有 request-unit 定义。
5. **广告和采集。** 实际 native AppID 为官方 iOS sample `ca-app-pub-3940256099942544~1458002511`，owned_registration_verified false；实际 AOT 没有 `ca-app-pub-…/…` 形式的广告请求 unit 字符串。Info.plist 的 Analytics / Crashlytics 采集默认均 false。编译选择明确 no-AdID，未声明 ATT 文案；没有把 sample AppID 当成自有登记、商业广告资格或真实展示成功。
6. **真实生产配置只读匹配。** 编码的 Dart Firebase options、包内 GoogleService-Info.plist、本地已选 prod/ios options 及独立 prod 登记互相匹配，native bundle ID 正确。原生配置值只在内存比较，没有写出完整配置、定义或凭据。
7. **目的地。** 包内 AOT 含已确认的帮助 `https://wangyule0379-max.github.io/pourlune-support/`、隐私 `privacy.html` 完整 URL 与反馈邮箱 `wangyule0379@gmail.com`；实际编译定义与候选目的地相同。本核包没有发送邮件或把收件、法律批准当成通过。
8. **SDK 锁与隐私资源。** 应用 / 核心 pubspec.lock、SPM Package.resolved 均有 exact source 哈希；24 份 SDK PrivacyInfo.xcprivacy 均存在且可解析。仅确认存在性与锁定事实，没有作法律全面认证或商店声明充分性审计。
9. **签名与符号。** 对独立解包后的新 app 执行 `codesign --verify --deep --strict` 成功；entitlements 为 `T7U878Z8H6.com.pourlune.app`、Team `T7U878Z8H6`、get-task-allow false。嵌入 profile 为 App Store，无设备列表 / 全设备标志，beta reports active，2027-09-16 到期。IPA、archive、dSYM 的 Runner / App / Flutter arm64 UUID 分别三方一致，具体值见公开 JSON。
10. **导出边界。** ExportOptions 实际为 manual / destination export / uploadSymbols false / manageAppVersionAndBuildNumber false；没有 allowProvisioningUpdates，没有生产运行、符号上传或商店上传。

## iOS 证书输入说明纠正

最初给定的 `E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2` 是历史 Android upload certificate pin，不能用于 iOS。独立从新 app codesign 签名抽取公开叶证书，并与新嵌入 profile、旧 build9 IPA 的实际 signed Runner 叶证书和旧 profile 比较，DER 字节相同；正确既有 iOS SHA256 为：

`C8597E5EB05BFA50F197544BA147D49BC9B3AA5468F01F44081CB09AA373ED83`

父已确认原输入标错。没有新建、重置或替换 key；该说明纠正不是包被篡改或证书轮换证据。

## 构建修复的只读审查

已读 `ios_release_plugins.py`、其单元验证及 firebase_build / beta_build 差额。没有亲自运行 Flutter / Dart / build / sign。当前修复：正常 Flutter 成功刷新后，仅在手动 App Store archive / export 的 scope 内，精确剔除唯一已知 dev plugin 的 import / register 调用与两条 SPM 声明；metadata、SDK、依赖版本、锁文件不改。

所有已知元数据 / 格式 / 残留校验在写入前完成；出现未知 dev plugin、缺块、重复块或额外引用会 fail closed。ExitStack 覆盖 archive / export，异常和正常退出都恢复两个生成输入；archive 实际 Runner 的拒绝 guard 位于 export 前，beta 还对导出 app 的 Runner 再拒绝一次。该源码设计未发现阻断问题，仍须新生成包的原生字节无标记、新冻结、exact SHA 和 CI 共同确认。首候选的 537 文件冻结及阻断事实保留，不覆盖旧包。

## 未验范围与下一门槛

当前只完成 iOS 首候选核包；没有扩大 Android / Play。没有将 UI / 内容独立通过、物理设备、人类首玩难度、真实广告、账号法律声明、生产网络运行或上传流程互相替代。新候选应在新目录冻结并重新核包；**在 native 测试组件门槛解除前，不允许下一 Xcode 工作副本上传准备或最终 Upload。**
