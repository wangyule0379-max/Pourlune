# BR05 独立验收：上传密钥与本地签名通过

2026-10-23 Asia/Taipei。用户明确授权原开发代建独立Android upload key与本地签名，无需等待本人输入密码。本报告不以作者自查替代架构复验。03:35:49Z原开发明确释放CLI、无在途命令，架构随后执行只读Java核验；没有重建、重签或再生成密钥。

**结论：BR05本地资产与签名范围通过，BR-B02本地项关闭。** 正式包为com.pourlune.app / 0.5.0+5，upload-signed AAB SHA256 `5016d22d030414dfbf3c9a84f59327badddb3d82cac1719df36c967e97593caa`。该结果不是Play上传处理、最终APK签名、安装或完整封测就绪。

|项目|架构实际独立验证|边界|
|---|---|---|
|BR05-1资产身份|真实keytool读取指定alias，PrivateKeyEntry、RSA3072、SHA256withRSA、非debug、公开pin一致且当前有效，到期2054-03-10T03:20:15Z。|一次创建、最初不存在及48字节CSPRNG生成历史来自作者执行记录；架构不声称独立观察创建时随机源或历史进程。|
|BR05-2保密|主资产及恢复文件均当前用户拥有、0600且仓库外，主目录/恢复目录及父恢复目录0700且非symlink；20公开证据/候选元数据文件不含实际口令。Java以:file参数读取，不回显原始命令输出/秘密内容。|扫描仅声明明确文件范围，不夸大为全主机历史无泄露；秘密与口令摘要不写证据。|
|BR05-3恢复|独立私下比较主key/口令与恢复副本字节相等，仅记录布尔结果。|同一Mac的副本，不是异机灾备；未验证外部恢复。|
|BR05-4派生|签名包/unsigned副本及原unsigned哈希、原sources清单及当前签名工具哈希匹配；旧iOS IPA保持原SHA。|无新native编译，原App来源394项仍为历史冻结，不冒充当前全工程重建。|
|BR05-5真实签名|5个真实只读Java命令全部exit0：alias检查、带指定keystore/alias的jarsigner strict、AAB公开证书pin、bundletool validate及manifest。571个非META-INF payload一致，无ZIP重名且CRC通过；136资源/90题、mapping+9原生符号一致，正式ID/版本/target36/显示名正确。|strict使用已授权本机keystore信任该自签证书；不把它当公开CA认证。Play最终app-signing证书、16KB实际设备运行、生产SDK/手机体验未验。|
|BR05-6交付|18作者范围文件SHA匹配，审阅代码工具（未改）与交付/恢复说明；保留首次只读collector字段错误记录，其修正未引起重建/重签。|无生产代码/配置/资源/锁修改，不重复旧Flutter/CI；本次提交仅非秘密文档与验证证据。|

独立脚本：[verify_independent.py](beta-readiness-BR05-evidence/verify_independent.py)；[完整运行结果](beta-readiness-BR05-evidence/independent-final.json)。脚本仅读指定Pourlune资产以核验，不创建key、不签名、不安装、不上传；私密读取用于相等/泄露布尔检查及Java解锁，不输出密码、私钥或其摘要。

公开upload证书SHA256 `E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2`；候选定位见[BR05交付](../deliveries/beta-readiness-BR05.md)。真实key留在仓库外且不应再次生成/覆盖/重置。无用户手动输入密码前置。

网站/邮箱/经营主体与可履行政策、持有人声明/受众/地区/图像权属、具体商店分发及生产运行授权仍未齐；公共目的地仍空，external_store_gates_verified=false。当前已授权可独立完成项已收束，暂停无效轮询；输入/授权到位再由原开发继续、架构复验。签名不自动解决这些事实。F9及窗口、旧库和其他产品均未操作，无受限采集重试。架构只读命令已结束，CLI释放。
