# BR05 独立Android上传密钥及真实本地AAB签名

2026-10-23（Asia/Taipei）。用户最新明确授权代建Pourlune upload key、生成并保存随机口令、完成本地签名；这次授权取代BR04仅本人交互/不代建的历史限定。已完成实际创建、同机恢复副本及真实签名，不需要用户输入密码或手动备份后才继续。原开发不stage/commit/push，架构独立验收。

## 六项完成范围

|项|实际执行|边界|
|---|---|---|
|BR05-1 指定资产|只检查/操作/Users/wangyule/.local/share/pourlune-signing；初始不存在，PKCS12新建一次，alias pourlune-upload，RSA3072/SHA256withRSA/10000天；实际PrivateKeyEntry、当前有效、非debug|未扫描/读取/复用FishPilot资产；未覆盖、重置或重复创建key，不操作Play App Signing托管key/条款|
|BR05-2 随机口令|系统CSPRNG48随机字节编码64字符ASCII，直接写仓库外0600文件；目录0700。创建使用O_EXCL/O_NOFOLLOW，Java全部:file参数，无argv实值/环境/回显或秘密日志|口令和私钥不入证据/Git/候选manifest，不展示内容；creation-state记录一次尝试防盲目重建|
|BR05-3 恢复副本|同机受限recovery/BR05-20261023保留keystore与口令文件，逐字节相等、目录0700/文件0600已实核|这是同一Mac的本地恢复副本，不能抵御整机/存储丢失，不是异机灾备；今后可由本人按安全流程另存，不阻塞本批|
|BR05-4 新签名派生|在全新ignored目录android-br05-sign-1复制已验unsigned及其原始sources.json，再由已独立验收android_signing模块真实签名新副本|没有不必要的Flutter/SDK重编，没有样例URL/邮箱；仍prod compile-only、adsdisabled、采集默认off。旧final3未改|
|BR05-5 实际验证|4个真实Java进程：list alias、JAR signing、strict verify、最终JAR证书读取均exit0；最终pin相同，非META-INF571条payload一致；bundletool3命令exit0，136资源含90题、mapping+9原生符号全部一致|不是命令替身；不是Play最终APK app-signing、手机安装、16KB/32位运行、控制台收件或商店处理通过|
|BR05-6 交付|公开证书/定位/有效期、实际命令状态、新候选/来源/hash、恢复与保密核验、可复用公开包检查齐备；结束明确释放CLI|等待架构独立验收，未代签法律、公开网站、上传/审核/开轨道/邀请或运行生产|

## 明确指定的真实候选

- 文件：`build/beta-candidates/0.5.0-5/android-br05-sign-1/Pourlune-0.5.0-5-upload-signed.aab`，**106207640 bytes**。
- SHA256：`5016d22d030414dfbf3c9a84f59327badddb3d82cac1719df36c967e97593caa`。
- 包名`com.pourlune.app`、显示名Pourlune、版本`0.5.0`/code`5`、min24/target36。实际JAR签名及当前pin校验通过，元数据`external_store_gates_verified=false`，公共目的地仍空/ready=false，不假称整体可提交。
- 原unsigned SHA256 `ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90`，旧final3与新目录输入副本均保持一致。同目录保留candidate.json、signing.json、signature-check.log、sources.json。
- 公共证书SHA256：`E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2`；alias `pourlune-upload`，当前有效，实际到期UTC2054-03-10T03:20:15。证书是独立upload用途，不把它当Play最终安装证书。

本批是签名派生，没有重新编译。原App payload仍准确对应历史394项sources.json和原构建基线0727f9c；签名工具为本批HEAD4dc4bd5及工具SHA，详[新候选索引](../evidence/beta-readiness/BR05/signed-candidate.json)。不能声称当前工具源码与旧394全部相同。版本5从未在本任务上传；签名动作本身不虚构新native build。最终URL/邮箱/功能配置到位后如改二进制，按平台现有构建号、新目录、新来源/符号及定向复验重建，不原位覆盖本批。

## 非秘密证据与恢复定位

[初始指定路径检查](../evidence/beta-readiness/BR05/preflight.json)、[公开key元数据](../evidence/beta-readiness/BR05/upload-key-public.json)、[4真实签名命令状态](../evidence/beta-readiness/BR05/real-signing-commands.json)、[包/资源/符号结果](../evidence/beta-readiness/BR05/artifact-verification.json)、[恢复/权限/保密检查](../evidence/beta-readiness/BR05/recovery-and-secrecy-check.json)。只保留公开证书信息、权限/比较布尔结果和定位路径，不存口令内容、口令hash或私钥字节。密码只经受限本地文件交给Java。

本机位置：`/Users/wangyule/.local/share/pourlune-signing/`，主keystore为pourlune-upload.p12，口令在同目录受限文件，恢复副本在recovery/BR05-20261023。不要将这些文件复制进仓库、公开交付ZIP或聊天；不更改/重置这把key。架构可用同一授权本地签名路径核验，公开证书可从signed AAB直接读取。工具本身仍不会自动生成key；本批创建是明确授权的一次性操作，不扩大为以后遇缺key就自动代建。

[公开候选检查脚本](../evidence/beta-readiness/BR05/verify-signed-candidate.py)不读取credentials、不签名/安装，只检查signed/unsigned/资源/符号并写本证据目录。初次结果收集器误用len(function)，在所有前置检查后报TypeError；保留[原始失败说明](../evidence/beta-readiness/BR05/collector-failure.log)，修正的是证据汇总字段，不是产品/签名缺陷。没有第二次生成密钥或重签名；纠正后只读检查成功。

## 剩余状态

BR-B02本地upload key与真实签名部分已解决，不再要求本人先创建或输入密码。仍待网页/邮箱/主体与可履行政策、法律声明/受众/地区/商业权属、明确生产运行及具体平台分发授权。USB仍不作为上传前一律门槛，手机实测按TestFlight/Play后续路径；未分发/未测项目继续未验。新包不是已上线closed，不把本机恢复副本说成异机备份。

本批无生产工具/App/core/native/assets/SDK/锁变更，未全量重跑旧Flutter/CI或查BR04终态CI；实际Java创建/签名/包核验即本次必要检查。iOS冻结IPA未动。F9及其窗口、普通/旧QA数据库完全不操作，无截图/录屏/录音重试或绕过。独立验收及精准提交由架构完成。


一次fresh终审Critical0/Important0/Minor0，独立公开包/证书/资源/来源及bundletool通过；审查不读取秘密，未将公开验签混作带keystore的strict重验。全部未判断范围及代价见[终审记录](../evidence/beta-readiness/BR05/author-final-review.md)。无修复pass/复审，架构独立验收仍待进行，CLI收尾于审查后实际追加。
