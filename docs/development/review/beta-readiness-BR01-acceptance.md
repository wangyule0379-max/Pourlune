# BR01 独立验收：工程准备通过，双商店提交仍不就绪

2026-10-22。架构读取完整交付及八项计划、实际代码差异、原始检查/失败记录、SDK矩阵和集中持有人事项后作出本结论。只接受本地工程、候选静态验证及资料准备范围，不将作者自查或签名成功等同于平台/设备通过。执行未修改生产Dart、纯核心、SQLite、游戏美术或规则，本次继承已有T/FB/MS明确通过范围。

## 本轮独立执行

- 在执行方15:39:44 UTC明确释放CLI后领取复验窗口，运行Python验证32项，全部通过；追加4项实际CLI拒绝探针：缺少既有profile、调用者传导出配置、导出目录越界、prod run均被拒绝且未触发签名或构建。日志与JSON在 `beta-readiness-BR01-evidence/`。
- 独立读取最终两份sources.json，分别394项当前源文件/资源/锁/工具无散列差异。生产Dart/core/assets对已验HEAD无变更。作者analyze、格式、内容/资源及编译日志已读，未将这些描述为本轮重跑；因未改玩法，不重复219项和旧原生路线。
- 从冻结IPA逐文件核对现有解包内容，再实际执行codesign deep/strict校验、读entitlements、CMS和本机可用签名identity公开元数据。正式AppID、Team、get-task-allow=false、profile UUID/当前有效期和既有certificate一致。未读取或导出私钥、未创建签名资产。
- 独立用已核对散列的bundletool验证AAB并重新dump实际manifest/config；jarsigner再次确认unsigned。正式包名、Pourlune名称、0.5.0/5、target36相符。8份64位ELF LOAD段静态对齐至少16KB，bundle PAGE_ALIGNMENT_16K；另有32位armeabi-v7a库，不能把整包库数写成8或宣称32位设备已验。
- 双端136份源码资源逐字节相同，含90题；IPA内24份SDK隐私manifest可解析，嵌套SDK标识均不等于主AppID；iOS路径与Android dex未发现integration_test插件。此为静态SDK清单，不是Xcode汇总隐私报告、实际网络测量或最终商店披露通过。
- 本轮检查脚本先错误假设所有.so均为64位，再错误假设字体文件名没有URI编码。两份脚本失败日志保留；修正检查器识别32位附加库及解码路径后全检查通过，未改变任何候选或生产代码。这两次是架构检查器问题，不记为产品失败，也没有削弱64位对齐/全部资源相等要求。

独立脚本：`beta-readiness-BR01-evidence/inspect_independent.py`；结果：`candidate-independent.json`、`inspection-independent.log`、签名与bundle日志、`validation-tests.log`、`export-negative-independent.json`。未安装、运行生产包、拍照、录屏或操作任何模拟器；用户F9及窗口、普通数据库完全未动。未重复之前Cocoa513/EPERM采集尝试。

## 八项裁定与AC边界

|计划项 / AC|独立依据|裁定与未验范围|
|---|---|---|
|BR01-1 / AC01–36|394×2来源、锁文件和版本；AC继承表与T/FB/MS报告|事实基线通过；未把历史运行变成本批全量新结果|
|BR01-2 / AC31、34|最终双端ID/显示名/版本、默认none开发包作者日志；签名profile独立匹配|包身份通过。会员/Play账号/控制台未独立登录回读，accounts.json仅作者观察；ASC/Play记录未就绪保留|
|BR01-3 / AC34|本轮32测试+4拒绝探针、实际IPA签名/CMS、AAB签名状态|已有资产手动本地导出路径通过；Android无授权上传签名，不能上传；无商店处理证据|
|BR01-4 / AC13–21、32、34、36|wrapper配置保护/原生产物、SDK清单、服务矩阵和代码|默认off/adsdisabled与现有prod编译方案一致；RC/SDK处理不能称零采集，prod运行/撤回/收件未验证|
|BR01-5 / AC31、34|实际manifest/SDK/资源ID/64位对齐；重新查官方规则|适用静态版本与包检查通过；16KB运行、最终隐私汇总/问卷/平台处理待完成|
|BR01-6 / AC31、34|英文beta文案、help/privacy及本地HTML、真实服务与功能对照|可审草稿通过；未发布、无批准公共URL/邮箱/处理人，最终披露不通过|
|BR01-7 / AC31、34、35|136包内资源一致、90题；原作者严格内容/资源检查日志及来源|来源/资源一致性通过；不替代真人难度、图像商业权属、真机音触觉/无障碍/性能|
|BR01-8 / AC23、24、34|不可覆盖目录及源码漂移门控、冻结散列、CI差异|可重复候选与交接范围通过；本次提交的新精确CI须另跟，BR02/BR03与实际商店分发尚未通过|

没有发现需在本批退回修复的阻断代码缺陷。持有人门槛BR-B01/B01-P/B02/B03/B04/B05/B06仍阻止整体提交就绪；详见执行方集中事项。旧FI-E02“Apple账号无法登录”已被实际专属profile及本地签名证据取代，不能继续要求用户恢复已可用登录；商店记录/协议由持有人判断的门槛仍存在。

## 冻结候选与局限

- iOS `build/beta-candidates/0.5.0-5/ios-br01-3/Pourlune-0.5.0-5.ipa` SHA256 `0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5`：本地签名验证通过；没有安装、App Store处理或TestFlight测试者证明。
- Android `build/beta-candidates/0.5.0-5/android-br01-3/app-release-unsigned.aab` SHA256 `ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90`：格式/静态内容验证通过，仍unsigned。

代码提交只包括本批原生身份/签名作用域、版本、构建工具/测试/CI、文档和已验BR01证据；不包含旧未验motion-polish、生成的.android/kotlin目录或私密客户端配置、profile和候选包。本轮没有重新编译或声称独立构建通过，独立接受的是代码检查、门控测试及既有最终产物实际验证。BR02仍须针对身份/签名/构建模式差异验证，不能借历史debug环境跳过。

## 官方依据回读

本轮重新核对[Apple要求](https://developer.apple.com/news/upcoming-requirements/)：Xcode26/iOS26 SDK、最低target13，候选minimum15/SDK26.5满足这些静态版本项。[Play target](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)要求新提交target36，包内为36。[Android16KB](https://developer.android.com/guide/practices/page-sizes)明确需要对应运行环境，静态对齐不能代替实测。[TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)内部/外部条件分别保留。[个人账号测试](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)的12人14天用于适用账号后续生产访问，不是开始closed前置。[Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)含第三方SDK数据，off默认不是零数据声明。上述仅用于本批相关判断，不代持有人签署法律/隐私结论。

## 后续

通过范围精准提交推送后跟进新实现CI；释放CLI给原开发，继续BR02可独立项与BR03交接整理。实际生产配置运行、创建/重置密钥、商店上传/开轨道/邀请/代签边界不变。无法获得正式签名/设备/允许采集条件的项目直接保留具体阻塞，不以再跑相同旧QA或无限等待替代。所有内部可做项收束后才集中通知需要持有人操作的最终清单。

提交记录：已验97文件范围已精准提交推送 `33433c76cd6c97338f0016815208999832050cfb`；精确CI `39809177137` 当前in_progress。原开发已接收BR02/BR03八项连续工作包并确认执行，CLI已交还；后续跟踪文档不要求新CI。

## 远端CI终态补记（2026-10-23）

精确实现33433c76cd6c97338f0016815208999832050cfb的run39809177137，架构通过GitHub连接器独立回读completed/success；ios-build于16:02:14Z、tests-and-android于16:02:56Z成功，run更新于2026-10-22T16:02:57Z。证据[remote-ci-final.json](beta-readiness-BR01-evidence/remote-ci-final.json)。此终态不再轮询；不扩大本报告为正式设备运行或商店提交通过。
