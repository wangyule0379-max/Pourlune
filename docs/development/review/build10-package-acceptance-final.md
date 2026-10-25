# Build 10 最终 iOS 候选 3 独立核包

## 结论

**实际包、最终 Organizer 变体与精确 CI 门槛均通过，未发现未关闭的 Critical / Important；允许按已有授权继续下述 exact 队列的最终 Upload。** 本 reviewer 未执行 Upload，不声称已经上传、生产运行或真机通过。

首候选的原生 integration-test 残留由候选 3 的新字节证据关闭；[首候选阻断报告](build10-package-acceptance.md)与原包保留，不改写历史结论。

## 本次输入与复现边界

- 原候选：`build/beta-candidates/0.5.0-10/ios-ui-content-3`；只读镜像：`build/package-review/0.5.0-10/ios-ui-content-3`。
- IPA：`Pourlune-0.5.0-10.ipa`，59273190 bytes，SHA256 `8eae6eafbbae3eabdefeebddc43b3ff12d7f40c9172c49967b4b6bac8c7216e2`。
- 来源 exact commit：`05220d7124519b72ca8366df38d936b9dac2544c`。419 项 sources 各自从 Git 该 SHA 重新读取核对；371 项此前受验 `app/` 与 `packages/pourlune_core/` 来源保持相同，包含实际 UI / 核心 / 资源及相应平台与测试来源。
- 新解包与核验脚本仅在 ignored `build/package-review-work10/independent-ios-3/`。本 reviewer 未执行 Flutter / Dart / pub / build / sign / run / upload、未操作 UI / F9、未修改源或输入镜像，未读取私钥。
- 新公开结果：[package-independent-ios.json](../evidence/beta-build10/final/package-independent-ios.json)。原生 Firebase / profile 内容仅在内存匹配，不输出完整配置或凭据。

## 独立核验结果

1. **冻结与来源通过。** 538 文件逐项 SHA256 等于 final/candidate-freeze.json，文件 444、目录 555；检查结束重新核哈希仍一致。candidate.json 自列 534 项与源 manifest 自身哈希匹配。419 source 全等 exact Git SHA；没有借用候选 1 或 build9 的旧通过代替本次检查。
2. **原生测试插件阻断关闭。** 从新 IPA 独立解包的实际 Runner 不含 `IntegrationTestPlugin` 或 `integration_test` 字节，包括原通道标记；实际 AOT 也没有测试插件、已知 QA 库或 debug 故障操作字符串。包内没有 `.sqlite` / `.db`。归档使用正常 `lib/main.dart`，实际编码定义没有 QA 场景或命名库。
3. **生成输入恢复通过。** `ios-export/release-plugins.json` 只排除已知 integration_test。独立重算当前两个生成输入，均与证据的 before_sha256 完全相同；未将 archive 临时剔除状态遗留给后续 QA，也未改 Flutter SDK / 插件元数据 / 依赖锁。
4. **资源通过。** ZIP 无重复项、CRC 正常，解包后每个文件与 ZIP 原字节相同。136 项资产与当前受验 source 逐项相等；60 主线、30 每日、daily catalog 全部相同。
5. **实际身份和构建选择通过。** IPA 为 `com.pourlune.app` / `Pourlune` / `0.5.0` / build `10`。新 archive 日志实际编码的 Dart definitions 为 prod、native-ready true、ads disabled、iOS、正常 main、version10；no-AdID 环境选择明确，没有 allowProvisioningUpdates 或广告 request-unit 定义。
6. **配置及默认采集通过本次静态范围。** 编译 Firebase options 与包内 native plist、本地 prod/ios options、独立 prod 登记一致；native bundle ID 正确。Info.plist Analytics / Crashlytics 默认均 false，没有 ATT 文案。仅验证静态选择，未启动生产服务。
7. **广告与目的地通过本次静态范围。** Native AppID 仍为官方 sample `ca-app-pub-3940256099942544~1458002511`，owned_registration_verified false；实际 AOT 没有 `ca-app-pub-…/…` 请求 unit 字符串。AOT 及实际定义包含既定支持站、privacy.html 和反馈邮箱 wangyule0379@gmail.com。未声称自有 AdMob 登记、真实广告或邮箱收件通过。
8. **SDK 锁与资源存在性通过。** 应用 / 核心 pubspec.lock 与 SPM Package.resolved 仍逐项核对来源；24 份 SDK PrivacyInfo.xcprivacy 存在并可解析。没有将存在性检查当成法律全面认证或 App Store 声明审核。
9. **新签名与既有证书通过。** 对独立解包的新 app 执行 codesign deep / strict 验证成功；entitlements 为 `T7U878Z8H6.com.pourlune.app`，Team `T7U878Z8H6`，get-task-allow false。Profile 为有效 App Store，无设备列表 / 全设备模式，beta reports active，2027-09-16 到期。新实际 signed Runner 叶证书与新 profile、旧 build9 IPA 的实际 signed leaf 和 profile DER 字节相等，正确 iOS SHA256 为 `C8597E5EB05BFA50F197544BA147D49BC9B3AA5468F01F44081CB09AA373ED83`。初始 E098… 属 Android upload pin，已纠正，不涉及新 key。
10. **符号与导出通过。** 新 IPA / archive / dSYM 的 Runner、App、Flutter arm64 UUID 三方逐项相同，具体值见公开 JSON。ExportOptions 为 manual、destination export、uploadSymbols false、manageAppVersionAndBuildNumber false；没有上传符号或自动改写版本。

## 工具修复与默认 unsigned 兼容

已只读审查未知格式拒绝、临时处理范围和 finally 恢复；发布 scope 只在正常 Flutter 成功刷新后进入手动 archive / export。archive Runner guard 先于 export；beta 再核实际导出 Runner。新增格式或 dev plugin 不会被猜测删除。

最终 beta guard 仅作用于 profile / signed IPA。默认 unsigned iOS 仍可产出 compile-only、signed_for_upload false、external_store_gates_verified false、production_run_or_upload false；它没有被错误提升成可上传。已读 63 项工具测试 OK 日志；本 reviewer 没有另跑构建或测试。

## 最终 Organizer 变体独立核验

准备队列的只读镜像为 `build/package-review/0.5.0-10/organizer-3/prepared-upload.ipa`，59273226 bytes，SHA256 `6714344141e848c43d15dc43518857d6dc5c3a7f92370aedae4f17c20a4ff057`。已独立确认检查时实际工作队列与该镜像同字节，文件 444 / 目录 555，未修改输入。新解包与脚本仅写 ignored `build/package-review-work10/organizer-independent-3/`；公开结果在 [organizer-independent.json](../evidence/beta-build10/final/organizer-independent.json)。

相对受验候选 3，ZIP 所有文件名集合相同，只有十个文件变化：八份 Mach-O、根 Info.plist 和根 CodeResources。独立解析薄 / fat Mach-O 的真实 LC_CODE_SIGNATURE 位置与长度，八份 binary 各自长度、签名区间相同；**只遮盖实际签名 blob 后，其他字节全部一致，包含 headers、load commands、padding 与业务二进制内容。** 没有用宽泛“去掉 LINKEDIT”掩盖代码差额。

Info.plist 的唯一语义差额为新增 `TFInternalTestingOnly=true`；其他身份、版本、原生配置等全部相同。该仅内部测试限制与本次明确的本人内部组范围一致，可以接受；不把它当成外部测试组或其他分发范围批准。

CodeResources 的 `files` 只更新七个重签 framework binary 与 Info.plist，`files2` 只更新七个 framework binary；其他条目集合、值与 seal 规则均相同。资源、90 题、catalog、AOT / 正常入口的非签名字节保持不变；实际 Runner 再次检查无 IntegrationTestPlugin / integration_test。

对独立解包的队列 app 执行新 codesign deep / strict 成功；entitlements 与原候选相同，Team / application identifier / get-task-allow false 正确。嵌入 profile 字节没有变化，仍是有效 App Store profile；新实际叶证书为既有 C859…，且被 profile 授权。队列 Runner / App / Flutter 与候选 archive dSYM 的 arm64 UUID 再次逐项相同。ZIP 无 dSYM；已实际查看 Xcode Review 截图和 AX，其中 Symbols 为 Not included、Version 为 0.5.0 (10)，Team / entitlements 与实际包匹配。

## 最终精确 CI

已读 `final/ci-final.json`：exact source `05220d7124519b72ca8366df38d936b9dac2544c`，run `40053916204`；iOS job `120752515500`、Linux job `120752515642` 均 completed / success，所有步骤 conclusion success。另独立核对两份实际 job 日志摘录，均包含 exact source SHA；相应证据 `ci-ios-success.json` / `ci-linux-success.json` 为 success。Linux 覆盖 63 guard / analyze / tests / APK；iOS 为 enforce-lockfile、no-AdID Simulator 构建。没有重跑或借用旧 CI 终态。

## 分发边界

最初包审时 CI 尚未终结；现在精确 CI 与实际 Organizer 变体均已补齐并独立核过，候选 1 的 native-test Important 已关闭。本结论只对应上述 exact 队列字节；队列再次变化仍应另核。可以按既有授权继续当前本人内部组 Upload，无需把本报告误读成 reviewer 已执行上传。

未验仍包括人类首次难度、物理设备、真实广告、生产网络运行、邮件收件、账号法律声明与商店分发。Android / Play 不在本轮范围。
