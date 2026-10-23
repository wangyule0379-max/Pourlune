# 封测持有人协作补齐 BR04（2026-10-23）

用户要求架构逐项给建议、带领本人完成账号声明/签名/设备准备，原开发继续可独立完成工程。已确认SKU POURLUNE-IOS-001、英语、益智游戏、免费封测/广告关闭、组名Pourlune Beta；域名/邮箱/Android upload key均暂无；远端Mac无法连接其手机，只能通过TestFlight/Google Play测试。

本计划是既有提交前就绪授权的定向执行，不需再次审批实施计划。目标是消除“等待资料所以不做可预备工程”与“无商店分发所以无法验真机、无真机所以不能分发”的循环；仍不把实际未测标通过。

## 验证先行和职责

先核对当前源码/锁/已验构建工具及正式SDK行为，确认实际缺口；原开发唯一实现，本架构只计划、tracking、独立验收。Flutter等串行无AdID。新来源/构建目录，不覆盖BR01冻结包、用户F9、旧QA/普通库。禁止截图权限绕过。无新产品范围。

|编号|原开发现在可独立完成的交付|验收条件|
|---|---|---|
|BR04-1|确认现有ServiceConfig目的地参数与beta_build缺口，补公开支持/隐私URL及反馈邮箱的明确输入、格式校验、产物元数据记录。|实际值未批准保持缺失/不就绪；拒绝非HTTPS/凭据URL/占位域名与错误邮箱；测试样例不得编入正式候选。不绕过原Firebase/身份/锁门控。|
|BR04-2|完成Android签名接入与失败关闭的校验路径；明确unsigned和已签名产物名/状态/证书摘要。|用户无key，不能伪称签名成功；不得创建临时或正式私钥以凑测试。使用单元/命令替身验证参数和故障门控，真实签名留待用户创建。密码不进入argv/日志/仓库/候选manifest，私密文件隔离且受限，检查误用debug证书/错误alias/缺失文件。避免无必要复杂secret系统。|
|BR04-3|准备可交给用户本人在远端终端执行的专用upload key创建步骤/命令（不执行），alias建议pourlune-upload，独立仓库外路径、密码交互输入、已有文件拒绝覆盖、备份与只输出证书指纹验证步骤。|核对本机Java/keytool实际路径和官方当前指南；不读FishPilot密钥、不生成/重置任何key、不自动签Play条款。后续真实签名需用户明确创建完并授权使用。|
|BR04-4|将现有本地支持/隐私草稿整理成只含公开网页的可部署目录和变更清单；低成本建议独立pourlune-support公共仓库+GitHub Pages，无购域名。|先准备，不新建公共仓库/不部署/不改App源码仓库可见性。运营主体、联系邮箱、权属、数据保留等未知项保留待填且不能伪成正式政策。说明Pages主机IP日志等实际第三方处理，不称零收集。|
|BR04-5|依已确认通用项准备双平台应用记录/测试资料填写表；年龄/地区/出口/主体/隐私等给技术依据和需本人决定栏。|可以只读核查Pourlune既有记录避免重复；本批不代签法律声明、不提交最终问卷，不因SDK默认off猜无数据。没有需要时不反复登录。|
|BR04-6|按远端约束重写设备验证路线为“上传前工程/包校验”与“授权分发后用户设备安装/升级/恢复/音触觉反馈”，沿用正式身份与版本记录。|不再以USB直连真机为上传前一律硬门槛；不可测项目写真实风险及后续关闭步骤。TestFlight先核实用户是否有内部测试资格，无资格走外部审核，不为测试扩大权限；Play最终目标closed，不偷换internal。商店上传/审核/开轨道/邀请仍待具体包就绪后的单独授权。|
|BR04-7|给用户设备反馈表、最小试玩顺序和故障取证字段，先自身账号/少量受控测试者；规划正式N→N+1保存升级，首包无旧N如实记录。|不让用户执行刷机/清数据或安装来源不明证书；TestFlight/Play安装不要求开发者模式/USB调试。生产运行当前仍需明确授权，不偷偷发数据。|
|BR04-8|聚焦测试/文档与可复用命令交付，按现在可验证和真实资产后验证分别列出。|交付deliveries/beta-readiness-BR04.md、evidence/beta-readiness/BR04/；完成释放CLI。架构独立review/beta-readiness-BR04-acceptance.md，代码通过才提交推送/新精确CI；不全量重复旧T/FB/MS，不查旧终态CI。|

## 外部确认与后续执行

详dependencies/beta-owner-decisions.md，所有建议未经明确回复不视为同意。用户目前仅批准通用发布项，没有批准公开网站、新密钥代建、生产运行或商店分发。可先做上表工程，不等待全部回复。真实输入到位后继续同一聊天接入、定向验收、新冻结包。最终上传授权请求须对应可审的版本/哈希/轨道/受众，不现在索取空白授权。

官方依据（2026-10-23回读）：
- https://developer.android.com/studio/publish/app-signing
- https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/
- https://support.google.com/googleplay/android-developer/answer/9859152?hl=en
- https://support.google.com/googleplay/android-developer/answer/9867159?hl=en
- https://support.google.com/googleplay/android-developer/answer/9845334?hl=en
- https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
