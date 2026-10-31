# GameMunchies 客户端地址差额

2026-10-28，作为整体统计/广告控制接入中的独立可审差额；不因换地址单独分发商店包。

正常main的GameMunchiesReporting.baseUrl固定为https://api.gamemunchies.com，不带/api后缀；当前活跃reporting单测使用同一新地址。gameId/platform/environment、事件字段、Google广告单元和回调不因换地址改变。最终构建仍须选择已核test或production登记，不能把换host当成完成统计接线。

既有SDK的ClientOptions本就支持HTTPS baseUrl，本次域名不要求升级或重接SDK。固定源92f5882的变化是另一个已授权需求：统计撤回后同一客户端仍取得广告规则、清除待发统计和阻止新发送；不是新域名的前提。SDK由受限固定归档消费，不公开源码。

SDK本地作用域包含origin。旧studio作用域的专用QA存储保留，队列、匿名安装ID和SDK插屏冷却不复制成新作用域；原游戏SQLite和180秒全屏保护保持。TestFlight17不含GM，没有正式玩家旧GM队列迁移。新scope仅在统计同意后生成新的匿名安装ID，此变化不能被当成同一安装统计连续性已证明。

历史回放probe仍明确绑定其旧origin/旧测试授权与记录，不批量替换历史证据，不用该工具向新host重发旧队列冒称迁移或去重通过。新host的实际正常main配置/事件与原生重试差额如下分别记载；SDK52、应用41与工具检查不替代运行验证。

服务端域名隔离由独立GM任务完成：2416758及4a27c6d记录新API只允许客户端路径，旧host客户端接口兼容。首次并行部署覆盖已通过冻结合并4a27c6d单一部署解决，当前Worker0c12ffaf保留API隔离与管理UI修复。后台已有test/production筛选与四平台v1配置实际回读，不把旧test历史值当作新客户端结果。

整体验收、后续候选和TestFlight终态见gamemunchies-live-integration.md；本项尚不声称新TestFlight已上传或物理安装已验。

## 新 API 原生重试差额（2026-10-28）

运行源 e4d1238；沿用既有受控断连/丢ACK入口，仅新origin作用域保护与证据隔离的QA源6b91e75138decb32b3b4be0cf35bf2aed9be0377，入口SHA256 dfcb3759b28b01cb89a4804bd604479822b8e49bd62041a2a963e18c4f1546b1。没有升级SDK或增加游戏侧队列。两个QA包都是0.5.0(18)、test登记566121d2-a3f5-4950-8bd9-6ff2f673a0ac、新库gm_api_native_recovery_20261028.sqlite；探针广告关闭，不代表正常main广告验收。

| 项目 | iOS | Android |
| --- | --- | --- |
| 实际身份 | dev.pourlune.gamemunchiesValidation | dev.pourlune.pourlune_dev |
| 冻结包 | build/gamemunchies-api-native/ios/Runner.app，361文件逐项清单 | build/gamemunchies-api-native/android/Pourlune-GM-API-Native-0.5.0-18-debug.apk |
| 包核验 | Computer安装前361项hash一致 | aapt身份/版本一致；APK SHA256 807734779c11021b0fbf78b2893de16ab13dbcc971944972b3e7d84e79013276，289877719字节 |
| 同安装重启与SDK重试 | 首次ACK 200 accepted3/received3；受控丢ACK后重试200 accepted0/received3 | 首批200 accepted2/received2；重试2原+1新增，200 accepted1/received3；原2条未重复计入 |
| 状态 | 原ID和首次时间保持、同实例恢复不新开局、pending0、SDK冷却保持；32.241秒 | 原字段/首次时间、同实例与冷却保持、pending0；32.719秒；纯0/N回执未观察 |

iOS实际后台test开局13→14，活跃2/展示1/失败28保持；完成后原e4正常main包已覆盖恢复且361文件hash一致，未卸载、清库或另起新局。公开回执在 ../evidence/gamemunchies-live-integration/api-native-ios/；原始事件字段、时间、scope快照与四库备份仅在专用设备/受限ignored目录，不进入Git。

早先手工Python回放仅发过一次，HTTP403，Cloudflare实际安全事件定位为Browser Integrity Check。该失败与一次性ledger保留，不换UA、不改WAF、不重放；它不算去重成功。以上成功来自SDK原生HTTP、持久化与重试。受控断连/丢ACK不等于无线断网、真机、广告展示/奖励或正式生产通过。F9未动。

Android原生SDK公开回执在 ../evidence/gamemunchies-live-integration/api-native-android/。新增自然active与原两条合批，所以不能声称Android收到纯重复0/N；只证明原两条去重。Computer已恢复冻结normal-main APK，安装内base SHA与f284eb192c4095bf7c77942c4c874a884bcbf65e90e94d976f446d8bd99e0d19一致、原正常库保留，未启动/清库。后台Android首次后验因页面变化/CDP超时未读到；随后Computer正常只读回读已完成：test活跃1→2、开局1→2、展示0/失败0保持，更新15:14:27，符合只新增一局。截图保留在原始Computer证据目录backend-after.png，不用HTTP ACK代替后台计数。

地址专项已交总控独立判断，不代表整体GM广告控制、隐私披露、CI或新TestFlight完成。现存隐私页误述与真实广告路径仍需修复/验证后再交整体候选。
