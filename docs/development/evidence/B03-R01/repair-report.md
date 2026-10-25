# B03-R01 / R02 修复交付

2026-10-22。执行侧修复证据；B03 独立报告仍为退回状态，复验裁定由产品架构完成。没有暂存、提交、推送或进入 B04。原件、原审查失败回归、独立报告与 tracking 未由本修复编辑。

## 变更与要求

- **R01 / B03-04/05/07、AC-07/12/31/33**：P01 品牌、tagline、场景插画、绿色 Start；P02 品牌/设置、实际拥有场景、五个拼片槽/数量、继续、三入口；P04/05 月亮关卡顶栏、返回/暂停、针织教学/提示卡、底部图标+文字免费操作；P06 月亮/真实保存说明及竖排 Resume/Restart/Home。共用 `KnitArt/KnitPanel/KnitHeader` 和原生按钮背景也覆盖收藏、场景、每日、奖励与结算。文字、按钮、状态、语义、持久化和所有原业务处理保留。未加入假 SDK 或额外瓶广告入口。
- **R02 / AC-11**：完成声音绑定原实例/修订，只有本实例成功回执、clean、前台、仍在 completion、无动画和待办导航时消费一次。保存失败/写入中不发送，Retry/慢 SQL/无 presenter 可成功发送，离页/后台/过期和重复回调不会补播。回执和奖励事务未放到动画。详见 `audio-report.md`。
- 原针织图以独立背景/图标/纹理接入，非整屏截图。七张 RGBA 生成候选与三张经过逐像素核对的原稿纹理有独立清单；10 份 App 副本字节一致，所有来源权属仍 **UNCONFIRMED**。已获拼片使用单张 sprite，不将包含边缘的贴片平铺；空槽继续使用重复纹理。没有修改原始 PNG 像素。

## 真实渲染与操作

[原稿 / 原生配对](visual-pairs.html) 共9组，分别对应 P01/P02/P04/P05/P06/P10/P12/P13/P14；左侧CSS显示原稿对应栏，右侧402×874真实Flutter视口（2x PNG），原PNG不改。原稿概念进度/瓶数与实际关卡、实际1/5状态不同处逐项标注，没有伪造原进度。另列7个320宽/2x入口；全部逐图元数据在 `native-runtime/runtime.json`。

原生流程使用默认 Bootstrap、正式90题资源、真实 sqflite 和真实本地音频后端，无 scenario/注入时钟。main1–4 全程真实按钮执行参考解，经正常事务得到4个first-clears及1片，随后打开奖励/首页/收藏/场景/每日。参考操作属于自动化验证，不是无提示真人试玩。

六瓶为 main012 受控 start；七瓶为同一定义经已有核心 `grantExtraBottle` + 正常SQL保存/重载构造的明确 QA 布局，不声称广告获奖、题库main021为七瓶或关卡已解锁。每瓶实际尺寸在正常宽为84×184，在320宽为66×184；6/7一致。窄屏使用相同真实 App/controller，未用图库或静态页面替代。按钮可滚动到达，保持字号与48触区。

普通无scenario App另使用 `b03_r01_manual.sqlite`。先实际首步保存，再同安装 terminate(pid20022)/launch(pid21252)、Continue；所有数据库表记录一致，同实例revision1/教学2/3/四瓶内容一致。见 `cold-{before,after}.json/png` 与 `cold-result.json`。安装发生在对照前；不是写入中强杀或未落盘恢复保证。该普通App恢复检查在最终仅修改拼片填充前执行，之后controller/store未改；最终原生配对已按填充修正重采。

最终：**Flutter 101/101、资源 23/23、原生 1/1（25张）、analyze无问题、format52文件0改动、iOS simulator与Android debug构建均退出0**。完整命令与退出值汇总在 `checks-final.json`，最终源码/截图摘要在 `final-source-manifest.json`。

## 检查记录

最终结果以实际完整退出日志为准；工作目录 `app/`，Flutter3.47.2/Dart3.13.2。Simulator为 GDF-Remaining-20261020 / iOS26.5 / 4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2。图像Python为 `tools/assets/README.md` 指定 bundled Python/Pillow。

|检查|证据|
|---|---|
|R02原独立回归 RED→GREEN，13项新增/复制用例；相关69项|`audio-red-review.log`、`audio-green-regression.log`、`audio-green-related.log`|
|R01 welcome/order/calendar、只读终盘、320/2x Pause 布局 RED→GREEN|`design-red.log`、`navigation-design-red.log`、`navigation-collection-red.log`、`design-green-initial-3.log`（17项含相关回归）|
|整合完整 app `flutter test --reporter expanded`|`app-tests-final.log`|
|`flutter analyze` / `dart format --output=none --set-exit-if-changed .`|`analyze-final.log` / `format-final.log`|
|原生 `flutter test integration_test/b03_r01_design_test.dart -d <ID> --dart-define=POURLUNE_DATABASE=b03_r01_runtime.sqlite`|`native-runtime.log` / `native-runtime/runtime.json`，25张真实PNG|
|`flutter build ios --simulator --debug --dart-define=POURLUNE_DATABASE=b03_r01_manual.sqlite` / `flutter build apk --debug`|`build-ios-final.log` / `build-android-final.log`|
|根目录 Python assets23项，原23图/22copies + UI10图/10copies|`asset-tests-final.log` / `asset-checks-final.json`|

R01初次组合RED因navigation测试缺LocalDay import有编译失败，同时Board AppBar和Completion缺BoardView已真实复现；补import后的单文件navigation RED为三个真实断言失败。初次GREEN遇到不可const Semantics后已修正。原生首轮25截图/断言完成但音频plugin FramePositionUpdater收尾未await导致退出1，保留 `native-runtime-initial-teardown-failure.log`；只改harness等待真实音频stop/dispose后完整重跑通过，后因拼片填充修正重采最终25图。过程失败不混为最终通过。

## 质量复核与未验证范围

仅一次新的独立上下文代码/现有截图质量复核，`final-quality-review.md` 无 Critical / Important；复核方未重跑命令，不等于产品架构验收。两项minor保持真实状态：320/2x的Restart尾项半宽导致单词换行；Rules返回Settings但共享返回控件仍播报Home。此前同色连续液体逐单位画形状的minor仍未改。三个minor不影响保存/规则/动作幂等，本次未扩展修复范围。

本轮不重复90题难度评价、全部18场景/15奖励页或原生6音源decode专项；此前证据保留，不能将本次25图替代这些范围。Android仅debug构建，无原生操作；无真机性能、声压/主观听感、系统音频中断、完整读屏遍历、真人无提示难度或商用美术权属通过。Firebase/AdMob/支持身份/签名保持 B04，未接入假SDK。修复交付完成不自行修改独立报告通过状态。

## 第二轮主审全内容脚本小修

主审在 `docs/development/review/B03-evidence-r2/native-full.log` 复现全内容脚本426行仍期待旧 `AlertDialog`；原失败历史保留未改。本次只更新 `app/integration_test/b03_runtime_test.dart`：Pause 改为核对真实可点击卡片、正确标题/已保存说明、无仅内存说明，且 Resume/Restart/Home 三个操作有正确文字、非空回调且可点击；同时核对当前完整状态与真实SQL存档一致，原动画结束、步数、Resume及Undo断言保留。扫描同文件只有这一处旧Dialog类型依赖。

收尾即使图库仍使Bootstrap处于offstage也能定位真实音频实例；stop后明确await真实dispose，再卸载widget，沿用有时限清理。未改产品代码、原失败证据、tracking或review。格式检查1文件0改动、单文件 `dart analyze` 无问题均退出0，见 `full-harness-{format,analyze}.log`；源码变化摘要与旧交付哈希见 `full-harness-update.json`。**本次未运行模拟器、原生测试或平台构建；更新后的全内容原生流程待主审独立复跑，不能沿用此前通过结论。** 前面的101/25等结果仍指其原已记录版本与范围；该文件的最新hash由此补充JSON单独记录。
