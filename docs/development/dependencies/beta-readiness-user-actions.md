# Beta集中持有人事项 — 2026-10-22执行核查

已完成能代办的准备：asc/bundletool下载校验；现有账号只读核查；Apple Pourlune显式AppID登记；复用既有分发证书生成、下载并安装Pourlune专用AppStore描述文件；Play com.pourlune.app可用性检查；工程/英文资料/本地支持草稿与签名校验路径。没有创建或导出私钥、接受法律声明、上传商店或发送邀请。不要把密码、验证码、密钥文件或服务账号发到聊天。

|编号|具体入口/最小缺项|影响|我已准备/可继续执行|
|---|---|---|---|
|BR-B01|[App Store Connect Apps](https://appstoreconnect.apple.com/apps)：确认Pourlune商店SKU；现有Schedule2更新banner由AccountHolder判断适用并自行处理。AppleTeam T7U878Z8H6已核实，会员续订2027-09-17。|未建立ASCApp记录，不能关联TestFlight构建；banner未实际阻止免费Beta的状态不猜定。|正式BundleID已登记，PourluneAppStoreprofile已下载安装并匹配既有证书。表单可用iOS/Pourlune/en-US/com.pourlune.app，SKU未知不猜填。|
|BR-B01-P|[Play创建应用](https://play.google.com/console/u/0/developers/8719288384645399837/create-new-app)：持有人批准/勾选开发者政策和美国出口法律声明。|PourluneApp记录未建，封测设置不能完成；不代签。|现有个人账号已登录，包名com.pourlune.app显示可用，英文/游戏/免费事实草稿已准备。未勾选法律框。|
|BR-B02|本机已有授权Android上传密钥由持有人选定并在本地解锁；如没有，密钥创建/托管决策由持有人处理。|Android候选仅unsigned，不能作为Play可上传包；不重置/复制FishPilot密钥。|已准备AAB编译、bundletool/签名核验流程。仅需后续指定本地资产，别把keystore或密码发到聊天。iOS现有证书/profile已可用，实际export结果单列。|
|BR-B03|确认已有归属的HTTPS支持/隐私地址、公开反馈邮箱及来信/隐私请求处理人；批准披露/保留/请求流程。|当前App链接如实未配置；缺公开政策/支持无法完成提交资料。|docs/support/help-draft.md、privacy-draft.md及可本地查看的docs/support/beta/已准备。未知域名不购买、不猜邮箱、不擅自部署。|
|BR-B04|原视觉与派生美术商业使用权/授权链确认；如需更换只处理具体缺权素材。|不能把候选美术或用户接受视觉当商业权属批准。|字体Nunito OFL/source、原创程序音频及原图/生成来源/散列齐备；manifest仍UNCONFIRMED。|
|BR-B05|按实际目标受众/地区确认年龄、内容权利、trader/export、商店隐私/DataSafety与审核联系信息。|不得猜填法律/主体/年龄/地区，未完成对应平台表单。|实际能力/SDK/门控/已知缺口和英文copy答题依据在BR01证据目录；无账号/支付/UGC等N/A已区分。|
|BR-B06|提供可用代表真机/最低OS安装条件及允许的屏幕素材采集方式；既有捕获限制不绕过。后续测试组/测试者由持有人给出或用已有授权名单。|BR02物理/升级/无障碍/音触觉/性能与正式截图、BR03分发不可虚构。|已验模拟器/核心范围继承；设备与截图清单已备。暂不上传、不创建测试组/开轨道、不发送邀请。|

这不是要求现在逐条动手或重复注册Firebase；Firebase dev/prod四App已存在，继续使用。可选广告在候选中关闭，真实广告联调未验不伪称通过；旧Firebase运输失败也不靠重复实验补作成功。12人14天属于适用账号后续生产访问条件，不把它误作开始封测的前置。具体无法代办的事项由架构集中通知，其余实现继续。
