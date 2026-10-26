# Build15 发布差额预检

范围：既有内部TestFlight，四项已独立验收的配色／可见流／口圈／换选修订。无账号、服务器、IAP、订阅、UGC、支付、权限、SDK／锁或题库变更。新包仍须核实际配置、隐私清单和原生纯净。不是公开App Store上架或Google Play更新。

2026-10-26读取[Apple审核指南](https://developer.apple.com/app-store/review/guidelines/)的完整性／Beta／准确元数据，以及[Apple加密技术分类表](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption)。本次继续真实说明标准TLS与Flutter附带加密，不把Info写成无加密；精确技术分类等新IPA核验后处理。未接受新法律协议。

合规自动guard实际退出2，报告critical1/high7/medium5；没有设置override环境、关闭规则或修改源码来换绿。人工按实际发布路径处置：

|扫描项|核查与处置|
|---|---|
|critical staging/localhost；high placeholder|service_config.dart:136起是httpsUrl明确拒绝localhost/example域名的列表，返回null，不是业务后端。实际目的地沿用已发布的Pourlune支持站/隐私页及公开支持邮箱。按代码确认误报，非未修复服务器。|
|high subscription cancellation|游戏无订阅/IAP/会员；扫描器跨文件匹配包含SDK/工具中的subscription与cancel字词，不构成取消付费功能。不得据此增加商城/订阅。|
|high unsafe deeplink|Runner Info.plist无CFBundleURLTypes/URLSchemes；本轮不新增URL路由。全树包含SPM等依赖文件，实际新IPA/entitlements另核。|
|high export compliance|不修改ITSAppUsesNonExemptEncryption来规避；新包继续核Flutter标准加密，并按仅本人内部测试真实事实填写已有技术分类流程。|
|high SDK privacy/DataSafety|依赖与采集策略不变；ads disabled、Analytics无AdID、Analytics/Crashlytics独立默认关闭；RC可能处理安装数据。新IPA核SDK隐私清单，不声称零数据；本次不改Play表单。|
|high R8/AD_ID|Android不发布；现有Manifest已显式移除AD_ID。不能照全局提示反向加权限或扩大平台改动。|
|medium social/accessibility/haptics/age/12testers|无社交功能新增；Flutter语义/触觉沿用已验实现；既有年龄事实不变。Play生产12人门槛不作为本次本人内部TestFlight上传门槛。物理手机声音/触觉仍未验。|

签名前结论：当前代码差额可准备关闭广告候选；扫描critical已定位为拒绝列表误报，无命中的真实staging后端。上传仍受新精确CI终态成功、父独立新IPA/签名/内容/原生纯净通过约束。

ASC已实际回读15空闲；Self现为2人，因此不沿用旧单人假设，不改旧成员。只通过个人定向或新手动单人内部组关联既有本人，无邀请/账号扩权。Xcode账号/团队及既有Pourlune profile已核可用。
