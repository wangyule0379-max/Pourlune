# B04 外部身份与真实联调交接

2026-10-22。依据 production-handoff 及当前仓库检索；不收密码、验证码、服务账号、签名私钥或访问令牌。执行侧台账，不修改架构tracking/独立验收。下列缺失不阻塞离线核心、状态机、真实SQLite和官方测试广告能力实现。

|尚缺最小资料|具体阻塞范围|可独立完成|
|---|---|---|
|最终iOS BundleID/Android applicationId及发布主体/负责人|B04-01正式配置归属、B04-09正式签名/分发；当前dev身份不得冒充正式注册|dev双端debug/离线启动/插件编译；官方测试身份|
|Firebase开发项目的受邀访问、匹配dev身份的公开客户端配置；生产项目单列|B04-01/07、AC34/36真实初始化、Analytics DebugView/去重收件、Crashlytics测试报告和符号、RC真实有效/错误/离线回退|SDK固定/编译、无配置disabled、超时失败、严格RC、许可/事件SQLite去重和边界测试。disabled/替身不算Firebase真实联调|
|AdMob所属应用及隐私消息配置的受邀访问/公开AppID；正式广告位后续单列|B04-06正式应用UMP/地区消息/适用ATT控制台验证，B04-01正式广告归属；官方共享测试App不证明用户应用消息配置|仅官方测试广告ID的真实SDK能力、状态机/SQLite回归、实际可用测试设备。绝不借其他用户项目或伪造同意|
|真实HTTPS支持/隐私URL、有效反馈邮箱、处理来信/隐私请求的负责人|B04-08设置入口正式可用、外部隐私声明批准/发布|严格配置入口、未配置真实说明、静态英文支持/隐私草稿和实际SDK数据清单。不虚构域名/邮箱、不部署、不代签|
|原视觉及派生美术的商用权属依据|B04/B05正式发布素材核验|维持production_candidate / UNCONFIRMED，不因运行截图改成商用通过|
|双方代表真机、Android运行设备及适用辅助功能/中断条件|Android原生操作/广告、真机性能、读屏、听感/中断覆盖|本机可用Simulator及双端debug构建；其他设备未验证|

收到配置后由归属负责人提供公开客户端文件或经授权工具配置；服务账号与签名凭据不入库/日志。用户选择UMP广告请求资格与Analytics/崩溃共享分别处理。Firebase Remote Config仍涉及InstallationID，不能声称关闭Analytics等于Firebase零数据。

Crashlytics原生自动上传保持关闭；官方SDK可能在本机缓存原生崩溃报告，报告共享与Dart记录受独立选择门控。显式发送/删除是SDK请求，不是控制台收件/删除完成保证，不能撤回已经发出的网络数据。具体项目配置/法律文案仍需负责人确认，草稿不构成合规认证。

## Data inventory for owner review (implementation, not store/legal approval)

|Capability|Local / third-party data|Current default / external evidence|
|---|---|---|
|Puzzle, rewards|Full snapshots/history, local random IDs, unique entitlement, attempt/status, cooldown time in SQLite|Local core; no account/server. Reset removes puzzle/reward records; preferences and service diagnostic dedup remain|
|AdMob + UMP|SDK app/device/network/advertising interactions; local attempt/request IDs are not custom ad targeting parameters|Official sample App IDs/units in debug; release Dart ads disabled by default; UMP qualification verified on iOS simulator, full ad outcome recorded separately|
|Analytics|Bounded manual gameplay/helper/ad/save events, SDK technical/automatic events; installation infrastructure|Separate default-off choice; no Firebase project supplied, disabled native build, no console/network delivery claim|
|Crashlytics|Sanitized category and stack; native technical/cached crashes may predate opt-in|Automatic upload always false, opt-in includes cached reports, explicit send gate; no real project/symbol/console evidence|
|Remote Config|Firebase installation infrastructure;4 strict parameters only|Last validated/default fallback; ads flags only future actions; no active-puzzle mutation|
|Support|External HTTPS browser or mailto subject; player writes/sends themselves|No approved domain/email provided; accurate unavailable copy; DRAFT help/privacy only|

ATT ruling: this implementation uses non-personalized requests and does not request IDFA/tracking authorization. No custom ATT prompt is fabricated. A future tracking-enabled configuration requires official UMP/ATT setup, truthful usage description and real-device evidence before activation. Current build is not certified for production privacy disclosures or all regions.

Firebase native-ready gate: `POURLUNE_FIREBASE_NATIVE_READY` defaults false; even valid Dart Options alone remain disabled. Android Gradle uses exact Google-services4.5.0/Crashlytics3.0.8 only when a real matching app/google-services.json exists. iOS real plist target/symbol registration and both consoles remain owner handoff. The flag is a configuration assertion, not a validation result.
