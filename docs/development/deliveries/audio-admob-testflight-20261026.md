# 新音频与 AdMob 官方测试广告 — TestFlight 16

2026-10-26，本批已按用户明确授权完成上传与原组分发；Apple 处理完成，原 Pourlune Self 组的 0.5.0(16) 实际显示“正在测试”。

- 版本0.5.0(16)，精确发布源2b364d62f060e3a537c47a9e1db987bb26c90fea。相对独立接受的48897d3仅版本15→16及发布授权/差额说明，出水口、选定音频/署名与SDK/题库/锁实现保持。
- 精确CI40335786098两job终态success，实际head与发布源一致；终态见evidence/ci-terminal.json，未复用旧CI。
- 已实际签名导出新候选build/beta-candidates/0.5.0-16/ios-audio-admob-test-1，86500225字节/SHA991b9b9e2d5aebb9b273739715a9c03ddf17fbadbf2c2fb5cb389662a3a1524d。同字节只读文件镜像build/package-review/0.5.0-16/ios-audio-admob-test-1；目录755的镜像权限差额由父单列为非阻断，不重建。
- 父已核561镜像文件/557候选索引/513精确源、147资产/90题/锁、两处strict签名及原profile/证书、5dSYM/24隐私清单；51项内容检查通过，见本批evidence/package-independent.json。
- 实际AppID ca-app-pub-3090980891246277~5042293200，两iOS单元仍为官方sample：rewarded /1712485313、interstitial /4411468910（publisher3940256099942544）；双端owner收费unit均不在AOT。prod Firebase/NoAdID/独立采集默认关闭，UMP/奖励/资格/离线回退门控不变。不是商业广告就绪。

## 实际上传变体

Xcode使用可变副本build/organizer-upload16/Runner.xcarchive，原候选不改。此次Custom→App Store Connect→Upload，明确关闭Upload symbols和Manage version/build，启用TestFlight internal testing only；固定既有2026/9/16证书及Pourlune App Store Beta20261022，不生成profile/私钥。

上传前已停在Review内容的Upload按钮前供独立核验；队列IPA、保存与只读变体SHA一致：405c7625647b9157f154cb0bd94ce9ce4f56b1b5172553ae2c3a675f8aa53cdb，86500276字节。只读文件build/package-review/0.5.0-16/organizer-audio-admob-test-1/prepared-upload.ipa。仅Info新增TFInternalTestingOnly=true、Mach-O签名区域与CodeResources差额；无新增/删除文件，无Symbols，embedded profile字节保持。父上传前变体差额25项全绿，严格签名/profile/执行字节/内容一致；精确CI总终态success后点击了明确Upload按钮。Xcode实际显示App upload complete、0.5.0(16) uploaded，Organizer显示Uploaded to Apple/22:19/Build16，无可见警告。

## 平台状态

上传已成功，Apple处理完成，ASC build ID为4db79882-0c24-4020-b0fc-a99c6022a9e7。沿用已获用户确认且加密事实未变的“标准加密算法与Apple系统加密同时使用”及内部测试不在法国分发，实际保存后状态变为“准备测试”；未谎报无加密或修改包内声明。测试内容已保存。

随后只加入既有Pourlune Self组1853bacc-97d1-40f9-b0cb-ae9ef9d01c74。实际构建页显示群组1/Self/2人；原组构建页显示0.5.0(16)“正在测试，90天后过期”，仍2测试员、共3个构建，不新建组/成员/邀请，14和15保留。最终回读及截图见evidence/self-group-readback.txt、self-group-ready.png、testflight-ready.json。

AdMob商业审核、公开商店关联、隐私消息和app-ads待办不冒称通过，不阻塞本次官方测试广告包。手机实际更新/物理音触觉/主观混音本批未验。F9/D79/256试听状态及库、其他保护设备与网络均未操作；未更新Google Play。

总控最终实际查看上传完成及原组正在测试截图，并核对回执；最终平台独立验收通过，见review/audio-admob-testflight-20261026-independent.md及evidence/platform-final-independent.json。界面文字回执仅清除末尾UI空白，截图保留原字节。发布目标已完成，不重复上传、终态CI或邀请。
