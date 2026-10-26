# AdMob 恢复接入 — 2026-10-26

## 本批实际完成

新独立账号已正常登录；Google账号审核仍待处理。创建并回读 Pourlune iOS/Android 应用及各一个激励/插屏单元，无重复建应用；未公开商店关联（Android按com.pourlune.app实际搜索无匹配，TestFlight不是公开App Store条目）。真实公开AppID放在app/config/admob/registration.json，owner单元仅保留console-registration.json清单。现有selection双端通过，精确官方sample unit仍固定，默认disabled不变。test_admob_config 5项通过；未升级SDK、依赖或改变策略。

独立新设备256788BA-29A1-4310-8AAE-162F70D4F504，独立dev.pourlune.admobResumeValidation身份，Firebase none，无AdID，串行Flutter3.47.2。正常lib/main.dart、无scenario、新admob_resume.sqlite，真实手工完成1–3关；main004真实官方激励加载/展示（Test mode）/reward/手动关闭返回。原实例done confirmed=1、一个entitlement、一个rewarded show，四瓶变五瓶、0步rev1，重复入口禁用且未新增attempt。奖励未由disabled直加、替身或模拟SDK生成。父已实际看图并只读核库接受此有限结果，见review/admob-resume-20261026-independent.md。

插屏仍只有11关起首通计资格、三次资格及180秒全屏间隔，20/40跳过。另用既有milestone调试scenario＋新admob_resume_interstitial.sqlite：前19个工程别名由现有调试场景建立，实际UI各5步完成20/21；20 Continue无广告，21 Next实际官方插屏（Test mode）显示，手动X关闭后正常进入22。show_id对应一个interstitial，qualifying_boundary=11，total=consumed=11，计数归0。明确不是正式20/21题库难度/自然玩21关，也没有修改策略、时钟或生产数据库。

两个iOS QA构建实际成功（普通38.1s；既有milestone40.2s），未签名/上传新商店包。激励/插屏原始SQLite快照与SDK原始网络日志在ignored .superpowers目录；公开摘要/截图在evidence/admob-resume-20261026/。

## 网络根因及恢复

原生真实请求googleads.g.doubleclick-cn.net被过滤，-1200 TLS失败；沿用既有明确批准的精确临时例外后HTTPS恢复。随后原生pubads.g.doubleclick-cn.net/gampad超时，用户单独批准这一新增精确域名。第二轮仅这两个精确域名沿用现有谷歌线路，900秒自动恢复；两轮最终restored=true、persistent_config_unchanged=true，不改TLS/DNS。

持久配置中的admob.com/doubleclick.net/googlesyndication.com三条允许在本任务应用前已被外部更改：旧候选基线校验失败即中止，未覆盖/撤销他人改动。不要把这些外部改动声称为本任务新增或已撤销。插屏库存于批准窗口内加载，恢复后使用缓存显示，未延长例外。

## 尚未完成的外部状态

新账号/应用审核未通过，双端未公开商店关联；不能把sample广告成功当商业ready或owner单元投放成功。欧洲/美国隐私编辑器均持续加载，正常重载无效；直接打开实际iframe URL返回Google403，没有绕过或反复索取登录。尚无隐私消息保存/发布、EEA/州级地区实测或ATT铺垫消息（无AdID不主动新建ATT）。

app-ads.txt须开发者网站根目录且与公开商店Developer Website关联，现有pourlune-support项目子路径不等于域根。根站仓库查询404，未擅自建立主域站点或覆盖其他产品。应用设置目前显示未公开应用无需verification；待公开条目/账号权限可用后再完成实际归属验证。官方依据：https://support.google.com/admob/answer/9363762 和 https://support.google.com/admob/answer/14538460 。

Android本批仅真实登记/工具配置校验，未声称Android SDK/物理手机通过；重复原生回调、无奖励提前关闭不是本次截图证据（现有受控测试保护仍保留）。F9/D79及其窗口/库未操作。TestFlight15冻结，无新包上传、无广告策略/采集选择/存档结构改变。
