# GameMunchies 统计、广告控制与下一次内部版本

2026-10-28，当前仍在独立验收/发布准备中；不把已分发的TestFlight17称为包含GameMunchies，也未上传18。用户已授权整体通过后更新原Pourlune Self组，地址专项本身不触发分发。F9未动。

## 实现与来源

正常main源e4d1238d4496f69f6cf26116ee4b43ecfca6ad4d，隐私提示修复a928c13。保留17已验反馈/隐私写入代次、题库、音频、隐私清单、奖励事务和离线玩法。版本准备为0.5.0+18，实际上传前再核Apple占号；不重传17或重邀既有2人。

- 只用同一gamemunchies_client 0.1.0，固定源92f588200a1d80b1d0023122fcfc3037db87c53c，7文件固定受限归档。归档10233字节、SHA256 3866eb1d0975fcaaad2e4fb3b9fe1d2c4a09b01e3305fb75637bb9df753a5d55；私有源码和payload不进入Git。
- 正常客户端只连接https://api.gamemunchies.com，无/api后缀。正式候选明确production游戏8feaf0dc-ec12-4308-ac58-16b2180f2d63/com.pourlune.app；QA使用test游戏566121d2-a3f5-4950-8bd9-6ff2f673a0ac及独立身份/库。默认未配置GM仍关闭；不能把disabled候选冒充本次GM版本。
- Analytics默认off；保存同意后才产生/发送统计。关闭立即门控、清当前scope队列、尽力取消在途，已经收到的记录不能撤回；规则拉取继续，不为规则生成安装ID/active。保存代次和SDK同意代次防旧回执竞态。
- 新实例成功落盘才round_start，恢复不新开局。展示/加载失败只认真实SDK对应回调；正常main不造事件/奖励。GM实际插屏冷却在统计off时仍保留。
- 请求前、载入后、show前检查总开关、类型/场景及规则修订；尚未原生show的旧机会不能迟到补弹。已开始展示继续真实回调，原实例合法奖励只入账一次。远程关闭加瓶不变成免费赠送。
- 保留本地最近全屏shown后180秒安全间隔；远程插屏impression间隔同时满足。前台30秒检查配置，到期尝试至少间隔5分钟/8秒超时；离线用缓存或默认，核心不等网络。

## 实际证据与限制

| 范围 | 结果 |
| --- | --- |
| 后台 | 冻结合并4a27c6d部署Worker0c12ffaf，保留API域名隔离/认证/D1；实际更正两登记平台身份、初始化能力、test/production筛选，不搬迁历史统计。总控已看图/源。 |
| 正常main iOS统计 | 同意后真实active1→2/round11→12，恢复保持12；关统计后观察不增。后续真实完成1进入2，round12→13。当前轮真实加载失败26→28；旧impression1不属于本轮。 |
| 正常main iOS控制 | Analytics off仍收到v2 global off、v3两个scene off，Extra Bottle不请求可用广告/不发瓶；v4 allOn/180正常收到。未实际诱发合格Next插屏，不能仅凭flag算该路径通过。 |
| 正常main Android | 原AVD收到v1/allOn/180；默认统计off未新增。GUI点击路由不可靠，人工开关/新局/广告未验，不扩设备掩盖限制。 |
| 原生SDK恢复/去重 | iOS200 accepted3/received3→0/3；Android2/2→1/3（2原+1新增）；原ID/首次时间不变、同安装同实例恢复、不新增局、pending0/冷却保持。两端后台均只增1局。两包恢复normal-main不卸载/清库。不是无线断网/物理手机或广告证据。 |
| 隐私提示 | a928c13修复Firebase缺失但GM已配置时的“全部不可用”误述，区分单提供方同步失败与本地保存失败；4渲染+原竞态/统计共16及F15反馈4通过，analyze0。正常main修复后iOS实际显示通过；截图已查看。 |
| 真实测试广告 | 17原Google官方测试激励/插屏及原实例奖励已实际验收可复用运输基线；本轮r2唯一一次官方测试激励实际展示/完成/关闭，原daily五瓶→六瓶，attempt/entitlement/fullscreen各0→1、confirmed done且同实例，恢复后仍六瓶/加瓶已禁；后台test展示1→2、开局14/失败28保持。没有独立原生callback日志，结论来自真实广告UI、SQLite事务回执和后台。 |

原始正常main和配置证据：根工作区docs/development/evidence/prelaunch-closeout-20261028/gm-live-client-ios/report.md；地址专项及本分支公开回执见gamemunchies-client-origin-20261028.md与../evidence/gamemunchies-live-integration/api-native-{ios,android}/。手工Python单次403和一次性ledger保留，Cloudflare实际定位Browser Integrity Check，不改UA/WAF重发。

当前网络基线由独立GM任务在其授权范围加入精确googleads.g.doubleclick-cn.net规则；本轮不恢复旧代理备份覆盖它，不扩大例外/TLS/DNS。无库存或真实网络失败按真实error记录，不延长超时冒成功。

## 构建与发布门槛

SDK52测试/分析、应用规则/同意聚焦41通过。最终修复后完整应用477通过、1个显式opt-in内容夹具跳过，214文件format零差额、enforce-lockfile通过，最终工具84通过；日志见final-tools-tests.log。干净导出e4无sibling SDK，从固定归档恢复后enforce-lockfile成功、实际依赖在受限目录、lock不变；见clean-source.json/pub日志。这证明本地干净消费，不能冒充远端CI。

e4正常QA冻结iOS361文件，Android APK f284eb192c4095bf7c77942c4c874a884bcbf65e90e94d976f446d8bd99e0d19。a928c13最小正常iOS隐私修复包位于ignored build/gamemunchies-live-qa/ios-privacy-r2，361文件清单及原参数；相同QA身份/库、test/官方测试广告/Firebase none，不是商店候选。

支持站版本18差额已在本分支两页草稿准备：默认off、API地址、独立规则请求、撤回清队列、已接收记录限制、提供方同步范围和test/production分离。原根工作区他人变更不覆盖；尚未发布这些18说明，且不声称18已分发。

剩余集中处理：总控核实际最终回执/源与隐私草稿；原有GitHub Actions私有SDK归档具体授权仍待本人答复，未传该payload或创建新凭据，现有明确问项不重复提。之后固定最终源精准CI、production GM+prod Firebase/NoAdID+官方测试广告签名候选、总控实际核包、按既有授权更新原Self组并回读Apple处理/可测试。没有把本地包或地址专项通过写成已更新TestFlight。物理手机升级/硬件音触觉/人类首玩难度继续保持未验。

## 最终可审签名候选（尚未上传）

候选build/beta-candidates/0.5.0-18/ios-gamemunchies-live-1，独立只读镜像build/package-review/0.5.0-18/ios-gamemunchies-live-1，567文件逐项hash一致，冻结清单在同父目录ios-gamemunchies-live-1-freeze.json。精确源码ea2bdee853559ddaa66e44e35fce7bac34a40d29（运行差额a928c13）；正常main/prod Firebase/NoAdID、GM production真登记、官方测试广告、采集默认off，复用原Pourlune-only profile/certificate，无自动改签名或符号上传。

IPA 86,731,598字节，SHA256 a37b9aa46932616744d04a2116a1b9c89acdd84a98a108eeccea46a6b7665541。archive/export成功，deep/strict签名、最终原生dev插件剔除/恢复与隐私清单检查均通过工具实际核验。作者另核AOT含api域名/正式gameId而无旧studio域名、无ATT字段、所有来源输入一致，见signed-candidate-author.json。镜像仅用于总控独立核验；不把签名就绪冒称精准CI/Apple上传或组内可安装已完成。

正常main r2最终公开报告、隐私/真实测试广告/恢复六瓶/后台截图及去标识SQLite汇总在../evidence/gamemunchies-live-integration/privacy-ad-r2/。reward-return.png曾误存Home，已在不再次请求广告、不重开局情况下恢复同一daily补拍并实际打开核对；报告明确补拍时间性质。

## 总控最终本地验收

总控已完成独立核包并接受现有候选：567冻结文件、554精确Git/固定SDK输入、IPA实际内容与90题、正式身份/production登记/API、采集默认off、官方测试广告、archive和IPA原生纯净、deep/strict签名/profile及dSYM一致均通过。见../review/gamemunchies-build18-package-independent.md及同名JSON；正常入口隐私与真实奖励独立结论见../review/gamemunchies-normal-privacy-reward-20261028.md。这些是总控原报告的逐字归档；报告内部原证据相对链接按根工作区解析，本分支实际运行副本在privacy-ad-r2。

本地签名候选已接受，不重造包或重复广告/地址/UI检查。总控已将技术核对通过的两页隐私/support交Computer同步既有站，真实部署回执待其最终回读。剩余仍是此前待答的私有SDK Actions具体授权落实后，最终精确源CI与既有原组发布流程；没有绕过或再次催问。商店构建号占用/上传处理/原Self组可测试仍须真实平台终态，当前尚未上传18。
