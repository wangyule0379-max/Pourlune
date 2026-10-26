# 0.5.0(16) 测试发布差额预检

本次仅更新既有内部TestFlight/Pourlune Self当前2成员；不公开App Store、不改Google Play、不新增成员或邀请。用户授权及范围见deliveries/audio-admob-testflight-handoff-20261026.md。

生产基线48897d3：出水口修复、完整Dream Culture及CC BY4署名、CC0水声和实际flow起止接音，以及已独立接受的AdMob官方测试链路。新版仅将0.5.0+15改16，不改变受验生产实现、题库/每日目录、SDK/锁或采集/奖励/离线门控。test显式使用console回读AppID，但rewarded/interstitial仍是官方sample unit，不启用收费unit；后台商业审核、隐私消息/app-ads尚未就绪不冒充通过。

现有privacy/support目的地不变。UMP先判断资格；未获资格、网络失败或无广告时保持免费提示/撤销/重开/离线核心。Firebase Analytics/Crashlytics独立默认关闭，NoAdID保持；实际新IPA须核配置/隐私清单，不把测试广告包声明成disabled/无网络数据。官方test文档已核https://developers.google.com/admob/flutter/test-ads，内部组及加密技术分类本次查https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/ 与 https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/。

自动guard对Flutter app根实际输出critical0/high5/medium4，未使用override或修改扫描器。定位如下：

|扫描项|本批处置|
|---|---|
|placeholder|service_config.httpsUrl中example/localhost为明确拒绝列表；目的地仍为真实已发布支持隐私站，不是占位后端。|
|export compliance|保留真实Flutter/BoringSSL+系统TLS，不填写无加密或改Info绕过；新包技术分类与原实际配置一致，按平台要求处理。|
|Android R8/DataSafety/AdID/12testers|本次不更新Android包或表单，不反向新增AD_ID。iOS test模式/NoAdID及独立采集同意在实际包中另核。|
|VoiceOver/haptics|Flutter真实语义/点击与已有触觉实现沿受验版本；扫描原生UI启发式不替代已验Flutter界面。物理音触觉不由构建替代。|
|age rating|既有13+目标事实不变，无账号/IAP/订阅/UGC/赌博/付费货币新增。此次是当前内部组测试，不新增公众评级承诺。|

结论：可准备本次测试候选，尚待精确源CI终态、新IPA/签名/原生纯净独立核验和实际上传/处理/原组回读。复用已验音频/实际广告/普通UI证据，不新加审核矩阵。F9/D79/256及其界面、库、设备状态和网络不操作。
