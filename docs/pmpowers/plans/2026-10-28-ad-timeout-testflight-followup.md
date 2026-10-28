# 广告运输修复与 TestFlight 后续执行计划

> 开发原生串行执行（superpowers:executing-plans）；Use Computer 独占实际电脑/设备/商店操作；总控最后独立读源、看实际画面/回执并验收。用户已要求直接推进，不另设计划批准停点。

**目标：**闭合本轮可修问题和官方测试广告实际链路，经总控验收后更新原 TestFlight 本人组。

**架构：**广告先取当前真实 SDK 运输证据，不延长 timeout 或猜测代码修复；只在命中已批准域时临时限域验证并恢复。发行源从已受验 f47610b 隔离，集成 F15 和非 GM 隐私并发修复；GM 测试完整工作分支保留，不发布私有 SDK。

**工具链：**Flutter3.47.2 / Dart3.13.2，现有 AdMob/UMP、SQLite、签名及 beta_build 工具；所有 pub/Flutter/iOS 操作串行、NoAdID。

**依据：**用户本轮继续修复/总控验收/TestFlight要求、AGENTS.md、PRD-supplement-v1.1.md、manual-functional-20261028.md、当前 computer-report.md；父明确接受本轮发行排除 GM。

## 全局约束与验收关注

- F9、D79、256 和原存档/设备不操作；只用已建2894新GM/功能QA身份及各自命名库。
- 不启收费单元、不跳UMP、不伪造展示/奖励；onAdImpression与真实SDK reward/事务回执分别证明。
- 仅 googleads.g.doubleclick-cn.net、pubads.g.doubleclick-cn.net 两个既有直接授权的exact域可在当前命中后沿原Google线路短时验证，最多900秒并核恢复；不改TLS/DNS/global/VPN或加新域。
- 原GM测试分支/依赖/回执不回滚；不能把私有SDK放入public Pourlune仓库为CI解围。
- 缺handler、并发保存失败回续、临时路由恢复、广告早关、旧存档升级是本轮重点；未完成的真实手机/工具条件明确保留，不能造“全部通过”。

## 任务

- [x] F15：父28a4941用4个RED/相关共13用例修复配置与external launch失败混报；Computer实际复测及父看图通过。发行checkout精确cherry-pick该提交，复用报告，不重复全页。
- [x] 运输：Computer在一次真实SDK窗口提取目标host/错误类别数字码，匹配两CN exact当前规则；符合既有授权才临时验证，备份/精确diff/自动与主动恢复并核持久hash。公开仅脱敏事实，不收全量网络日志或Cookie。
- [x] 实际广告：正常页面显示官方Test mode；记录展示/提前关闭不获奖、完整奖励一次、Undo/Restart/重启保留、合格Next插屏，以及GM仅独立test环境impression差额。遵守原180秒间隔；需要的正式题库前置只在独立function库准备。
- [x] 非GM隐私并发差额：在 app/test/privacy_choice_generation_test.dart 复用真实SQLite写入＋受控完成回执，断言“旧失败不覆盖最新成功”“dispose后的旧回续不改状态”；先在基线看RED。app/lib/services/service_hub.dart仅保留选择代次/最新保存失败应用/dispose失效，无GM引用。运行新用例＋b04_services_test及F15测试，analyze；提交精准差额。
- [x] 发布源复核：总控对照f47610b/53dc/F15及当前完整分支，确认保留音频、21–60题库、隐私清单等已验非GM变化。核pubspec/lock无本地GM路径；仅在真实广告与产品复验达到约定范围后冻结新版本候选，不使用占用的16。
- [ ] 精确检查：执行匹配该发行源的内容/资源/工具/核心/App检查与新CI；不借旧终态CI。按app-store-compliance复用已完成审计，仅核本次实际依赖/行为/清单和内部测试差额。
- [ ] 签名核包：在新ignored目录用既有profile/certificate导出，不生成密钥；新源/版本/所有输入hash、production身份、官方sample units、NoAdID/采集默认关闭、无integration_test及有效隐私清单由总控独立核验。
- [ ] Computer上传并回读：沿用原Pourlune Self组，不新建组/邀请；确认Apple处理完成/原组正在测试。若登录确需本人则集中说明，继续独立可做工作；未就绪不称已更新。

## 台账

- 原目录主分支工作区保留；独立checkout为codex/testflight17-fixes，f47610b起点包含53dc优化与本地签名隐私修正。
- 决定：本次发行排除GM，仅解决本轮产品/广告差额；依据原GM test-only范围及父明确批准，代价是GM测试继续独立，不在本次TestFlight采集。
- 候选构建/上传尚未开始；ASC已实际回读最高16、17未占用，已选择0.5.0+17。

- 源准备实证：enforce-lockfile通过、服务基线6通过；通用隐私2用例RED后修复，2新＋F15/既有服务UI共15通过，analyze无问题，pubspec/lock未变。首次pubget仅缺新checkout ignored SPM父目录，建立后恢复；日志保留。父已读差额接受，候选仍未构建。

- 实际结果：激励及正式21→Next插屏均已实际完成并获父看图/回执接受；仅googleads exact当前REJECT对应限域验证，两轮规则完整恢复。ASC已回读17空闲。版本17源准备中，隐私/来源指纹均有限审查接受；最终签名包尚未生成。
