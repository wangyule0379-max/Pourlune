# 广告关闭 build9 独立包验收

2026-10-23。双端新签名候选与公开说明增量独立核验通过，可继续用户已授权的 TestFlight 本人测试与 Google Play closed 提交。此结论不等于已上传、商店处理完成、可安装或手机运行通过。AdMob 接入按用户最新要求暂停，build8 显式测试广告包冻结不上传。

## 本轮实际核验

父在原开发明确 CLI RELEASED 后执行只读核验，没有重编重签、读取回显秘密、运行生产或操作设备。

- 405来源逐项对Git已验ea52dcf核对，只允许pubspec 0.5.0+8→0.5.0+9，当前无漂移，两端source manifest同SHA42fe38405772def0e4c54651bcc20a3b9fa7ce3fa7706cc9c82a193ef74e2356。应用/核心及SPM锁未变。
- 直接读取两新ZIP及清单所有文件hash，ZIP完整且无重复；各136资源/90题与源逐字节匹配。旧build7/8共六包hash不变。
- actual iOS Info与Android bundle manifest均为com.pourlune.app/Pourlune/0.5.0/build9；Android min24/target36，原生Analytics/Crash默认false。
- iOS IPA逐文件匹配解包验签树，codesign deep/strict、entitlements、CMS/profile有效且App Store非debug；24份SDK隐私清单，5个dSYM条目/4模块对actual binary UUID一致。Android既有pin/jarsigner strict、bundletool validate通过，signed/unsigned571项非META payload一致；mapping及9native symbols hash核对。共17个真实只读Java/codesign/CMS/UUID命令exit0。
- candidate显式mode=disabled，真实iOS archive的转义DART_DEFINES经独立shlex/base64解析确认disabled/ios/com.pourlune.app/prod/native-ready与normalmain/noAdID。iOS和Android三ABI的AOT均无对应官方测试unit，均保留正确公开目的地。Android普通构建日志没有原生guard JSON，未把日志缺失视作运行证明；结论结合已验wrapper、冻结来源、实际候选参数与AOT变化。
- 直接读受验ServiceConfig.adsConfigured：disabled返回false；ServiceHub.prepareAdsPrivacy在此门控返回，AdCoordinator初始化仅读存档，其load受configured门控。native sample AppID仍在，不能由此声称账号登记；SDK及权限仍嵌入，不声称零处理。未做正式App实际网络捕获或运行。
- 12ELF PT_LOAD静态≥16KB，不等真机16KB运行通过。
- 两公开页父直接HTTPS200回读，分别SHA150bdf7832948681c7f844c7b334a28be3cc6a94cd79a6756ee90ad4dbeb5fe8和a0902fa699712fe8d23f10519905ec5f9a1da6e874095cb01ebbd81ebc015fe1，逐字节等于本地审核稿；相对已验页仅文本变更、标签/属性不变。当前build9关闭广告/UMP资格、免费助手保留、SDK/权限仍在及采集独立off说明一致。不是法律充分性或服务实际零处理认证。

## 精确候选

|平台|项目根相对路径|SHA256|
|---|---|---|
|iOS|build/beta-candidates/0.5.0-9/ios-ads-disabled-1/Pourlune-0.5.0-9.ipa|194ce45cfe31cd73259a05be9cde4f422624d60f721492a81867d5a1ee1abd74|
|Android|build/beta-candidates/0.5.0-9/android-ads-disabled-1/Pourlune-0.5.0-9-upload-signed.aab|28da3d087819da1ec96c4f8b790f9a7d75ab0476eea1d89a9cfd8b5c41cbf0e7|

证据：ads-disabled-build9-evidence/verify_independent.py、verification.log、independent-final.json、verify_mode_and_elf.py、mode-and-elf.json、public-site-readback.json。既有工程/LY测试不重复，暂无新玩法/依赖实现。本次版号提交若自动产生CI，仅追精确新SHA至终态，不重查旧run。

## 分发交接

原开发复用既有ASC记录6826203407及仅本人组、既有签名，继续实际原IPA/AAB上传和独立记录回执。旧记录创建与版本空闲仍为作者可见UI范围，本轮父未登录控制台，上传前仍核对。Play政策/美国出口声明不能代签；认证或其他未知必填集中指明真实页面和影响，继续另一可行路径。无需重复通用上传许可，不扩大IAM/购买/邀请未知人/公开生产发布。

本人手机安装、升级、保存恢复、音触觉、读屏、性能仍未验；不要求远端USB。F9、普通库、FirebaseQA、旧冻结包及受限采集保持不动。父全部只读验证结束，CLI RELEASED交回原开发。

## 2026-10-23 11:49 UTC CI及Organizer重新签名差额

精确779c82eb1d82a582b327d3cbdd517419f06201b4的CI39947544889已于11:49:11Z终态success，父独立回读两job均成功，remote-ci-final.json已保存，禁止重复查询。

Xcode使用既有团队会话对本次归档准备上传，生成新IPA：`build/store-submission/0.5.0-9/ios-organizer-attempt-1/prepared-upload.ipa`，SHA256 **7fd86c11a7cfc5053b1a96aa381134861e9aec0b8a75311adef25c189b51d117**。父另写独立验证器直接读取新旧ZIP并独立解包，非复用作者验签树：256文件中247逐字节相同；8个Mach-O仅各LC_CODE_SIGNATURE实际签名blob变化，签名范围位置/大小、fat头/padding、全部load commands及其他代码字节均不变；另1个CodeResources仅相应framework哈希变化。Info/profile/资源/广告模式继承字节相等证据。

16个真实只读命令exit0，actual codesign deep/strict、同entitlements、有效profile UUID74a202b2-3b25-4e31-8fd4-0413bf15d486及既有公钥证书SHA1 13362E4AF31A860FA6B705DB5192AF78613F7A58、5个dSYM对新实际二进制UUID通过。旧候选533文件hash不变。证据verify_organizer_independent.py、organizer-independent.log、organizer-independent-final.json。

已通知原开发解除该精确重新签名包的上传等待，继续当前Xcode会话；会话如产生不同新包需核差额。父未点击上传/运行生产或设备，也未把作者“最终Upload前”当上传成功。Play本人两项声明已由开发一次询问，不重复提问。CLI归原开发，父命令全部结束。
