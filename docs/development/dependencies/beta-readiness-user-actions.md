# Beta最小持有人事项 — 2026-10-23收束

工程侧已完成：工具下载/校验；Apple专属AppID、profile生成/下载/安装及现有证书本地签名；双端0.5.0+5静态候选、资源/源码/配置指纹、符号索引；英文说明/表单事实、支持隐私本地草稿；BR02设备条件/升级步骤和BR03交接。Apple登录、profile下载、Firebase四App注册均不再是用户待办。账号事实沿用2026-10-22作者控制台观察，本批未重复登录或轮询，不把它称再次独立回读。

以下归并为4组，架构集中通知即可；不要求现在逐条操作，不把密码/验证码/私钥/keystore/服务账号发到聊天。没有创建/重置密钥、代签声明、购买域名、部署、上传或邀请。

|最小动作组|持有人确需提供/自行操作|具体入口与已完成准备|对应门槛／影响|
|---|---|---|---|
|1 一次提供发布与内容决定|确认Pourlune SKU、公开支持/隐私HTTPS目的地、公开反馈邮箱及处理人；目标受众/年龄/地区、实际主体/审核联系、商业图像授权链；后续测试组/名单。已有归属资料可一次给出，不猜填。|[ASC Apps](https://appstoreconnect.apple.com/apps)；help/privacy可审草稿在docs/support/beta/；英文copy及SDK清单已备。OFL和程序音频来源已留档，不需重交。|BR-B01、03、04、05、06；尚无ASC应用记录或真实公开联系入口/权属批准。网址填入文档并不会自动进入已冻结二进制。|
|2 在控制台自行确认法律声明|AccountHolder判断现有Apple Schedule2 banner是否适用并处理实际协议；Play创建应用所需开发者政策/美国出口声明及后续实际年龄/数据/主体问卷由持有人确认。|[ASC协议](https://appstoreconnect.apple.com/business)及[Play创建应用](https://play.google.com/console/u/0/developers/8719288384645399837/create-new-app)；既有Apple Team T7U878Z8H6和个人Play账号已观察，正式BundleID及包名准备完成。|BR-B01/B01-P、05；不代签，不把banner猜成所有免费Beta的阻断，不复用FishPilot的配置/密钥。准确声明以最终包和经营事实为依据。|
|3 在本机选择授权Android签名资产|选定已有、允许用于Pourlune的upload key及alias并本地解锁；若不存在，持有人决定创建/托管，当前执行不代建或重置。不要传密码/keystore到聊天。|包名com.pourlune.app；[Android签名说明](https://developer.android.com/studio/publish/app-signing)。当前AAB格式/资源已验，工程release signing仍未配置，拿到资产后要定向实现本地签名门控并复验新文件。|BR-B02；当前unsigned不能上传，debug或FishPilot密钥不自动获准；upload key和Play实际安装app-signing key分开记录。iOS现有签名资产无需重复处理。|
|4 提供适用设备和运行/观察条件|提供可用独立真机/最低OS及安装条件；明确允许生产配置实际运行（可能涉及RC/SDK数据）的后续范围；提供合法允许的观察/正式素材采集条件。测试名单可与第1组合并。|当前devicectl无连接设备，adb仅API36/arm64/4KB模拟器；iOS仅26.5模拟器；BR02步骤、完整证据字段及截图清单已备。不会重试或改路绕过既有Cocoa513/EPERM限制。|BR-B06及03/05实际行为依据；正式安装/同签名升级/16KB/读屏音画/性能/正式截图未验。无条件时不重复旧QA或下载无可运行候选的环境来凑通过。|

内部分工：资料和权限到位后，执行方在新候选目录完成批准目的地配置/签名、必要自动/原生复验、更新最小差异索引；不把技术整合转给用户。架构独立验收并按原授权精准提交/推送。生产运行授权与将来的上传/审核/开轨道/邀请是不同决定；本轮尚未进行后者，也不要求现在批准分发。

三条结论均不就绪：iOS内部TestFlight、外部TestFlight、Play closed。Play internal不能代替closed，适用个人账号12人连续14天属于后续生产访问条件，不把它误作开始封测前置。可选广告保持关闭，真实联调和旧Firebase运输失败保留真实状态，Firebase无需重新注册。

执行交付：[BR02](../deliveries/beta-readiness-BR02.md)、[BR03](../deliveries/beta-readiness-BR03.md)；具体重建/复验条件及最终产物指纹见报告链接。此表只集中无法代签或缺少实际资产的输入，其余可做项已由执行方收束。
