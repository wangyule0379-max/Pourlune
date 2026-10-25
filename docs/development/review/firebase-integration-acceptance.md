# Firebase 注册及配置接入：独立验收

2026-10-22（Asia/Taipei），产品架构。**注册与配置实现及本次可验证运行范围通过；真实Analytics/Crashlytics收件未通过，整批服务验收未关闭。** 不等于Apple商店身份、正式签名、真机性能、真实广告或发布通过。

## 独立执行证据

- 本聊天实际打开Firebase控制台，逐项回读开发/生产项目ID、number、Spark方案、四个平台App ID和原生ID；开发ID保持既有值、生产双端com.pourlune.app。记录见firebase-integration-evidence/browser-independent.json。Analytics属性/流隔离还参考作者注册证据；本聊天独立打开dev属性560151748，未将作者截图称为本聊天现场回读所有属性。
- 独立运行真实本地四组配置交叉核对，原生文件/Options/注册矩阵一致，只保存公开ID和hash。见independent-config-validation.json；配置不入Git。
- 审查firebase_config/build/symbols、Gradle、Xcode build phases及QA入口；无产品游戏规则或默认采集策略改动。生产target修复后独立重跑24项Python测试通过（config-tests-independent.log），覆盖错项目/平台/ID、缺配置、环境切换、目标参数与符号UUID。
- 独立复跑23项Flutter服务测试，全部通过（services-independent.log）。检查源代码限定QA入口仅debug+dev+独立库，产品main不引用QA入口。
- 独立检查当时dev iOS制品plist、App ID、实际Mach-O UUID和Android APK hash，匹配作者dev产物。随后串行独立构建Android none与iOS none均成功；实际产物无Firebase原生配置残留，默认开发ID保持。对应两个none-independent-build.log与artifact.json。**当前build路径已被架构none构建覆盖**；已安装专用设备仍为dev QA，不能把当前build当作dev制品。
- iOS专用模拟器7C054CE1-CCA7-405E-A884-886A859D6968实际打开App、手动瓶2→瓶1，教学进入第三步、显示2moves；实时QA响应确认SDK ready、正确开发App ID、双采集关闭、修订2落盘且clean。截图与ios-independent-runtime.json为本聊天新证据。
- Android独立AVD emulator-5582在作者有界重启后，本聊天用唯一命令ID取得实时响应（PID3591），SDK ready、正确开发App、双采集关闭、原实例修订3与落盘一致。android-independent-runtime.json。没有把该诊断取样写为Android人工UI/真机操作。
- 独立回读开发RC版本3，false/false/false/[]已恢复安全值；双端实时policy也相同。v1→非法v2→安全v3及Android断网历史使用作者原始记录，未重复发布服务器测试配置。iOS物理断网未验证。
- 独立打开dev DebugView，过去30分钟0设备/0事件；独立打开两端Crashlytics，仍为Add SDK引导、无可读issue。初始化成功/发送API/上传工具exit0均不提升为收件通过。
- 独立计算普通b04_review_r2.sqlite摘要仍为dc94bbfd1e8b10cda675f139a822c39e83dcc38bdf830c3a245d2221da9978c6，未触碰普通安装。见protected-review-independent.json。

## 八项判定与AC

|任务|独立结论|证据与边界|
|---|---|---|
|F01注册|Firebase项目/四App通过；Apple未完成|控制台及本地配置交叉回读；Firebase注册不能证明ASC/Play身份可用|
|F02配置校验|通过|四组真实文件+24项主机检查；无私钥/API key输出|
|F03原生选择|实现与复验范围通过|作者dev/prod/none历史构建；本聊天dev制品检查和双端none重建；未独立重建prod|
|F04符号|实现与UUID关联通过，收件未通过|SPM路径/脚本输入/配置匹配审查；作者uploader exit0；本聊天dev Mach-O UUID匹配。receipt脚本发生于最终签名之前，不能要求脚本时binary hash等于最终签名binary hash；UUID仍须一致|
|F05初始化/分析|可用SDK及隐私/离线范围通过，AC-36分析收件未通过|真实dev运行、本地保存/去重；控制台0事件不算通过|
|F06崩溃|触发/恢复有作者证据，报告/符号化收件未通过|本聊天独立控制台未见issue；不能把pending=false当上传成功|
|F07RC|安全恢复与本地生效通过；异常/Android离线为作者运行证据|本聊天live版本3及双端policy；iOS断网待验|
|F08交付|通过，外部项保留|明确源文件、命令、可复验路径、缺口；本报告独立签署范围有限|

AC-33：本聊天实际动作落盘与实时状态通过，历史native crash恢复由作者证据支持；不重复宣称已复跑全部B05强杀。AC-32真实广告未新增通过结论。AC-36本地实现可验，但分析服务验收仍未通过。

## 未通过项与后续

- FI-E01（服务验收阻塞）：Analytics无DebugView收件，两端Crashlytics无可读报告。Android原始运输诊断有连接关闭/TLS握手失败，iOS相同根因尚未证明；不把网络问题推定为全部根因，不改变TLS/代理/权限来绕过。需有界补充诊断并在可达服务网络复验，不能反复等待库存或仅刷新控制台。
- FI-E02（平台身份外部依赖）：Apple Developer Identifiers重定向登录，需账号持有人恢复登录后继续已授权标识注册；旧协议提示由持有人本人处理。Firebase文件无需用户再次下载。
- 代表真机、正式签名、ASC/Play记录、支持入口、权属及AdMob仍按原交接保留，不新增本批通过结论。
- 未发现阻止保存本批配置实现的未关闭P1/P2代码缺陷。仅提交已核查实现和相应证据，不合并main、不发布；推送后检查这次精确提交CI。
