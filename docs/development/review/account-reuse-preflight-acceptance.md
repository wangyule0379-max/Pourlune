# 账号沿用准备：独立验收

2026-10-22（Asia/Taipei）；产品架构。**只读配置准备交付通过**。没有生产代码变更，无需重跑B05。外部注册、签名、SDK真实收件及设备运行保持待验，不把本报告当接入完成。

## 实际复核

- 阅读执行报告全部八节及六份证据；六个manifest文件摘要/大小匹配。独立复核14个Pourlune源码指纹无漂移；检查service_config、Gradle条件和Xcode资源/脚本引用。
- 本聊天通过CUA只读重新打开现有控制台：Apple Developer显示T7U878Z8H6与个人会员；ASC可见FishPilot和Paid Applications Schedule持有人处理横幅；Play可见FishPilot包名；Firebase可见fishpilot-staging/production。未在当前列表看到Pourlune不代表穷尽所有权限/团队，未查注册可用性或写权限。
- 本地实际核对：Pourlune两端Firebase文件缺失；iOS缺plist资源引用与Crashlytics上传阶段；Android插件依赖根google-services.json存在，release签名未配。不能仅设置native-ready或把配置放在不生效目录就算完成。
- 独立运行devicectl与adb清单：无已连接物理Apple设备、无Android设备。未启动/清理任何AVD或App；普通B04审查库未操作。
- AdMob连接失败和本地签名材料明细使用执行方分层证据，本轮不重复失败请求或输出证书个人资料，不将其升级为独立SDK/签名结论。
- 独立核对[Firebase环境隔离指南](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)：同项目共享资源/Analytics property，开发与生产宜分项目；核对[Crashlytics符号输入说明](https://firebase.google.com/docs/crashlytics/ios/get-deobfuscated-reports)，报告方向成立。最终路径和可读崩溃仍须配置后现场验证。

原始账号页面含个人资料，仓库仅保留白名单事实，不保存全文或个人资料截图。独立证据：account-reuse-preflight-evidence.json。无P1/P2文档缺陷，不改作者交付及其冻结清单。

## 决策与下一步

1. 账号来源已关闭：沿用FishPilot Apple/Google/Firebase，不再要求新开户或重复登录。可见会话不代表Pourlune注册完成。
2. 提供可审核方案：正式双端ID建议`com.fishtk.pourlune`；同一Firebase账号下独立Pourlune开发/生产项目，候选ID`pourlune-dev`/`pourlune-prod`。这些是尚未确认和查重的建议，需用户确定后再注册，保留当前开发与QA身份及存档。
3. 账号持有人须自行在[ASC Business](https://appstoreconnect.apple.com/business)核对并处理协议提示；不代签，也不以横幅推断所有开发任务受阻。
4. AdMob归属待恢复可读访问后确认，不能根据Google账号推定已开通；真机联调等待连接iPhone/Android。其余支持/隐私/权属依赖沿用user-handoff，不重复整份通知。
5. 准备工作与B05 CI均已结束；只剩具体外部交接，暂停自动轮询。用户确认目标身份或提供资料后，恢复既定范围的注册/本地接入计划，由原执行聊天执行、本聊天验收。权限扩大、条款、购买、商店上传与发布仍遵守独立授权边界。
