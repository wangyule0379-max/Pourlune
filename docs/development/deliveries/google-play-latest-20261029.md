# Google Play 最新 Alpha 封测更新（进行中）

2026-10-29，Asia/Taipei。当前最高已上传仍为 Alpha 0.5.0(13)，19在本轮只读控制台回读时可用。新版19已签名并完成作者包核及新精确CI；Android原生缺口、旧13升级和商店声明仍在验证，尚未上传或提交。不得以此文档或旧13终态声称新版已分发。iOS19既有Self测试与正式等待审核状态不改。

## 新包与来源

生产代码基线eb48e7d，最新Android修复源`9eab3b62940146dbc8cb9fb1a80a9e5b37cc8906`。沿用SDK0.2.0固定私有源6dac3537及7文件指纹，不降级SDK、不重登记gameId。主线题库/5色、R03源瓶运动、原静态布局/接水瓶、音频、奖励/存档事务及统计默认off保持。原Android正式AppID和两个既有正式单元经控制台再次确认后填入公开登记；QA继续使用独立test游戏和官方sample单元。

AAB1保留为未上传候选。最终manifest审计发现它只去掉GMS广告ID权限，却仍有平台`ACCESS_ADSERVICES_AD_ID`能力。Android官方文档确认这是另一条广告ID访问通路；没有据此声称本轮实际读取或发送过该ID。最小修复同时移除两条权限，最终manifest guard覆盖两者；NPA、PG上限、其它权限、游戏ID和同意默认不变。新生产权限反例先红后绿，7项聚焦检查通过。

新签名候选：`build/beta-candidates/0.5.0-19/android-alpha-gm020-2/Pourlune-0.5.0-19-upload-signed.aab`，136231956字节，SHA256 `fbe5f16b7bf7a3d5432e2b58a22143d38cac393da6a64a742b71fa8d3518167f`。只读同字节9文件镜像为`build/package-review/0.5.0-19/android-alpha-gm020-2`。复用原BR05上传key及公开pin，不创建/重置key，秘密不进入仓库或日志。

作者离线核563源输入、147包内资源及90题、三ABI生产AOT的正式API/GMID/Android单元、12个ELF的16KB载入对齐、bundletool校验与16KB打包配置、无原生integration_test类/通道、strict签名和pin。包为com.pourlune.app/0.5.0(19)，min24/target36，debuggable=false；实际无GMS或平台Advertising-ID权限，Analytics广告ID采集及原生采集默认false。AAB1到AAB2的非签名ZIP载荷仅`base/manifest/AndroidManifest.xml`变化，其余Dart AOT、dex、原生库、资源均逐字节相同。静态16KB检查不是16KB物理设备运行证明。

新精确CI `40808115652`，head同9eab3b6，两job成功；工具87/核心47/应用491通过、1个已有opt-in夹具跳过，格式与分析通过，APK和iOS simulator编译成功。固定SDK V2真实恢复7文件。未重跑已完成的40715422974/40718567516。CI与实际包是独立证据，未用编译替代Android设备验收。详同名evidence目录的`no-id-ci-final.json`和`repair-r2/`。

## Android 实际状态与限制

设备操作全由既有Use Computer执行。专用AVD`Pourlune GM QA 20261028`/Android16，实际运行时回读emulator-5554；不根据旧编号猜设备，自动目标跳到FishPilot时没有Run。原QA数据先经Device Explorer导出40文件，0700目录/0600文件私密保存，未用allowBackup=false作清库理由。

APK分析项目缺SDK的原因是模块没有SDK引用且项目只指Java21。只在新ignored标准APK项目中显式引用既有Android36 SDK，零编译脚本、clearStorage=false，未改全局SDK或App生产代码。GUI实际安装成功。旧权限变体APK1显示官方测试激励、Reward granted、extraBottle=true/pending0及冷却阻止；这些仅是该次界面回执。

随后专用AVD失联、启动超时。仅精确核对PID/qemu/该AVD路径后通过活动监视器普通Quit，再启动该AVD；F9及其他设备不动。恢复后extraBottle=false、队列状态变化，与之前奖励截图不一致。导出的前后gm_020库均schema5、integrity ok、相同原实例/棋盘，均无奖励回执；before本来是在激励前导出，不能以恢复它修补后发奖励。快照页显示Quickboot自动快照，但尚不足以证明回退原因；没有加载、删除快照或恢复库。该次奖励跨重启持久化未通过，不把它写成App故障已确认或SDK持久化成功。

r2 APK使用同身份/同debug签名、官方测试广告、无两种广告ID权限及独立`gm_020_recovery_20261028.sqlite`，保留旧库。待补受控离线/丢ACK/正常App重开去重、真实无ID广告、SQLite奖励即时回执、冷却/撤回、正常main及后台test/android回读。普通main使用独立gm_020_normal_20261028.sqlite，保持默认统计off；不得用iOS的成功补这些Android缺口。

## 商店与隐私差额

旧13的“不包含广告”须更新，不能沿用。新版实际阻断两条Advertising-ID权限后可按最终包处理AAID声明，但其它SDK标识符仍需披露。既有四类数据中的位置、互动、崩溃/诊断和设备或其它ID逐项核，广告SDK处理不因Analytics关闭而全部可选。拟定字段与官方来源在`data-safety-plan.json`，尚未保存为商店终态。

Play Policy Insights完成7目标/2批critic静态审计；报告仅2项建议。其Flutter动态包名识别为pourlune_dev并抓到404，不能据此认定应用未发布或无声明，也不采用其绿色标题代替实际manifest和真实控制台核对。原报告留在隔离scratch，范围说明在`policy-audit-scope.json`。

支持站隐私HTML已发布最小版本说明及两条广告ID权限的准确文案：支持仓库提交e3d03704、Pages40812749349成功，HTTPS200字节与源一致，SHA912721d14190cd8bf03bd4ce6f3ffe07d44bb790266777ec6ac64c4ff9466e46。未改iOS商店提交。真实13升级准备从原已发行13 AAB派生同上传证书APK，旧AAB SHA3383d698…匹配；这不等于Play App Signing交付签名的手机升级，实际安装及存档回读尚待。

后续须完成真实Android门槛、总控独立核新包、声明和站点一致，再由Use Computer复核19占用并上传/提交现有Alpha封测，回读处理/审核/安装入口。不另开internal或公开production，不新增测试员或重复邀请。物理手机升级、硬件音触觉、真人首玩和正式广告填充保持未验；AdMob应用待审/投放受限不冒称商业readiness通过。

## 当前唯一持有人阻断

Computer导出r2数据时远端Mac锁屏，正常自动解锁失败。已有本人解锁请求，不再重复问，不绕过登录。锁屏前已留42项r2私密原件：真实首批3/3，加入4条新加载记录后的重传4/7，原3不重复、原ID/首次时间检查true、最终队列0；不能写成纯0/7。实际无ID测试广告完成加载与曝光，但误入外部Play登录后未收到奖励确认；SQLite只有open/confirmed0尝试、1次rewarded shown、无entitlement/extra。证据是中断状态，不冒称完成奖励或跨重启持久通过。已准备只启动已有QA的NoDeploy配置、正常main及真实13/最终19同上传证书APK标准GUI项目，均未借锁屏进行设备操作。解锁后继续剩余实际门槛，再提交Alpha。
