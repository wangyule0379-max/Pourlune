# Pourlune iOS 0.5.0(19) 提交记录

状态：签名包、精确 CI 已通过；TestFlight 既有 Self 组正在测试；2026-10-29 00:10（台北）App Store 正式提交完成，当前“等待审核”。父已实际查看组页面、提交成功及等待审核截图。未公开发布。

## 候选及验证

- 源：`eb48e7d151e6cd2aeaccb653b8e960d6c3c4e561`。
- 精确 CI：`40718567516`，终态 `completed/success`，父已通过 GitHub API 核对 head 与结果。此前 SDK 源 CI `40715422974` 已成功。
- 候选：`build/beta-candidates/0.5.0-19/ios-production-gm020-1/Pourlune-0.5.0-19.ipa`。
- 86,736,330 字节；SHA-256 `b9f0001c38baea35917681add9c88d04d35f6dd75c8aae117976444896afa5ca`。
- SDK 0.2.0 固定包 SHA-256：`70effde1c9150b416b34f4dd4b6d95912ef836b5f429c98ea5a8cbf98fd0c167`。
- 563 源输入与 563 候选文件 hash、ZIP 字节、archive/IPA 签名及身份、90 题与资源、dSYM UUID、原生测试插件清除、GM 生产配置和正式广告单元均已独立核验。详 `evidence/ios-production19/package-independent.json`。

SDK 生命周期、真实测试广告、奖励、重试/重启去重、统计撤回及后台回读详 `gamemunchies-sdk-020.md`。本轮未改游戏构图、接水瓶、倒水修复、奖励/存档规则。Android 原生验证未完成，不宣称双端全部通过。

## 商店准备

Use Computer 负责电脑操作。ASC app `6826203407`：0.5.0、免费、既定 13+ 目标、美国/加拿大、手动发布。既有 Self 组 2 人，不另邀请。审核联系人已按用户提供的信息保存，电话不写公开证据。七类 App Privacy 已经本人明确同意后发布，隐私站同步正式广告和 SDK 0.2 的说明。

Organizer 上传完成，ASC 已处理19，出口声明按实际标准 TLS／法国否补填，缺失状态解除。ASC build `c39e2e07-bfb8-4170-bbcf-d467e60d8c5f`，既有 Pourlune Self 仍2位测试员，0.5.0(19)显示“正在测试”、90天到期，无新邀请。

正式审核提交 ID `b9c5f905-35d7-4e43-885e-eb15c63a25db`，提交版本0.5.0(19)，台北2026-10-29 00:10，实际状态“等待审核”。美国/加拿大、免费、手动发布保持。此前账户协议通用提示没有阻止本次提交，未代签新协议。证据：`evidence/ios-production19-self.png`、`ios-production19-review-submitted.png`、`ios-production19-review-waiting.png`。

实际上传变体：SHA-256 `5732d392d842be0f343423c055d46b275aa7a96372ab4d77ea77922789a38b86`，101,668,176 字节。父从该次分发日志定位原 IPA 并保留副本，8 个重签名 Mach-O 的非签名代码全同，Info.plist 语义全同，strict 签名/身份通过；差异仅签名、同 Team 同 App 的既有 Store profile 与新增四个符号文件。详 `evidence/ios-production19/organizer-independent.json`。四个供应商 SDK dSYM 警告未导致上传失败，应用自身 Runner/App 符号匹配。

## 真实边界

当前配置使用现有正式 AdMob 单元、NPA 请求、UMP 资格及 PG 内容上限，不擅自改变统计选择。AdMob 应用仍需平台审核且投放受限；官方测试广告成功不证明正式库存填充。美国隐私消息详情页面未成功回读，不声称该项发布已验证。无广告库存不阻塞离线游戏。未点击真实收费广告、模拟收入或配置报表 OAuth。审核通过后仍手动发布。
