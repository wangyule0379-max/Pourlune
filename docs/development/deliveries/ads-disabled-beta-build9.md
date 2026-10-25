# 广告关闭封测候选 build9

2026-10-23。用户最新“先放弃AdMob接入”已落实为本轮停止账号恢复/真实SDK联测，并为既有授权 TestFlight本人＋Play closed 准备新的广告关闭候选。**双端本地构建、签名及作者包检查通过，待架构直接独立核验这两个实际新包；尚未上传、处理或可安装。** build8显式test候选冻结不上传，不复用旧包冒充广告关闭。免费提示、撤销、重开及离线核心规则无变更；未拆除既有可选SDK。

## 来源与精确包

既有受验工程18f8c8b及后续build8来源保留。405运行来源与已验build8逐项比较，唯一差额 `app/pubspec.yaml` **0.5.0+8→0.5.0+9**，其余源码、资源、应用/核心锁和两份SPM锁不变。两端sources.json相同，SHA256 **42fe38405772def0e4c54651bcc20a3b9fa7ce3fa7706cc9c82a193ef74e2356**。构建前既有ASC Pourlune组回读1测试员/0构建版本；Play创建表单包名可用、应用仍未创建，无可见build9占用，实际上传前仍须查重。

|平台|新冻结路径（项目根相对）|字节|SHA256|
|---|---|---:|---|
|iOS|build/beta-candidates/0.5.0-9/ios-ads-disabled-1/Pourlune-0.5.0-9.ipa|59266689|194ce45cfe31cd73259a05be9cde4f422624d60f721492a81867d5a1ee1abd74|
|Android|build/beta-candidates/0.5.0-9/android-ads-disabled-1/Pourlune-0.5.0-9-upload-signed.aab|106239354|28da3d087819da1ec96c4f8b790f9a7d75ab0476eea1d89a9cfd8b5c41cbf0e7|

Android unsigned AAB保存在同目录，未覆盖。旧build7/build8六个IPA/AAB逐项hash均不变。复用既有Pourlune Apple profile/证书与Android upload key；未创建、重置、导出私钥或回显密码。

## 模式及实际核验

- 应用先执行固定工具链 `flutter pub get --enforce-lockfile` exit0，然后既有 `beta_build.py` 串行Android→iOS，各exit0，均显式 **--ad-mode disabled**、正常lib/main.dart、release、prod编译配置、正式com.pourlune.app/Pourlune和既有公开帮助/隐私/邮箱。统一FIREBASE_ANALYTICS_WITHOUT_ADID=1，未运行生产App/上传符号/安装设备。
- 根目录 `.venv/bin/python docs/development/evidence/ads-disabled-beta-build9/verify-packages.py` exit0。直接读新ZIP和冻结来源：iOS533候选文件、Android3文件hash全匹配；两端各136资源/90题逐字节等于来源；四份锁hash未变。具体见package-checks.json/package-verification.log。
- iOS实际归档日志DART_DEFINES使用shlex解析Xcode转义后的export语句，只保存允许的公开模式字段：AD_MODE=disabled、ios、com.pourlune.app、prod/native-ready=true，正常main/noAdID记录存在，详见archive-mode-proof.json。未输出完整Firebase客户端选项。
- 包内iOS AOT和Android三个ABI的AOT均**不存在官方测试广告unit字符串**。两端native sample AppID仍保留以兼容已嵌SDK，候选ad_configuration.mode=disabled、owned_registration_verified=false；它们不是真实AdMob登记或启用广告的证据。结合冻结的ServiceConfig.disabled→adsConfigured=false与ServiceHub.prepareAdsPrivacy门控，当前App路径不请求广告或UMP资格检查。SDK依赖/原生权限仍在，不宣称所有SDK零处理。
- iOSdeep/strict codesign、actual entitlements/profile/CMS核对通过；正常distribution、get-task-allow=false，既有Team/profile/certificate匹配。5个dSYM条目/4模块UUID与导出二进制匹配。Androidjarsigner strict/pin、bundletool validate/manifest/config通过；实际versionCode9、target36/min24，signed/unsigned571非META payload相同。12 ELF PT_LOAD静态≥16KB，未声称16KB手机运行通过。AndroidR8 mapping/9native符号、iOS隐私清单保留。
- 原生Analytics/Crash默认false。未新增业务实现或依赖，因此不重跑已经通过的工程/LY全套测试；本轮验证范围是版本差额、真实双端构建、广告关闭模式和新包内容/签名/符号。build8精确CI39942263602终态由架构已有证据覆盖，未重复查询；此处不把build8 CI当build9新提交远端运行。

## 披露与测试说明差额

支持页/隐私页明确新的0.5.0+9候选广告关闭、不请求test/live ads或UMP资格、不提供广告额外瓶；移除“当前可测试广告”的引导，保留免费助手。明确GMA/UMP依赖及Android权限仍在、关闭请求不等于零SDK处理、Firebase/RC及独立默认off选择仍按原实际行为披露。仅修改两HTML文字，DOM结构/属性/链接无变化，无新跟踪脚本/表单。公开仓独立更新记录见public-site-update.json，公开提交 c681be8a7c139bf64fb4900e1045b216a6e5a800；两页实际HTTPS200且逐字节等于源文件，已独立于push回读上线状态。

新apple-what-to-test.txt/play-release-notes.txt聚焦离线关卡、单屏布局、免费助手、存档与链接，明确广告关闭；不再要求完成测试广告或把未收到奖励当成功。均为准备资料，未提交商店问卷/声明。

## 网络与商店边界

旧三条例外已恢复，运行时临时规则前缀移除且原配置hash不变；同一用户回复虽批准四条，但因停止AdMob而未应用，不再要求手机扫码。AdMob两个验证页已关闭。未代签条款、扩大IAM或建立重复账号。

既有ASC应用6826203407与Pourlune Beta仅本人组可复用；无构建可安装。Play仍停在政策合规/美国出口声明前，两项未勾，后续App Signing/真实测试地区等据实际必填处理，不猜私人事实。TestFlight/Play上传、商店处理、封测/手机安装和音触觉/性能/读屏等尚未通过。F9、普通存档、FirebaseQA及原始美术未操作，受限截图/录屏采集未重试。

**CLI RELEASED**：本方Flutter/pub/SPM/Xcode/包检查已全部结束，无本方平台构建在途。父可直接核新IPA/AAB、两sources、来源唯一差额、实际关闭模式、资源/签名/符号及披露差额后确认，再继续既有授权分发。主仓未stage/commit/push；只在已授权独立公开支持仓提交两HTML。
