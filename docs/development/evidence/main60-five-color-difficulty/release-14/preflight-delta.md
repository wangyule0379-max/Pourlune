# Build14 发布差额预检

范围：既有 Pourlune 内部 TestFlight，新五色主线；不做公开商店上架或新Play分发。
[Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)已实际读取，
按完整性、真实元数据和隐私一致性核差额。当前实现无新账号、IAP、UGC、支付、权限或SDK依赖；
新色／题库／布局不增加数据采集。父已接受完整阶段Beta候选，真人手机首玩仍未验。

自动guard退出0：项目关键0、高5、中4；全局期限打印不等于本游戏命中。具体处置如下：

|项目|分级|核查与处置|
|---|---|---|
|占位域名|高，误报|service_config.dart 的example.com是明确拒绝列表；实际候选仍必须填已授权支持／隐私URL及反馈邮箱。|
|出口分类|高，发布流程待核|不把Info.plist直接写成无加密。保留已有Flutter BoringSSL标准加密及仅本人内部测试的分类证据；新IPA需复核相同技术，再处理ASC分类。未接受新法律协议。|
|Android R8|高，当前非iOS差额|本轮不改Android发布优化或签名；不为扫描器开启无关混淆。|
|SDK隐私/DataSafety|高，包差额待核|Firebase/广告SDK依赖未变，广告继续disabled、Analytics无AdID、选择默认关闭；新IPA继续核实际配置和SDK隐私清单。不能因此宣称零数据。|
|Android AD_ID|高，误报|AndroidManifest.xml已显式tools:node=remove；不照建议重新加权限。|
|无障碍／触觉|中，通用原生扫描误报|Flutter原生语义实测R星及8个按钮完整，HapticFeedback由现有FlameBoard调用。|
|年龄／12人规则|中，分开处理|新解谜内容不变更既有年龄事实；Play生产12人要求不作为本次内部TestFlight上传门槛。|

[Apple出口加密文档](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption)
已读取；不把标准TLS/BoringSSL误判为完全无加密，也不将历史回答冒充新包核验。

结论：代码差额可准备签名候选。上传仍待：1. 新版本精确提交CI终态成功；2. 独立核新签名包、
原生纯净、配置／隐私清单、符号及来源后通过。实际ASC新构建号回读为14空闲，上传前再查重。
既有组当前2人、手动分发，本次只给既有已授权本人，保持原2人组成员不变且不给该组勾新包。
