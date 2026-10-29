# Android 0.5.0(19) 签名包独立审查

最新结论（2026-10-29 16:15 台北）：**R3 静态签名包及已完成 Android QA/后台证据独立复核通过；仍未批准上传。** 只剩当前已排队的修复后真实 release 启动、合成旧库实际操作，以及 Play 声明/提交回读。远端 Mac 再次锁屏，Computer 已一次请求解锁，其他聊天不重复询问。下文 AAB1/R2 为历史结论，不能上传旧包。

2026-10-29。结论：**来源、负载和签名检查通过；NoAdID 权限补漏须重建，当前包不批准上传。** Android 实际运行及 Play 声明交付仍待完成。

审查对象为 `build/package-review/0.5.0-19/android-alpha-gm020-1/Pourlune-0.5.0-19-upload-signed.aab`，来源 `04f175503681e4452231731ea353a33b13f711f8`。包大小 136231971 字节，SHA-256 `16fc6e61270dcb6ba9cc449bad1b32d520c5cdfd76bbd01400c3b3edefa5175b`。

总控直接读取原包及独立镜像，运行只读 ZIP/ELF、bundletool、签名验证；没有重建、安装、操作设备、读取私钥或再次查询旧终态 CI。

- 两目录 9 个冻结文件逐一哈希一致；563 个构建输入与当前文件一致，其中 Git 文件与精确提交逐字节一致。相对已验 `eb48e7d`，运行输入仅新增两个已由电脑操作聊天回读确认的 Android 广告单元及配置说明；应用、原生、核心、工具及锁文件未变。沿用已完成的 CI 40718567516，不重跑无差额全套。
- GameMunchies 0.2.0 私有固定包 SHA-256 `70effde1c9150b416b34f4dd4b6d95912ef836b5f429c98ea5a8cbf98fd0c167` 再核一致，7 个解包文件与固定清单一致。
- 实际 AAB 为 `com.pourlune.app`、0.5.0(19)、minSDK 24、targetSDK 36、非 debuggable。147 项运行资源（含 90 题）与冻结源一致；签名前后除签名元数据外全部负载一致。
- 直接从 AAB 提取公开证书，核对既有 BR05 pin，再以临时仅含该公开证书的信任库运行 `jarsigner -verify -strict`，成功。未访问签名私钥及密码。
- 三 ABI 的实际 AOT 包含 `https://api.gamemunchies.com`、既有 production gameId 及正确 Android 正式广告单元；所查旧后台地址、测试 gameId、QA 入口标记未出现。实际 DEX 无 integration_test 插件类及通道标记。
- bundletool 对实际包 validate、manifest、config 检查成功，PAGE_ALIGNMENT_16K；12 个原生 ELF 的全部 PT_LOAD 对齐和文件/虚拟地址关系满足 16KB 静态条件。这不是实机 16KB 运行验收。
- 实际 manifest 无 `com.google.android.gms.permission.AD_ID`，Analytics ad-ID collection 为 false；Analytics/Crash 初始采集及相关广告存储/用户数据/个性化默认关闭。存在 Privacy Sandbox 和其他服务权限，不能据此宣称广告 SDK 不处理任何标识符。

开发在本轮另指出 `android.permission.ACCESS_ADSERVICES_AD_ID` 仍存在。总控核对 [Android 官方权限定义](https://developer.android.com/reference/android/adservices/common/AdServicesPermissions)，它属于 Advertising ID API 的访问权限，并非可忽略的普通服务权限。仅删除 GMS 那条权限不足以支持完整的 NoAdID 结论。开发按既有策略做 Android 最小差额移除及最终 manifest 双权限守卫，新目录重新构建；当前 AAB1 保留不上传。独立机器记录中的负载/来源/签名通过事实继续有效，但不是隐私声明通过。新包只补源码差额、最终包及相关验证，不重做已验 iOS 或无差额全套。

本地 `docs/support/pages-site/privacy.html` 的本次差额已读审：明确 Android 13 为旧关闭广告版本、iOS/Android 19 使用 SDK 0.2.0 与正式单元，保留非个性化、统计选择和真实奖励说明，措辞使用“when made available”，没有把未提交 Android 19 写成已上线。版本说明差额可纳入本次发布；广告 ID 文案须与上述修复后的实际 manifest 一致。网站实际发布回读、Play Contains ads/Data safety 与其他声明仍由电脑操作聊天完成并留回执。

待交付的是 Android 官方测试广告的真实回调/奖励、统计撤回及冷却保存、正常入口与后端核对、非空旧版存档升级结果，以及 Play 最新声明。已有 iOS 结果不替代这些 Android 结果；AdMob 商业填充仍受账号与应用审核限制。GUI 安装方法失败是工具操作阻断，不等于 App 本身失败；保持专用设备及存档，交由开发与电脑操作聊天协调无损方法。

独立机器记录：`docs/development/evidence/google-play-latest-20261029/package-independent.json`；实际 bundletool/签名输出：同目录 `parent-package/`。上传后还需分别回读上传处理、审核/轨道发布、加入安装入口；不改动 iOS 19 的既有审核。

## R2 差额独立复核（2026-10-29 11:32 台北）

**R2 签名包检查通过；仍待 Android 实际运行和 Play 声明完成，尚不批准上传。** 新源 `9eab3b62940146dbc8cb9fb1a80a9e5b37cc8906`，候选 `android-alpha-gm020-2`，AAB 136231956 字节，SHA-256 `fbe5f16b7bf7a3d5432e2b58a22143d38cac393da6a64a742b71fa8d3518167f`。

独立核对 9 个冻结文件、563 个源输入和精确 Git 版本。相对 AAB1，603 个非签名负载项中只有实际 AndroidManifest.xml 改变；直接解析新旧 manifest 后确认语义差额只有删除 `ACCESS_ADSERVICES_AD_ID`。两种广告 ID 权限现均不存在，其余身份、广告 AppID、初始采集状态与权限不变。实际新包 bundletool validate/config 及公开证书 pin、严格签名验证通过。AOT、DEX、原生库、资源、SDK 和锁文件逐字节不变，因此复用已完成的这部分独立验收，不重复全量工具链。

新精确 CI 40808115652 的已保存终态回执对应同一源，两个 job success；87 工具、47 核心、491 应用通过及 1 个原有夹具跳过为开发保存的 CI 记录，本轮未重查远端或重跑测试。机器差额报告为 `evidence/google-play-latest-20261029/repair-r2/package-independent.json`，实际输出在 `repair-r2/parent-package/`。

Data safety 拟定文件已对照 [Google Mobile Ads 25.5.0 官方披露](https://developers.google.com/admob/android/privacy/play-data-disclosure)及 [Firebase Android 披露](https://firebase.google.com/docs/android/play-data-disclosure)读审：广告开启后位置、互动、诊断及其它 ID 的收集/分享须包含广告用途，不能沿用旧 13 的全部不分享，不能把 Analytics 选择当成所有广告 SDK 的开关。Crashlytics 的可选崩溃上报与广告性能诊断分开；无 AAID 不代表无其它 ID。现有国家配置也要计入 Remote Config 对 App functionality 的用途。最终以当前表单逐项保存并回读的结果为准，草案不是商店完成回执。

R2 原生公开摘要已读：第一次恢复 3/3 被服务接收，包含原离线 2 条及新活跃 1 条；重试混合批 7 条仅新增接受 4 条，摘要记录原事件 ID 和首次时间保留。这支持该批原事件去重，不能写成纯 0/7，后台记录仍待独立回读。中断的真实激励广告只有 impression/shown，SQLite 无确认奖励和 entitlement；没有把进入外部 Play 页面或关闭当作获奖。旧宿主恢复后的 extra 状态差异未归因、未覆盖，R2 独立命名库与旧证据分开。成功奖励、撤回、持久冷却、正常 main 和真实旧存档升级仍需交付。

远端 Mac 锁屏已提出本人解锁请求；两聊天不得再重复提问。总控本轮只做离线包和文档复核，没有操作桌面或设备。

## R3 与 Android 最终证据差额复核（2026-10-29 16:15 台北）

修复源 `de5a5950b6e86c50c24e681add0b43e079bc4145`，候选 `android-alpha-gm020-3`，签名 AAB 136310168 字节，SHA-256 `bcfa0483c086c71161653829067d12e42ee30f275dcc4699bd7c2ca0ee19c06d`。总控独立读取实际包与镜像，9 文件及 570 输入均吻合。严格公开证书签名验证、既有 BR05 pin 和 bundletool validate 通过，没有读取私钥或运行新的构建。

实际原13在创建 `InitializationProvider`/`WorkDatabase` 时崩溃，尚未生成非空玩法存档。R2 包也受同一 R8 反射入口缺失影响，因此先前静态通过不再作为可上传结论。最小 keep 规则只保留 WorkDatabase_Impl 和 InputMerger 的 public 无参构造器。总控另写原始 DEX 结构解析，独立于开发的 apkanalyzer 门槛确认：旧 R2 三个类都存在但缺对应构造器，R3 三个类都有 public 无参且具实际代码的构造器。不升级依赖、不关闭 R8、不用宽泛 keep 回避原因。

R2→R3 非签名载荷仅 DEX、映射、R8 元数据及两项 baseline profile 变化；manifest、三 ABI Dart AOT、全部 native 库和资源逐字节相同，复用已接受的双广告 ID 权限排除、身份、同意默认、SDK、90 题与16KB静态检查。生产 AOT 没有夹具或 QA 入口变化。由同一 AAB 派生的真实 release APK SHA-256 `3859b4f2e27786e380bcd0acf4033c4c4267b01da31006085a3e6f0f98bdf12a`，其168项 DEX/native/assets 与 AAB 相同；它使用上传证书，不能冒称 Play App Signing 交付或物理手机升级。

已保存的新精确 CI `40837181164` 终态回执对应同一源，两 job success（工具87、核心47、应用492及原有1项 opt-in 跳过，含新增 minified AAB/构造器检查）。父未重查远端终态或重跑该套检查。完整机器核包记录为 `evidence/google-play-latest-20261029/release-startup/candidate3-package-independent.json`。

总控另对已导出的真实专用 Android 数据做只读独立检查，记录在 `native-final-independent.py/json`，没有重做设备操作：

- 获奖后、正常 App 重启、统计撤回后的完整 active payload、两次奖励 attempt 和唯一 entitlement 逐行一致。只有真实确认的新 attempt 为 done/confirmed1，旧中断请求没有补奖；同实例五瓶、待处理0。其他五个已有 SQLite 原字节保留。
- 独立解析 Android DataStore preferences protobuf，确认同一安装标识、空队列及持久 lastShownAt；正常 main 后仍保留该冷却记录。两个统计 Off 进程的实际诊断显示广告许可 true、插屏 ready、冷却142/73秒、已持久保存；均无 SDK POST 或发送批文件。实际展示与点击阻止过程来自 Computer 的观察，父通过导出记录核对，未声称自己操作设备或看过每张新图。
- 获奖进程真实 ACK 合计16/16；重启进程新增仅 active 一条，没有新 round_start。早期离线恢复 ACK 为3/3，包含重传的下一批为4/7；保存的运行断言确认稳定 ID/首次时间及旧事件去重。现存 last-batch 文件不能独立重建每一条更早的发送载荷，保留这一证据边界，不写成0/7或全量逐条重新核验。
- 正常 main 独立库 integrity/schema5 通过。父按原题的合法倒水规则独立重放 Main1 前两步和 Daily002 的1→5，逐格对应最终棋盘；分别2步/rev4和1步/rev1。最终两项隐私 false、无奖励 attempt/权益，库 SHA 与交付一致。初始选择、Hint/Undo、真正前后台及开局数不增加由 Computer 的正常 UI 观察和导出共同支持，不拿早先 IDE 重新部署当成真正前后台。
- 后台归档为 Computer 在既有登录浏览器读取的真实 JSON：test/android 当日总览1活跃、2开局、4曝光；版本19漏斗机会5、privacy阻断1、加载16/成功16、展示尝试4/曝光4、奖励2、乱序0。包含同日其他 QA，且总览不受版本筛选，不能全部归因本次单一流程。production 同日 Android/version19 过滤 hasData=false，没有据此宣称全局正式统计或收入为0。

上述 Android 真实测试广告、奖励幂等、统计/配置解耦、冷却重启及正常入口证据可复用，不再重复已完成流程。它们使用官方测试广告的 debug QA，仍不能代替 R3 的真实 minified 启动，也不能证明商业填充。

原13不修补、不重制为假原版。采用原13精确源码生成的合成非空存档可验证旧契约兼容；生成器与真实 SQLite 测试已通过，待已排队的隔离 QA 正常入口操作/仅 App 重启。该结果必须标为合成旧库兼容，不称“原发行13非空现场升级”。另一条已排队的正式 R3 APK 路径直接更新当前空状态13并验收启动/普通动作/仅 App 重启及当前 PID Logcat。两者均等已请求的 Mac 解锁，无需再建候选或扩大验证矩阵。

这两个有明确目的的设备结果完成后再按既有授权更新 Play 声明并上传当前 R3 到原 Alpha，分别核上传处理、送审/轨道状态和加入安装入口；本轮不触碰 iOS19、F9、保护存档或新增测试员。

## 用户催促后的收尾范围收敛

新一轮 Computer 已实际重新进入 Android Studio 和兼容窗口，旧锁屏状态解除。合成原13夹具已有来源核验及当前真实 SQLite 撤销/重开/动作/保存再打开检查；其额外 GUI 若仍被工具窗口映射阻断，仅记实际 UI 未验，不再作为单独发布门槛，也绝不改称原发行13非空现场升级。优先完成最终R3真实 minified 启动、仅 App 重启和当前进程日志，以直接验证本轮实际启动崩溃修复；通过后继续原 Alpha 声明与上传，不再重复已验 SDK 和数据流程。

## R3 实际运行结果接受与 Alpha 放行

Computer 已实际完成专用5554上的 minified R3安装/首次启动、Main1基本操作、仅App停止重开及Continue原局面恢复；下一步2→1结果正确。当前重启PID13997可见日志没有FATAL，Firebase初始化成功、采集关闭。总控结合已独立核定的同字节AAB/APK及该明确运行回执，接受本轮R8修复，放行现有Alpha封测更新，不再因报告排版重复设备测试。GUI由Computer执行，父没有冒称亲自点击或看过所有新图。详release-startup/r3-runtime-acceptance.json。

保留具体限制：合成旧库UI未完成，不称原发行13非空现场升级；UMP该Android AppID未配置表单、测试标记设备广告load3，不称商业填充通过。由Computer核后台当前消息关联并交开发判断，不通过客户端绕过隐私门控。该远程配置/填充状态不阻止本轮受限Alpha提交，不扩成公开发行或iOS19重新提交。商店声明按已经独立读审的data-safety-plan逐项更新并实际回读。

## Play 收集与分享用途拆分复核

实际表单将两种用途分开，开发据此把 data-safety-plan 更新为 collection_purposes 与 sharing_purposes。父再次直接读取 [Google Mobile Ads 25.5.0 官方披露](https://developers.google.com/admob/android/privacy/play-data-disclosure)（页面更新2026-10-28）及新JSON，确认四类广告数据分享对应广告、分析、防欺诈安全合规；不把既有 Remote Config/Firebase 的 App functionality 收集用途平移到广告分享用途。位置/设备ID收集保留该功能用途，Crash仍仅可选收集分析、不分享。此次是已核定事实在实际表单中的准确拆分，不改包、SDK、用户选择或Alpha放行；Computer已获完整逐项答案，继续保存并回读实际平台结果。

## Alpha19 正式送审回执

Computer在确认Network已能记录普通页面请求后，仅作一次有记录的正常界面提交，观察 publishing:sendChangesToRe… XHR HTTP200。平台随后明确显示“正在审核中的更改”“您的更改目前正在接受审核”，包含封闭式测试Alpha0.5.0(19)和应用内容。提交活动新增ID3，2026-10-29 17:32台北，状态审核中；版本、广告声明、数据安全三项均在审核。父据这些明确回读确认本次正式送审完成；此前三次无回执原因仍未知，不猜测权限/会话故障。未读取认证头、未导HAR、未脚本代发。当前只是审核中，不是已批准或已可安装；既有iOS19不变。机器记录parent-formal-submission-acceptance.json。

## 实际测试范围与本人确认

最终只读回读为美国及巴基斯坦，勾选Pourlune Beta（1人）与“10月29test”（51人），不是旧记录的仅美国/本人。Computer未在本轮改名单或国家，不能推定设置来源；名单人数不是已加入/已安装人数。因范围当时未经核，先可逆开启自管发布保护，ID3和旧13不变。本人随后对上述精确范围直接回复“是，19版按当前国家和名单开放”。现范围已确认，已指示Computer仅对本次Alpha19/广告/数据安全三项恢复此前自动发布，解除临时保护，不增删名单、国家或邀请；审核/可安装仍按真实平台状态分别回读。
