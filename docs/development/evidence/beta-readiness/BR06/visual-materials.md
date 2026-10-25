# 商店视觉素材：具体可复用项与缺口

逐文件路径/SHA256/尺寸/模式/来源/QA叠层见visual-material-inventory.json。仅盘点既有文件，没有启动/操作F9、没有屏幕/音视频采集或限制重试。

|素材|已有结果|当前可提交状态|
|---|---|---|
|Apple icon|app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png，1024平方RGB；B03标准尺寸导出，随build5冻结；新build6沿用|尺寸技术条件具备；原视觉/派生图商用权未确认，不能称商业通过|
|Play launcher icons|app/android/app/src/main/res/mipmap-*/ic_launcher.png，48/72/96/144/192平方RGB；不是Play512 store icon|需由已核权的brand-source或1024icon标准导出512平方32-bit PNG≤1024KB；不重新设计图标|
|品牌源图|docs/design/production-candidates/runtime/icons/brand-source.png；尺寸/hash见JSON|原视觉派生，rights仍UNCONFIRMED；不直接用透明源替代商店截图|
|普通main截图|T-R01/{ios-light,android-light}/home.png有真正lib/main.dart来源；实看两图均有Engineering tools及Local development progress，iOS还有Pourlune Dev返回栏|拒绝正式截图用途：旧debug身份/旧版本/工程叠层。不可裁掉文字后宣称新beta实测|
|B03普通App成功页|B03/manual-final-completion.png；旧原生运行历史|旧内容，晚于它的UI/完整棋盘/SDK配置有变化，不能作为当前签名包通过或正式商店画面|
|其他T/FB/B05/UI增量|原型、受控QA实例、种子/快进路线和调试身份已在各报告标明|只用于回归/验收；不混入正式宣传截图集合|
|Play feature graphic|未找到经核权、准确反映当前版本的1024×500成品|缺失；现阶段完成版式清单，不伪造或用未核权素材生成新宣传图|

官方要求（2026-10-23查阅）：[Apple截屏规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)、[Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-FO)。以下是素材准备条件，**不是将正式App Store上市图片一律加到TestFlight上传门槛**。

Apple准备选择：竖屏iPhone中型Dynamic Island可用1206×2622或1179×2556；若后续App Store资料用大屏可用1260×2736/1290×2796/1320×2868。支持iPad时准备13英寸2064×2752或2048×2732。按实际设备族和控制台要求核对，不把中型截图拉伸伪装大屏，不保留alpha。官方页面当前总览要求iPhone中型和适用的iPad13，历史按6.5/6.9英寸称谓不在本批硬编码为唯一要求。

Play准备：512×512 PNG store icon；feature graphic 1024×500 JPEG/24-bit PNG无alpha。截图至少2张，按支持设备类型整理，JPEG/24-bit PNG无alpha，边长320–3840，长边≤短边2倍；宣传推荐使用手机1080×1920的9:16实际画面。不要直接上传旧1080×2400（比例超过2）的debug截图或为了尺寸切掉关键控件。推荐数量/比例与必要条件分开，不要求增加TV/Watch/XR产品。

待具备合法捕获条件后一次采集清单：正常release入口、精确com.pourlune.app/版本/build/hash；无scenario/工程菜单/QA叠层；正常游戏存档路径；Home、真实六瓶教学/玩法、Daily及Collection各一张，至少玩法＋收藏两图优先。固定相同设备族尺寸，不虚构未解锁场景、不展示广告奖励假回执、不把debug模拟器截图当物理机性能证据。保留原始文件、尺寸/hash、来源包版本与取得方式；审核画面后才做标准格式导出。图片内容权属与技术尺寸分别通过。

feature graphic版式准备：沿用天蓝针织背景与已核权瓶/场景图，核心画面在中心，边缘仅背景，简短真实文字（如Match colors, uncover cozy scenes），无价格/排名/评价/商店徽章；不生成新视觉。最终图需权属闭环后再排版，不能用文案清单冒充已完成图。
