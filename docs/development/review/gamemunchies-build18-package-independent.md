# GameMunchies 整体接入 Build18 签名候选独立核验

2026-10-28。结论：本地签名候选包核通过，等待原计划的精确源码CI与支持站同步；未上传、未声称TestFlight可安装。地址专项本身已结束，不作为另一次发布授权。

## 包与来源

候选精确源 `ea2bdee853559ddaa66e44e35fce7bac34a40d29`，运行修复a928c13。父只读镜像 `/Users/wangyule/.codex/worktrees/testflight17-fixes/Pourlune/build/package-review/0.5.0-18/ios-gamemunchies-live-1`，独立重算567冻结文件全部一致；554来源输入逐项对精确Git树（7个私有SDK文件对GameMunchies固定92f5882树）全部一致。实际IPA逐文件与inspection目录相符，题库90份与精确来源相符；锁文件包含在来源核验中。

IPA 86,731,598字节，SHA256 `a37b9aa46932616744d04a2116a1b9c89acdd84a98a108eeccea46a6b7665541`。实际plist：com.pourlune.app / 0.5.0(18)，Pourlune既有GAD AppID；实际AOT含新API与正式GM登记，官方sample两广告单元存在，无旧studio或新QA入口。生产Firebase项目pourlune-prod/正式身份，Analytics、Crash及广告相关默认采集键均false，无ATT提示字段。

父分别实际执行archive与IPA的codesign deep/strict，均退出0。读取内嵌profile确认复用Pourlune App Store Beta 20261022，UUID74a202b2、teamT7U878Z8H6，appid匹配且get-task-allow=false，有效期2027-09-16。Runner与App.framework各自真实UUID和dSYM一致。archive及IPA两个Runner均不含IntegrationTestPlugin/integration_test类/通道字节。shared_preferences隐私清单真实存在，UserDefaults理由1C8F.1、tracking=false。详细机器结果见同名JSON。

## 已完成的运行验收复用

复用独立API双端配置/统计/重启补传/去重，及正常main iOS远程v2总关闭、v3场景关闭、v4恢复、隐私修复和一次官方测试激励/同实例落盘/后台展示+1。见gamemunchies-api-domain-20261028与gamemunchies-normal-privacy-reward-20261028；不重复广告、UI或题库测试。完整应用477通过/1显式opt-in夹具跳过、工具84、格式214零变更及分析为已读取的作者本轮结果；不冒充远端CI。

## 支持站与剩余发布项

父已实际阅读本分支两页HTML差额，内容符合当前实现：18尚未分发的条件措辞、默认统计off、独立广告规则请求、新API、撤回清当前scope队列及无法撤回服务端已收记录、单提供方同步失败不假称全部阻断，16/17/Android13明确无GM。可同步到既有Pourlune支持站，仅两页，不覆盖根工作区他人dirty材料。

既有GitHub Actions私有SDK归档具体确认仍待用户答复，不绕过、不重复催问、不上传秘密。答复落实后原开发可推进最终精确源CI；若来源运行输入与本567/554冻结保持相同，可复用本包核，不为文档提交重造包。商店上传仍需原整体任务既有门槛和明确范围，18占号、上传处理及原Self组可安装以真实平台回读为准。当前未生产运行、未上传符号、未向任何商店上传18。保留物理设备及商业广告未验范围。
