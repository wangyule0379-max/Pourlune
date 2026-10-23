# BR04 独立验收：工程和准备资料通过，真实签名/发布待条件

2026-10-23 Asia/Taipei。架构按BR04八工作包独立读源码与差异、测试、交付/签名步骤/公开站点/逐字段资料/远端路线；确认原开发01:55:52Z明确释放CLI且无在途命令。本轮未使用作者终审替代独立验收。

结论：**接受本批Python构建门控及资料准备**。真实Android签名、新配置原生候选、网站公开及商店分发均未执行。支持目的地格式ready不是已批准、可达或商店就绪；signed_for_upload仅标技术签名，external_store_gates_verified仍为false。

|任务|实际独立验证|边界|
|---|---|---|
|BR04-1|审阅public_destinations、beta_build、firebase_build；46项独立Python测试包含目的地参数经definefile传输、恶意/占位输入拒绝、caller覆盖拦截及原prod身份/主入口保护。额外真实CLI不安全URL拒绝exit1且无输出目录。|域名/邮箱暂无；没有新原生构建或真实链接点击。|
|BR04-2|读签名源码：仓库外受限文件、alias/证书pin/有效期/debug检查；密码通过Java:file选项，外部错误内容不回显；生成新副本，strict验证、实际签名证书pin、非META-INF payload比对，失败清理新副本。单元覆盖失败/篡改/密码不进入日志；额外真实CLI部分参数及缺失资产各拒绝，无构建。|密码非实值；成功路径为明确命令替身，不是密码解锁或真实Java签名通过。真实key后仍要验证新AAB/证书和Play安装签名。|
|BR04-3|逐行审查本人key命令，创建拒绝覆盖、仓库外权限、交互密码、公开指纹与备份步骤；回读Oracle JDK21 keytool/jarsigner官方语法。|架构未执行genkeypair/创建密码文件/读取任何真实key。现有本机JDK版本证据为作者只读结果。|
|BR04-4|独立ZIP CRC、哈希、目录/成员白名单、逐文件字节比对：仅3文件、两HTML均DRAFT/noindex，无script/iframe/form/img。内容保留主体/联系方式等未知，区分App SDK与GitHub主机IP日志。|只验资料内容与包结构，未浏览器视觉验收或部署，不能作为已上线政策。|
|BR04-5|字段表采用已确认SKU/英语/类别/免费封测/组名；年龄、主体、地区、隐私、出口等保留事实与本人确认栏。|未登录控制台/创建记录/代签/提交声明；不自动勾零数据。|
|BR04-6|路线明确上传前工程与授权分发后真机；内部资格不猜、不扩IAM，Play目标closed。|USB不再为上传前普遍门槛，但未测设备风险仍保留。|
|BR04-7|核查最小试玩/反馈、正式N→N+1保留安装和存档、首包无旧N如实未验、不清数据/不要求USB或私密设备标识。|实际手机安装升级/音触觉/读屏/性能待分发后；生产运行及分发仍需明确范围。|
|BR04-8|独立46/46测试（4.411秒）、3个实际CLI拒绝、36交付范围文件SHA相符、旧IPA/AAB哈希不变；改动范围无App Dart/core/native/assets/依赖锁变化。|不重复既有T/FB/MS原生全套；旧冻结包不代表本次新增工具已重建进候选。|

证据：[Python日志](beta-readiness-BR04-evidence/python-tests.log)、[独立脚本](beta-readiness-BR04-evidence/inspect_independent.py)、[结果](beta-readiness-BR04-evidence/independent-check.json)、[已审来源](beta-readiness-BR04-evidence/accepted-source-hashes.json)。脚本和单元测试仅以非秘密fixture检查命令与失败门控，未生成测试或正式私钥。原作者46通过与独立46通过分开记录。

已验旧IPA `0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5`、AAB `ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90` 不变；新的工具来源有变化，后续实际资料/密钥到位须新目录构建、冻结来源/包/签名/符号，不能复用旧394来源等同当前。

本轮未发现需阻断提交的具体代码缺陷。批准精准提交本批工程/资料及架构证据，不夹带旧未验motion-polish和后台emulator日志。新增工具触发既有CI的Release configuration guards及平台流水线；提交后仅跟踪本次精确SHA，不查旧终态run。CI终态前不暂停有效跟进。

用户F9及窗口、普通b04_review_r2.sqlite/FirebaseQA完全未操作；无Flutter/Dart/SPM/Xcode命令、设备启停或受限采集重试。当前CLI无在途。后续仍由原开发实施、架构验收。只剩真实网站/邮箱/本人签名资产/账号声明和明确分发运行条件时集中处理，不重复要求直连真机。

官方命令依据（本轮回读）：[JDK21 jarsigner](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jarsigner.html)、[JDK21 keytool](https://docs.oracle.com/en/java/javase/21/docs/specs/man/keytool.html)。已有上轮官方Apple/Play/Pages依据见BR04计划；法律答案未由工具推断或代签。
