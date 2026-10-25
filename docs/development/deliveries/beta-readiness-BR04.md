# BR04 持有人协作补齐：工程已接入，真实资产与分发待确认

2026-10-23（Asia/Taipei）。按已授权八工作包连续实施，不新增玩法/服务方案/SDK。用户确认SKU POURLUNE-IOS-001、英语、益智、免费封测广告关闭、组名Pourlune Beta已用于资料准备；不再把USB连真机当上传前普遍条件。当前实际域名/邮箱/key、法律及生产运行/分发未批准，不以样例或命令替身冒充正式候选通过。原开发未stage/commit/push；计划/decisions/tracking/独立review归架构。

## 八项交付与验证边界

|项|实际完成|真实输入后仍要验证|
|---|---|---|
|BR04-1 公开目的地|public_destinations.py校验支持/隐私HTTPS及邮箱；beta_build和firebase_build显式flags，经原private definefile传入现有ServiceConfig；候选metadata记录确切公开值/格式完整状态，缺失为空；拒绝直接dart定义覆盖目的地或ads|真实URL/mail尚无，未编入新原生包或实点。格式ready不等于归属/可达/批准/提交ready|
|BR04-2 Android签名|既有资产显式4参数+可选key密码文件；仓库外私密权限/alias/指纹pin/PrivateKeyEntry/有效期/debug门控；保留unsigned，另生成upload-signed副本，strict校验+非META-INF payload一致；失败删除新不完整副本，manifest只有公开证书元数据|无真实key，不执行真实签名。单元/命令运输替身正反向通过不等于Java真实签名/Play最终APK签名或升级通过|
|BR04-3 本人key命令|只读核对本机JDK21/keytool/jarsigner；交互创建/拒绝已有文件覆盖、仓库外路径/备份、仅公开SHA256及0600密码文件步骤已准备|命令从未执行，不生成任何测试/正式私钥，不读FishPilot资产；本人创建并授权后再接入|
|BR04-4 仅公开网页|pages-site/只有index.html/privacy.html/.nojekyll；复用既有可审草稿，补Pages IP安全日志及运营联系/保留流程未决状态；3文件ZIP及hash|未创建public repo/部署/购域名/改源码可见性，DRAFT/noindex仍保留，非已可用隐私政策|
|BR04-5 逐字段资料|确认SKU/语言/游戏/免费/组名；Apple/Play字段、SDK数据/隐私/出口技术依据、本人决定栏齐备|未重复登录/创建记录/签法律/提交问卷；年龄/地区/主体/权属不猜填|
|BR04-6 远端时序|上传前工程与明确授权分发后的TestFlight/Play手机验证分开；内部资格先核实，无资格走外部审核、不扩IAM；Play目标closed|无真机不伪称测过，也不形成无USB不能上传的循环；生产运行及分发仍另待具体授权|
|BR04-7 最小试玩/反馈|本人/少量受控名单优先，版本/设备OS/商店地区/操作/保存/音画字段及N→N+1路线；首包无旧N记未验|不要求debug USB/开发者模式/装未知证书/清数据/导库；真实安装升级/恢复/音触觉/读屏/性能仍未验|
|BR04-8 聚焦验证|Python46项通过，3项真实CLI拒绝探针未创建输出；HTML/公开ZIP/原冻结包hash与预期工具源码漂移核对；没有改App Dart/core/native/assets/locks|真实目的地/签名/新包/平台处理与设备证据后续关闭；不全量重跑旧T/FB/MS，不查旧终态CI|

## 可直接审查的产物

- [目的地与签名使用说明](../../../tools/validation/README.md)：新flags、私密文件契约、默认unsigned/签名后状态；metadata.signed_for_upload仅描述技术签名，external_store_gates_verified保持false。Android以官方JAR签名后处理新副本，未向Gradle写密码配置。
- [本人key交互步骤](../evidence/beta-readiness/BR04/owner-key-steps.md)、[本机工具链事实](../evidence/beta-readiness/BR04/java-toolchain.json)。只准备，不代执行新key。
- [Pages方案与公开差异](../../support/README-pages.md)、[3文件/hash/ZIP](../evidence/beta-readiness/BR04/public-site-package.json)。可部署根docs/support/pages-site/；本地ZIP build/beta-owner-assisted/BR04/support-site-draft.zip只含网页，不含源码/SDK/config/日志/密钥。
- [双平台字段/技术依据](../evidence/beta-readiness/BR04/store-fields.md)、[远端验证路线](../evidence/beta-readiness/BR04/remote-device-route.md)、[本人手机最小试玩/反馈](../evidence/beta-readiness/BR04/device-feedback.md)、[最小持有人事项](../dependencies/beta-readiness-user-actions.md)。

## 实际执行证据

根目录`.venv/bin/python -m unittest discover -s tools/validation -v` **46/46通过**：原32保护保留，新增目的地传输/非法输入/覆盖拒绝、候选metadata缺失/unsigned与运输替身signed区分、密码/权限/alias/debug/pin/日期/损坏验证/不可覆盖及payload篡改/实际导出证书pin不符拒绝。外部keytool/jarsigner采用明确命令替身，fixture“not a real key”不是私钥；不会调用genkeypair。日志validation-tests.log。有效RED包括目的地flags缺失/覆盖实际被接受、缺失签名模块、未接CLI参数、密码多行实际越过校验；对应GREEN与补充证据保留。

[真实CLI拒绝](../evidence/beta-readiness/BR04/cli-refusals.json)：不安全URL、部分签名参数、缺失keystore均exit1，未产生候选目录或原生构建。JDK仅运行version/help，只读路径见工具链JSON。没有Flutter/pub/SPM/Xcode构建或设备操作，本批只改构建Python/说明及纯静态网页；不以样例地址编译正式包。纯Dart/Flutter套件、原生签名/平台安装不重复，新增代码只在Python构建边界。

[旧冻结包检查](../evidence/beta-readiness/BR04/frozen-artifacts-check.json)：BR01 final3 IPA/AAB SHA与已验BR03索引一致，旧sources.json未改；当前旧394清单中5个tools/validation文件有预期变更，并新增3个工具/测试源文件。不能继续声称当前源码等于旧394；不改写旧metadata或用旧包冒充含新配置/签名。后续新真实值/key及适用版本准备后在新目录重建，核对新来源/锁/包/符号/签名及平台记录。

## 当前结论与裁定

本批可独立工程/可审资料已完成；不是TestFlight/Play closed已就绪或已分发。当前限制来自真实网页/邮箱/签名资产、持有人法律/权属/受众地区、具体生产运行与分发决定，不能靠再做旧QA关闭。USB直连从上传前一律门槛移除，分发后手机真实体验风险保留。F9及窗口、普通/旧QA库完全未操作，没有任何截图/录屏/录音重试或绕过。

执行裁定：复用现有wrapper/ServiceConfig而不新增SDK或秘密管理服务，代价是本机文件权限和外部Java版本需满足文档契约；签名先preflight再本地新副本，真实资产缺失即失败，代价是当前只能给运输替身证据；网站只允许3公开文件，未知政策事实保留DRAFT，代价是尚不能作为正式政策URL；根据远端约束把设备验收放到获准分发后，代价是提交前带有明确未测风险而非假通过。历史T/FB/MS及既有BR01验收按原范围继承，不改动未验motion/后台emulator日志或tracking。独立验收和精准提交/新CI由架构处理。


一次fresh作者终审完成：Critical0/Important0/Minor0，独立Python46项与scope whitespace通过。完整裁定及代价见[终审记录](../evidence/beta-readiness/BR04/author-final-review.md)；无修复pass/复审。作者收尾检查与CLI RELEASED在审查后追加，架构独立验收尚待进行。
