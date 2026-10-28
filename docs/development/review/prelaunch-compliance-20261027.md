# Pourlune 正式上线前合规检查 — 2026-10-27

> 2026-10-28纠正：下表PL-ART-RIGHTS遗漏了10月23日已有用户确认与条款核对，不能继续按“所有美术无授权依据”阻断。见 `asset-rights-reconciliation-20261028.md`；其余项目按后续收尾报告逐项更新，以下保留当日审查记录。

结论：**当前不能直接提交公开正式版。** 已完成 TestFlight 16、Google Play Alpha 13 的事实保留；内部测试和封测通过不等于公开上架所需资料、权属和平台资格全部通过。

按用户指定的 [app-store-compliance 技能](/Users/wangyule/repositories/app-store-compliance/agent-os/skill/SKILL.md) 执行。本轮只读源码、实际已上传 IPA、既有签名/测试证据、公开隐私政策和商店页面，运行 guard、metadata audit 与隐私清单结构验证。没有修改生产代码、SDK、线上声明、广告配置、签名或测试名单，没有重建包、重跑终态 CI 或操作模拟器。

审查基线：工作树 HEAD `91bd759`（文档归档）；最新 iOS 运行源 `2b364d62f060e3a537c47a9e1db987bb26c90fea`，0.5.0(16)，官方测试广告；Google Play 仍为源 `236cea0` 的 0.5.0(13)，关闭广告。两端不能混作同一发布版本。

## 按优先级处理的发现

`PL-*` 是本次审查补充编号，其他编号来自技能规则；严重度针对**公开正式上线**，不是要求撤回现有测试包。

| 优先级 / 严重度 | Pattern ID / 平台 / 依据 | 实际发现 | 最小修复与具体位置 |
|---|---|---|---|
| 1 / 高，已证实 | `PL-PRIVACY-STALE`；双端；Apple 5.1.1 / Play User Data | 实际公开隐私政策仍将范围限定为 beta，并写广告请求、UMP 检查关闭；最新 iOS 16 已真实加载测试广告与运行 UMP。政策的广告章节和第三方处理章节没有覆盖当前版本。 | 更新 `docs/support/pages-site/privacy.html`，明确不同已分发版本与正式模式，准确解释 GMA/UMP 数据、用途、选择和服务商；部署后回读。仅更新本地文件不算完成。不能再用 NoAdID 或非个性化广告推导“没有收集”。 |
| 2 / 阻塞，已证实 | `PL-IOS-INTERNAL-ONLY`；iOS；Apple 分发机制 | 本轮实际读取上传 IPA：`TFInternalTestingOnly=true`；后台已有内部 16 正在测试。该构建不能用于 App Store 顾客分发。 | 关闭正式候选的 Internal Only 选项，以确定的正式运行配置构建/上传新未占用 build，绑定正式版本；复用既有签名和已验流程，不重传 16。[Apple 官方说明](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/) |
| 3 / 阻塞，已证实 | `GOOGLE-12-TESTER-RULE`；Android；Play Production Access | 当日 Play 信息中心显示“目前已有 **0 名测试人员选择参与**”，12 人/连续 14 天条件未完成，“申请发布正式版”禁用。测试名单中有 1 个邮箱不等于实际 opt-in。 | 邀请由用户确定的真实测试人员加入、持续测试达到平台要求，然后申请 production access 并填写真实测试结果。本轮不新增陌生测试者。[官方要求](https://support.google.com/googleplay/android-developer/answer/14151465) |
| 4 / 高，公开版本配置未完成 | `PL-TEST-ADS-IN-RELEASE`；双端；完整性 / GMA 测试规范 | 最新 iOS 16 使用 Google sample unit，正确用于测试，但不是最终商业广告配置。Play 13 仍是 ads-disabled 旧运行版本。 | 正式版明确选择：先关闭广告发行，或完成商业投放准备后用本人正式单元；不能把当前 sample 广告包直接称正式商业包。工程入口 `app/lib/services/service_config.dart`，构建工具 `tools/validation/admob_config.py` / `beta_build.py`。[Google 要求发布前替换测试 ID](https://developers.google.com/admob/flutter/test-ads) |
| 5 / 高，包内实际发现 | `APPLE-MANIFEST-API-TYPES-EMPTY`；iOS；TN3181 | 实际上传 IPA 的 24 份隐私清单中，14 份带空 `NSPrivacyAccessedAPITypes`，集中在 Firebase/GoogleUtilities/nanopb/url_launcher/sqflite/webview 等资源 bundle。以前仅“plist 可解析”的检查不足以覆盖这一项。 | 正式候选前按对应 SDK 的受支持修复方式消除空键，或取得明确适用性说明；不能盲改 SDK 全局缓存或删除有效原因。重新核最终包即可，不需重做所有 UI。Apple TN3181 明确要求空时移除此键。现有 TestFlight 处理成功，不等于本报告已经看到拒审；这项是确认的格式风险。[TN3181](https://developer.apple.com/documentation/technotes/tn3181-debugging-invalid-privacy-manifest) |
| 6 / 高，声明差额待关闭 | `APPLE-PRIVACY-NUTRITION-LABELS` / `GOOGLE-DATASAFETY-MISMATCH`；双端；Apple 5.1.1 / Play Data safety | Play 当日广告声明仍为“否”，10 项声明最后修改 10 月 25 日；这符合当前关闭广告的 Android 13，**不能直接套用到启用广告的新 Android 包**。保存的五类数据声明也是按关闭广告核验。iOS 正式 App Privacy 本轮因登录失效未能回读。 | 最终广告模式确定后，逐项合并 Firebase 与 GMA 实际采集/共享/广告用途，更新对应声明及商店文案。若 Android 继续无广告，不能为凑表把当前“否”改成“是”。iOS 登录恢复后核营养标签、分级、截图、审核说明、发行地区；未读到不等于缺失或已通过。 |
| 7 / 高，证据缺口 | `PL-ART-RIGHTS`；双端；Apple 5.2.1 / Play Intellectual Property | `docs/design/production-candidates/runtime/manifest.json` 的原稿/派生美术仍为 `UNCONFIRMED`；`p05-restoration/*reference.json` 也未补商业权属依据。没有找到后续关闭记录。 | 为实际入包原稿及派生图层补原创归属或许可范围记录，确认允许发行及商店宣传；无法确认的具体素材再替换。**这是缺少权属依据，不是认定侵权。** 字体 OFL 和两首新音频的许可不能覆盖图像。 |
| 8 / 高，启用商业广告或扩大地区时适用 | `PL-ADMOB-PRODUCTION`；双端；AdMob 账号/应用就绪、EU User Consent | 10 月 26 日交付记录：账号/应用审核、商店关联、app-ads 验证以及欧洲/美国隐私消息尚未完成。今天 AdMob 入口重定向 signup，未能刷新这一状态，不能断言仍在审核或已经通过。 | 回读现有账号，不重新开户；按正式发行地区发布适用隐私消息、核同意/拒绝/撤回以及年龄相符广告内容。app-ads 和账号就绪是商业投放待办，不拿它们阻止经过核验的无广告版本发行。[CMP 要求](https://support.google.com/admob/answer/13554116?hl=en)、[广告数据披露](https://developers.google.com/admob/ios/privacy/data-disclosure) |
| 9 / 高，地区适用性待确认 | `BOTH-US-ASAA-AGE-SIGNALS-MISSING`；双端；适用州年龄保障义务 | 当前源码没有 Declared Age Range / Play Age Signals / Significant Update 集成；已知 Play 封测地区为美国。13+ 目标受众和 Everyone 内容分级本身不能证明州级义务已满足。 | 正式美国发行前明确适用性及处理方案，必要时最小接入年龄/监护信号和重大变更处理；不要自动增加自建实名、生日或业务服务器。Apple 当前说明受法律要求地区需要检查年龄；Google 明确不是所有 App 统一强制使用该 API。不能把技能的一条通用提醒当成所有国家统一拒审。[Apple 当前说明](https://developer.apple.com/support/age-assurance/)、[Google 当前说明](https://support.google.com/googleplay/android-developer/answer/16569691?hl=en) |

## 已核对的实质通过项与范围

- iOS 16 实际包为 `com.pourlune.app` / 0.5.0(16)，最低 iOS 15，SDK `iphoneos26.5`，满足现行 iOS 26 SDK 最低上传条件；没有 ATS 全局放行、相机/麦克风/定位等新增敏感权限描述或自定义 URL scheme。签名、dSYM、原生测试插件剔除和正常 main 入口复用上一轮实际包验收，没有重跑。[Apple SDK 要求](https://developer.apple.com/news/?id=ueeok6yw)
- Android 13 已验实际 target 36/min 24、正式 upload 签名、12 个 ELF 的 16KB 对齐；AD_ID 已从合并清单移除且 Analytics 广告 ID 收集 false。当前政策要求新包/API 更新 target 36，现有 13 达到该项；新 Android 候选仍需对自己的最终包核差额，不能拿旧包代替。[Play Target API](https://support.google.com/googleplay/android-developer/answer/11926878)
- 正常核心离线，60 主线＋30 每日，固定目标、存档事务、奖励幂等、Hint 过期结果守卫均有既有实测。没有账号、IAP、订阅、支付、UGC、聊天、真钱赌博或运行时生成内容，不需要为本次审查新增账户删除、演示账号、IAP 或 UGC 举报系统。
- Analytics/Crashlytics 分开且初始关闭；UMP 资格门控、隐私选项入口、非个性化 AdRequest 已在代码；广告失败不阻塞免费核心玩法。激励必须真实 earned 确认、插屏只在既定结算 Next 条件下出现，复用已验原生路径。
- 已发布支持/隐私网页本轮在浏览器实际可访问；隐私问题是**内容过时**，不是链接不存在。支持邮箱在页面可见；本轮没有发送邮件验证收件。
- Dream Culture 的 CC BY 4.0 署名、作者、来源、许可链接和改动说明，以及 Pouring Water 的 CC0 来源/剪辑说明已在 `app/assets/audio/ATTRIBUTION.txt` 并由 `main.dart` 注入 Licenses；Nunito 有 OFL。未发现本轮需要购买或另加订阅授权的音频问题。
- Play 已处理 10 个声明、无“需要注意”提示，当前 Alpha13 有效。此 UI 状态不代表新广告版本或公开正式版已经通过。

## 扫描结果的人工分辨

原始 guard：exit 2，1 critical / 7 high / 5 medium。没有用 override 把扫描器强行改绿。扫描器只提供线索，不是最终裁决。

| 扫描项 | 人工处理 |
|---|---|
| localhost/staging、example.com 占位 | 主要命中 `service_config.dart:129` 的拒绝列表和验证工具测试夹具；实际包链接已有既有核验。不是 release 连接本地业务服务器。排除误报。 |
| 订阅取消困难 | 项目没有订阅或计费；关键词跨文件命中。排除。 |
| 社交功能 | crash/analytics sharing 不是社交发布/UGC。排除功能误判；商店问卷仍应按真实内容回答。 |
| 缺少加密 plist 键 | 实际键确实缺省，但 Apple 允许在 ASC 回答出口问题；16 已按既有分类提交。不能直接填 false 掩盖 Flutter/BoringSSL 的事实。正式候选依实际加密及地区作答；不是已证实上传失败。[Apple 出口流程](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance) |
| R8 未启用 | app Gradle 未直接写不代表关闭；固定 Flutter 插件 `FlutterPlugin.kt:218` 在默认 shrink 配置启用 minify/resource shrink。不能据此要求升级或加一套构建框架，也不把未来日期当今天阻塞。 |
| 自定义 deep link | Manifest 中 PROCESS_TEXT 的 mime 查询不是导出的业务 scheme；iOS 实包无 CFBundleURLTypes。没有据此确认劫持入口。 |
| Android AD_ID | 扫描器看到的是 `tools:node="remove"`；旧实际 AAB已确认无此权限。排除。 |
| VoiceOver / Haptics | 项目是 Flutter，已有 Semantics/触觉设置与实现；启发式 SwiftUI 匹配不能证明缺失。本轮不声称全 VoiceOver/真机触觉通过，也不追加小字号/UI 全量打磨。 |
| GMA tracking contradiction | 原始 SDK 清单把 DeviceID 的 tracking 用途声明为 true，但顶层 `NSPrivacyTracking` **缺省**，并非明确 false。验证脚本将缺省当 false 产生一条 high。此项需要结合正式广告配置、SDK说明与 ATT/隐私披露核对，不能仅凭它认定已非法追踪，也不能擅自把厂商清单改成全 false。 |
| 14 个空 API 数组 | 与上面的误报不同，这是从实际 IPA 逐份读取的内容，也有 TN3181 对应说明。合并为发现 5，不制造 14 项重复整改。 |

技能的全球截止日期输出涵盖 AI、金融、社交、儿童、多个地区，未全部套在本离线益智游戏上。美国已有明确背景，所以记录相关年龄保障待办；EU/英国/巴西等正式地区尚未核定，不擅自扩大国家、作法律身份声明或代签。若开启 EU，还需核 DSA trader 状态、相关隐私及数据处理安排；若开启中国大陆，不得沿用“海外小游戏”假设直接发布。

## 元数据与现场限制

2026-10-27 后续状态补证：按用户指定，由“Pourlune ｜ Use Computer”在 12:14–12:19 台北时间进入正确的已有账号，总控已读交付和页面文字。账号仍验证中、未获批；iOS/Android 均需审核、投放受限且未关联商店，各有两个有效广告单元；政策中心无个案问题。app-ads.txt 无状态数据，隐私消息详情持续加载，后两项仍未确认。先前 signup 是另一个已登录账号入口，不能据此认定账号不存在。此补证覆盖上表第 8 项和下文第 4 点的“今天未能回读账号”限制，但不改变尚未商业就绪结论。详 `docs/development/deliveries/admob-status-20261027.md`。

1. `metadata-audit.py` 对 10 月 25 日已保存 Play 名称、短文案、完整文案与支持/隐私链接扫描结果为 clean。它只能查格式与常见措辞，不能理解“广告关闭”的描述已经不适合未来广告版本；不能据此认为新正式 listing 完成。正式版还需去掉 beta 描述、写实际广告行为并用对应平台当前画面。
2. ASC 从 TestFlight 切到分发后出现 `authResult=FAILED`。因此本轮**未核实**正式版本文案/截图、最新年龄问卷、App Privacy、内容权利回答、可销售地区、DSA 及审核联系信息；不把历史草稿或空白加载页说成当前资料缺失。需恢复 Apple 登录后仅补这些差额。
3. Play 当日已实际读取生产资格、Alpha13、已处理声明及“无广告”选项。数据安全 CSV 导出发生工具超时，浏览器连接随后脱离；没有拿到新字段级 CSV。五类数据与用途只复用 10 月 25 日独立记录，不冒充本日逐项重验。
4. AdMob 本日只到 signup 重定向，未填写、创建或接受任何条款。账号/消息/验证进展以上一日记录为最后证据，不重复新建应用或密钥。
5. 本轮没有重新试玩、听音或测试物理手机；没有实际拒审回执。性能、真实手机安装与主观音效、公开商店审核结果仍未验。

## 建议收尾顺序

1. 先明确公开首版是否启用商业广告，以及实际发行地区；保留已有测试版。
2. 改正网站隐私政策，按最终 SDK 行为补商店隐私与广告声明，处理原稿/派生美术权属依据及适用年龄保障。
3. 处理包内空隐私声明字段并生成可公开提交的 iOS 包；Android 将所选最终源制成新签名包，补相应平台差额，不重做无关 UI。
4. Apple 登录恢复后核上架资料；Google 按真实测试人数/天数达到 production access，再申请发布。不要把等待测试人数变成新增代码工作。

没有要求重做已通过的游戏页、非正常字号矩阵、小纹理或无关流程。当前审查只交付问题与依据，尚未授权本轮改线上设置或公开发布。

## 证据

- 本轮机器摘要与索引：`docs/development/evidence/prelaunch-compliance-20261027/audit-summary.json`、`evidence-index.json`。
- 自动扫描：`guard.log` / `guard-result.json`；元数据：`metadata-audit.log` 与明确标为旧版的 `play-metadata-saved-20261025/`。
- 实际 IPA 读取：`ios16-privacy-and-build.json`；结构验证原始结果：`privacy-structure-validator.json`。
- 实际平台回读：`play-production-access.txt/.png`、`play-alpha-current.txt`、`play-declarations.txt`、`play-ads-declaration.txt`、`privacy-live.txt`、`asc-auth-required.txt`。
- 复用而未重跑：`audio-admob-testflight-20261026-independent.md`、`google-play-data-safety-independent.md`、`google-play-android13-ad-id-independent.md`、`admob-resume-20261026-independent.md`。
