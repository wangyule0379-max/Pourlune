# TestFlight 0.5.0(17) 源准备

2026-10-28。用户要求修复已发现问题、总控实际验收后更新原TestFlight组。父已接受F15、通用隐私回续差额及本轮实际激励/插屏路径；版本17由Computer在ASC实际回读最高16、无17/处理中17后选择。当前进入精确CI和签名候选准备，尚未上传。

## 隔离发行范围

分支codex/testflight17-fixes从受验f47610b（含53dc的21–60正式题校准、音频中断修复与隐私清单构建阶段）建立，原GM开发分支/证据不回滚。F15 28a4941等补丁精确纳入e545d08；非GM保存选择代次37e72c7，host正式21前置工具3ba4bc1。新客户端没有gamemunchies_client或本地SDK path，不把私有SDK推到public仓库。

相对当前开发源，246个共同运行源/资源完全相同；仅GameController的GM开局时间/上报、GoogleAdsTransport的GM/QA诊断、ServiceHub的GM reporter被排除。通用隐私选择代次已保留。正式60题/每日30/catalog、音频、瓶体、其他运行UI、iOS Runner与注册配置一致，见source-parity.json。

## 已修与实际验收

- F15：配置存在而邮件handler打不开时，显示真实邮箱而非假称未配置；浏览器失败与缺配置独立。父13聚焦通过并实际看Computer新图接受。
- 隐私：旧失败回执不能覆盖新成功选择，dispose后旧回执不再改状态。真实SQLite写入、仅完成回执延迟的2项先RED，再与原服务/UI/F15共15通过，分析无问题；父已读源/测试接受，不重跑全量旧矩阵。
- 广告环境：本轮实际SDK googleads.g.doubleclick-cn.net命中REJECT。仅已批准exact域沿现Google策略短时验证后，两库存ready，官方Test mode激励展示/关闭、原实例一次confirmed/done与entitlement、Undo/Restart/重启保留。正式main021预置最后7→5后Next真实插屏、关闭进入22，boundary/total/consumed11且首通一次。两轮分别约142秒/71秒后主动恢复，持久配置不变。未加pubads或其他域、未改TLS/DNS/时钟/SDK超时/策略。
- 常态网络策略按原要求保留，后续新请求仍可能被本机拦截；不声称永久修改网络。GM后台聚合1已收到，单事件归属未独立证明；此包不带GM。Android人工/物理手机/真人难度不冒称已验。

## 本机发布检查

68配置工具测试、90题strict release+catalog、v5校准、UI清单、assets单元与音频检查通过。visual manifest初次失败唯一为历史bottle来源指纹；实际瓶体SHA与已发16源2b364d6/f476完全相同，23资产/运行副本/其他来源无差额。父独立核准只同步这一来源SHA，复验通过，首轮失败记录保留，没有重做图片或刷新未知漂移。

源码合规scanner仍exit2/critical3，原输出保留，不设绕过环境变量。以下按实际范围triage，最终以签名包/平台处理结果收口，不宣称公开App Store发行批准：

| 条目 | 分级/范围 | 实际判定 |
|---|---|---|
| FLUTTER-PRIVACY-MANIFEST-MISSING / APPLE-PRIVACY-MANIFEST-MISSING | scanner critical | 源扫描不含ignored SDK框架；已有16和f476签名包具有效SDK清单。本次候选仍须独立检查包内全部清单/原因及无空数组，当前待核 |
| APPLE-2.1-STAGING-BACKEND | scanner critical | ServiceConfig包含localhost/example域拒绝列表，QA测试有合成地址；正常离线核心无业务服务器，发行prod Firebase与确认HTTPS目的地单独核，无GM/test backend运行 |
| BOTH-PLACEHOLDER / SUBSCRIPTION-HARD-CANCEL / SOCIAL-MEDIA | scanner high/medium | 示例值在测试/URL拒绝列表；无订阅、账号或社交功能，邮件为反馈入口且本轮已修，未增加伪功能 |
| APPLE-EXPORT-COMPLIANCE-MISSING | scanner high | 不伪填无加密；Flutter BoringSSL事实未变，沿本人已批标准算法+Apple系统/内部不法国，上传后实际保存平台合规状态 |
| Android R8/AD_ID/Data Safety/12-testers | 非本次iOS内部TF发布 | 维持Android13旧分发/声明，不以本次iOS结果批准Play正式版；不加新权限或开轨道 |
| 真机、公开发行地区/分级等 | 保留范围 | 复用父现有审查及内部本人组，不扩成公开发行或编造真人/物理设备验收 |

两份prod iOS客户端配置只在ignored600路径，public summary/hash与原输入一致；既有Pourlune专属profile/现有签名identity匹配且有效，不生成/重置私钥。此次仍official sample units、原owned native AppID、正式com.pourlune.app、NoAdID及独立采集默认off。准确源CI、签名包/hash/原组正在测试将记录到最终交付；此文不提前宣称完成。
