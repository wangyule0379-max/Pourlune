# 已验收游戏交互修订发布到 TestFlight

2026-10-26用户明确：『你检查以后，如果没问题，就让“Pourlune ｜ App 设计 开发”传到testflight』。本次新授权覆盖各实现文档中的“本轮不自动发布”；实际验收已完成，可进入新包发布，不需要再问通用上传许可。

## 已通过的范围

- 液体配色依原稿加深：e61deb1，review/liquid-color-original-20261026-independent.md。
- 可见连续水流和液面同步：3a52129，review/visible-pour-20261026-independent.md。
- 橙色进一步加重与可见瓶口分离：9006a25，review/orange-pour-gap-20261026-independent.md。
- 不能倒入有水瓶时直接换选、清理旧Hint、选择不记步：1da13c6，review/tap-to-reselect-20261026-independent.md。

交付HEAD c3de374已推送。其上仅正常发布版本等必要差额；保留60主线/30每日、旧存档与奖励、既有服务配置和已验收UI。未授权十二瓶／九色或新功能，不扩大字号和轻微材质审计。现有14及其证据冻结。

## 实施与核包

继续由既有开发聊天01a15eca-2b7f-70c1-978d-45dd735765f1/local执行，重新接回生产文件、串行CLI、专用QA及必要ASC/Xcode发布界面。父只审查与自己的文档，不并发运行Flutter/Dart/pub/SPM/iOS或操作该QA。

1. 回读ASC当前版本占用，预计0.5.0+15，使用实际未占用号。沿用现有Apple profile/key；不重建凭据、邀请或改成员。仅分发到既有Pourlune Self（1853bacc-97d1-40f9-b0cb-ae9ef9d01c74）本人1名；原Pourlune Beta两人组保持。
2. 精准版本提交并push，运行一次新exact-head CI直到终态，复用既有检查，只补必要release差额；不查询14或更早已知终态CI。保护所有无关dirty文档/日志/截图，不broad-stage/reset。
3. 新ignored候选目录构建ads-disabled签名IPA，使用FIREBASE_ANALYTICS_WITHOUT_ADID=1；沿用ios_release_plugins.py仅手动archive/export临时排除唯一integration_test生成注册/SPM并finally恢复，保留QA插件，不改SDK/locks。
4. 交付冻结候选和来源索引。父独立核新精确源/版本身份/locks、90题与已验库同字节、ads disabled、签名profile/entitlements/dSYM、archive与最终IPA Runner无测试类通道。若Organizer实际上传变体不同，冻结并核该实际变体。签名包门槛通过即继续上传，无需再问用户。
5. 分别回读上传成功、ASC处理完成、Pourlune Self本人组新版本正在测试／可访问，不能将处理中称可安装。真机实际安装和声音触觉未验仍如实保留。必要登录验证仅到真实需要时集中说明。

## 交付及保护

交付 `docs/development/deliveries/gameplay-polish-testflight-20261026.md` 与同名evidence；父review同名independent。记录每次候选/精确CI/IPA及Organizer实际hash/平台回执。

F9C16DE7-01D8-4740-B796-A3A2DB8C3265及其窗口绝对不动；普通2AE、Small11b/4188、历史Large、FirebaseQA和旧冻结包不动，不全局清理。D79仅如有必要先inventory再用自有身份命名库；本次无需重复旧采图。Google Play不随本次更新，AdMob仍关闭；不生产测试事件/符号、不代签购买/IAM扩权/公开App Store发行。

## 实际组成员变动补充

开发本轮回读报告现有Pourlune Self已变为两名测试员；该观察待父核实际平台证据，覆盖前文一名的历史假设。没有新增收件人授权记录。保持现有组及成员不动，优先定向既有本人wangyule0379@gmail.com，或使用已存在且成员准确的本人单人组。若平台仅按组分发且没有适合现有组，可为本次版本新建手动内部组，仅关联该已存在的授权测试员；不创建新账号、不发新邀请、不自动添加到原两人组。此为落实既有本人范围的执行方式，不必另问通用上传／建组许可。其他工程准备继续。

## 用户最新分发选择（覆盖前文单人/新组方案）

新组操作被自动审批拒绝，未执行。开发向用户精确说明现有Self两人及新单人组方案后，用户直接答复：“为啥分这么多组干啥呢？目的是啥？尽量用同一个组”。父已read_thread核实该userMessage `01a17735-0112-7133-937b-2616a1e30eca`。本次因此沿用既有Pourlune Self `1853bacc-97d1-40f9-b0cb-ae9ef9d01c74` 当前两名测试员，不新建组、不改成员、不重新邀请，原Pourlune Beta不动。不得再以旧单人假设阻塞或重问；这不允许绕过已拒绝的新建组操作。

候选2源70d9b59、CI40287545684和签名包45项已父独立通过，继续实际Organizer变体核验及上传/处理/组可测试三项回读。报告 `docs/development/review/gameplay-polish-testflight-20261026-independent.md`。

## 最新沟通要求

用户明确“不要每件事都上报，结果上报就可以”。常规检查、构建、上传和处理自主推进，证据落盘；最终结果集中汇报。仅真正阻断且需要用户动作或新的重大决定时打扰，不逐步请示、不为汇报停工。
