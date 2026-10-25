# 应用记录/封测资料逐字段技术依据（不代提交）

2026-10-23。用户已确认：Pourlune / com.pourlune.app、SKU **POURLUNE-IOS-001**、英语、益智游戏、免费封测/广告关闭、组名 **Pourlune Beta**。这些值可用于准备。受众/年龄/地区/主体/trader/export/权属等未确认，不把建议当答案。本批没有登录反复核查、创建重复应用、提交问卷或签署条款；旧账号事实仅继承有日期BR01观察，用户在控制台的新记录由架构回读接续。

## Apple记录与测试资料

|字段|可用事实/草稿|状态／持有人动作|
|---|---|---|
|Platform / Name|iOS / Pourlune|已确认范围；iPad支持与最终设备family对应，不额外创建macOS/tvOS记录|
|Primary language|英语；现有copy为en-US，可用English(U.S.)对照控制台|平台实际选项核对，不能把主语言当国家地区|
|Bundle ID / SKU|com.pourlune.app / POURLUNE-IOS-001|已登记AppID；SKU本轮确认，后续创建前先核对是否已由架构/本人创建，避免重复|
|类别|Games / Puzzle方向|用户确认益智；实际可选类别按App Information核对，不增新功能|
|价格/广告|本次免费封测，adsdisabled|不扩大为未来付费商业模式或App Store价格策略决定|
|Beta group|Pourlune Beta|只确认名称，未创建组/加人；先核实本人已有内部资格，否则走外部Beta审核，不授新IAM|
|Beta description / What to Test|60主线+30每日候选、固定目标标签/空缓冲、免费Hint/Undo/Restart、双槽离线存档、拼片收藏；详BR01英文稿|应在最终包确认后复核；去掉不适用工程标签，不宣称真机性能或服务收件通过|
|Review access|无需游戏账号、密码、购买、业务后台；Start→源瓶/目标→Pause/Home/Daily/Collection|不虚构demo账号；审核联系人姓名/邮箱/电话由本人填真实渠道，不入公共repo|
|Support / Privacy / Feedback|本批新增受控构建输入，网站3文件draft可审|暂无获准公开URL/邮箱/处理人，不填示例/建议地址；需发布与收件/包内点击验证|
|App privacy / tracking|见下方数据技术依据；无ATT提示/此候选不启tracking，no-AdID Analytics不代表所有嵌入SDK零数据|最终数据类别/关联/共享/追踪标签需按SDK及实际配置审核，不自动勾全部不收集|
|Age / countries / trader / content rights|无账号/支付/UGC/赌博等业务功能；图像授权状态仍UNCONFIRMED|数值分级由实际问卷产生；目标年龄、地区、主体/trader、权属由本人确认，不按时区/语言猜国家，不直接指定4+/18+|
|Export compliance|源码使用系统/第三方SDK网络/TLS能力，未增加自定义加密特性；依赖存在crypto哈希包不自动决定分类|完整出口问卷/豁免适用由本人核对；不自动写ITSAppUsesNonExemptEncryption=false或签法律声明|

官方：[创建记录](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)、[内部资格](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/)、[外部测试](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)。TestFlight内部/外部和完整上架资料不是同一套门槛；按真实控制台必填，不凭通用清单增加业务。

## Google Play创建/closed资料

|字段|技术事实／可审稿|状态／持有人动作|
|---|---|---|
|Name / language / type / pricing|Pourlune / 英语(en-US文案) / Game，Puzzle分类方向 / 本轮免费|已确认通用项，不改已发布其他App或承诺永久商业模式|
|Package|com.pourlune.app；BR01查询可用，仅为当时观察|实际记录由本人/架构核对，本批不重复创建|
|Policy / US export / Play App Signing|已有原生/SDK及加密依据，上传key与最终app-signing区分|本人读实际声明/条款，未代签。无key时不勾“已签名验证通过”|
|Short / full description|短句Match colors. Uncover cozy scenes.及BR01 beta英文资料|准确反映本版本，不把候选广告关闭说成未来任何版本都无广告|
|Contains ads|当前adsdisabled，不发广告请求；但广告/UMP SDK仍嵌入，native sample AppID保留|按最终版本与Play实际问题/规则由本人作答，不仅靠SDK存在或默认off猜最终选项|
|Data safety / privacy URL|第三方SDK也需评估，见下表；无有效公开policyURL|不能统一“无数据”；controller/contact/请求流程/保留政策由本人补齐|
|App access|无玩家登录或付费门槛，可直接Start|不需要demo凭证或账号删除入口；不增加账号系统|
|Content rating / target audience / countries|离线益智/本地内容；没有聊天/UGC/付费lootbox/金融医疗业务|受众不是商店自动分级；本人确认实际设计营销年龄/国家，问卷据内容产生，不直接指定Everyone/18+|
|Closed group / testers|Pourlune Beta，先本人账号和少量受控名单|具体邮箱/地区和名单须获授权，未开轨道/邀请。internal仅中间验证，不替代closed；适用新个人账号12人14天是后续生产访问条件|
|Screenshots / contact|已有正常main截图清单；无QA种子/伪造回执|最终素材与公开邮箱待条件齐备，不能拿旧QA图作正式分发包实测|

官方：[创建和设置应用](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)、[内容分级](https://support.google.com/googleplay/android-developer/answer/9859655?hl=en)、[目标受众](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en)、[轨道](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en)。表为字段准备，不代表已回读当前账号全部动态必填项。

## 隐私/数据安全/加密技术依据

|实现面|当前源码/产物事实|不能从中推定什么|
|---|---|---|
|本地玩法|SQLite schema5/快照2，本地进度/历史/拼片/设置；无账号、云同步、业务服务器|无账号不等于SDK无安装标识；Reset保留偏好不等于清除供应商已接收数据|
|Analytics|firebase_gateway.dart独立choice；先关闭再按analyticsStorage选择开启；adStorage/adUserData/adPersonalization为false，原生自动屏幕上报关；telemetry字段受限|SDK可能有技术/自动事件，不能称只有手写事件；on/off调用不是送达或删除回执|
|Crashlytics|自动上传false；独立choice，允许时sendUnsentReports，关闭时deleteUnsentReports；错误类别受限但含stack/SDK信息|可能先缓存再在同意后上传；不能召回已排队/送出的报告，不声称SDK已实际删除或控制台收件|
|Remote Config|真实prod配置可初始化并fetchAndActivate，5s超时/12h间隔；默认/last-valid保底|analytics off不关闭全部installation处理；未运行prod不能推定无网络、零IP或全部optional|
|AdMob/UMP|SDK仍嵌入，合并manifest含AD_ID/AdServices等；当前Dart adsdisabled，不启真实广告|权限/SDK存在不是实际收集实测，disabled也不是零处理证明；未来启用广告须另复核同意/ID/问卷|
|反馈/支持|链接/邮箱仅用户主动打开浏览器/mail，不自动上传棋盘；当前未配置|联系邮件内容与网站主机日志是另外的处理，需要真实联系主体和可履行保留/请求流程|
|网站|无自带JS/表单/跟踪字体；若部署Pages，GitHub会记录IP安全日志|不称整个网站零收集，不替GitHub承诺具体删除或期限|
|加密|应用未新增加密产品功能；系统/Google网络安全与依赖哈希不是同一个法律分类|技术依据不能替代本人出口声明/豁免判断，不能为了省问卷猜填不受限|

上表据当前源码及BR01已独立验收包的SDK/权限清单，非新prod网络/控制台测量。供应商当前资料：[Firebase privacy](https://firebase.google.com/support/privacy)、[Crashlytics opt-in](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)、[AdMob privacy](https://developers.google.com/admob/flutter/privacy)、[Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)。所有最终yes/no/数值和法律经营事实仍待本人确认。
