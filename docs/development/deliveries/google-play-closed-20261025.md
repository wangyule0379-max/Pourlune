# Google Play closed testing — 2026-10-25

状态：Android 0.5.0(13) 的签名包、总控独立审查和精确CI全部通过；已上传并处理成功，替换旧12且不保留旧制品。Google已受理14项封测送审申请，自动快速检查已完成，现明确显示“您的更改目前正在接受审核”。本轮提交完成，外部正式审核待结果，尚未审核通过或开放手机安装。TestFlight 0.5.0(12) 已完成，本轮不重传 iOS。用户已确认美国地区、本人 wangyule0379@gmail.com；不扩大其他测试者、公开生产发行或 AdMob。

## 原12候选与复用基线

- 运行源 `54a7fc148f2762918262146f2f4ac0bd084b5f6e`，0.5.0(12)，`com.pourlune.app`。复用精确源 CI40180964750 成功终态，不重复查询。
- 签名 AAB 及只读同字节审查副本：`build/{beta-candidates,package-review}/0.5.0-12/android-play-closed-1/Pourlune-0.5.0-12-upload-signed.aab`，128135797 bytes，SHA256 `09393032348e4096917e9037c06e51e2c45ac6ef6aae3015fb74f495a9595182`。上传前再次 hash 相同。
- 既有 BR05 upload key，RSA3072；证书 SHA256 `E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2`，strict jarsigner 通过，未创建或重置签名材料。
- 495 个源码文件与运行源相同；父独立核验完整 146 项资源、90 题及 22 主线改题差额。作者子集计数145不代替父完整资源清单。
- minSdk24 / targetSdk36；bundletool validate exit0；PAGE_ALIGNMENT_16K；12 个 native ELF 的 LOAD/RELRO 检查通过，生成 APK 的12个未压缩库 ZIP 16KB 对齐通过。包含 R8 mapping 与9份原生符号。对齐 APK 仅检查，未安装或运行生产 Firebase。
- 独立核包报告：`../review/google-play-closed-package-independent.md`。包内 prod Firebase 仅编译，广告 disabled，正常 main 无 QA 入口；本轮没有生产事件或 Firebase 符号上传。

## 真实 Android 画面

新专用 AVD `Pourlune_Play_Closed_API36` / emulator-5596，Firebase none、广告 disabled、无种子正常 Bootstrap，独立 `play_closed_listing.sqlite`。真实点击完成1–4关并获得第一拼布；1080×1920 原生图覆盖主页、main004、完成及收藏。原始图及最终 `+1 PASS / exit0` 日志保留于 `build/store-submission/0.5.0-12/android-play-closed-1/`。早期失败是采图 harness 的音频/异步 teardown，按既有测试模式收尾后重跑通过，未改产品代码；临时 integration test 已移出源码。

正式交付 `docs/design/store-delivery/google-play-closed-20261025/`：4张真实截图仅去除恒255 alpha，RGB逐像素保持；512图标、1024×500横幅与 BR07 用户选定素材同字节。总控实际逐图验收通过，原始截图和 manifest 保留来源。Console 已标注素材所含既有 AI 美术；截图仍是真实运行截取。QA设备页大小4096，不宣称16KB设备运行通过，也不以该debug/none安装冒充Play签名生产包实机验收。

## 后台资料

- 复用既有 Pourlune、Alpha 轨道及 Play App Signing，无新协议或 key 操作。Google app-signing证书与 upload证书分开记录。
- Alpha 美国唯一定位（Console 自带包含7个附属地区）；Pourlune Beta独立名单只含本人1个邮箱，其他 FishPilot/test 名单不勾选。反馈邮箱沿用公开支持邮箱。
- 隐私URL、无账号/无受限访问、无广告、13+目标人群、非政府/非金融/非健康、Puzzle类别及公开联系方式已保存。IARC在用户明确“已开始”确认后完成；实际仍未勾的同一IARC条款由代理在该确认后勾选，不把它记作用户亲自点了checkbox。评级 ESRB Everyone / PEGI3 / Generic3+ / Taiwan大众级 / USK all；内容评级与13+目标人群不同。
- 英文商品页、4张截图、图标横幅已保存为“可以送审”。实际图序收藏/玩法/完成/主页，均真实。完整说明如实写免费单实例一次加瓶、离线本地存档及可选采集。
- Data Safety：大致位置、设备或其他ID为必需（应用功能/分析）；互动、崩溃、诊断为可选（分析）；均非临时处理，传输加密、无玩家账号。未承诺全量90天删除。总控已核11份后台读回并接受 Not shared 答案，见 `../review/google-play-data-safety-independent.md`；已最终保存并纳入提交编号1。
- prod Firebase/GA 后台只读核查：Signals未启用，Google产品和服务unchecked；Google Ads、AdMob、AdSense、AdManager、DV360、SearchAds360及BigQuery无关联；模型/业务洞见聚合分享、技术支持、业务建议checked；账户DPA未接受，未代签或更改任何设置。原始读回见证据目录。

## 发布前检查的实际处置

`app-store-compliance` guard exit0，critical0/high4/medium4。通用扫描高项逐项定位：example.com仅是ServiceConfig拒绝占位地址的防护；Apple出口摘要不适用于本次Android差额；R8扫描未识别Flutter默认配置但AAB实际mapping/符号已核；Data Safety已按实际SDK和后台配置独立核对、保存并送审。12人连续14天用于后续新个人账号申请生产权限，不能拿它阻止本次本人closed开始，也不据此邀请未授权人员。Apple既有UI/触感/年龄提示不因这次Android差额重开。

当前官方依据：[target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-en)、[16KB](https://developer.android.com/guide/practices/page-sizes)、[Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)、[Firebase披露](https://firebase.google.com/docs/android/play-data-disclosure)、[GMA初始化](https://developers.google.com/admob/android/quick-start)、[closed/生产资格](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)、[素材AI标注](https://support.google.com/googleplay/android-developer/answer/17262077?hl=en)。

## 原12平台检查及修复原因

Data Safety已最终保存，发布概览包含“填写完数据安全调查问卷”。AAB实际处理结果12(0.5.0)/API24+/target36/3ABI，附ReTrace和native符号；版本预览“可以发布了”，新安装估计79.4MB（平台估算），保存后进入发布概览。

发布概览最初额外包含“Google Play游戏电脑版”启用更改，已实际退出PC计划并回读“选择加入计划”，待审项15变14；不扩大本次手机封测。Android XR是原有与移动应用同轨道、同制品、同测试者和地区的默认兼容，不新建XR轨道，未改变设置。

预检发现必填广告ID声明。实际12包保留SDK自动合并的AD_ID权限，但GMA关闭不init，Analytics广告storage/user data/personalization均denied，不能将普通分析等同实际AAID分析，也不能为过表单选营销用途。曾展开Yes检查字段但未保存；改按实际无AAID使用选No并保存，所有用途均未勾选。页面确认“更改已保存”。等完整一轮快速预检结束后，终态仍有唯一“广告ID声明不完整”阻塞，见 `precheck-terminal-ad-id-blocked.txt`；因此执行下述最小去权限修复。

## Android13最小权限修复

- 新精确源 `236cea0479837d415094a784f47b6d3928c3366c`，已push。5个文件差额：main manifest标准 `tools:node="remove"` 移除AD_ID、Analytics `google_analytics_adid_collection_enabled=false`；版本+13；既有admob_config增加实际解码包manifest校验CLI、对应回归及README。没有新增flavor/生成框架，没有动SDK、锁文件、玩法或生产广告分支，既有显式测试广告门控保留。
- 回归先失败（CLI尚无该检查），实现后通过；针对旧12实际AAB的manifest正确拒绝 `disabled_android_ad_id_permission`。完整Python配置守卫64项通过。`flutter pub get --enforce-lockfile`通过，源码/锁未被改写。
- none + test 模式debug真实编译exit0；actual merged manifest仍是dev身份及官方Android sample App ID，AD_ID不存在，Analytics adid显式false；CLI以对应test定义校验通过。这是配置/编译验证，不是真实广告加载/展示/获奖验证。
- 新签名冻结包 `build/package-review/0.5.0-13/android-play-closed-1/Pourlune-0.5.0-13-upload-signed.aab`，128135970 bytes，SHA256 `3383d698ccb51157c2f9c4b9d0b34d4f4897a75dc0b72c24a5e4a469c1d08a95`；与新beta-candidates原件逐字节相同，8文件0444，原12冻结保留。
- actual AAB包名com.pourlune.app、version0.5.0/code13、target36；bundletool validate exit0，实际包manifest的disabled守卫通过：AD_ID false、Analytics adid false。495来源文件匹配新提交；154个flutter_assets条目与12完全同字节，包含已验90题和146项正式资源。12个ELF的16KB LOAD/RELRO检查通过，mapping+9原生符号仍在。
- 新生成universal APK仅用于对齐检查，12/12未压缩native库ZIP 16KB对齐；未安装/运行。原始命令日志和APK保留在13的store-submission目录，机器结果 `android13-apk-alignment.json`。
- 父实际核验新签名包通过，见 `../review/google-play-android13-ad-id-independent.md` 与 `package-independent-android13.json`；含495来源、146资产/90题、签名/代码/权限/SDK默认采集、AOT/DEX无QA入口、12ELF及符号，不重验全页。
- 新精确CI40188631583（head236cea0、push）已completed/success，tests-and-android与ios-build全部步骤成功，`android13-ci-terminal.json`为实际回执；父独立回读也确认成功。终态后不重复查询。

## 实际平台受理

13上传处理成功，平台实际显示13(0.5.0)、API24+/target36、mapping及native符号；版本预览“可以发布了”。新版本明确“不包含”12，覆盖100% **Alpha本人测试组**，不是公开生产发行。美国、Pourlune Beta名单1人、反馈邮箱及既定内容声明保持原配置。

保存13后，发布概览不再出现广告ID问题，“提交14项更改以供审核”可用。代理依既有具体封测授权点击该按钮并确认“将更改内容送审”，实际进入“正在审核中的更改”；此时自动检查约14分钟，文案明确检查成功后立即送审。状态不能混同审核完成或可安装。

回执 `android13-upload-processed.txt`、`android13-release-ready.txt`、`android13-precheck-no-blocker.txt`、`android13-submission-accepted.txt`；受理时截图 `build/store-submission/0.5.0-13/android-play-closed-1/submission-accepted.png`。无需本人登录/新事实。

实际提交活动编号1，Console显示2026-10-25 19:44、审核中，14项变更包含Alpha13/美国/本人名单，见 `android13-submission-activity.txt`、`android13-submission-details.txt`。本人名单再次回读仅Pourlune Beta勾选且1人，其他名单未选；复制加入链接仍disabled，不能提供“可安装”结论。新包后广告ID页面回读仍No且原AD_ID权限冲突提示已消失，`android13-ad-id-no-readback.txt`。文本版bundletool XML只去掉空白行尾，原始输出另保留在对应ignored store-submission目录，包字节与签名不变。

平台13详情另外实核：10项权限列表没有com.google.android.gms.permission.AD_ID；仍有三项AD_SERVICES、FOREGROUND_SERVICE等SDK合并权限，且Play处理增加CHECK_LICENSE，不能描述成“无权限/无SDK”。服务器显示min24/target36、3ABI、支持16KB及R8完整模式，`android13-play-bundle-details.txt`。这是商店处理结果，不替代Play最终APK的本人手机安装/离线验收。轨道列表明确13审核中，12已被另一版本取代，`android13-track-review-pending.txt`。

官方[Mobile apps consent mode](https://support.google.com/tagmanager/answer/13802165?hl=en)说明ad_storage denied不能收集Advertising ID；[Android manifest merger](https://developer.android.com/build/manage-manifests)为标准权限移除机制。包保留其他SDK合并权限不等于自动启用服务，原五类Data Safety及不共享结论不变。

2026-10-25约19:58实际回读：快速检查进度条/倒计时消失，无阻塞，明确“您的更改目前正在接受审核”。终态证据 `android13-formal-review-pending.txt`；最终截图 `build/store-submission/0.5.0-13/android-play-closed-1/formal-review-pending.png`。正式审核是外部等待，不重新提交或伪称通过。当前测试URL `https://play.google.com/apps/testing/com.pourlune.app` 尚未启用，不能当可安装交付；审核通过和本人手机安装/离线验证仍待后续实际状态变化。

F9及其窗口、Small11b/4188、历史Large、普通库、FirebaseQA及旧冻结候选未动；未全量清理。所有原生/Flutter命令串行，CLI现已释放；本轮新AVD经具名核对后仅关闭emulator-5596进程，磁盘及证据保留。本轮改动为商店资料/实际截图、Android权限和版本差额及对应产物守卫；玩法和题库未改。
