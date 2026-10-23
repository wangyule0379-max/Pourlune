# ADM01 披露差额与真实状态

BR08/build7保持广告disabled历史包，原资料不改称测试广告。新候选尚未生成/分发。唯一网站源docs/support/pages-site更新为区分build7关闭广告及显式ad-testing builds；正文说明官方test unit不收费不等零处理，UMP/GMA的IP/约略地区、设备/App标识、交互、诊断/性能，以及非个性化不匿名；Analytics/Crash独立默认off保持。两HTML已在独立站commit baf00f20859f9ce84576a474e9e2a1ed326055ff发布；HTTPS200且逐字节等于源，见site-http-check.json。

|问项|新test模式实际建议|剩余边界|
|---|---|---|
|Contains ads|由旧关闭广告No建议改为Yes：新模式会展示测试广告|实际Play表单尚未进入，不能保存No沿用|
|Play Data safety|保留Firebase RC/Installations及可选Analytics/Crash；新增/核对GMA/UMP数据：Approximate location(IP)、Device or other IDs、App interactions、Diagnostics及适用广告/分析/反欺诈目的|供应商共享不能全部套服务提供者例外；确切表单及当前账号设置待核，不勾完全不收集|
|Apple privacy|保留既有Firebase项；核对GMA Coarse location、Identifiers/Device ID、Product interaction、Advertising data及Diagnostics/Performance，按SDK用途声明|无ATT/手动tracking opt-in不等SDK完全沉默；关联/追踪结论依实际供应商配置，不擅作法律声明|
|13+与UMP|目标13+不等于用户均成年；保留实时资格和隐私选项，不强制同意、不伪装地区|实际本人测试商店地区、适用年龄/地区保护及控制台消息配置未知，不对年龄信号签准确性认证|
|AdMob App ID/unit|无真实登记时native仅官方sample、metadata owned=false；test unit固定官方按平台匹配|控制台连接失败，真实publisher/apps/units/readiness未创建核实|
|app-ads.txt|需真实publisher ID和商店Developer Website域根|当前项目URL /pourlune-support/不等域根；不把项目目录文件冒充验证成功，不借FishPilot字段|
|TestFlight/Play说明|明确Google Test Ad，玩家正常完成测试广告后再观察奖励，不能要求点击真实广告|下一新版本号在实现独立验收和精确CI后才选择；现阶段无可用安装入口|

2026-10-23实际读取的官方依据：
- https://developers.google.com/admob/flutter/test-ads
- https://developers.google.com/admob/flutter/privacy
- https://developers.google.com/admob/flutter/targeting
- https://developers.google.com/admob/android/privacy/play-data-disclosure （该页针对当前最新Android SDK；仅作类型/用途输入，不冒充锁定版本网络实测）
- https://developers.google.com/admob/ios/privacy/data-disclosure
- https://support.google.com/admob/answer/9989980?hl=en
- https://support.google.com/admob/answer/9363762?hl=en
