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
