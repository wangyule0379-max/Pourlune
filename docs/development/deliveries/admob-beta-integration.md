# ADM01 AdMob 同批封测接入检查点

2026-10-23，**工程增量及一次终审修复已完成，最终Python54/54通过；真实账号登记与广告闭环尚未通过，待架构独立验收。CLI RELEASED：全部Flutter/pub/SPM/Xcode及检查命令已结束，无在途平台命令，架构可开始聚焦复验。**按已授权计划执行，复用B04既有激励/插屏/UMP/控制器，不增加广告位置或依赖。BR08 build7继续冻结为已验ads-disabled基线；未重签、未生成下一候选、未上传或开商店测试轨道。

## 已实现

- `firebase_build.py`、`beta_build.py`增加显式 `--ad-mode test`；默认release与默认wrapper仍disabled，prod仍只编译正常main，不运行生产/上传符号。test模式只使用平台准确的Google官方插屏/激励unit，远端本人手机无需先提供广告设备ID，不能请求自有收费unit。
- `admob_config.py`区分native App ID与test unit；无真实登记文件时只用Google平台sample App ID，metadata `owned_registration_verified=false`。可用公开 `--admob-registration`选择控制台已核对的Pourlune双端App ID，匹配platform与com.pourlune.app，保持unit官方测试。当前没有真实App ID/publisher/unit登记回执，不能称已完成商业AdMob申请。
- wrapper同时固定Dart defines、iOS临时xcconfig及Android Gradle属性；两原生入口核对native AppID，显式test模式再校验Dart平台/实际identity，test错配、重复定义、手工注入unit或production模式拒绝。iOS广告校验在Firebase资源落盘前执行，错误不能改旧资源。默认无显式选择的debug仍官方sample，`ServiceConfig.adsConfigured`收紧为准确平台/格式，拒绝跨平台或伪造sample unit。
- 锁文件、SDK版本、游戏规则/奖励/存储事务均未修改。Analytics/Crash选择独立默认off，现有UMP资格与隐私选项、非个性化请求保持；未推断13+都成年或填地区/年龄认证。具体受众保护/控制台消息/适用声明仍按真实账号和本人事实核对。

## 实际检查与结果

证据根目录 `docs/development/evidence/admob-beta-integration/`，源码范围见 `source-checkpoint.json`。

|实际执行|结果|边界|
|---|---|---|
|根目录 `.venv/bin/python -m unittest discover -s tools/validation -v`|最终54/54 exit0（终审前51，新增3项回归）|synthetic配置/构建边界，不是实际签名或商业账号|
|app/ `flutter pub get --enforce-lockfile`|exit0，lock/SPM无差额|没有升级SDK|
|app/ 相关9个Flutter测试文件|47/47 exit0|覆盖新test模式，既有UMP阻止初始化、奖励幂等、shown后路由、保存故障/Next；受控运输不冒充真实广告|
|app/ 3个改动Dart文件format检查、flutter analyze|格式无差额，analyze无问题 exit0|不重跑已验LY/FB全量原生流程|
|根目录firebase_build.py none/android/ad-mode=test → build apk --debug|exit0，实际Gradle原生检查通过；APK manifest sample AppID准确|未安装Android App；开发debug包不是封测签名候选|
|app/ 专属iOS真实插件probe|构建与测试exit0；真实UMP allowed=true、failed=false、privacy options required=true|插屏和激励库存均unavailable/timeout，**真实展示、关闭、SDK获奖回调未验**|
|iOS probe 同期实际sqflite保存|合法动作后revision从库读回一致；Firebase disabled、Analytics/Crash默认off|只删自己的adm01_native.sqlite，未伪造同意/奖励；不是进程恢复测试|
|原生产物静态回读|iOS实际dev.pourlune.admobValidation、sample AppID、无Firebase plist、原生采集默认off；Android sample AppID与构建选择匹配|见native-artifact-checks.json，不是正式包核验|

Flutter精确聚焦命令（app/，统一FIREBASE_ANALYTICS_WITHOUT_ADID=1）：
`flutter test test/admob_test_mode_test.dart test/b04_services_test.dart test/b04_ads_test.dart test/b04_controller_ads_test.dart test/b04_sdk_lifecycle_test.dart test/b04_reward_store_test.dart test/b04_review_regressions_test.dart test/b04_continuation_window_test.dart test/b04_r03_controller_test.dart`。

iOS仅使用允许的255890D5-B4A3-42F9-B1A2-409E77118348、外部ignored QA xcconfig固定dev.pourlune.admobValidation、Firebase none、adm01_native.sqlite和准确sample AppID/test defines。新probe无图片/录屏/音频采集，也不自动弹无法安全关闭的全屏广告。未操作F9设备/窗口、普通App、FirebaseQA库或旧b04_review库。测试exit0只证明真实资格观察与离线保存；`ios-native-probe.json`显式actual_sdk_display_close_reward_pass=false。

TDD证据：wrapper缺test参数、beta未转发test参数、iOS错AppID仍覆盖资源、Dart跨平台sample被接受分别先RED再GREEN，日志保留。首轮测试插入位置导致旧invalid-email循环错位已纠正，首次Dart测试创建多写app/前缀导致文件未载入已纠正；这些操作失误不作为有效产品RED。初次analyze的QA if括号info修正后复跑无问题。

## 账号、资料与真正未完成项

AdMob官方首页可访问，但其Sign in实际目的地 `https://apps.admob.com/` 首次和一次普通刷新均 `ERR_CONNECTION_CLOSED`；独立无凭据HEAD诊断也SSL_ERROR_SYSCALL/exit35。没有账号页面，所以账号是否已开通、publisher、Pourlune应用/units/隐私消息均**未知**，不能声称账号不存在或重复注册。未改代理/TLS/安全策略，不会无网络变化反复重试。证据account-check.json与console-network-head.log。尚未到必须由本人接受条款/填写国家时区币种/税务付款的页面，暂不要求用户凭空填写。

唯一网站源 `docs/support/pages-site/` 已准备按build7关闭广告与新test builds分别披露GMA/UMP处理、test不等零数据、非个性化不匿名及独立选择；本地HTML结构/链接/无新增采集元素检查通过。经fresh作者审查，独立站两HTML已提交推送baf00f20859f9ce84576a474e9e2a1ed326055ff；帮助/隐私实际HTTPS均200并与唯一源逐字节一致，见site-http-check.json及site-deployment.json。GitHub按commit查询未返回workflow run，本报告不编造run通过；实际公开正文更新已核实。`disclosure-matrix.md`列出新test模式Contains ads=Yes建议及Apple/Play数据类型/用途变化，具体平台表单和供应商配置未代填或作法律声明。

app-ads.txt需要真实publisher ID及商店Developer Website域根；现有GitHub Pages项目子路径不自动等于根。没有复制FishPilot字段或悄改主域站点。真实受众/测试地区、适用未成年保护/UMP消息及法律声明仍需真实控制台/本人信息；目标13+不是平台评级，也不是成年认证。未接受协议、购买、扩IAM或邀请他人。

## 下一步和交接

账号连接恢复后复用已有账号、先查重，再按授权登记Pourlune双端未发布App和既有激励/插屏位、关闭可选user metrics，核实真实ID与适用消息；工程不因账号缺口停在口头方案。真实SDK库存/展示/关闭/获奖仍需在合法资格下验证，不能用单测或probe退出0补成通过。

当前独立验收/新精确CI/下一新签名候选/实际商店提交均未完成。待架构接受本工程增量并精准提交推送通过CI后，再核对下一未占用build号，在新目录复用既有Apple profile和BR05 key生成test-mode候选，直接核其native AppID、test unit/启动参数、来源/锁/资源/签名/符号。用户既有TestFlight与Google Play closed授权仍有效，首批仅本人；不要求USB。新包父验收后继续分发，手机实际结果保留未验。

本批主仓未stage/commit/push，tracking/plans/review归架构；旧motion日志和icon-selection不夹带。**CLI RELEASED**：所有Flutter/pub/SPM/原生CLI及检查已结束，无在途命令，架构可立即聚焦复验；账号/SDK外部未完成项不伪装整体通过。

fresh作者审查Critical0/Important1/Minor1。Important登记读取时序问题已在同一轮修复：同一份bytes解析/hash，候选output内冻结只读副本并委派/事后校验，副本计入产物hash，iOS实际AppID再核对。三类回归先RED再GREEN，完整Python54/54 exit0，详author-checkpoint-review.md及python-guards-after-review.log。不再派第二轮作者审查，待父独立验收。Minor暂留disabled模式对部分显式Dart身份字段不检查（仍校验native sample AppID；默认wrapper发一致值且disabled无广告请求）；已收窄交付表述，不将轻微项扩入fix pass。

2026-10-23续查补充：已通过实际本机规则及按目标过滤的实时日志确认，AdMob后台和Google广告主请求域都被Clash广告规则reject→REJECT拦截；不是仅凭TLS报错推断账号或库存。普通Google服务HTTPS对照正常。私密备份及精确3条临时例外已准备，尚未改网络；一次具体确认待回复。新诊断证据见network-diagnosis/diagnosis.md和root-cause-and-proposal.json。原405工程来源未变，架构当前接管聚焦CLI窗口，本方不重跑平台检查。此结论不补齐尚无的真实SDK展示/关闭/获奖证明。
