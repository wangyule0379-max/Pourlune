# T-R01 原生启动连续背景修复（作者交付完成，待独立验收）

2026-10-22。接受独立验收P2：此前作者启动验证覆盖了Flutter壳，遗漏系统原生LaunchTheme/LaunchScreen白色阶段。页面内转场独立已测通过，本修复不重做页面内路线。

## 根因与明确范围

- iOS LaunchScreen.storyboard白色，Main.storyboard中Flutter原生容器也为白色；LaunchImage为1px空白。
- Android旧launch_background白/系统色，NormalTheme使用系统背景；Android12+未覆盖windowSplashScreenBackground，系统使用默认图标/底色。夜间资源又可选择另一套模板。

修复复用既有#82DFF1与Pourlune针织字标，原生/引擎容器/Flutter初始化壳声明相同标称色值，静态居中字标176dp；正常Home仍按原稿立即展示。无进度条、计时保留、额外业务等待。只改Startup/原生明确文件和对应验证，不改board/Flame/controller/storage/services。

## 官方依据（2026-10-22核验）

- [Flutter Android launch/normal themes及Android12衔接](https://docs.flutter.dev/platform-integration/android/splash-screen)：launch与normal是不同阶段；normal应接近Flutter底色，Android12使用系统splash属性；可立即移除默认退出动画以衔接相同Flutter首帧。
- [Android Splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen)：系统窗口纯不透明色；普通/夜间均需资源覆盖；无背景icon的288dp外框、192dp圆形安全区。本批沿用原有栅格美术为静态drawable，字标176×约70dp完整放在安全圆内，以实际Android12+运行检查裁切和显示。
- [Apple specifying launch screen](https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen)与[Launch screen interface](https://help.apple.com/xcode/mac/current/en.lproj/dev765148f31.html)：原生静态storyboard展示初始化背景。使用现有storyboard与AutoLayout，不执行启动业务代码。

## 已验证和未验证

- tools/assets/test_startup_native.py有效RED：iOS两处RGB白色、NormalTheme系统底色、Android12配置缺失、1px图像；native-red.log记录5处失败。
- 修复后native检查4项通过；所有assets检查27通过；原visual/ui manifest检查通过；startup_assets.py重建一致性通过。仅为静态/资源检查，不算native运行通过。
- Flutter居中壳与小屏大字号Retry测试已准备，待串行CLI窗口先跑旧壳RED，再最小修复GREEN。
- 尚未声明冷启动、双端编译、实际普通/夜间或独立验收通过。

## 可复验基线与正常入口

旧8cb转场baseline/zip保持不动。R01独立副本：根build/page-transitions-r01/app；从旧冻结版复制，叠加本修复，不含后续完整棋盘代码。

正常main不引用测试入口：构建lib/main.dart，命名库ui_transition_r01.sqlite，Firebase none、广告disabled。iOS外部xcconfig仅指定dev.pourlune.transitionsr01；Android独立副本仅将applicationId覆写为dev.pourlune.transitionsr01并明确MainActivity原类名，保留生产源Gradle/Manifest不动。QA身份overlay单独记录，Firebase仅none，不能冒充生产签名或身份验证。

使用现有UI专用设备上的新身份，保留旧dev.pourlune.transitionsValidation与Android dev.pourlune.pourlune_dev审查安装和其page_transitions.sqlite。进程冷启动将显式终止/force-stop后启动，不以Flutter运行器重装充当恢复；分别记录light/dark外观与冷启动→Home连续录像/抽帧。无真实性能门槛结论。CLI窗口尚由完整棋盘方持有，当前仅源码与Python准备。

静态准备补记：13个密度输出已生成并一致性检查通过；共23个原生修复文件已同步到R01副本。tools/assets全27项通过，原生4项GREEN。Flutter新增测试草稿仅在R01副本，避免其他任务的共享全套误读尚未实施的RED。原生产Gradle/AndroidManifest不改；隔离副本的QA身份overlay明确拒绝Firebase非none环境。

Flutter壳有效RED：402×874视口中旧字标中心(201,90)，目标(201,437)。新壳纯蓝居中176宽字标，不再先显示另一套顶部/底部装饰布局；失败状态仍显示真实错误与Retry，支持320×568/2倍字号。19项启动/转场/保存门控相关测试GREEN，analyze无问题。Bootstrap只增加相同scaffold底色，没有业务逻辑或等待变化。开始构建正常main，未将通过测试当冷启动验收。

## 最终执行结果（以上准备过程保留为历史）

本次正常main候选已实际构建、安装并取证。R01副本19项启动/转场/保存门控测试通过，analyze无问题、format106文件0改动；iOS Simulator debug构建76.8秒成功，Android debug构建32.6秒成功（既有Kotlin迁移/弃用提示保留）。命令均在build/page-transitions-r01/app串行执行，FIREBASE_ANALYTICS_WITHOUT_ADID=1。两端target均为lib/main.dart，defines为POURLUNE_DATABASE=ui_transition_r01.sqlite、POURLUNE_AD_MODE=disabled，Firebase默认none。构建窗口已明确归还原开发；没有重新占用其CLI。

|正常main实际冷启动|已观察的结果|证据|
|---|---|---|
|iOS / light|专用身份PID41520；居中品牌→正常Start首页，命名库存在|ios-light/cold-start.mp4、capture.json、home.png|
|iOS / dark|终止返回0后新PID42267；同色品牌→正常Start首页，命名库存在|ios-dark/cold-start.mp4、capture.json、home.png|
|Android API36 / light|force-stop后PID为空，启动PID7064；系统返回COLD/ok，正常Start首页|android-light/cold-start.mp4、capture.json、home.png|
|Android API36 / dark|force-stop后PID为空，启动PID7774；系统等待超时，录像随后实际到Start首页，命名库存在|android-dark/cold-start.mp4、capture.json、review-frames.jpg、home.png|

Android夜间`am start -W`原始结果为Status: timeout / UNKNOWN(-1) / WaitTime12586。保留失败等待结果，未重跑掩盖；实际完整录像约18秒位置及最终截图显示正常首页，进程仍在。它支持本次颜色连续性复核，不能记为系统启动等待通过、启动时延达标或性能通过。设备为debug模拟器且录屏，不归因业务故障或声称性能改善。

iOS设备3497E78D-608C-415C-8326-26E46F1B6E29、Android emulator-5586；仅操作dev.pourlune.transitionsr01。旧转场审查安装/数据库未重装或清理。结束时两台专用设备外观恢复light/no。

完整原始录像保留根build/page-transitions-r01-candidates/；证据mp4仅用AVFoundation MediumQuality整段重新编码，没有裁切、变速或插帧。startup_frames.swift按请求0.1秒抽实际帧，frame-check.json保留请求及实际时间；Android录屏为可变帧率，多个请求可能对应同一实际帧，不能把请求数当独立渲染帧数。四段完整录像分别135/226/135/231个请求样本，均未触发应用内部白色占比≥70%的旧症状阈值。已人工检查品牌位置、未裁切与后续首页。旧版iOS反例在2.6–3.8秒的13个请求样本触发相同阈值（counterexample/）。这是可复核的采样及画面证据，不保证每一帧、真机性能或所有设备覆盖。

## 资源检查范围与现有漂移

最终assets单元测试27项通过，startup_assets.py核对13个密度输出一致。最终根目录visual_manifest --check与ui_manifest --check返回失败，只有geometry_sources/geometry_source整体文件SHA不同；所有美术资源条目、尺寸、像素摘要及几何数值条目相同。R01冻结副本同样存在该历史文件SHA差异，不能将此前静态准备阶段的通过描述沿用为最终全清单通过。manifest-scope-check.json保留具体摘要。R01没有改变bottle.dart、scene_art.dart、knit_components.dart；未运行--write、未替其他任务刷新清单。这项旧范围漂移须由对应所有者判断。本批Startup独立资源检查及原生测试通过与此明确区分。

## 冻结、复核与未验证边界

旧8cb源码zip/双端候选保留不动；本次源码zip与双端普通main候选在build/page-transitions-r01-candidates/。source-freeze.json记录349文件、26项相对旧版的产品/测试文件差异及逐文件摘要；repair-source.patch是文本修复；qa-identity.patch单独记录Android隔离身份覆盖（生产Gradle/Manifest未改）。artifact-manifest.json记录实际候选各文件摘要。原有页面内200项、双端102步证据属于旧冻结版；R01追加19项聚焦及4段正常main冷启动，没有将共享工作区后续完整Flame代码混入本批。

本次只确认作者实现、构建与上述运行证据完成；独立整批验收仍待架构方记录。Android12样式已在API36实际采用，Android12初版/API31、pre12旧系统、iOS最低支持系统及真机未实际运行；没有发布签名、商业权属、真实SDK、60fps、冷启动性能或上线结论。未stage/commit/push。

## 独立复验补充：色阶与清单闭环

iOS native→Flutter阶段存在轻微可见蓝色色阶，保留为Minor观察，不声称像素完全同色。独立审查在同段录像抽到t2.0 RGB(81,223,245)、t3.2 RGB(118,219,239)。本方原始视频缩小抽帧100,100点分别为(92,226,245)/(130,224,240)；不同取帧、尺寸、点位/解码不能混作同一像素的严格对照，但都支持存在色阶。没有为此添加延时或调整业务。

来源核实：两份storyboard明确customColorSpace=sRGB、RGB(130,223,241)；Flutter Color(0xff82dff1)的本地固定SDK实现Color(int)直接委托_fromARGBC并传入ColorSpace.sRGB。原始H.264视频元数据为ITU_R_709_2 primaries/matrix、IEC_sRGB transfer、FullRangeVideo=0；抽帧PNG的ICC均为QuickTime nclc(1,13,1)，两个样本ICC SHA一致；最终simctl截图为sRGB IEC61966-2.1。见ios-color-metadata.log、ios-color-observations.json。源码标称值一致，实际呈现和录屏转换路径未隔离，因此不能将可见差异全部归因编码或声称已经找到唯一原因。白底症状修复与轻微色阶残留分别记录。

资源清单的交付整理现已完成：R01原docs为根目录链接，先将清单分支改为物理隔离副本，未对根目录执行--write。逐项对比build_manifest与原记录，visual仅geometry_sources、UI仅geometry_source不同；替换这些元数据后其余字段完整深度相等，包括资源、像素摘要和人工显示几何。只在隔离候选修正scene_art/knit_components文件SHA后，两份check_manifest(candidate)通过。修正副本和最小diff在manifest-corrections/及manifest-corrections.patch，完整断言见manifest-correction-check.json。根目录清单仍保持原状；前述FAIL保留为历史，不能将候选通过说成共享根目录清单已通过。

相对HEAD46e3d67aec10118cac36e210853ea57298376cfc的精准来源已整理，见precise-submit.md / precise-submit-manifest.json：55个产品/测试/工具/必要M依赖/两份候选清单文件，根build/page-transitions-r01-candidates/precise-submit-files.zip可供逐文件提取。排除完整Flame、QA身份overlay、已提交CI修复的旧版本和其他owner文档；page_transitions_test冻结版仅作来源，不覆盖原开发当前等待兼容修复。没有运行新的Flutter构建或改动原始349文件源码包/二进制。源码摘要与候选文档修正分开追溯。
