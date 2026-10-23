# 技术问卷建议：本批直接回答与真正需本人核实

2026-10-23；在BR04/store-fields.md基础补具体建议，不重复账号表。基于BR01/BR05已验build5及本轮BR06真实build6 IPA/signed AAB（SDK/资源沿用，版本与目的地更新）及app/lib/services/{firebase_gateway,service_policy,service_config,google_ads_transport}.dart。尚未运行生产配置，不等于网络观察。商店问题以实际版本措辞为准；以下是开发建议，不代本人签署。

|问项|可由开发直接给出的建议|依据与剩余核实|
|---|---|---|
|是否登录/受限访问|Apple Sign-in required=No；Play All functionality available without special access；不用demo凭证|无玩家账号、支付墙、订阅或业务后台。应用内账号删除要求不适用，不能据此删去SDK隐私请求说明|
|是否含广告|针对当前关闭所有广告请求且不展示广告的beta，建议Play Contains ads=No；后续启用广告必须先更新声明|广告SDK/UMP仍嵌入、官方sample AppID仍在，不把未来激励实现冒充当前展示；实际发布包/Play页面问题复核|
|App Privacy / Data safety总体|建议按存在离设备处理准备披露，不能选整体“不收集数据”|prod Firebase配置；RC/Installations独立运行，analytics/crash默认off不足以豁免；缺生产网络验证保留而非填No|
|设备/安装标识|Apple Identifiers→Device ID、Play Device or other IDs：建议纳入RC/Installations，功能用途，不能称完全可选|RC与独立sharing选择无关；安装ID不等于玩家账号。Google服务处理条款和实际配置由持有人核对|
|粗略地区与技术信息|RC的国家/语言/时区、OS/App/SDK版本需披露技术用途；Play Approximate location是否适用按IP/国家推断处理范围核对，保守建议纳入评估|没有GPS/精确位置权限或功能；不勾Precise location。供应商说明country code不自动等于GPS；表单类型映射与控制台实际配置须复核|
|Gameplay analytics|Apple Usage Data→Product Interaction、Identifiers及适用的Coarse Location/Other Diagnostic Data；Play App activity→App interactions、Device or other IDs及适用Approximate location：建议纳入，分析用途，用户可选|手动事件含puzzle/version、局部随机instance/request ID、完成/时长/助手/存档类别；无全盘/email/反馈正文；SDK自动事件/技术数据也需考虑。analytics独立opt-in不等于无需披露|
|Crashlytics|Apple Diagnostics→Crash Data/Other Diagnostic Data及适用Device ID；Play App info and performance→Crash logs/Diagnostics、Device or other IDs：建议纳入，故障排查用途、可选|独立off；native可本地cache，打开后可请求发既有报告；关闭不召回排队/已发送；不能承诺SDK回执或完整抹除|
|关联到用户|不能因为没有账号就统一选Not linked；安装/实例ID与事件或诊断若关联，建议按linked处理，除非能证明上传前去关联且供应商同样保持|纯本地身份不是公开身份，但Apple关联标准包括设备。最终项目级数据关联/导出设置需本人核对|
|Tracking / 数据共享|当前无ATT、无跨App广告追踪功能，建议Apple“用于追踪”No（以供应商配置确认）；Play sharing按服务提供商例外逐项判定，不能把Firebase传输全部直接等同sharing|Analytics广告storage/userdata/personalization均false、iOS noAdID；AdSDK权限存在不证明实际tracking，也不证明沉默。未确认是否另有project级关联/数据分享功能，持有人核实|
|数据目的|RC/installation=App functionality；analytics=Analytics；crashes=App functionality/诊断；没有广告定向、开发者营销、信用评估用途的应用逻辑|不把供应商自身目的省略；依供应商最新说明和实际项目设置复核|
|传输加密|Firebase文档说明其列示数据使用HTTPS；开发建议对当前已知Firebase路径按encrypted in transit准备|非实测TLS成功，不能据此称所有外部邮件/商店供应商均端到端加密；不关闭TLS验证|
|删除/请求入口|无账号；本地Reset删除玩法保留偏好；隐私请求通过获准公开邮箱处理|不要将Reset当服务端删除。邮箱可收件/处理人执行、Firebase保留/删除/国际传输政策需落实后填最终声明|
|收集邮箱/玩家自发反馈|游戏手动telemetry不收email；主动发邮件会使邮箱/正文由邮件供应商和处理人接收，网站政策应说明|不要把支持邮箱地址写成App自动采集玩家email；是否纳入具体商店data标签按其支持请求/可选披露例外核对|
|内容评级技术项|暴力/血腥/性内容/赌博/付费lootbox/聊天/UGC/浏览任意网页/用户间通信均无相应功能；无运行时生成AI|外链仅支持/隐私及用户主动邮件；勿将这些链接误填任意浏览器。按真实美术内容作问卷，最终分级由平台产生|
|目标受众/地区|普通休闲益智建议；不能自动指定18+或儿童标签|这是本人确认实际目标年龄/营销与测试商店地区的唯一剩余产品事实，语言/时区不作推断|
|出口/加密|源码无自定义密码协议或加密产品功能；用系统/供应商TLS和存储，crypto哈希依赖不单独决定分类|建议走标准加密/豁免资格判断路径；不替本人作法律适用声明、不擅写ITSAppUsesNonExemptEncryption=false|

当前包：Android target36/min24，含AD_ID/AdServices等10项manifest权限；iOS最低15、24份SDK隐私清单。权限/manifest是评估依据，不等同最终数据标签或实测。历史SDK清单见BR01/android-native-final.json、ios-native-final.json及BR05/artifact-verification.json；当前build6确切身份/版本/24份隐私清单、资产与新符号见BR06/delivery-checks.json、native-package-checks.json。

官方依据（2026-10-23读取）：[Firebase Android数据说明](https://firebase.google.com/docs/android/play-data-disclosure)、[Apple数据说明](https://firebase.google.com/docs/ios/app-store-data-collection)、[Apple App privacy](https://developer.apple.com/app-store/app-privacy-details/)、[Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)。供应商文档针对其说明的SDK版本；锁定版本见app/pubspec.lock、app/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved及BR01原生inventory，不将最新版文档当本包运行观测。
