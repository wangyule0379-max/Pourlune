# Pourlune 项目协作约定

适用于本目录及其子目录。用户当前明确指令优先于本文；不要把本文变成重复询问许可的理由。常规、可逆且已获授权的实现和修复应直接推进。

## 项目基线

- 海外 iOS / Android 单机解谜游戏；Flutter、纯 Dart 游戏核心、SQLite / sqflite。
- 分层静态美术＋局部 CustomPainter 动画；提示在可取消、有时限的 isolate 中求解。
- Firebase Crashlytics、Analytics、Remote Config；AdMob；静态支持网站和反馈邮箱。
- 首版题库内置，本地存档，离线核心玩法。不增加账号、云同步、业务服务器、商城、订阅、排行榜或新货币。
- 原始 UI 已存在，复用既定视觉。不得因为附件不易读取就推断 UI 未设计，或重新生成整套页面。

## 开始任务时读取

按任务范围阅读相关章节，不必每次重读所有资料：

1. [产品规格补充稿](docs/pmpowers/specs/PRD-supplement-v1.1.md)：产品行为和对旧规则的修正。
2. [首版技术方案](docs/pmpowers/specs/technical-architecture-v1.0.md)：技术边界和数据一致性。
3. [验收与内容交付清单](docs/pmpowers/specs/acceptance-and-content-readiness.md)：AC 编号、内容门槛。
4. [UI 原稿审查](docs/design/review/original-design-review.md) 和 [UI 交付约定](docs/pmpowers/specs/UI-design-handoff-and-review.md)：D01–D09 增量范围。
5. [开发准备清单](docs/pmpowers/specs/development-readiness.md)：阶段依赖和未决事项。
6. [数据与状态契约](docs/pmpowers/specs/data-contracts-v1.0.md)：题库格式、索引方向、实例与奖励数据边界；适用于内容和核心逻辑任务。

原始包位于 `docs/design/original/Pourlune_Design_Pack/`，保持原件不改动。原始包作为视觉和历史来源；已明确修正的产品规则以补充稿为准，技术选择以技术方案为准。文档之间出现影响玩家行为的真实冲突时，定位冲突并解决，不自行把待定建议当成确认要求。

UI 增量目录 `docs/design/ui-addendum/` 中的原型、截图和自查仅是交付证据；通过状态以独立验收报告为准。静态 UI 验收不能替代 Flutter、SDK 或真机验收。

## 实现约定

- 游戏核心不依赖 Flutter、数据库、广告 SDK 或网络；界面不直接发奖或写通关记录。
- 固定目标标签参与胜利判断；目标瓶满且匹配标签、所有缓冲瓶为空才胜利。标签不限制临时接收其他颜色。
- 一次动作提交一次完整状态；动画不承担业务提交。异步提示结果必须核对实例和棋盘修订，丢弃过期结果。
- 存档按动作保存，通关相关记录原子提交；保存失败不得假称成功或继续需要成功落盘的导航。
- 奖励绑定原实例并去重；关闭广告不等于获奖。不得承诺恢复从未收到且未落盘的奖励确认。
- 题目使用稳定 ID 和版本，活动实例保存原题定义。升级迁移不能默认清空存档。
- 保留免费提示、撤销、重开与离线玩法；联网服务失败不得阻塞核心流程。
- 使用真实文字、按钮、语义及点击区域；不要用整屏图片冒充可交互页面。正式资源需明确图层、尺寸和使用权。
- 保持结构适合首版，不为假设中的云端扩展提前建设框架。新增依赖须有具体用途，避免重复状态管理和抽象层。
- 工程建立后固定 Flutter / Dart 与依赖版本，提交应用的锁文件。最低系统版本由依赖兼容性和目标设备验证决定。

## 工作与文件边界

- 修改前查看当前文件与已有变更，不覆盖其他任务的交付；并行任务避免编辑同一文件。
- 原件、产品规格、增量 UI、正式客户端资源分别保留明确用途。原型素材不能未经检查直接标为生产素材。
- 任务只授权 UI 时，不扩大为完整 App 开发；需要另一个聊天执行时遵循用户已有授权，不擅自创建或派发无关聊天。
- 常规代码变更同步更新相关说明；产品行为变化需要明确记录，不能通过实现悄悄改规则。
- 私钥、签名凭据、服务账号和访问令牌不进入仓库或日志。区分客户端公开配置与服务端秘密；开发使用测试广告。
- SDK 版本、平台能力和发布政策在实际接入时查官方资料；文档中不写未经测量的性能结果。

## 验证与交付

Flutter 应用位于 `app/`；纯 Dart 核心位于 `packages/pourlune_core/`。工具链固定 Flutter 3.47.2 / Dart 3.13.2（根目录 `.flutter-version`）；应用与核心的 `pubspec.lock` 均须保留。工程和运行说明见 `app/README.md`。B03 默认读取 `app/assets/puzzles/` 的60主线＋30每日候选及 `app/assets/catalog/daily.json`，并使用独立运行美术层、Nunito与本地音频。候选资源不等于独立视觉或商业权属通过。B02 调试场景的别名和测试时钟仍仅用于隔离库；release入口忽略这些场景。

目前已有独立 Git 仓库，origin 为 `https://github.com/wangyule0379-max/Pourlune.git`，主分支 `main`；Python 内容准备工具已建立。在项目根目录使用 Python 3.11+ 的 .venv，依赖固定在 `tools/content/requirements.txt`；命令为 `.venv/bin/python -m unittest discover -s tools/content -v` 和 `.venv/bin/python tools/content/validate.py docs/content/fixtures/*.json`。`--release --catalog ...` 用于正式内容完整性检查；当前工程夹具不能通过发布门槛。具体用法见 `tools/content/README.md`。这些检查不等于 Dart / Flutter 测试。

正式资源和账号交接见 `docs/pmpowers/specs/production-handoff.md`。`docs/design/production-candidates/` 仅是待接入验证的资源；不要把候选状态改成视觉/运行通过。早期工具链现状见 `docs/pmpowers/specs/toolchain-check-2026-10-21.md`：CocoaPods 已安装，Android doctor 的旧输出解析仍有兼容警告，须以实际构建进一步核验。

在 `packages/pourlune_core/` 运行 `dart pub get --enforce-lockfile`、`dart format --output=none --set-exit-if-changed .`、`dart analyze`、`dart test`。在 `app/` 先运行 `flutter pub get --enforce-lockfile`，再运行与改动相关的检查。应用基础命令为 `dart format --output=none --set-exit-if-changed lib test integration_test`（避开iOS构建生成的SourcePackages依赖副本）、`flutter analyze`、`flutter test`；明确工作目录和测试范围。平台构建、集成测试、真机或性能检查按改动风险增加，不把所有平台全量测试套在每次小修改上。

平台命令（工作目录 `app/`）：`flutter build apk --debug`、`flutter build ios --simulator --debug`；真实插件集成命令见 `app/README.md`。临时身份为 iOS `dev.pourlune.pourluneDev`、Android `dev.pourlune.pourlune_dev`；正式签名未建立。CI 配置位于 `.github/workflows/flutter.yml`，配置存在不等于远端运行通过。B01/B02 执行证据见 `docs/development/deliveries/B01.md`、`B02.md`，独立验收由验收方记录。B02 真实插件集成使用 `flutter test integration_test/offline_flows_test.dart -d <device-id> --dart-define=POURLUNE_SCENARIO=flow --dart-define=POURLUNE_DATABASE=b02_native_flow.sqlite`；测试会清理自己的命名库。`milestone`/`final` 场景及普通 App 冷启动方法见 app/README，不能把测试运行器重装当进程恢复。SQLite 当前 schema5、快照 schema2，必须保留非空 B01 迁移测试。

规则、参考解、撤销、事务、奖励幂等、迁移及异步过期结果必须有有效的自动验证；UI 则检查实际渲染、操作路径与适用设备条件。沿用 AC 编号记录证据，避免只镜像实现细节的测试。

交付说明包含：改了什么、对应要求、实际运行的检查及结果、未验证范围。明确区分“文档确认”“静态设计通过”“运行测试通过”。未完成项保留真实状态，不以占位内容、模拟 SDK 或自查截图冒充正式通过。

工程路径、构建命令和 CI 建立后更新本文，使约定与实际项目保持一致。

Firebase 分环境接入：根目录用 `.venv/bin/python tools/validation/firebase_config.py --environment dev|prod --platform ios|android --config-dir app/config/firebase` 校验本地忽略配置；使用 `firebase_build.py` 按次选择构建，完整命令见 `tools/validation/README.md`。默认 none 无配置离线构建；native-ready 单独开启、平台/项目/实际 ID 错配必须拒绝。正式双端 ID 为 com.pourlune.app，开发身份不变，B05 QA 不使用 dev 配置。dev/prod 项目独立，生产本批仅编译、不运行或上传符号/测试数据；符号上传仅显式 dev iOS。真实运行使用 Pourlune 专用设备及 firebase_dev_native.sqlite，正常 main/Bootstrap 不引用测试入口。Flutter CLI 与原生构建串行、保持无AdID环境；证据与未验证范围见 `docs/development/deliveries/firebase-integration.md`，执行报告不等于架构独立通过。

B03资源与表现检查：候选题库须运行上述Python严格release＋catalog90检查与核心production_content_test；图像在根目录用带Pillow的Python运行 `tools/assets/visual_manifest.py --check`、`-m unittest discover -s tools/assets -v`，音频用 `.venv/bin/python tools/assets/audio_generate.py --check` 和 `audio_verify.py`。显式资源变更才可用visual_manifest `--write`刷新，不能用刷新掩盖漂移。B03原生无种子集成：`flutter test integration_test/b03_runtime_test.dart -d <id> --dart-define=POURLUNE_DATABASE=b03_runtime.sqlite`；仅清理该命名测试库。原生音频与校准命令分别为 `b03_audio_native_test.dart`、`b03_visual_calibration_test.dart`。运行器可能卸载测试App，截图须在结束前复制沙盒；它不构成进程恢复。最终证据／已知轻微待办／外部未验证范围见 `docs/development/deliveries/B03.md`，独立验收仍由架构方确认。

B03-R01/R02修复：UI新增10图有独立命名空间与校验，根目录同时执行 `tools/assets/visual_manifest.py --check` 和 `tools/assets/ui_manifest.py --check`（带Pillow的Python），再运行assets单元检查。UI人工显示几何在 `knit_components.dart`，明确改变时才可刷新UI清单。原生配对命令为 `flutter test integration_test/b03_r01_design_test.dart -d <id> --dart-define=POURLUNE_DATABASE=b03_r01_runtime.sqlite`，只清理该命名测试库；七瓶为明确的核心权益QA状态，不是广告发奖或题库main021定义。成功音效必须等待本实例成功回执并通过前台／页面／动画／去重门控。最新执行边界、轻微待办见 `docs/development/evidence/B03-R01/repair-report.md`，整体通过仍由独立验收决定。

B04 可选服务位于 `app/lib/services/`，控制器串行处理奖励确认与动作写入；SDK确认必须绑定展示前已保存的原实例，关闭不是发奖。原生采集默认关闭，UMP广告资格与Analytics/Crashlytics选择独立；无Firebase真实配置为disabled。调试仅使用官方测试广告，release默认关闭广告，配置步骤和原生测试命令见 `app/README.md`。schema3→4→5须保留非空迁移及reward/fullscreen事务故障测试。新增UI不得用替身回调冒充SDK获奖；真实收件、正式域名/邮箱/身份和商业权属见 `docs/development/dependencies/B04-external-handoff.md`。构建iOS时设置 `FIREBASE_ANALYTICS_WITHOUT_ADID=1` 以选择无AdID Analytics SPM依赖，并保留Package.resolved。

B04-R01/R02：广告2分钟只限预展示确认等待；shown后等待SDK真实关闭／失败，不以后台或elapsed时间销毁回调路由／推进Next。schema5在SDK show前用fullscreen_attempts持久化资格序号边界，实际展示记录只消费该边界，晚重试不能清后续首通；Next检查需刷新持久计数。Reset不回拨资格总序号；旧v4无边界intent不得当成展示证明，重启仍保守180秒。修复报告 `docs/development/evidence/B04-R01-R02/repair-report.md`。聚焦原生 `flutter test integration_test/b04_repairs_native_test.dart -d <id>` 只清理b04_repairs_migration.sqlite和b04_repairs_flow.sqlite，实际sqflite/Flutter＋受控广告运输，不能当真实广告成功。

B05 候选验证：执行证据/AC矩阵见 `docs/development/deliveries/B05.md` 与 `docs/development/evidence/B05/`。`flutter build apk --profile` 使用开发debug证书；`flutter build appbundle --release` 当前无正式签名。iOS `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --profile --no-codesign`／`--release --no-codesign` 只证明设备目标编译；同一路径后建覆盖前建，Simulator不支持据此验证profile性能。测试入口 `integration_test/b05_lifecycle_app.dart` 仅为独立QA二进制，主入口不引用；配合 `tools/validation/b05_lifecycle.py` 对显式 `b05_lifecycle.sqlite` 做同安装SIGKILL恢复。B05原生测试通过外部 `XCODE_XCCONFIG_FILE` 固定独立身份 `dev.pourlune.b05Validation`，保护普通App及审查库；用法见 `tools/validation/README.md`。所有会刷新插件SPM生成文件的Flutter CLI与iOS构建应串行执行，并统一上述无AdID环境，不能用并行检查产生的文件改写失败修改SDK源码或版本。


BR01封测历史候选：版本0.5.0+5。正式双端com.pourlune.app/显示名Pourlune仅由显式prod选择，默认none/dev保留原开发身份/Pourlune Dev。可复现工具tools/validation/beta_build.py在新的ignored build子目录冻结源码/资源/候选；默认unsigned，iOS可显式复用已核验既有profile/certificate做手动本地archive/export，不带allowProvisioningUpdates、不生成/重置私钥、不上传商店/符号或运行生产。命令及私密签名边界见tools/validation/README.md；Pythonguard为`.venv/bin/python -m unittest discover -s tools/validation -v`。release使用正常Flutterpub/tooling刷新（先enforce-lockfile，后核对源码/lock不变），不能用--no-pub保留dev integration_test注册器。iOS身份/签名用POURLUNE变量仅在Runner消费，避免覆盖SDK资源bundle的ID/profile。新签名IPA不等于TestFlight就绪，unsigned AAB不等于Play可上传；实际证据、集中持有人门槛与设备/商店未验范围见docs/development/deliveries/beta-readiness-BR01.md。

BR04目的地/Android签名预备：beta_build.py与firebase_build.py可显式接收--support-url/--privacy-url/--feedback-email，缺失保持空；格式完整不代表归属或法律批准。Android仅在用户本人创建并授权已有keystore、alias、私密password file及证书SHA256 pin后，可在新目录对unsigned AAB另生成upload-signed副本；工具不创建/重置key，密码不进argv/日志/manifest。参数/文件权限/真实签名未验范围见tools/validation/README.md。远端Mac不能USB连接用户手机，上传前工程/包核验与授权分发后TestFlight/Play真机验证分开，USB不作为一律上传前门槛，未验仍未验。纯网页可部署根为docs/support/pages-site/，本批仅draft，不创建public repo/部署。持有人交互步骤、远端反馈及交付见docs/development/evidence/beta-readiness/BR04/和deliveries/beta-readiness-BR04.md；生产运行/上传/审核/开轨道/邀请仍待后续具体授权。

BR05新增明确授权已代建Pourlune独立Android upload key，仓库外私密保存并生成同机受限恢复副本；已用android_signing对旧已验unsigned AAB在新android-br05-sign-1目录真实签名，未重编/覆盖。不要再生成/覆盖/重置此key或要求本人重新输入，秘密不进仓库/日志/argv实值/manifest。公开证书/定位及signed候选SHA见docs/development/deliveries/beta-readiness-BR05.md；本机恢复副本不是异机灾备，真实签名不代表网站/声明/分发/手机通过。工具不自动创建key，本次是有范围的一次性授权；生产运行/上传等边界不变。

BR06历史候选0.5.0+6：用户新增授权沿用FishPilot真实主体/邮箱并发布独立GitHub Pages已执行，唯一网页源docs/support/pages-site/，仅3文件公开在wangyule0379-max/pourlune-support；帮助https://wangyule0379-max.github.io/pourlune-support/，隐私privacy.html，支持邮箱wangyule0379@gmail.com。不得再按BR04历史draft限制要求重复批准站点或重建key。既有BR05 key/Apple profile在新build/beta-candidates/0.5.0-6/{android,ios}-br06-1/生成带实际目的地的签名AAB/IPA；来源/版本/资源/签名/符号证据见docs/development/deliveries/beta-readiness-BR06.md及BR06/submission-index.md。旧build5冻结保留。公开站点/本地包检查不等于邮箱收件、生产运行、手机/商店通过；实际上传/Beta审核/开轨道/邀请/代签仍须后续精确授权，F9/采集限制继续保护。

BR08布局后候选0.5.0+7已在新0.5.0-7/{android,ios}-br08-1目录完成签名及包内作者检查，保持ads disabled，待架构实际核包；详docs/development/deliveries/beta-readiness-BR08.md。用户已授权LY通过后TestFlight与Google Play closed，首批仅本人、目标13+；无需重复通用上传许可。新增AdMob联测范围正在衔接：先冻结build7，不将关闭广告的包当广告联测通过或直接替代后续测试广告候选；不代签开户协议、猜支付税务事实或向未标测试设备本人手机投放真实广告。

ADM01新增同批封测测试广告工程：firebase_build.py/beta_build.py显式--ad-mode test，默认disabled；可选--admob-registration使用经控制台回读的公开Pourlune登记，候选先冻结同字节只读副本/hash再委派，不能注入真实收费unit。原生入口核AppID，test绑定平台/实际identity，ServiceConfig只接受准确平台官方sample unit；无登记时owned_registration_verified=false。当前后台apps.admob.com连接失败，真实资源/消息未建；iOS专属dev.pourlune.admobValidation/adm01_native.sqlite真实UMP资格可用但两库存timeout，不能称展示/关闭/获奖通过。Python54、相关Flutter47及双端debug编译检查见docs/development/deliveries/admob-beta-integration.md；新候选仍等独立验收/精确CI/真实配置，build7保持冻结，禁止以测试成功替代商业readiness/手机验收。

ADM01-5工程候选0.5.0+8在新0.5.0-8/{android,ios}-adm01-1目录完成实际签名和作者包检查，source405仅受验18f8c8b+版本7→8，显式test/Google官方sample native AppID与test unit，owned_registration_verified=false；不可标为已申请AdMob或实际展示/关闭/获奖通过。新包验收及精确路径/hash/模式/签名/符号见docs/development/deliveries/admob-test-candidate-build8.md；旧build7冻结，商店/本人手机另验。CLI在交付后明确释放。

2026-10-23当前范围覆盖上述历史分发状态：用户已暂停Google Play/AdMob，ads disabled build9已进入TestFlight本人组；新工作由父完整接手，原开发已释放CLI/文件/专用QA。主线v2的60实际定义已安装，58改题，1/12原字节及每日30/catalog不变；主021由2升3。作者输入/逐关契约在docs/content/design/，复现用tools/content/author_main60_v2.py，旧author_candidates.py仅继续用--check核打包，不用旧schedule覆盖新盘。核心main60_v2_test和历史content_measurement_contract_test、应用main60_upgrade_test分别核规则/提示与旧非空存档。实际画面/首玩难度仍独立未验，不以算法和测试通过批准新TestFlight。父亲自修菜单滚动、设置入页/子页及原稿全页问题；用户F9和禁止重试受限采集的约定保持，明确新授权到达再按范围处理。新包须当前UI实际逐页观察与内容验证通过后精准CI/签名核包；不重复旧终态CI或旧邀请。

2026-10-24用户已明确解除专用QA截图/录屏重试限制，F9及其窗口继续完全保护；不要再把历史采集限制当阻断。正常main实际P01–P21、三专用手机及八代表114次完整UI操作/SQLite回执已观察，独立图审见docs/development/review/actual-ui-independent-20261024.md；真实广告、物理设备和人类首次难度仍未验。实际连续提示发现DFS循环，核心改有界A*（2秒/50000不扩大、固定目标保位、仅无标签缓冲归一、isolate门控不变），188有序盘BFS距离与八代表有/无extra连续通关回归保留。核心38、应用280、工具57通过；最新caption差额/精确CI/签名核包和TestFlight以full-ui-reacceptance实际交付更新为准。下一候选0.5.0+10，旧5–9冻结，不重复邀请唯一测试员，不恢复Play/AdMob。

Build10首次独立核包拦住原生integration_test：固定Flutter3.47.2即便正常release/pub刷新仍主动包含iOS dev插件（上游163874），旧build9也有同样native插件，历史“正常刷新即可排除”判断不成立。手动AppStore archive/export现用ios_release_plugins.py仅在正常生成后临时剔除本App生成注册器和SPM的唯一integration_test，finally恢复，不改SDK/pubspec/locks；未知dev插件/格式拒绝。archive和最终IPA真实Runner都必须无测试类/通道字节；QA构建保留插件。首个build10候选保留且不上传，修复在新目录重建、精准CI与独立核包后再更新TestFlight。

2026-10-24最终ads-disabled 0.5.0+10已更新TestFlight本人组：源05220d7/CI40053916204成功，候选ios-ui-content-3与Organizer实际上传变体独立通过；原538文件冻结不变。构建10在原Pourlune Beta内部组显示正在测试/90天后过期，仍1测试员、不重邀；详deliveries/ads-disabled-build10-submission.md与evidence/beta-build10/final/。首10未上传阻断记录保留。普通QA仍保留integration_test，纯净guard仅手动signed IPA分发，unsigned仍compile-only。F9未动，Play/AdMob暂停，真机升级/音触觉/人类首次难度仍未验；不要重复上传10、重跑其终态CI或重发邀请。

2026-10-28当前发行覆盖历史状态：0.5.0(17)已更新原Pourlune Self内部组，既有2名测试员、正在测试/90天，Apple build33420d37-55f2-4a7f-bfd3-fc8cb2f6108c。精确源5fb8b79a8f228a0ece125fba7aa8bb91e2d48b3a（codex/testflight17-fixes，f47610b非GM基线）/CI40631141257两job成功；工具68/core47/app446+1个opt-in夹具跳过，总控实际修复/广告路径、签名包54项、Organizer变体22项及平台三图均接受。F15反馈失败提示与通用隐私旧回执竞态已修，保留21–60题/音频中断/有效隐私清单；GM测试分支和私有SDK原样保留，不在此发行。仍官方测试广告、NoAdID、采集默认off；本机googleads.g.doubleclick-cn.net的REJECT仅按已批范围临时验证后恢复，不永久改代理/TLS/DNS，新请求仍可能受原环境拦截。详docs/development/deliveries/testflight17-functional-fixes.md。禁止重复上传17/旧终态CI/邀请。实际电脑交由既有Pourlune ｜ Use Computer聊天01a17b8e-aee4-7322-ae34-7b8d1531cae4（local），F9及原设备/库保持保护；物理手机升级、音触觉、Android人工广告和真人首玩难度仍未验。


2026-10-28最新发行覆盖17：GameMunchies统计/远程广告控制与隐私提示修复已由总控实际验收，0.5.0(18)已更新原Pourlune Self内部组，仍2人、正在测试/90天；ASC6956eb73-ec07-4ff7-a449-76867836c112。签名源ea2bdee853559ddaa66e44e35fce7bac34a40d29，最终CI a8e6be9323d97855de25bcfbcabc0e88337cf415/run40653590242双job成功（工具84/core47/app477+1 opt-in夹具跳过）。554来源唯一CI顺序差额已独立核，实际App/SDK/锁/构建工具不变，复用原567文件冻结包；成功Organizer IPA6e39f3ad4073d70cb0c3f076e03655125d01a4cfffa378185b2ab456df51c034/86731625B独立核仅签名差额。客户端https://api.gamemunchies.com，正式8feaf0dc-ec12-4308-ac58-16b2180f2d63/production/com.pourlune.app，正常main、prod Firebase/NoAdID/官方测试广告/采集默认off。SDK92f5882固定受限归档已获本人仅供Actions构建及继续发布的具体授权，不重复问；不得读取/回显密钥值或公开SDK源码，配置AX意外工具回显事件只按既有报告留真记录，不假称删除历史。真实激励/同实例奖励/后台展示+1、v2/v3/v4控制及双端SDK补传去重通过；Android混合重试2原+1新仅accepted1/3，不能写纯0/3。首次Apple TLS/checksum会话已取消，同18新官方会话成功，无App/网络/TLS改动。详docs/development/deliveries/gamemunchies-live-integration.md及独立release-final。禁止重传18/重跑终态CI/重邀；原17及全部冻结候选保留。F9及原设备/库不动；物理手机升级/首笔正式数据、硬件音触觉、Android人工广告、真人首玩与商业广告仍未验，Play/AdMob商业接入暂停不变。

2026-10-29当前进展覆盖18历史状态：iOS0.5.0(19)已在原Self组2人分发并正式送审，详ios-production19-submission.md；本轮不改iOS19/不重复隐私发布、上传或邀请。SDK0.2.0固定私有源6dac3537/V2归档沿用已授权7文件，不公开源码或重复询权。Android原13及未上传候选19-2的R8移除了Room2.2.5/WorkManager2.7反射无参构造器，原13实际在Flutter前崩溃；不要把此前debug或静态通过当release运行通过。修复仅app/android/app/proguard-rules.pro三个反射入口，Flutter固定版本自动读取；CI新增minified AAB和tools/validation/android_release_startup.py实际DEX守卫，不关R8、不升依赖。修复源de5a595/精确CI40837181164双job成功（工具87/core47/app492+1 opt-in跳过），候选android-alpha-gm020-3的9文件冻结包SHA bcfa0483c086c71161653829067d12e42ee30f275dcc4699bd7c2ca0ee19c06d/136310168B已独立接受；三ABI Dart AOT/manifest/native/assets与19-2相同，仅DEX及R8元数据差额。真实5554 minified启动/普通动作/仅App Force stop重开及当前PID13997可见无原Fatal已过总控，旧13非空现场升级仍未验；原13精确源合成SQLite动作/重开/保存再打开自动验证通过，额外夹具GUI只到Continue4，不能冒称原发行升级。既有R2真实奖励、statsOff无POST/正冷却重启、正常main及后台证据已独立通过，不重复测试/采样/终态CI。

Android19现已上传原Alpha并被Play识别、版本号已占用；最终更改仅Alpha19、Contains ads、Data safety，100%封测预览保存并点击确认送审，当前快速检查中且尚未取得实际送审回执，不称审核通过或19可安装。禁止重复上传19/反复点击提交，沿用Computer当前页面等待并回读；具体新终态以google-play-latest-20261029.md及evidence/google-play-latest-20261029/play-upload-and-review-request.json为准。AAID两权限均排除，其他ID仍披露；Data safety须分收集/分享用途，位置及ID的应用功能仅收集页，广告四类分享为分析/广告/反欺诈安全合规，可选Crash收集仅分析不分享。UMP无表单及code3无填充、未见商店关联仍是后台/商业待办，保持SDK canRequestAds门控和统计默认Off，不绕过许可、不以测试成功证明商业填充。实际桌面只交既有Use Computer聊天，不动F9、保护库/其他设备、iOS或公开production；物理手机/硬件音触觉/真人首玩保持未验。
