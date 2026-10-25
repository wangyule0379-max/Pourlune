# 三条提交路径分别交接（未上传、未开轨道）

本表是项目提交前门槛及平台路径，非声称每个完整App Store资料字段都是TestFlight内部测试强制项。实际必填项在持有人完成应用记录后按当时控制台核对；目前不重复登录或猜填。账号观察沿用BR01作者记录，未升级为本批架构/作者再次回读通过。

|项目|TestFlight内部|TestFlight外部|Google Play closed|
|---|---|---|---|
|精确包|签名IPA0.5.0(5)，本地签名通过；还需最终支持配置重建/复验|同一iOS最终候选要求；不能把内部可测当外部已过审|当前只有unsigned AAB0.5.0/5，非最终可上传包；需上传签名及最终配置|
|应用记录|Apple显式AppID/profile已有；ASC应用记录/SKU待持有人确认|同左，另Beta审核资料/联系信息|Play包名可用仅为BR01观察；应用记录未创建，政策/出口声明未签|
|协议／身份|会员与Team已有记录；Schedule2 banner由AccountHolder判断适用，不猜免费Beta被阻断|同左；出口问卷按实际SDK/加密事实由持有人答|持有人处理实际政策/出口/开发者及app-signing决定；不改变别的App|
|签名／分发|既有证书/profile本地export；平台处理未发生，真机TestFlight安装未验|首次外部构建按平台Beta审核路径处理；尚未提交|上传key与最终APK app-signing key区分。AAB JAR签名、Play最终证书/实际测试安装均未验|
|隐私／支持／权限|公开归属URL/反馈邮箱/处理责任人未定；DRAFT已备；SDK/RC不能说零采集|同左，审核/测试联系信息未定|DataSafety须覆盖嵌入SDK/实际行为，AD_ID等权限已清单化；未提交表单|
|内容／受众／地区|实际离线解谜功能草稿；年龄/地区/出口/主体由持有人确定|同左，外部测试范围需确认|年龄分级/目标受众/国家地区/广告声明以本版本事实和表单为准，未知不猜填|
|商业权属|图像及派生来源UNCONFIRMED；Nunito/OFL、程序音频来源已留档|同左|同左|
|测试者／组|仅已有获授权且具备访问资格的ASC内部用户；没有授权名单/组，不扩大IAM|持有人提供外部名单/组或批准公开链接；当前未邀请/开链接|明确closed组/地区/opt-in入口，用户给名单或授权既有列表；internal不能替代closed|
|说明／反馈|英文WhatToTest/已知问题/复现字段已备；未创建实际反馈入口|另审核路线无登录/无购买；未虚构测试账号/录屏|私密测试反馈路线草稿已备；没有可访问测试链接|
|当前结论|不就绪，无上传/处理/安装证据|不就绪，无外部审核/安装证据|不就绪，无上传签名/应用记录/closed发布证据|

[TestFlight官方路径](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)区分内部用户与外部测试/审核；[Play测试轨道](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en)区分internal/closed/open。[特定新个人账号12人14天](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)用于后续生产访问，不是开始封测前置；当前账号创建日期/适用性未核实，不预填已满足。本文不执行任何上传、审核提交、轨道创建/发布、测试组配置或邀请。
