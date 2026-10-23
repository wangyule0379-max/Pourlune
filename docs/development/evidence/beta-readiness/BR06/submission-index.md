# 当前提交资料入口（尚未上传或开启测试）

2026-10-23；新候选为**0.5.0+6**，正式双端com.pourlune.app、Pourlune。新包带已上线支持/隐私/邮箱，替代build5作为下一次拟提交候选；build5及其历史来源仍保留，不改写旧报告。ASC/Play只读列表均未见Pourlune记录，版本选择理由见version-selection.json；实际上传前再核最高已使用build/versionCode，当前检查不预留号码。

|资料|唯一入口|现有核验|
|---|---|---|
|新iOS IPA|build/beta-candidates/0.5.0-6/ios-br06-1/Pourlune-0.5.0-6.ipa|SHA256 c7d5c5428da62644179abbd29d95e6fe5ab1270026dbfb054ac2aa6bde6c1ce4；59,257,872bytes；既有Store profile/cert手动archive/export、deep strict；不是Simulator/AdHoc安装包|
|新Android签名AAB|build/beta-candidates/0.5.0-6/android-br06-1/Pourlune-0.5.0-6-upload-signed.aab|SHA256 57118f03b57d6c75264a2dd310740ff486336b19d0acfe6597804f63461a74d8；106,208,709bytes；BR05同一upload cert、真实strict与pin检查|
|来源/配置/资源|两candidate.json、sources.json；本目录delivery-checks.json|397来源条目，manifestSHA261b407b742a2eeabe2df1e075c95de82b02c42e5d930b72cc9e71d0f0dc504b一致；每平台136assets/90puzzles逐字节源一致；AOT中三个目的地实际字符串存在，不只metadata.ready|
|符号|新ios-export/Runner.xcarchive/dSYMs；新AAB内BUNDLE-METADATA的proguard.map及debugsymbols|native-package-checks.json精确dSYM UUID与IPA匹配；delivery-checks.json保留新AAB mapping/9native symbols hash；旧BR03独立mapping属于旧build5，不能拿来给新build6配符号|
|既有Android key|仓库外 /Users/wangyule/.local/share/pourlune-signing/；alias pourlune-upload|公开pin E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2；2054-03-10到期，BR05恢复副本仍仅同机。无需再创建/输入密码；私密文件不入Git/网页/日志|
|英文资料|本目录6个.txt；copy-and-official-checks.md|Apple Beta/What to Test/Review Notes；Play short/full/release，字符实测copy-checks.json|
|公开网站|https://wangyule0379-max.github.io/pourlune-support/ 与 privacy.html|主体changjiang li、邮箱wangyule0379@gmail.com；commit24ff80c，Pages39906073868success，3文件白名单/HTTPS200且正文匹配；邮箱收件未验|
|技术声明建议|questionnaire-recommendations.md|开发给具体SDK数据类型/用途/可选性/关联/分享建议；本人最终项目设置、受众和适用声明不能假填|
|视觉与权属|visual-materials.md、visual-material-inventory.json、rights-gap.md|图标有源；正式当前版本无QA截图/512storeicon/feature graphic及两组图像授权仍待闭环，未伪装已验|

## 三条实际测试路径

|路径|上传前准备|授权分发时|手机安装后|
|---|---|---|---|
|TestFlight内部|当前新IPA、现有AppID/profile、建/核正确ASC app记录、按实际提示出口/协议；只用已有合格ASC测试身份|用户针对精确build/hash授权上传/组分配后执行；不要为内部测试任意扩大账号权限或创建外部人IAM|用TestFlight安装，验证正常冷启/离线玩法/同安装升级与存档/链接打开/设置、物理音触觉、可访问性；USB不是前置条件|
|TestFlight外部|同一精确IPA、Beta description/What to Test/review notes、真实私有审核联系人、反馈邮箱、需要的出口/实际账户声明|用户授权具体build的Beta Review、Pourlune Beta组与名单；按Apple实际审核结果继续，不把上市全部资料一律当外部Beta门槛|通过已获准邀请安装；与内部相同真实手机路线和反馈，不以本地编译替代|
|Play closed|当前新signed AAB、准确app记录、App Signing/政策及出口本人适用声明、公开隐私/联系、listing素材和App content、目标国家/测试者清单|用户授权具体bundle/closed轨道/地区/名单后配置并审核分发；internal不冒充closed完成|用Play测试链接及授权账号安装/升级；记实际Play app-signing cert（不是仅upload cert），验证相同功能/存档/链接/声音触觉等|

没有执行商店上传、Beta审核、开轨道、邀请、代签或生产App运行。远端手机路线复用BR04/remote-device-route.md及device-feedback.md，USB/开发者模式不作为所有上传前普遍门槛。正式音触觉、最低OS/16KB/性能/屏幕朗读和生产服务实际收件仍保留未验。

## 后续确需再重建时的固定输入

当前已是真实URL候选，不再等待目的地或密钥。只有真实源码/配置/资源/目的地变化或号码已被占用才重建：先回读两个商店已用号，更新app/pubspec.yaml中的build（不盲选复用6），新ignored输出目录；保留旧二进制/hash/sources。根目录使用既有tools/validation/beta_build.py：--platform ios|android、--output新的build子目录、--support-url https://wangyule0379-max.github.io/pourlune-support/、--privacy-url https://wangyule0379-max.github.io/pourlune-support/privacy.html、--feedback-email wangyule0379@gmail.com。iOS显式既有profile，Android显式BR05路径/alias/password-file/public pin；不打印密码、不新建key。详细私密边界复用tools/validation/README.md。

构建工具固定prod/main/release/adsdisabled/noAdID、enforce-lockfile及正常pub刷新，串行Flutter/SPM/Xcode。新包重新检查身份/版本/AOT目的地/签名/pin/资源/来源与符号，不带allowProvisioningUpdates、不上传符号、不运行prod。公开URL语法ready不替代站点内容/法律/运行验收。
