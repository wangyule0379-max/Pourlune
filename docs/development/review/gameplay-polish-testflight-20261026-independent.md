# 游戏交互修订 TestFlight 15 独立发布审查

2026-10-26，父只读核验。结论：**签名候选2与精确CI通过，可继续实际Organizer变体核验及上传**。本报告暂不代表已上传、ASC处理完成或手机安装。

## 来源与已验收范围

发布源 `70d9b5909e6a1d8c158df349f59fd4cfb043b99e`。与已验收交付 `c3de374` 相比仅版本14→15及两份旧测试契约更新；已验生产实现、资源、题库、SDK及锁不变。普通不能倒入时的新换选断言已更新，同时显式 `c.pour` 保留真正拒绝提示、详情、布局与状态不变守卫，未删除真实安全检查。

本包包含四项既有独立验收：原稿液体颜色、连续可见倒水、橙色加深/瓶口间距、不能倒入时直接换选。画面和动态证据复用对应四份独立报告，不重复无差额全套采图。

首候选 `87dcf05` 的CI失败记录及包保留，不上传。父通过GitHub连接器实际读取新run `40287545684`：exact head一致，`completed/success`，`ios-build`与`tests-and-android`及其步骤均成功。终态已存 `ci-independent-terminal.json`，不重复查询。

## 签名候选2

只读镜像 `build/package-review/0.5.0-15/ios-gameplay-polish-2`。实际IPA SHA256 `fde95b02f7bd0e8c00245f893c9a4a89403ba88d983ebc148410c2c2f5660513`，80,311,850字节。

父独立脚本 `evidence/gameplay-polish-testflight-20261026/verify_package_independent.py` 共45项PASS，结果 `package-independent.json`：

- 镜像558文件、候选554文件索引、508运行输入均逐个核hash；运行输入等于精确Git源及本地冻结时内容，镜像只读。IPA每个ZIP成员与解包目录逐个一致且无重复路径。
- IPA/archive均为Pourlune、`com.pourlune.app`、0.5.0(15)、iOS15。正常`lib/main.dart`，无场景/命名QA库注入；实际配置prod Firebase、ads disabled、NoAdID核心依赖；Analytics/Crashlytics默认关闭，无ATT声明。
- 146资源与源一致，60主线+30每日；21–60五色/七瓶/两个缓冲，90题与已验库相同，每日30及catalog31项保持。SDK/锁不变。
- IPA与archive严格深签名有效，沿用既有profile `74a202b2-3b25-4e31-8fd4-0413bf15d486`、Team `T7U878Z8H6`、签名公证书SHA1 `13362E4AF31A860FA6B705DB5192AF78613F7A58`，分发entitlements无调试、无设备限定，profile未过期。
- archive与IPA实际Runner无IntegrationTestPlugin/integration_test；AOT无本批QA库/旧QA标记/测试广告unit。仅临时排除integration_test生成注册/SPM且本地QA生成输入已恢复。
- 5份dSYM UUID分别匹配archive与IPA二进制，24份隐私清单可解析。

系统Python3.9不支持file_digest，使用项目Python3.12重跑；沙盒内公共profile解码不可用，经只读系统证书访问授权后完整45项通过。未读取私钥或密码，未构建/操作设备/改签名包。

## 合规差额与分发

开发的preflight扫描器命中localhost拒绝列表、无订阅项目的跨文件关键词等；这些已定位为扫描误报或本次iOS内部测试不适用项。父实际包核支持站/隐私目的地、采集默认、NoAdID及隐私清单；无本次新真实阻断。未将扫描器退出码改绿或借此新增权限/功能。真机音触觉与用户实际安装仍未验。

新建单人组曾被自动审批拒绝，未执行，也不换入口绕过。父随后直接read_thread核实真实用户消息 `01a17735-0112-7133-937b-2616a1e30eca`：在明确告知Self当前2人后，用户答复“为啥分这么多组干啥呢？目的是啥？尽量用同一个组”。按此新指令沿用既有Self `1853bacc-97d1-40f9-b0cb-ae9ef9d01c74` 当前两人；不新建、不改成员、不新邀，其他组不动。

后续必须分别读取实际Organizer上传变体、上传成功、ASC处理、Self组15可测试状态；不会把本次包门称为已发布。

## 实际上传变体补核（发生在上传启动后）

Xcode本次直接TestFlight Internal Only的Next自动准备并启动上传，未出现先前的Review确认页。开发尝试Cancel等待核验被自动审批拒绝，未执行、不绕过。上传已有用户授权，但这不符合计划的实际变体先验顺序；不得倒写为上传前核验。

父实际核队列/保存/只读三个IPA SHA256均为 `aa25b84dcf09956466f47fd8070f09aa80ac17d56e38fab2a2353edbfa56075e`，95,141,354字节；只读补验 `organizer-independent.json` 24项PASS：原266个payload文件全部保留，8个Mach-O仅原签名区变化、执行字节/UUID不变；Info仅增加TFInternalTestingOnly；资源、90题、运行配置及QA排除继承已验同字节。

此次额外差异如实保留：Xcode替换了embedded.mobileprovision，为本轮08:04:51UTC生成的 `ead60500-17f6-45e7-beda-52e18144dc17`（iOS Team Store Provisioning Profile），不能称沿用原profile。其Team/AppID及分发entitlements正确，get-task-allow=false、未过期、无设备限制，签名证书仍原公钥pin13362E4A…。没有读取/创建私钥的证据。

直接内部测试方式还默认附带4个Apple Symbols条目；这与原不上传符号选项不一致，不伪称symbols false。4个UUID对应已有dSYM；5份archive dSYM（objective_c有一同字节副本）均独立逐一与实际上传二进制UUID匹配。未执行Firebase符号或生产测试事件上传。后续发布应使用可检查参数的自定义流程，避免再次自动采用这些默认值。

父已实际查看 `organizer-actual-state.png` 及 `organizer-upload-result.txt`，Xcode显示Upload completed with warnings。4项警告为FirebaseAnalytics/GoogleAppMeasurement/GoogleMobileAds/UserMessagingPlatform的第三方dSYM未随archive提供，属于对应SDK崩溃符号化限制；不宣称完整第三方符号，亦不将其误报为IPA上传失败。当前实际包无新的代码/资源/签名阻断，继续ASC处理与Self组回读；尚不声称可安装。

## 最终平台验收：已完成

父已实际查看私有最终Self截图，并读取testflight-self-ready.txt、build-group-readback.txt与出口声明保存回执。构建 `74f1d564-5166-4735-960c-e1a17ffc860e`、0.5.0(15)已上传并完成ASC处理，测试说明已保存，唯有关联原Pourlune Self组、当前两名既有测试员；该组实际显示15“正在测试/90天后过期”，14保持。出口声明在真实用户明确同意后保存，没有绕过此前自动审批拒绝。

最终证据hash及逐项结论见 `evidence/gameplay-polish-testflight-20261026/platform-final-independent.json`。发布目标已达成；无需重传、重查终态CI、新建组或重新邀请。手机实际安装/升级及音触觉仍未由父验证，4供应商SDK符号化警告及上传流程偏差保留上述真实记录。
