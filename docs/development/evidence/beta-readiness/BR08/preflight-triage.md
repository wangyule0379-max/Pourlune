# BR08 静态预检分诊

app-store-compliance-guard.sh 对 app/ 执行 exit0，原始 static-preflight.log 的应用汇总 critical0/high4/medium4。脚本附带的全球期限提示没有自动认定为本项目适用项。该扫描不是“商店已通过”。

|扫描项|本包实际核对与处置|
|---|---|
|BOTH-PLACEHOLDER|命中的 example.com 是 service_config.dart 拒绝占位域的守卫；实际新双端AOT含已确认帮助/隐私/邮箱，未改正常校验。|
|APPLE-EXPORT-COMPLIANCE-MISSING|新IPA未填 ITSAppUsesNonExemptEncryption；保留真实状态，在实际商店问项按系统/SDK TLS技术事实处理，不擅作法律声明。|
|ANDROID-R8-OPTIMIZATION-MISSING|静态未发现显式Gradle旗标；新AAB确实包含 proguard.map 及9份native符号，不能据扫描认定R8未工作，不为此改依赖/重建。|
|GOOGLE-DATASAFETY-MISMATCH|实际SDK/权限仍存在，默认采集off不等于零数据；沿用BR06具体技术问卷，进入实际表单时核对。|
|Accessibility/haptics heuristics|原生文件启发式不足以覆盖Flutter；LY已独立验收。当前不重跑LY，不把自动bounds或静态检查当真机读屏/触觉通过。|
|Age rating/target|用户目标13+；平台内容评级以实际问卷产生，不写成固定13岁内容级别。|
|Play personal-account testing|closed按用户授权推进；不以生产准入12人门槛要求本轮招募未知测试者或偷换internal。|

没有玩家账号/业务服务器/IAP，相关登录、账号删除、后台鉴权项不适用；不因此新增首版范围外功能。包内含广告相关权限，即使本候选ads disabled，也不会直接把Advertising ID及数据安全问题全部回答No。公开政策与实际供应商设置、适用声明和手机验证仍分别记录。
