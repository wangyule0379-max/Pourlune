# Beta持有人事项 — BR04更新（2026-10-23）

以[持有人确认表](beta-owner-decisions.md)和BR04计划为最新输入；BR01–03历史验收边界保留。**已确认**SKU POURLUNE-IOS-001、英语、益智游戏、免费封测/广告关闭、组名Pourlune Beta。Apple登录、profile下载/安装/本地签名、Firebase四App注册已解决，不再要求用户重复处理。暂无域名/邮箱/Android key，不把建议当批准。

远端Mac无法USB连接用户手机，**USB不再是上传前一律门槛**。工程/包签名校验先完成，授权分发后经TestFlight/Play验本人手机；真机/最低OS/16KB/读屏/音触觉/性能/升级等未验风险仍如实保留，不因调整时序改成通过。详细[远端路线](../evidence/beta-readiness/BR04/remote-device-route.md)。

|需本人决定/操作的组|现状与最小下一步|开发侧已完成／后续代办|追溯|
|---|---|---|---|
|发布主体/联系/受众/权属|提供准确经营/隐私主体、审核联系和公开支持邮箱及处理人；确认真实目标受众/国家地区/图像商业授权。SKU等通用项已确认，不再询问。|双平台逐字段技术依据、英文资料、未决栏已备；不在仓库公开私人审核电话/测试者邮箱，不猜数值分级/trader/export。|BR-B01、03、04、05|
|本人控制台法律声明|按架构正在引导的真实提示阅读Apple适用协议、Play政策/出口/App Signing条款及最终问卷；不代签。新应用记录创建前核对是否已有，避免重复。|已用确认值准备记录表；Schedule2 banner适用性不能猜成免费Beta一律阻断；不再重复登录轮询。|BR-B01/B01-P、05|
|独立upload key|本人决定创建后，在远端终端交互创建专用pourlune-upload，备份并授权本地使用；不复用FishPilot，不发密码/keystore到聊天。|[本人命令](../evidence/beta-readiness/BR04/owner-key-steps.md)仅准备未执行。已完成密码文件/权限/alias/证书pin/有效期/debug拒绝及签名新副本/失败关闭工程；真实key后执行侧接入，不把工程转给用户。|BR-B02|
|公开站点与后续封测范围|独立pourlune-support公共repo+Pages为待批准方案；本人注册真实公开邮箱。待具体网页/最终包可审后分别决定公开部署、生产配置运行与商店分发，并给已有内部资格或外部/closed名单/手机OS/地区。|仅网页3文件draft及ZIP、Pages/IP日志说明、目的地构建输入/元数据、手机最小试玩/反馈/N→N+1路线已备；未知不填示例值，不创建repo/部署/上传/审核/轨道/组/邀请，不扩IAM。|BR-B03、05、06|

纯网页目录为docs/support/pages-site/，不是已发布政策。实际URL/邮箱获准后，开发侧校验可达/收件并在新候选目录编入，必要时增构建号；格式通过不等于归属、法律或商店通过。新签名AAB的upload证书与Play最终安装app-signing证书分别核对。首包没有旧正式N就先记升级未执行，后续N+1原位更新验证，不卸载/清档凑恢复。

不需要用户再下载描述文件、注册Firebase、连USB/启开发者模式、导SQLite、制造存储故障或反复走旧T/FB/MS路线。可选广告保持关闭，生产当前compile-only，旧Firebase运输问题仅网络条件实际变化且获准后有限复验。内部新增工程的实际/替身验证与尚待真实资产项见[BR04交付](../deliveries/beta-readiness-BR04.md)。
