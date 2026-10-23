# BR08 一屏布局后的新签名候选

2026-10-23，作者包内检查通过，**待架构对这两个实际新包独立核验**。本批未创建商店记录、上传、开轨道、邀请或代签协议，未运行生产App。用户已经授权 LY 通过后继续 TestFlight 与 Google Play closed；这里的独立核包是既定交付门槛，不是再次请求用户通用上传许可。

## 基线与改动

LY接受源码 `cd335efc5d293549d97a4b6c44420e605b665297` 的[精确CI39928698433](https://github.com/wangyule0379-max/Pourlune/actions/runs/39928698433)两job success，checkout SHA已核对。当前冻结HEAD `cf8e75fedd5204680c3ed5becc63290fa3672402` 相比LY仅架构文档提交，无app/core/tools/workflow差额。唯一构建源改动为 `app/pubspec.yaml` 的 `0.5.0+6 → 0.5.0+7`；未修改SDK、游戏/UI行为、依赖或锁文件。

已有认证账号只读搜索未发现Pourlune记录，build7未在可见记录占用；实际创建/上传前仍复核。现有本人ASC Admin/all-apps可走内部测试，无需扩IAM。Google保持closed，首批仅本人。最新13+目标及五张原图ChatGPT生成出处按 beta-owner-decisions.md 复用，不重新要求笼统商用授权。

## 实际新包

|平台|项目根相对路径|字节|SHA256|
|---|---|---:|---|
|iOS|build/beta-candidates/0.5.0-7/ios-br08-1/Pourlune-0.5.0-7.ipa|59266776|2a23d891cee81975feb0ddfaa5fff9b7d2c21c315b40a17009db67fbc52b8a1c|
|Android|build/beta-candidates/0.5.0-7/android-br08-1/Pourlune-0.5.0-7-upload-signed.aab|106239437|cec8cb62b952bb58c44b6d673f9c8addd5e7c3ef40c4020496834a608cac1ffd|

Android unsigned 同目录 `app-release-unsigned.aab` SHA256 `dfe046983d236ca3d0cbf7ec83bf27be7d85c86a11df53360c1d25684794907e`。两端构建命令日志位于 `docs/development/evidence/beta-readiness/BR08/{android,ios}-build-command.log`，完整构建记录与symbols在各ignored候选目录。旧build5/6不覆盖、不当布局修复后包上传；build6三个产物hash重新核对不变。

## 本次实际检查

根目录串行执行既有 beta_build.py：Android结束后iOS，两端返回ok。统一 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`，prod、正常main/release、广告关闭、公开帮助/隐私URL与邮箱；正常pub刷新并核对来源不变，无生产运行/测试事件/符号上传。Apple复用既有profile/certificate，Android复用BR05 upload key，未创建/重置或回显口令。

随后根目录执行 `.venv/bin/python docs/development/evidence/beta-readiness/BR08/verify-packages.py` exit0；日志 `package-verification.log`、结果 `package-checks.json`，实际内容包括：

- 双端401来源字典相同且逐文件与当前一致，manifest SHA256 `4d6711d360b782e5efc86d9d03b7e95b488883a640fc877a6cbfcd45bd1cf671`；相对已验LY仅pubspec版本差额，两个pubspec.lock和两个Package.resolved不变。新candidate所列533个iOS文件/3个Android文件均重新hash一致。
- 每端136正式运行资源含90题与当前源逐字节一致；AOT实际包含三个已确认公开目的地。未刷新视觉manifest、未把候选资源标为视觉/商业通过。
- iOS IPA身份 `com.pourlune.app / Pourlune / 0.5.0 / 7`，最低15.0、iPhone+iPad、SDK iphoneos26.5；deep/strict codesign exit0。Team T7U878Z8H6、profile UUID 74a202b2-3b25-4e31-8fd4-0413bf15d486、证书SHA1 13362E4AF31A860FA6B705DB5192AF78613F7A58，profile有效至2027-09-16T15:29:23Z。实际entitlements的application identifier/team正确、get-task-allow=false、beta-reports-active=true。24份隐私清单；5个dSYM条目/4模块UUID全部与导出IPA二进制匹配。
- Android bundletool validate/manifest/config三命令exit0；`com.pourlune.app / 0.5.0 / code7 / min24 / target36`。实际AAB证书pin `E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2`，既有信任项下jarsigner strict exit0，签名前后571个非META文件payload相等。保留10项manifest权限、proguard.map及9份native符号hash；12个ELF的PT_LOAD对齐静态均≥16KB，未声称真实16KB手机运行通过。
- 静态商店预检exit0，应用汇总critical0/high4/medium4，逐项分诊见 `preflight-triage.md`。占位域命中正常拒绝守卫，R8有实际mapping；出口问项/数据安全/最终评级按实际控制台继续处理，不称扫描全绿。Android旧SDK XML及Kotlin迁移提示保留，未为此改依赖。

首轮收集器把armeabi-v7a误按ELF64解析，停止在header断言；检查12个真实头后补ELF32解析，完整重跑通过。属于只读证据收集修正，没有修改应用/SDK或重新构建签名。

## 后续交接与未验

构建全部结束，CLI可供架构只读核包；最新新增AdMob同批联测，build7现冻结保留，不把ads disabled包当新增联测要求已满足并上传。架构需直接核验本表新IPA/AAB；通过后原开发继续既有授权的实际Pourlune记录/上传及TestFlight本人内部、Play closed，不复用旧包验收。主仓未stage/commit/push；版本由架构精准提交推送并检查新CI，其他motion日志/tracking/icon-selection不夹带。

实际商店处理/审核/可安装入口尚无；现有Paid Applications Schedule提示未代签，是否影响免费TestFlight以实际门槛核对。asc无API凭据、Transporter未安装，不为CLI新建API key或扩IAM；后续使用现有账号的可用上传方式。出口key未擅填，实际测试商店地区/适用私人审核事实仍未知，遇到真实必填再集中收集，私密字段不入Git。

邮箱真实收件、生产SDK送达、手机安装/升级/存档、最低系统/16KB设备/性能/声音触觉/读屏均未验证；不重跑已验LY或把静态bounds当真机证据。无F9及窗口操作、无任何受限采集重试/绕过。远端手机走TestFlight/Play安装，不要求用户USB连接或开发者模式。未以QA/设计图替代正式商店截图。

作者fresh检查点审查Critical0/Important0/Minor1，详BR08/author-checkpoint-review.md。该审查直接核了新包，不替代架构验收。**时间界限：本报告“当前源码”指冻结时cf8e75f工作区；ADM01自此另行修改源码，属于新任务，不是build7漂移。** 原verify-packages.py是该时点收集器，之后历史复验应读已存来源manifest/accepted LY与实际包，勿用可变工作区断言替代。
