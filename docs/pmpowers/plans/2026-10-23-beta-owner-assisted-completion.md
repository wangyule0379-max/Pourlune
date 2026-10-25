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


## BR05：用户授权代建独立上传密钥并完成本地签名（2026-10-23，优先于上述旧限制）

用户针对Android upload key明确表示“你来搞就可以了，跟以前一样”“不要因为这个停下来等我”。现授权原开发代建Pourlune独立upload key、机器生成强随机口令、仓库外受限本地保存，使用已验工具完成真实本地签名及候选验证；不再要求本人先输入密码。旧BR04本人交互限定仅作为历史，不阻止本批。原开发实施，架构独立验收。

1. 核对实际Java工具和指定Pourlune路径是否已存在。不得覆盖、重置或删除已有key；如用户期间已创建，则确认其alias/公开证书及可用受限凭据，不读取其他产品资产。没有资产时才创建一次正式独立PKCS12 upload key，alias pourlune-upload，RSA3072/SHA256withRSA，有效期10000天。只创建上传密钥，不操作Play App Signing托管密钥或条款。
2. 使用系统密码学安全随机源生成至少32字节熵的ASCII口令，直接写仓库外用户私有目录的0600文件，目录0700。密码只通过Java受限文件参数传递；不得输出至终端/工具结果、argv实值、环境变量、日志、证据、Git或候选manifest。不要展示文件内容，不启用shell trace。文件创建拒绝覆盖与symlink；失败按实际状态诊断，不能盲目再生成第二把key。密钥本身0600，原开发可读取明确授权密码文件供签名程序使用，但不得回显。
3. 留存本机受限恢复副本及仅公开的证书指纹/alias/有效期/路径定位资料，核对副本字节一致。明确本机副本不等异机灾备，不上传秘密或把完整key/password打包进交付；后续由用户自行保存到其控制的安全位置。不得以等待手动备份阻塞本批可做签名验证。
4. 使用已验beta_build/android_signing门控，在新的ignored候选目录生成真实upload-signed AAB，保留原unsigned候选；如新构建则串行、正常prod compile-only/广告disabled/采集默认off/无AdID/锁不变，不虚构未确认支持URL邮箱。不能把已签名等同其他商店资料完成。
5. 实际验证PrivateKeyEntry、公开SHA256 pin、有效期、非debug、jarsigner strict和最终签名证书一致、unsigned与signed非签名payload一致；记录来源/产物哈希、身份版本、资源/符号适用性以及实际命令退出状态。密码字段不得进入证据。真实签名失败才最小修复代码并聚焦复验；无实现变化不重跑旧全量Flutter/CI。
6. 交付docs/development/deliveries/beta-readiness-BR05.md及evidence/beta-readiness/BR05/，明确释放CLI。架构review/beta-readiness-BR05-acceptance.md独立复验公开证书/签名/包；仅提交已验非秘密代码资料。真实设备/商店分发仍未执行。授权未扩大为公开网站、账号声明代签、商店上传/审核/开轨道/邀请或生产运行。

保护F9用户模拟器、普通库及旧QA冻结包；不因其他待定发布资料停止上述已授权工作。任务只在真实技术缺陷/权限阻碍时汇报，不重复索取已获密钥创建和本地签名授权。
