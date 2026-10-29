# Android 0.5.0(19) 签名包独立审查

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
