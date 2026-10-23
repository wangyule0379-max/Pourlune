# ADM01 build8 独立包验收

2026-10-23。本地双端签名候选核验通过，可沿已授权 TestFlight 本人测试及 Google Play closed 路径继续办理。此结论不是 AdMob 账号登记、真实 SDK 加载/展示/关闭/奖励或商店接收/本人手机通过；这些仍须分别记录。当前仅使用 Google 官方样例 AppID/unit，owned_registration_verified=false。

## 实际核验

父使用独立核包脚本直接读取两个新 ZIP 包、冻结来源及真实签名信息；没有重编、重签、读取回显密码、运行生产 App 或操作设备。

- 两端各405来源逐项对Git已验18f8c8b比对，唯一允许差额pubspec 0.5.0+7→0.5.0+8；来源清单同SHA46bfe52fd544e5aad03dfe3571883b50d9dd01d661495b4c913ebbc14c029114，当前来源无漂移，锁文件相同。
- 候选清单列出的文件全部hash匹配，ZIP无重复/损坏；各136资源含90题与来源一致。旧build7三包hash均未变。
- iOS导出IPA256文件逐字节与验签树相同，codesign deep/strict、entitlements/CMS、非debug/AppStore profile及有效期通过。24 SDK隐私清单；5个dSYM条目/4模块与导出二进制UUID匹配。
- Android既有证书pin E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2一致，jarsigner strict通过；signed/unsigned571 payload相同；bundletool validate及实际manifest正式ID/com.pourlune.app、0.5.0/code8、min24/target36准确。mapping与native符号hash记录。12 ELF的PT_LOAD静态≥16KB，不代表真机16KB运行。
- 两端实际native sample AppID正确；iOS和Android3ABI AOT都有准确平台官方test units和帮助/隐私/邮箱。iOS实际归档日志编码参数核到AD_MODE=test、platform/identity/AppID/prod/native-ready，正常main/noAdID标记存在；Android普通构建日志不输出原生guard JSON，不把此日志当运行模式独立证明，结合受验wrapper/源、候选显式参数及真实包内units判断。
- 双端native Analytics/Crash默认false。共17个Java/codesign/CMS/UUID只读命令全部exit0。

## 精确候选

|平台|路径（项目根相对）|SHA256|
|---|---|---|
|iOS|build/beta-candidates/0.5.0-8/ios-adm01-1/Pourlune-0.5.0-8.ipa|e79ed16b612b1f8ad845281d9baa966f32038411473820e107ccf710fcacd364|
|Android|build/beta-candidates/0.5.0-8/android-adm01-1/Pourlune-0.5.0-8-upload-signed.aab|4c81599e49a252f52b2ae84442c1d149e0e593e09a1c9cd9664ea89b42169b7f|

独立证据：`admob-build8-evidence/verify_independent.py`、`verification.log`、`independent-final.json`、`verify_mode_and_elf.py`、`mode-and-elf.json`。作者实际构建日志/可见控制台查重与父直接核包结论分开；父没有登录控制台，未独立确认版本未占用，实际上传前须查重。

## 继续分发与保留项

已通知原开发继续已授权实际商店流程并交付`deliveries/admob-build8-submission.md`。技术已知项直接办；未知真实账号/地区/私人审核字段/适用协议不能猜或代签，首批仅本人，不扩大IAM。准备、上传、处理、Beta审核、封测可安装分别回读，不以当前包通过代替。

网络临时规则例外仍待用户在原开发聊天确认；父未批准或更改。AdMob真实登记未知，先前iOS UMP资格可用但两库存timeout、实际广告闭环未验；测试说明须明确这些限制，本人手机结果在分发后补充。禁止用样例登记伪报商业资格。生产仍未运行，F9/普通库/FirebaseQA/旧包保持不动；受限图像采集未重试。
