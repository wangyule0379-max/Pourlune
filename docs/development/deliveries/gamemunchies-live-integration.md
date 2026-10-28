# GameMunchies 接入与 TestFlight 0.5.0(18) 最终交付

2026-10-28，Asia/Taipei。**已完成总控实际验收、精确CI、Apple上传与处理，原Pourlune Self组的18显示“正在测试 / 90天后过期”，仍为既有2名测试员，未新邀。** App 6826203407，Apple build 6956eb73-ec07-4ff7-a449-76867836c112。开发及总控均实际查看最终上传成功、原组可测试两图；这不等于物理手机已安装。F9未动。

## 实现与实际验收

正常入口保留17已验反馈/隐私保存代次、21–60题、音频、有效隐私清单、离线核心和奖励事务。没有为接入GM改题库、美术、货币或账号。

- 同一gamemunchies_client 0.1.0拥有可选统计及广告规则，固定源92f588200a1d80b1d0023122fcfc3037db87c53c。客户端只连接https://api.gamemunchies.com，无/api后缀或管理员凭据。正式gameId 8feaf0dc-ec12-4308-ac58-16b2180f2d63 / ios / production，真实身份com.pourlune.app；QA使用独立test登记/原生身份/SQLite，不把测试数据搬成生产数据。
- Analytics默认off，启用只在选择保存成功后；关闭立即阻止新采集/发送、清当前scope待发队列、尽力取消在途请求，已收服务端记录不能撤回。规则拉取继续，不为取规则新建安装ID/active。保存代次与SDK同意代次保护旧回执竞态。
- 新实例首次成功落盘才round_start，恢复不新开局。展示/加载失败只认真实Google对应回调；上报失败不改变奖励。统计off时实际插屏仍更新SDK冷却。
- 请求前、载入后、show前核总开关/类型/场景/规则修订；关闭使尚未原生show的机会失效。已展示广告保留真实回调，原实例合法奖励按SQLite事务只入账一次。远程关闭加瓶不变免费赠送。本地最近任一全屏shown后180秒安全间隔与GM插屏间隔同时满足。
- 前台每30秒检查配置，到期尝试至少间隔5分钟、请求8秒超时；离线用缓存/默认，核心不等网络，不承诺后台设置瞬时生效。
- 隐私页修复只涉及只读配置getter及两条显示文案：Firebase缺失但GM已配置时分别说明crash不可用/analytics按保存选择；单提供方同步失败不再假称所有分享阻断，本地保存失败仍阻断新应用分享。

| 范围 | 实际结果 |
| --- | --- |
| 后台 | 合并4a27c6d部署Worker0c12ffaf，保留API隔离/认证/D1；实际更正正式/测试两登记平台身份、初始化能力、test/production筛选。保留gameId和历史，不迁移或制造正式统计。 |
| 正常main iOS统计 | 同意后真实active1→2、round11→12，恢复保持12；关统计观察不增。真实完成1进2后round12→13。SDK真实失败26→28，旧impression1不冒本轮结果。 |
| 正常main iOS控制 | Analytics off仍收到v2 global off、v3两个scene off，Extra Bottle无可用广告且不发瓶；v4 allOn/180恢复正常收到。未单独诱发合格Next插屏，不能仅凭flag标该实际路径通过；运输基线复用17已验真实插屏。 |
| 双端原生恢复/去重 | iOS真实200 accepted3/received3→0/3；Android2/2→1/3（2原+1自然新增）；原ID/首次时间保持、同安装同实例恢复不另开局、pending0/冷却保持，两端后台均只增1局。Android不写成纯零接收。旧origin QA状态原样保留，不迁移重播；17无GM玩家状态。 |
| 正常main iOS隐私/激励 | 修复包实际显示正确隐私文案；唯一一次官方Test mode激励展示、完成、关闭，原daily五瓶→六瓶，attempt/entitlement/fullscreen各0→1、confirmed done且同实例，恢复后仍六瓶/加瓶已禁。后台test展示1→2，开局14/失败28保持。没有独立原生callback日志，依据真实广告UI、SQLite和后台。 |
| Android正常main | 原AVD收到v1/allOn/180，默认统计off未新增；GUI触控路由不可靠，人工开关/新局/真实广告未验，不扩设备或借iOS结果标通过。 |

证据见../evidence/gamemunchies-live-integration/的api-native-{ios,android}/、privacy-ad-r2/、platform/；独立结论见../review/gamemunchies-normal-privacy-reward-20261028.md与gamemunchies-build18-release-final.md。原事件/首次时间及SQLite私密备份仅在受限ignored目录，不进入Git。受控断连/丢ACK不等于无线断网或物理手机验收。手工Python单次403及一次性ledger保留，Cloudflare定位Browser Integrity Check，不改UA/WAF重放；原生SDK成功与这次失败分别记录。

## 精确来源、CI与签名包

- 实现e4d1238，隐私修复a928c13575a32e9efe30e9f99a57a5909b0c7021，签名候选精确源ea2bdee853559ddaa66e44e35fce7bac34a40d29。
- 最终CI源a8e6be9323d97855de25bcfbcabc0e88337cf415，[run40653590242](https://github.com/wangyule0379-max/Pourlune/actions/runs/40653590242)两job终态success。工具84/核心47/应用477通过、1个显式opt-in内容夹具跳过；17核心文件及214应用文件格式零差额、分析通过，APK和iOS simulator构建成功；两job真实恢复固定SDK7文件。总控独立API核相同head/终态，见final-ci.json、final-ci-excerpts.log及独立ci-bridge/terminal报告。
- 首轮0687fce/run40653136080的Ubuntu guard因SDK恢复排在guard之后，21项private_sdk_missing失败；只将恢复移到guard之前，未跳过检查或修改App/SDK/测试期望。最终head对签名候选554输入仅该workflow顺序差额，其余553同hash，实际App/SDK/资源/锁/构建工具均不变。总控接受复用原包，不无差额重造或重跑旧终态。
- 固定受限归档10233字节，SHA256 3866eb1d0975fcaaad2e4fb3b9fe1d2c4a09b01e3305fb75637bb9df753a5d55；7文件指纹在tools/validation/gamemunchies-sdk.json。干净e4导出无sibling SDK，恢复后enforce-lockfile成功/依赖实际在受限目录/lock不变；该本地证明与后来的真实CI分别保留。SDK本身52测试及分析通过。
- 候选build/beta-candidates/0.5.0-18/ios-gamemunchies-live-1；只读镜像build/package-review/0.5.0-18/ios-gamemunchies-live-1，567文件一致。总控核554来源、90题、真实AOT的API/正式GMID、官方sample单元、prod Firebase/NoAdID、采集默认off、无ATT、archive及IPA无原生测试插件、deep/strict签名/profile/dSYM通过。复用既有Pourlune-only profile，不新建或重置key。
- 原IPA：86,731,598字节，SHA256 a37b9aa46932616744d04a2116a1b9c89acdd84a98a108eeccea46a6b7665541。实际成功上传Organizer变体：86,731,625字节，SHA256 6e39f3ad4073d70cb0c3f076e03655125d01a4cfffa378185b2ab456df51c034；总控核269文件无增删、差异仅签名区，签名严格通过。两者来源关联、可写archive284文件同原件由总控独立核，详package/ci-bridge/organizer-retry独立报告。

## Apple终态与上传故障历史

Xcode约16:43实际成功；Apple处理完成，6956eb73-ec07-4ff7-a449-76867836c112加入原Self内部组，显示18“正在测试 / 90天后过期”、2人。未新邀、未上传生产测试符号、未公开App Store提交。加密沿用已批准事实：系统外标准加密与Apple系统加密同时使用，本次不在法国公开分发，不谎报无加密。最终两图及指纹/平台事实在platform/release.json。

首次官方会话在Apple object-storage出现证书主机错配，随后1,666,016字节asset-description第1段379次checksum重试，已取消而非无限等待。保持同18/已验包，确认可信连接后新官方Organizer会话成功；未改App、网络、DNS或TLS信任。不能由此断定初始网络错配的全部根因，也不把checksum错误说成IPA损坏。详upload-transport-note.md及独立upload-transport报告；原日志含cookie/签名URL，不原文复制入Git/聊天。

## 支持站与具体授权记录

两页按父审源ea2bdee发布到既有pourlune-support，提交01764d8eb8de85755f6cbf9214b2f3db9db46af0 / Pages40651368042成功。HTTPS help SHA256 ff8c960faeb77ddb6df15f0871d5cc0f119ff971694594c1bf054115ac204c89，privacy 2fb654594fb1d8dbdb4d91656861ac8dd782857301a1afd9afc56b878296ac55，与该源一致；浏览器实际读到18条件、默认off/独立规则/API/撤回清queue/单提供方失败范围，以及16/17/Android13无GM。当前分支privacy只有后续API链接markup差额，不误称站点与当前文档HEAD逐字相同。

本人明确允许私有SDK归档“仅供构建并继续发布”，既有Repository secret GAMEMUNCHIES_DART_SDK_ARCHIVE_V1已配置并被真实CI消费，不再重复索要此授权。配置时Computer的页面AX工具记录意外回显代码归档值；它不是登录token/密码，开发与总控未读取或复制该输出，目前无公开仓库发布证据。此事件已告知并保留，不声称已删除聊天工具历史，也不以重编码相同源码冒充撤回。归档/私钥/凭据不进入公开源码或本报告。

## 使用与实际未验范围

更新18后，按已保存的Share gameplay analytics选择正常游玩；默认关闭，不能为让面板有数字擅自打开。后台在Pourlune正式登记选择“正式统计 / iOS”，测试游戏已有计数不代表手机已产生正式数据。广告规则独立于统计选择，须等客户端正常刷新后生效。

平台可测试已确认；物理手机安装/17→18升级、该手机首笔正式统计、真实音触觉、Android人工广告及真人首次难度仍未验。广告保持官方测试单元，不代表收费投放、商业收益或AdMob账户商业readiness通过。F9及原设备/存档保护保持。禁止重复上传18、重跑已完成CI或重新邀请；只处理真实新反馈。
