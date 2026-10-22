# BR01 TestFlight / Play封测准备（执行交付）

2026-10-22。基线与精确来源见[事实表](../evidence/beta-readiness/BR01/release-facts.json)和各产物sources.json；版本 **0.5.0+5**，双端正式身份 **com.pourlune.app**，显示名Pourlune。原开发未stage/commit/push；计划/tracking/独立review归架构。MS01–03及MS-R01已有独立复验通过范围，音画/真机和焦点Minor不扩大。BR01本地可独立完成范围已实施，一次fresh作者终审已完成（Critical0/Important0），等待架构独立验收；**整体仍不具备可提交结论**，见编号门槛。

## 八项执行范围

|项|实际完成|仍缺/边界|
|---|---|---|
|BR01-1|当前源码/工具链/locks、已验T/FB/MS、AC01–36逐项继承登记；旧B05无配置/旧身份不再照抄|历史证据不是本批全量重跑；[AC登记](../evidence/beta-readiness/BR01/ac-inheritance.md)保留SDK/物理条件缺口|
|BR01-2|确认既有AppleTeam T7U878Z8H6/个人/续订2027-09-17及Play个人账号；Apple专属PourluneAppID登记；Play包名可用；正式/开发名称隔离、版本4→5递增；复用既有月亮图标|ASC记录/SKU、Play创建声明及最终年龄/地区/审核联系未填，不代签。没有改FishPilot项目/配置/密钥|
|BR01-3|复用既有分发证书，生成/下载/验证/安装新PourluneAppStoreprofile；完成手动archive/export及IPA深度严格签名/entitlements/embeddedprofile验证。新增现有资产/身份/过期/分发类型门控与不可覆盖候选工具|Android未选定授权上传密钥，AAB仍unsigned；未创建/重置/导出私钥，无自动provisioning-update或symbolupload|
|BR01-4|沿用既有prod匹配配置仅编译、adsdisabled/独立采集默认off；4个dev/prod本地配置重新校验，实际嵌入SDK/权限另列|不是零数据；RC可涉及installation。旧Firebase收件/网络失败未重复实验，真实广告仍未联调；[服务矩阵](../evidence/beta-readiness/BR01/service-matrix.md)|
|BR01-5|两商店适用预检+当前官方版本规则；修复名称/签名作用域、release devplugin残留及SDK资源BundleID污染；最终IPA24份SDKmanifest、AAB合并manifest/10权限/target36/64位ELF及16KBbundlealignment|[预检及scanner人工分流](../evidence/beta-readiness/BR01/preflight-review.md)；不把扫描提醒当已拒绝或全项合规，实际16KB设备运行未验|
|BR01-6|英文beta/WhatToTest/已知问题/反馈/审核路线/截图及表单事实草稿；复用并更新help/privacy，提供本地可审HTML；未知公开目的地未伪填|真实公共支持/隐私URL、邮箱/处理责任人、披露与法律批准、正式截图仍缺；[英文资料](../evidence/beta-readiness/BR01/beta-copy-en.md)|
|BR01-7|90题严格release+catalog、核心production_content4项；视觉/UI清单只读通过、音频生成/PCM检查通过；双端136资源逐字节与当前源码一致；字体OFL/原创程序音频来源保留|自动解≠真人难度；视觉接受≠商业权属。原/派生图像UNCONFIRMED；当前无iOS物理设备，adb仅5588模拟器|
|BR01-8|隔离命名的最终3候选、源码/资源/SDK/签名/版本散列；CI加入无凭据Pythonguard检查；BR02/03具体清单|尚无本批已提交代码的远端CI；没有上传/审查/测试轨道/邀请/测试者安装证明；[后续门槛](../evidence/beta-readiness/BR01/BR02-BR03-checklist.md)|

## 冻结产物

以下目录被Git忽略，执行日志/JSON证据入交付；旧失败/中间候选保留，不互相覆盖。两平台最终sources.json与当前源码逐项仍一致，见final-source-check.json。没有安装或运行生产候选。

|平台|本地路径（项目根下）|字节/签名|SHA256|
|---|---|---|---|
|iOS|build/beta-candidates/0.5.0-5/ios-br01-3/Pourlune-0.5.0-5.ipa|59257617；既有分发证书签名，deep/strict通过，get-task-allow=false；同目录保留xcarchive/dSYM/导出日志/签名JSON|0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5|
|Android|build/beta-candidates/0.5.0-5/android-br01-3/app-release-unsigned.aab|106155330；JAR unsigned，bundletool validate通过；不是可上传包|ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90|

[候选核验摘要](../evidence/beta-readiness/BR01/candidate-inspection.json)记录90题与全部136资源一致、正式身份/名称/版本、iOS24份vendor隐私manifest、AndroidAPI36和8个64位.so的LOAD对齐≥16KB、bundle PAGE_ALIGNMENT_16K。前述静态检查不代替16KB实际运行、Xcode汇总privacy report、平台处理或商店表单。最终iOS所有SDK资源包保留自身标识，不再等于主AppID；双端release不含IntegrationTestPlugin。无SDK升级、无生产Dart规则/UI/SQLite逻辑改动。

## 实际验证和有效修复

- 根目录Python验证32项通过，包含既有Firebase错项目/环境/ID/target/上传阻断、新profile身份/到期/分发/既有本机signer、候选不可覆盖/目录逃逸/版本门控。开发签名profile绝不当AppStoreprofile。新工具从缺失RED到GREEN；RunnerID作用域有真实fixtureRED→GREEN及原生中间包22资源ID污染证据。
- app/：enforce-lockfile、dart format lib/test/integration_test 0变更、flutter analyze无问题；最终生产签名归档/导出与Androidrelease均通过。另默认none/dev Simulatordebug编译成功，实际Info仍dev.pourlune.pourluneDev/PourluneDev，未带GoogleServiceplist；仅编译未安装，不冒充默认配置运行。
- packages/pourlune_core/：enforce-lockfile及production_content_test4项通过（90解、原教程/旧12历史、每日/旧实例定义和当前状态求解预算检查）；不是测出真机性能达标。
- 根目录5资源/内容检查通过，详见resource-checks.json。未刷新manifest掩盖漂移，未重生成美术/音轨。136资源实际进入双端最终候选且散列一致。
- iOS-Br01-1全局profile传给SPM导致归档失败；Android-Br01-1 stale注册器引用release缺失devplugin；iOS-Br01-2虽签名成功但SDK资源ID被全局覆盖。都先保留失败，最小改应用配置/构建工具，未改SDK源码/版本。具体[修复历史](../evidence/beta-readiness/BR01/repair-history.md)。最终3目录才是交付候选。
- asc5.16.0、Googlebundletool1.18.3和专用profile均已由执行侧下载安装；bundletool SHA核对官方digest，profileCMS核对Team/App/过期/现有证书。普通链接下载失败后用浏览器正式downloadAPI保存，无cookie/token提取。无任何屏幕采集限制重试。

## 提交前结论与集中事项

**iOS：本地签名IPA已具备；TestFlight提交前仍不就绪。Android：unsigned AAB检查完成；Play closed testing提交前不就绪。** BR-B01商店记录/持有人声明、BR-B02 Android授权上传密钥、BR-B03公共支持/隐私及联系方式、BR-B04商业权属、BR-B05准确表单/受众/地区、BR-B06适用设备/升级/无障碍/正式截图保留。具体入口和已完成准备集中在[持有人事项](../dependencies/beta-readiness-user-actions.md)，不要求传私钥/密码，不重复注册Firebase。账号/密钥/公共目的地/法律/设备不齐不能靠本地自查标通过。

iOS内部/外部TestFlight和Playclosed各自门槛分开；Play内部测试不能替代封测，12人14天为适用新个人账号后续生产访问条件，不是开始封测前置。默认不开真实广告，免费/离线核心不等广告库存。此前Firebase运输故障、实际音画/物理触觉、性能/读屏/最低OS和同签名正式覆盖安装未补作通过。开发/QA与正式App不同身份的存档不自动互迁；这不是正式同身份升级保留的证明。

执行取舍：不从通用清单添加账号/支付/后台/UGC/年龄SDK；代价是未知受众/地区适用声明仍需持有人确定。签名只复用既有资产且手动本地export；代价是缺失资产即失败、不自动创建。release允许Flutter正常tooling/pub刷新并逐字节锁源码/lock；代价是生成元数据刷新增加少量构建准备，但避免dev注册器污染。与已验T/FB无关的全量重跑未做，边界已按AC逐项继承。MS焦点转移未直接断言的Minor及物理音触觉限制保留原报告。

作者交付完整可审查包后才进行架构独立验收/精准提交。当前未stage/commit/push，未修改tracking/plans/review；F9及窗口、普通b04_review_r2.sqlite、旧FB/Firebase库和原始设计均无运行/写入操作。CLI最终释放记录见ui-transition-handoff，必要后续命令先协调。


## 一次作者终审及执行裁定

fresh reviewer `br01_final_review`（gpt-6-astra）对本批整体作一次只读终审：Critical0 / Important0 / Minor2，并独立运行Python32项、核对两平台各394项当前来源和IPA/AAB散列。没有再次派发复审。报告为[作者终审记录](../evidence/beta-readiness/BR01/author-final-review.md)，不代替架构独立验收。

两项Minor为收尾时点差异：CLI HELD记录已在所有命令结束后追加真实RELEASED；隐私HTML的3个供应商Markdown链接在审查进行时已转换为实际锚点，并验证3个链接均存在。未因此扩大代码修复范围；本批无新增未处理代码Minor。历史MS焦点Minor继续保留。

执行裁定（含终审未判断范围及代价）：

- 通用审查中的账号、后台、IAP及年龄SDK不适用于当前离线解谜功能，不新增功能；受众/地区未确认的代价是最终声明尚不能签定。
- 商店事实、SKU、持有人声明、受众/地区及商业权属由持有人确认；资料和入口已准备，未代签。代价是本地签名成功不能关闭这些提交门槛。
- 真实设备、同身份正式升级、16KB运行、读屏/音画及正式截图不以静态检查替代；列入后续门槛。代价是对应运行体验和兼容性仍未证实。
- 终审未独立访问Keychain/profile，仅审阅工具和保存证据；执行侧实际签名验证已记录，架构可复核。代价是作者签名证据不构成第二次独立资产验证。
- 未提交代码的远端CI、商店处理、测试者安装未执行；不通过上传或邀请来补证。代价是本地32项通过不能推定这些外部阶段成功。
- 已接受MS/T/FB按AC边界继承，不在BR01重跑/重审；代价是历史未验项仍保留，不能升格为本批全面通过。
- 手动本地export只复用既有证书/profile、不自动生成或重置密钥；代价是缺失资产会明确失败。release正常刷新Flutter生成元数据并锁定源码/lock；代价是增加构建准备，避免旧开发插件注册器污染。
- 按既有分工由架构精准提交，本执行不commit/push；本批记录及候选保留，BR02/03在架构接受BR01后推进。代价是本地交付完成不等于分支已合入或整体Beta目标完成。
