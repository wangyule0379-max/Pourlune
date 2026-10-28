# iOS 0.5.0(19) 正式广告发布差额

用户明确先TestFlight、无问题后正式审核，并要求首版带正式广告。电脑操作全部由既有Use Computer执行，审核后手动发布。

## 已确认

- SDK0.2.0 iOS正常入口、官方测试广告、真实奖励/离线重试/重启去重/统计撤回已验，见gamemunchies-sdk-020交付。Android原生未完成不冒称通过，不阻塞iOS。
- 正式gameId不变，API仅api.gamemunchies.com；production标签与独立test统计隔离；默认统计及崩溃分享关闭，保留现有选择。
- Use Computer重新从正确AdMob账号回读现有iOS AppID及两个unit；公开标识登记在app/config/admob/registration.json，后续候选将冻结。没有新建广告资源。
- 只补构建工具原先缺少的production选择，客户端本来已有production配置分支；NPA请求、UMP资格、展示节流、真实奖励去重不变。官方测试成功不等于正式库存填充。
- 当前AdMob应用需审核、投放受限，提示关联公开商店；政策中心无个案问题。app-ads尚无请求数据，未证明验证成功。美国隐私消息详情持续加载，尚未读到发布状态。
- ASC当前0.5.0最新build18，19未占用。App Store首版草稿1.0需改0.5.0后选择19；原Self组2人保留。
- 原稿生成权属已有本人确认、Nunito OFL、Dream Culture CC BY4.0署名及Pouring Water CC0不变；本轮无新资源。此前空隐私API键修复/原生测试插件剔除沿用，最终新包再核。

## App Privacy填写依据（对应最终production配置）

无账号/登录/IAP/UGC/聊天/定位权限，游戏状态本地。可选Firebase与GM统计不是全部不收集，RC和广告SDK有独立网络处理。GM0.2增加广告阶段/关联ID/版本/固定原因，不采姓名、邮件、IDFA、完整棋盘、原始错误或金额。

|类型|用途|关联与跟踪|
|---|---|---|
|大致位置（SDK IP派生）|第三方广告、分析|可能与SDK设备标识关联；不主张匿名|
|设备ID（安装/应用或开发者范围ID）|App功能、分析、第三方广告|关联设备|
|产品交互|分析、第三方广告、App功能|关联安装标识|
|广告数据|第三方广告、分析|关联安装标识|
|崩溃数据、性能数据、其他诊断|App功能、分析、第三方广告（GMA诊断用途）|保守按可关联设备，不把无账户等同不关联|

当前不请求ATT/IDFA、不启用个性化、不将玩家资料接入数据经纪商，Firebase广告存储/用户数据/个性化均拒绝、无广告产品链接。仅用于安全反欺诈的共享不等同跨App定向跟踪。不能将GMA厂商通用清单盲改，也不能仅凭NPA推断所有数据不处理；须与后台实际设置一致后填写“未用于跟踪”。可选采集仍列入声明。

Apple定义：https://developer.apple.com/app-store/app-privacy-details/
GMA数据：https://developers.google.com/admob/ios/privacy/data-disclosure
Firebase：https://firebase.google.com/docs/ios/app-store-data-collection
UMP：https://developers.google.com/admob/flutter/privacy

## 尚待事实及平台结果

正式地区建议美国、加拿大，用户要求北美推荐；不自动扩大到全部地区。审核联系人用户要求沿用，FishPilot姓名已回读为玉乐/王，电话因工具隐去尚无法可靠取得，不绕过脱敏。邮箱沿用已确认支持邮箱。ASC显示账户协议提示，是否阻止免费首版提交待真实提交页回读，不能代签。

需依次记录新精确CI、最终签名包验收、TestFlight上传与组可安装、正式审核受理；未完成不写成通过。

## 跟踪声明差额

Google官方说明publisher first-party ID不用于将本发布者App活动关联第三方App，且尊重NPA；NPA仍可用于频控/聚合报表，不是零采集。无ATT授权不发送IDFA。此版本无其他mediation SDK或自定义PPID/email/phone，Firebase广告用途均拒绝，GM为本发布者统计。结合上述配置，App Privacy应披露所列7类关联数据及广告/分析用途，但不声明跨公司tracking；若后续改投放方式需重审该项。不是仅凭“NPA”三个字推导。

- https://support.google.com/admob/answer/14199649?hl=en
- https://support.google.com/admob/answer/7676680
- https://developers.google.com/admob/ios/privacy/idfa
- https://developer.apple.com/app-store/user-privacy-and-data-use/

为既定13+受众，广告初始化前设置PG内容上限，未设置虚假的年龄/儿童标签。12个Flutter定向测试及分析通过；生产构建6项广告守卫、33项Firebase配置、12项beta工具测试通过。

Use Computer已回读ASC草稿0.5.0、免费、13+覆盖、无登录和手动发布；地区未设，联系人因缺电话未保存。隐私站更新提交c3d991f255517476bb92db2aeefe780ab1f97f6f，正式privacy标签尚在填写。

## 最终签名包独立核验

运行源 `eb48e7d151e6cd2aeaccb653b8e960d6c3c4e561`；`ios-production-gm020-1` 的签名 IPA 86,736,330 字节，SHA-256 `b9f0001c38baea35917681add9c88d04d35f6dd75c8aae117976444896afa5ca`。563 源输入与提交/固定私有包一致，563 候选文件实际 hash 一致，ZIP 完整性与解包字节一致。archive/IPA 分别独立 strict 签名、既有分发 profile/com.pourlune.app/0.5.0(19)、get-task-allow=false、90 题与全部资源一致，Runner/App dSYM UUID 匹配；两份 Runner 均无 integration_test 类及通道字节。核验脚本最初未解码字体文件 URL，修正核验路径后全项通过；未修改候选。详 package-independent.json。

实际 AOT 包含现有 production gameId、api.gamemunchies.com 和两个已回读正式广告单元；不包含独立测试 gameId。原生 AppID 为现有 Pourlune 正式登记。Info.plist 的 Analytics 默认与广告存储/用户数据/个性化开关均 false，无 ATT usage description；同哈希来源全广告请求 NPA、PG 内容上限在初始化前生效。并不声称仅靠静态包检查证明商业库存填充或运行时全部 SDK 数据行为。

Use Computer 已获用户直接确认后发布七类 App Privacy 声明，父实际看发布截图。美国、加拿大两地区已保存，父实际看 2 地区回读图；未勾未来地区自动供应，手动发布不变。用户已提供审核电话，由 Computer 填入并保存，重载姓名正确、电话/邮箱非空但工具遮蔽；不把号码写公开文档。审核电话待办关闭。

精确运行源 CI 40718567516 已 `completed/success`，父核对 head 为 eb48e7d151e6cd2aeaccb653b8e960d6c3c4e561；Use Computer 已继续上传，正式审核尚未完成。SDK 实现源 645a7a2 的 CI 40715422974 已成功，不重复检查。

Computer 首次选择 App Store Connect 后 Organizer 自动进入分析上传，随后取消；当时 ASC 上传记录无19，未当成上传成功。CI终态后从同一归档继续，未反复新建候选或要求用户再次授权。

## 上传后的出口声明

Organizer 已报告上传完成，四个厂商预编译 SDK dSYM 警告记录保留，Runner/App dSYM 自身已独立核符。ASC 完成处理后要求补出口声明。实际 GM 固定客户端使用 package:http 默认 IOClient → dart:io HttpClient；实际 Flutter 二进制包含 boringssl、SecureSocket、tls13 标记，标准 TLS 不仅依赖 Apple 系统 URLSession。故按事实选择“在 Apple 操作系统加密之外或同时使用标准算法”，无专有算法；本次仅美国、加拿大，不在法国分发。不选“以上均无”来省略声明，也不为补 Info.plist 键重建19。

依据：[Apple 加密文件要求](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/)、[Dart HttpClient](https://api.dart.dev/dart-io/HttpClient-class.html)、[Dart TLS 源码](https://github.com/dart-lang/sdk/blob/main/runtime/bin/secure_socket_filter.cc)。后续平台结果按实际回读记载，不把选项判断当正式批准。

## 最终平台回执（2026-10-29 台北00:10）

父实际看过 `ios-production19-self.png`：既有 Self 2人，19正在测试、90天到期；`ios-production19-review-submitted.png`：已提交1个项目；`ios-production19-review-waiting.png`：iOS0.5.0(19)等待审核，提交ID b9c5f905-35d7-4e43-885e-eb15c63a25db。ASC构建ID c39e2e07-bfb8-4170-bbcf-d467e60d8c5f。声明保存后Missing Compliance消失，未触发额外出口文件要求。没有代签账户协议、增加邀请或公开发布。

实际Organizer上传IPA另核 `organizer-independent.json`：101,668,176字节，SHA-256 5732d392d842be0f343423c055d46b275aa7a96372ab4d77ea77922789a38b86。8个变更Mach-O非签名代码全同、Info语义同，strict签名及既有同Team/App分发profile有效；新增4个符号文件，资源不变。上传的运行内容与已验源相符。商店审核尚未批准，商业广告填充和Android原生未验边界不因提交而改写。
