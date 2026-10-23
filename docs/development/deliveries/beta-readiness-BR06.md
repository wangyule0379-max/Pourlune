# BR06 发布资料、公开支持站与真实链接候选

2026-10-23，作者交付，**待架构独立验收**。原六项计划及用户随后“沿用FishPilot主体/邮箱、同意GitHub Pages、能做的继续”授权已落实。新增站点部署和双端build6签名候选；没有商店上传/审核/开轨道/邀请、代签或生产App运行。本批开发可做材料收束，余下真实受众/测试名单/权属/适用声明集中交架构。

## 新做与复用

|要求|本轮具体增量与证据|复用/边界|
|---|---|---|
|BR06-1|BR06/6个.txt为可粘贴Apple Beta/What to Test/Review Notes及Play short/full/release；copy-checks.json字符875/895/875、34/1240/274，Play上限及格式通过|BR01玩法/短句复用；Apple官方帮助未提供数值上限，三字段仅本地<2000预算，控制台接受未验，不假借IAP字段上限|
|BR06-2|唯一docs/support/pages-site，按玩家任务/本地与在线数据/独立选择/请求与保留完善；真实主体/邮箱/公开Pages；site-http-check.json、tree-public.json、site-deployment.json、site-browser-check.json及site-package.json|FishPilot公开支持源仅复用获准邮箱；主体从ASC商务协议实体核实，不从CN/账号昵称猜；无账号/订阅/定位条款照搬。实际邮箱收件未验，未发测试信|
|BR06-3|questionnaire-recommendations.md给数据类型/目的/可选性/关联/分享、广告No建议、无登录/评级功能/出口技术事实的具体建议|BR04字段基础/BR01 SDK清单复用；默认off不称零数据，项目级供应商设置/受众/适用本人声明未代填|
|BR06-4|visual-material-inventory.json逐路径/hash/尺寸/模式/版本/QA标记26项；实看两张普通main均工程菜单，不能商店用；visual-materials.md给准确官方尺寸与后续一次采集/feature版式清单|当前没有经核权的当前签名版正式截图/512storeicon/featuregraphic；旧QA和原型不当正式素材，没有新截图/采集重试或F9操作|
|BR06-5|rights-original-groups.json与rights-gap.md把未决收敛为5张实际原图一组＋派生生成/裁剪一组；字体/6WAV字节与1634组包内许可记录附据|两原图manifest保持UNCONFIRMED不刷新；不推定ImageGen套餐或商用授权，不泛泛要求所有文件重证|
|BR06-6|submission-index.md及version-selection.json；新0.5.0+6 IPA/真实signed AAB，397来源同hash，包内目的地、签名、资源和符号实测；三条分发路径分阶段|BR03/05旧来源/候选/符号保持历史；BR05同一个key复用，不创建/重置；USB不作为上传前通用门槛|

## 公开站点已上线

- [帮助](https://wangyule0379-max.github.io/pourlune-support/) / [隐私](https://wangyule0379-max.github.io/pourlune-support/privacy.html)。主体`changjiang li`从ASC商务协议记录核实；`wangyule0379@gmail.com`经用户批准沿用FishPilot现有公开支持邮箱。identity-contact-provenance.json只存必要证据，不存私有电话/地址/财务记录。
- 独立[公共网页仓库](https://github.com/wangyule0379-max/pourlune-support)，精确commit`24ff80c6fc0cc2f0b513b49c5c236a029334cc2b`；[Pages39906073868](https://github.com/wangyule0379-max/pourlune-support/actions/runs/39906073868)终态success，main根/默认域/强制HTTPS。只公开`.nojekyll/index.html/privacy.html`；未改App仓库可见性、未传配置/代码/名单/秘密。
- 两HTTPS200、正文逐字节与唯一目录一致；实际浏览器Help→Privacy点击及mailto href通过，1440宽无水平溢出。320/375/430仅CSS/结构检查，真实移动端浏览未验；无屏幕采集或限制绕过。站点无脚本/表单/外部字体/嵌入媒体，GitHub安全IP日志如实披露。
- 正式公开政策只陈述实际默认off/可选共享/RC/本地保存/邮件请求处理，不作固定响应天数、SDK收件或全部数据删除保证。受众/地区/最终商店法律声明仍需真实确定；上线不等于商店合规整体通过。

## 新候选与检查

|平台|新产物（项目根相对）|SHA256|
|---|---|---|
|iOS|build/beta-candidates/0.5.0-6/ios-br06-1/Pourlune-0.5.0-6.ipa|c7d5c5428da62644179abbd29d95e6fe5ab1270026dbfb054ac2aa6bde6c1ce4|
|Android|build/beta-candidates/0.5.0-6/android-br06-1/Pourlune-0.5.0-6-upload-signed.aab|57118f03b57d6c75264a2dd310740ff486336b19d0acfe6597804f63461a74d8|

实际根目录顺序运行既有beta_build.py：Android→结束→iOS，参数为prod受控工具、正常main/release、真实两个URL与邮箱、既有BR05上传key/公开pin或既有Apple profile；全程FIREBASE_ANALYTICS_WITHOUT_ADID=1。详细命令/私密边界见submission-index.md与tools/validation/README.md，口令不回显。两构建exit0，app/pubspec.yaml唯一配置变化0.5.0+5→+6；锁文件、依赖、核心、SDK源码和玩法未改。historical-source-delta.json列出从原始build5到本轮的9条差异，其中8条为已验BR04工具演进，本批只有pubspec版本变化；不是394原来源仍与当前工具相同。

- delivery-checks.json：两平台397源码条目同manifestSHA`261b407b742a2eeabe2df1e075c95de82b02c42e5d930b72cc9e71d0f0dc504b`，与当前精确源码一致；136assets/90puzzles逐字节一致，AOT中三个目的地字符串真实存在；签名前后571非META条目相同，public pin/strict/payload通过；旧IPA、unsigned/signed AAB及BR04网页ZIP hash不变。
- native-package-checks.json：3次bundletool validate/manifest/config均exit0，Android包名/显示名/版本code6/min24/target36正确；iOS deep strict codesign exit0、5个dSYM条目/4模块UUID与新IPA一致，24份SDK隐私清单。新AAB mapping与9符号hash独立记录，旧build5符号不混用。
- material-verification.log、copy-checks.json、site包/HTTP/导航检查：通过。Nunito/OFL与六WAV副本一致；未刷新视觉manifest。本次无生产行为改动，未重跑旧全量Flutter/Dart/CI或原生流程，实际编译是新增明确授权的URL候选工作。
- 已保留构建提示：Android依赖Built-in Kotlin迁移及SDK XML旧解析兼容警告；实际构建通过，不在本资料批改依赖/SDK。iOS常规run-script提示不称故障或性能结果。
- 首轮只读收集器因字体ZIP路径URL编码匹配失败，修正收集器后完整重跑通过；见collector-history.md，非产品失败，无额外重编/签名。

## 保留真实范围

当前仅完成文档/静态网站/本地包与签名检查，不是TestFlight或Play接收/分发/真机通过。需要本人集中处理的仍是实际目标年龄、测试国家/地区与私有账号名单/手机条件；两组图像权属依据；适用账号/出口/App Signing等本人声明与私有审核联系。密钥、主体、公开邮箱和Pages批准/部署不再列为待办。

真实邮箱收件、正式手机安装/升级/存档/链接打开、生产服务送达、最低OS/16KB/性能/屏幕朗读/声音触觉仍未验。移动浏览只静态窄屏检查。已有受限采集不换工具/路径/委派，用户F9及窗口、普通库/FirebaseQA/原件/旧冻结包未操作。

一次fresh作者终审Critical0/Important0/Minor2，已完成终审记录和事实引用收尾，详BR06/author-final-review.md；未再重建/重签/复审。AGENTS.md同步当前版本、真实站点和新增授权，历史BR01/04仅为旧批状态。主仓未stage/commit/push，计划/tracking/独立review归架构；旧motion-polish和后台emulator日志不夹带。CLI释放状态见共享ui-transition-handoff.md最后条目。
