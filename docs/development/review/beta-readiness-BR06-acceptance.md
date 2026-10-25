# BR06 独立验收 — 网站、资料及 build6 本地候选

2026-10-23，架构独立验收。结论：**BR06-1至8在资料、公开站点和本地签名候选范围通过**；不是商店接收、法律声明或正式手机运行通过。没有重编译、重签、运行生产配置、上传商店、发送邮件或操作用户F9。原开发05:48:07已明确释放CLI，架构接手只读包验证。

## 独立证据

- `beta-readiness-BR06-evidence/verify_independent.py` 本轮实际PASS：45交付范围SHA、双端各397来源与当前文件一致、每端136资源/90题、ZIP完整性，三个真实目的地在iOS AOT及Android各libapp ABI内存在。17条实际Java/codesign/security/dwarfdump只读命令全部exit0。不是命令替身或复用作者结论。
- Android：真实jarsigner strict、包内证书SHA256与既有BR05 pin一致、bundletool validate及manifest通过；com.pourlune.app/0.5.0/code6/min24/target36/Pourlune；signed/unsigned 571个非META条目完全一致，新mapping及9份debug symbols记录。没有创建或修改私钥。
- iOS：精确IPA每个文件与待签名核验目录一致；codesign deep/strict通过，entitlements为T7U878Z8H6.com.pourlune.app且get-task-allow=false；CMS profile对应身份、App Store分发且未过期。5个dSYM位置对应4种模块，分别实际核UUID与IPA二进制一致；24份SDK隐私清单。未把Store IPA当模拟器或可直接侧载包。
- `materials-independent.json`：原build5三候选hash未变；新旧iOS Firebase客户端配置与7项原生隐私开关相同；六份可粘贴文案逐项阅读并计数。Play短/全文34/1240字，release正文274字（含语言包装291）；Apple三字段875/895/875，仅本地预算，不声称控制台已接受。45范围文件私钥/高风险token模式检查无命中。
- GitHub连接器独立读取`24ff80c6fc0cc2f0b513b49c5c236a029334cc2b`远端tree，只有`.nojekyll/index.html/privacy.html`；Pages run39906073868 completed/success。结果`public-github.json`，此终态不再轮询。
- 两站HTTPS实际200，正文与唯一源码逐字节一致。Chrome现有网页独立阅读Privacy→Help实际点击，帮助标题/相对链接/mailto正确；当前1440宽、文档scrollWidth1425，无水平溢出。未进行屏幕采集或受限能力替代；真实手机排版仍未验。
- 架构只读App Store Connect商务页，实体标题确为`changjiang li`，免费App协议有效。只保存必要姓名、协议状态和来源，不复制私人地址/电话/银行信息，不接受新付费协议。邮箱来自获准复用的FishPilot既有公开站；没有验证实际收件。

## 逐项结论

|编号|结论及边界|
|---|---|
|BR06-1|可粘贴英文资料与60主线/30每日候选/三场景/离线规则、免费helpers及广告关闭一致；无登录需求准确；平台最终接受未验。|
|BR06-2/7|支持/隐私站公开部署与内容技术事实通过；主体和邮箱由用户授权复用且有独立依据。无脚本/表单/外部字体/嵌入媒体，公开仓库只含网页。off不等零处理、RC/缓存报告/邮件/网站日志与本地Reset区别保留。不是所有地区法律充分性或实际请求处理审计。|
|BR06-3|技术事实、建议与本人经营声明分开；原生开关和gateway源码支持表述。当前官方Apple Test information、Play Data safety及Firebase Android披露已回查。RC标识和可选共享不能统一填无采集；最终项目级关联/保留设置及法律事实仍待核实。|
|BR06-4|既有素材来源/尺寸/QA污染盘点通过，正确拒绝旧工程菜单截图冒充正式宣传；正式当前版本截图、Play512图标和1024×500横幅仍不齐。后两项可继续制作本地待核权候选，见BR07，不把技术准备也一律等权属。|
|BR06-5|权属差额收敛为五张实际原图一组、运行派生/裁剪一组；字体/OFL与数学波形来源已附据；所有图像仍UNCONFIRMED，不以本次验收改变其商业状态。|
|BR06-6/8|新网址版本与签名候选本地通过，旧包保留；设备/内部外部TestFlight与Playclosed三路线区分正确，不要求USB。build6尚未上传、号码未在平台预留；后续上传前再核已用号。|

## 精确候选

- iOS `build/beta-candidates/0.5.0-6/ios-br06-1/Pourlune-0.5.0-6.ipa` SHA256 `c7d5c5428da62644179abbd29d95e6fe5ab1270026dbfb054ac2aa6bde6c1ce4`。
- Android `build/beta-candidates/0.5.0-6/android-br06-1/Pourlune-0.5.0-6-upload-signed.aab` SHA256 `57118f03b57d6c75264a2dd310740ff486336b19d0acfe6597804f63461a74d8`。
- 来源manifest SHA256 `261b407b742a2eeabe2df1e075c95de82b02c42e5d930b72cc9e71d0f0dc504b`。本批生产文件差额为pubspec build5→6；链接由已验构建工具显式注入。没有玩法、依赖或SDK变更；不重复旧全量本地测试。提交后核对该精确push的新CI，CI仍不等正式签名包运行。

## 剩余与后续

没有发现阻止接受本批范围的代码缺陷。截图/手机安装升级恢复、最低OS/16KB运行、性能/读屏/物理音触觉、真实邮箱收件及生产服务送达仍未验。Firebase原有TLS问题不重复实验。用户F9及窗口、普通库、FirebaseQA未操作；旧motion和后台emulator日志不纳入提交。

继续有界BR07本地宣传素材准备；需本人提供的仅真实年龄定位、测试地区/私有名单与设备条件、两组图像来源/许可，以及适用私有审核联系和法律声明。实际商店上传/审核/开轨道/邀请及生产App运行在精确范围就绪后另行授权。不能将公开网站完成解释为这些已获准。

官方依据：[Apple测试信息](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)、[Play数据安全](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)、[Firebase披露](https://firebase.google.com/docs/android/play-data-disclosure)。供应商页面针对其说明版本，不能替代本包网络观察。
