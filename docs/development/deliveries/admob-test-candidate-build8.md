# ADM01 build8 测试广告签名候选

2026-10-23，双端本地签名与包内作者检查通过，**待架构直接核验这两个实际新包**。本批未运行生产App、上传符号或商店、创建商店记录/邀请、改变网络规则。实际AdMob登记和SDK展示/关闭/获奖仍未完成，不能把本候选当商业ready。

## 来源与版本

受验工程 `18f8c8b0fdf94acb9bb8ffcc71193723ce805a58`，精确CI [39938640955](https://github.com/wangyule0379-max/Pourlune/actions/runs/39938640955)于2026-10-23T10:33:11Z completed/success，两个job均success；直接读取已存父独立终态证据，没有重复查询旧CI。构建时HEAD `5239511e919991c87acea4bd37c98d4f148334b5`相比受验commit仅文档差额，405运行来源逐项匹配Git接受版本；本批仅 `app/pubspec.yaml` 从0.5.0+7改为0.5.0+8。

版本选择前：认证ASC Apps搜索Pourlune无结果；Play原应用表只有其他两个App，搜索Pourlune后无匹配行。Play同时显示generic unexpected-error提示，因此证据仅限可见记录，不作全局唯一保证；实际上传前再核。新ignored目录 `build/beta-candidates/0.5.0-8/{android,ios}-adm01-1/`，旧build7三个IPA/unsigned/signed AAB hash重新核对不变。

## 实际产物

|平台|项目根相对路径|字节|SHA256|
|---|---|---:|---|
|iOS|build/beta-candidates/0.5.0-8/ios-adm01-1/Pourlune-0.5.0-8.ipa|59266547|e79ed16b612b1f8ad845281d9baa966f32038411473820e107ccf710fcacd364|
|Android|build/beta-candidates/0.5.0-8/android-adm01-1/Pourlune-0.5.0-8-upload-signed.aab|106239585|4c81599e49a252f52b2ae84442c1d149e0e593e09a1c9cd9664ea89b42169b7f|

Android unsigned同目录 `app-release-unsigned.aab` SHA256 `d70842c30d390ee71c3e4ff0fc4bb40301d0e802e08ca2604e5b518977085fd6`。既有Apple profile/证书与BR05 upload key复用，未创建/重置私钥或读取回显口令。

## 配置与本次实际检查

统一 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`，既有beta_build.py串行Android结束后iOS，两次exit0。显式 `--ad-mode test`，prod compile-only/正常lib/main.dart/release，正式身份com.pourlune.app/Pourlune；公开帮助/隐私URL与邮箱沿用已验值，Analytics/Crash独立默认off，无生产运行/测试事件/符号上传。默认release行为仍disabled，本批没有改该默认。

**没有真实AdMob登记文件。** 两候选 `ad_configuration.app_id_source=official_sample`、`owned_registration_verified=false`；AppID和unit分别记录，不把Google样例当Pourlune账号登记。

|平台|包内实际native sample App ID|AOT实际官方interstitial / rewarded test unit|
|---|---|---|
|iOS|ca-app-pub-3940256099942544~1458002511|ca-app-pub-3940256099942544/4411468910 / ca-app-pub-3940256099942544/1712485313|
|Android|ca-app-pub-3940256099942544~3347511713|ca-app-pub-3940256099942544/1033173712 / ca-app-pub-3940256099942544/5224354917|

证据目录 `docs/development/evidence/admob-beta-integration/candidate-build8/`：

- `source-baseline.json`、两候选sources.json：同405来源，manifest SHA256 `46bfe52fd544e5aad03dfe3571883b50d9dd01d661495b4c913ebbc14c029114`，相对受验工程仅pubspec7→8；两个pubspec.lock与两个Package.resolved不变。冻结时逐文件比对工作区，未修改SDK、玩法或奖励事务。
- 根目录 `.venv/bin/python docs/development/evidence/admob-beta-integration/candidate-build8/verify-packages.py` **exit0**；`package-verification.log/package-checks.json`记录本次实际检查。iOS候选清单533文件、Android3文件hash均匹配；每端136运行资源含90题逐字节与源码相同；iOS与Android3个ABI的AOT都含正确test units及三个公开目的地，QA专用Dart标记不存在。
- iOS actual Info.plist：com.pourlune.app/Pourlune/0.5.0/8、最低15.0、iPhone+iPad、SDK iphoneos26.5；GADApplicationIdentifier为表中sample；Analytics/Crash原生默认false。deep/strict codesign exit0，Team T7U878Z8H6，profile74a202b2-3b25-4e31-8fd4-0413bf15d486，证书SHA1 13362E4AF31A860FA6B705DB5192AF78613F7A58，expiry2027-09-16T15:29:23Z；actual entitlements identifier/team正确、get-task-allow=false/beta-reports-active=true。24份SDK隐私清单，5个dSYM条目/4模块UUID与实际导出二进制匹配。
- `archive-mode-proof.json`从本次实际iOS归档日志核对编码后的Dart选择：AD_MODE=test、AD_PLATFORM=ios、AD_NATIVE_ID=com.pourlune.app、sample AppID、FIREBASE_ENV=prod/native-ready=true，同时normalmain及noAdID环境记录存在。未把候选JSON单独当运行模式证明。iOS native IntegrationTestPlugin类符号在旧build7也存在，不能用类名本身判定Dart QA入口；本次正常入口依构建日志、受控工具及QA标记缺失核对。
- Android实际AAB bundletool validate/manifest/config均exit0，com.pourlune.app/version0.5.0/code8/min24/target36；actual manifest native sample AppID、原生采集false及10项权限保存。AOT三ABI test units核对、Dex无IntegrationTestPlugin；12 ELF静态PT_LOAD对齐≥16KB。proguard.map＋9份native符号hash记录；不是实际16KB手机通过。
- Android实际证书pin E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2，既有信任项下jarsigner strict exit0；unsigned/signed571项非META payload一致。口令只由既有工具内部通过受限password file使用，不写日志/argv实值/Git。
- 两条`*-build-command.log`确认构建结束；完整原生日志及symbols在各ignored候选目录。保留Android现有Kotlin迁移/SDK解析提示，未为此改版本。无新行为实现，因此不重跑已独立通过的54 Python/47 Flutter、LY/BR08全套；本轮运行的是实际双端构建与新包检查。

## 分发前保留门槛

作者核包不替代父实际包验收。CLI RELEASED：本方所有Flutter/pub/SPM/Xcode/检查命令均结束，无本方在途命令。父可直接读新IPA/AAB及source/锁/资源/模式/AppID/unit/签名/符号后确认；build7验收不能自动覆盖build8。主仓版本/文档由父精准提交推送，本方没有stage/commit/push主仓。

之后沿已授权的TestFlight本人内部及Google Play closed路径，先查重再创建必要记录，真实必填/协议/地区/账号事实按控制台处理，不代签、不猜，不邀请未知人或公开生产。`apple-what-to-test.txt`、`play-release-notes.txt`与submission-state.md仅准备，尚未提交。

AdMob后台与广告请求被本机Clash reject规则拦截，临时三条网络例外尚待本聊天实际确认，未应用。真实publisher/AppID/unit/UMP消息/app-ads.txt登记仍未知；此前iOS资格可用但两类库存timeout，实际加载/展示/关闭/SDK获奖与本人手机行为仍未通过。没有生产App运行、邮箱收件或性能/读屏/声音触觉通过结论。F9与窗口、旧冻结包/原图/普通库/FirebaseQA不操作，受限采集未重试或换路径绕过。
