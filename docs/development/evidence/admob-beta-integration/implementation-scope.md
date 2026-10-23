# ADM01 增量与依赖

账号：官方首页可访问，但其Sign in实际apps.admob.com连续两次ERR_CONNECTION_CLOSED；不能判定账号不存在，未重复开户、改网络安全、接受条款或创建其他App。只有控制台实际恢复后才创建/复用Pourlune专属两端资源。

工程：新增 --ad-mode disabled|test（默认disabled），可选择经控制台核对的公开 --admob-registration；暂无真实注册时仅官方sample native AppID，明确owned_registration_verified=false。真实AppID与sample unit是两层不同配置；尚不能称自有AdMob登记/隐私消息配置完成。test只使用准确平台的官方插屏/激励unit；不要求远端用户提供广告ID或点击真实广告。

构建：wrapper同时下发Dart定义、iOS临时xcconfig、Android Gradle属性，原生入口再核platform/nativeID/AppID/registration及定义冲突；prod仍compile-only正常main。独立QA使用Firebase none和命名库/专属iOS身份，不进行生产App运行。

13+：不是全体成年声明。维持现有UMP当前资格/需要时的隐私选项、非个性化请求及Analytics/Crash独立默认off；未填成年人/拒绝同意绕过。当前官方API含age-treatment认证语义，不根据13+目标猜本人年龄或代作法律认证；地区/实际未成年配置及AdMob隐私消息待真实控制台核对。封测仅本人、仅官方test unit；正式广告仍禁用，商业发布前必须补真实受众/地区及适用保护配置。

app-ads.txt：publisher ID尚未知；官方要求的开发者网站根与GitHub Pages项目子路径不同。当前不猜publisher、不复制FishPilot字段、不修改账号主域仓库。测试工程不以商业readiness审核为前置；正式验证仍待准确站点根方案和账户记录。

BR08：父已独立验收ads-disabled build7，报告review/beta-readiness-BR08-acceptance.md。保持冻结；不是ADM新实现验收。先聚焦独立验收与新精确CI，再选下一真实未占用build号，旧包不重签覆盖。

原生QA边界：新增integration_test/admob_beta_native_test.dart仅实际UMP/GMA资格/库存+真实sqflite免费动作落盘，不自动展示无法安全关闭的原生广告覆盖层。若资格/网络失败，sdk_status必须unavailable，不能以QA用例退出0声称广告加载/展示/关闭/激励成功。展示/关闭/获奖仍是真实SDK未验项，控制运输测试仅证明原奖励/Next门控。
