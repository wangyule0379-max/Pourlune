# TestFlight 0.5.0(17) 功能修复与广告验证

2026-10-28。总控已实际验收产品修复和测试广告链路，精确源码CI、签名包及Organizer上传变体均通过独立检查。Computer已上传0.5.0(17)，Apple处理完成，原Pourlune Self组显示“正在测试 / 90天后过期”，仍为既有2名测试员。总控已实际看上传成功、原组和构建详情三张图片并读AX，末项通过；无需重复上传或邀请。

## 修复与验收

- 邮件反馈有有效配置但系统没有邮件handler时，现显示可手动联系的真实邮箱；打开浏览器失败、未配置和打开成功分别处理。F15在正常main实际复测，总控看新图通过。
- 隐私选择保存采用代次门控，旧失败回执不能覆盖较新成功选择，页面释放后旧回续不能修改状态。两项真实SQLite写入/延迟完成回执测试先失败后通过，连同服务和反馈UI共15项聚焦检查通过，总控读源接受。
- 本轮实际广告timeout对应googleads.g.doubleclick-cn.net被本机REJECT规则阻断。按既有授权，只对当前命中域短时沿原Google线路验证；官方Test mode激励完整关闭后原实例奖励仅一次，Undo/Restart/正常重启保留。正式21最后一步7→5后Next真实插屏、关闭进入22，持久资格/消费序号及首通去重一致。总控实际看图及SQLite回执通过。
- 两轮临时例外分别约142秒和71秒后恢复，持久配置不变；没有改变TLS/DNS、延长SDK超时、增加新域或启用收费单元。原本机拦截策略恢复后，新广告请求仍可能被该环境阻断，不能称永久解除网络限制。

本包包含此前已受验的正式21–60题五色七瓶校准、音频中断修复及SDK隐私清单修正。GM测试分支/数据/私有SDK保留在原工作区，本次内部发行不包含GM依赖或上报。

全功能人工记录F01–F19及当日F03/F06/F07/F08/F15/F17后续见证据manual-functional/computer-report.md；其中F15是实际观察到的产品失败，已修复复测。BLOCKED行保留真实未覆盖部分，不把工具条件、手工未诱发的故障或测试夹具通关改写成自然通关/全覆盖通过。该记录是原报告副本，内部相对链接仍按原证据目录解析；本发行目录另附F15实际修后截图和广告证据。

## 精确来源和检查

- 发行分支：codex/testflight17-fixes；源码5fb8b79a8f228a0ece125fba7aa8bb91e2d48b3a，版本0.5.0+17。隔离基线f47610b，F15纳入e545d08，通用隐私修复37e72c7。
- [精确CI40631141257](https://github.com/wangyule0379-max/Pourlune/actions/runs/40631141257)两job终态成功，总控独立API核验同一head。工具68、核心47、应用446通过/1跳过（需要显式启用的manual_function_fixture_test夹具生成器）；静态分析、Android debug APK及iOS simulator构建通过。
- 本机90题strict release/catalog、v5内容校准、图像/UI清单、assets单元及音频检查通过。仅按总控核准同步历史瓶体来源SHA，实际图片/瓶体源与已发16相同；首轮差额保留。
- 源合规scanner原exit2/critical3保持真实，逐条范围判定见源准备文档；实际签名包所有SDK清单及无空访问API数组由总控独立检查通过。未以绕过开关、补占位功能或谎报无加密消除扫描输出。

证据在../evidence/testflight17-fixes/；源准备说明见testflight17-source-preparation.md。

## 冻结候选与实际上传变体

候选：build/beta-candidates/0.5.0-17/ios-functional-fixes-1；独立只读镜像build/package-review/0.5.0-17/ios-functional-fixes-1，563文件同字节，559产物hash和526来源输入匹配。总控54项检查通过：正式身份com.pourlune.app、既有签名/profile、90题147资源、prod Firebase/NoAdID/采集默认关闭、owned原生AppID及官方sample units、正常main、无GM/QA/原生测试插件、dSYM和有效隐私清单。

- 原IPA：86,500,945字节，SHA256 835150b548a84e352f268d98ba69c0298daac996980562848e606aaa2d646765。
- Organizer实际准备上传变体：86,500,977字节，SHA256 1c9e3c86d8a044c9687063d06e8572349ab054d21687c731b4bebffe6ca91df5。总控22项独立检查通过；10处差额只有8个Mach-O既有签名块、TFInternalTestingOnly=true及签名资源，执行内容/UUID/资源/profile一致。
- Computer仅操作可写隔离archive，原候选/镜像保持冻结；符号上传及自动改版本关闭，内部测试only，不创建或重置密钥/profile。

## 平台结果与范围

2026-10-28 04:44 UTC总控独立收口：App 6826203407，构建33420d37-55f2-4a7f-bfd3-fc8cb2f6108c；原Pourlune Self组1853bacc-97d1-40f9-b0cb-ae9ef9d01c74显示0.5.0(17)“正在测试 / 90天后过期”，2名测试员，未新建群组或邀请。实际上传成功、Apple处理完成和原组可访问均有页面证据；没有把平台可测试冒称手机已安装。加密事实沿用本人已批准的标准算法与Apple系统加密并用、本次内部不在法国分发，不伪填无加密。

证据platform/testflight-ready-independent.json包含末项状态和图片/AX指纹，相关平台证据已使用总控脱敏版本保存。准确源CI保留原终态，后续本交付文档提交不改变发行二进制或其源码身份。

F9及原设备/存档保持保护。本轮不证明物理手机安装/升级、触觉/真实音频硬件、真人首次难度或Android人工广告通过；真实广告提前关闭未单独实测，受控合同测试继续保留。GM后台聚合变化不作为单事件去重或展示归属证明。公开App Store发行及商业广告readiness不在本次内部TestFlight通过范围。
