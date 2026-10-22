# Flame 完整棋盘 FB01–FB08 执行交付

2026-10-22。执行者完成实施与下述自测；本报告不是架构独立验收。用户确认样板后的完整棋盘授权沿用，不需再次确认。工作区保持在 `codex/offline-foundation`，未由执行者暂存、提交或推送。

## 改动及规则边界

- `app/lib/presentation/flame_board/` 将已确认样板组织为生产几何、不可变视觉帧、瓶体绘制、Flame有限Effects和Flutter原生按钮/文字/语义。正式`BoardView`接收真实`GameInstance`/`PourMotion`/token；不从样板session导入夹具，纯Dart核心和SQLite仍是唯一业务权威。
- 4/5/6/7瓶沿用2+2/3+2/3+3/4+3布局，七瓶同尺寸；修复审查发现的标签交叠后，上排容量标签放在瓶体上方，下排仍在下方，生产轨迹使用两条标签带之间的flightBounds，包含靠近/回正阶段的整瓶与水流均避让；O/G/P/B、目标标签、符号、高对比、选择/按压/非法反馈、免费辅助及减少动态效果保留。液体、水流与旋转瓶口共用几何；移动源瓶最后绘制。
- FS-M01：原生容量文字及语义内容由同一视觉进度导出。用`round((out+arrived)/2)`作为两端共同转移整数，源端减、目标端加；连续液体还计入在途水流，整数容量不独立舍入。靠近阶段保持动作前计数，最终/中断统一贴合已提交完整棋盘。样板使用同一规则；不延迟、拆分或重复存档。
- `board_page.dart`保持公开参数，给活动实例的BoardView稳定key，避免教程步骤完成时重建游戏/两张解码图。`game_controller.dart`仅把动作presenter布尔量改为平衡引用计数：新实例先attach、旧页后dispose时，旧bool会错误清除新所有者，造成下一次已存动作无动画；已观察RED并回归GREEN。没有更改schema、事务、奖励、提示或固定目标规则。
- 美术状态明确区分loading/ready/failed；未就绪时禁用原生与语义动作，失败提示和Retry置于可访问的Flutter层。Retry只替换渲染游戏，保留实例和存档。真实asset-channel失败与延迟加载后卸载有回归。
- `motion_test.dart`/`system_motion_test.dart`断言更新为实际新渲染器；新增几何、真实绘制顺序、语义/文字、过期回调/生命周期、样板及真实SQLite控制器回归。page_transitions_test仍仅在获准的实例替换用例导入辅助并增加3处真实Flame就绪等待。加载保护还要求ui_test、motion_arrival_test、replay_navigation_test、offline_ui_test在点击前等待实际解码；首个就绪点击仍发生在入场动画中。该测试边界已在共享handoff记录。共享`game_screen.dart`、`motion.dart`、启动/导航、`bottle.dart`、依赖锁文件及原件未改。

## 实际验证

|范围|命令/记录|结果|
|---|---|---|
|核心`packages/pourlune_core/`|`dart pub get --enforce-lockfile`、format、analyze、`dart test`；`core-check.log`|30/30，分析/格式通过|
|应用`app/`|`flutter pub get --enforce-lockfile`；`pub-get.log`|通过，无依赖升级|
|应用完整测试|`flutter test`；`fix-full-tests.log`|219/219，1:09|
|最终格式/分析|`dart format --output=none --set-exit-if-changed lib test integration_test`；`flutter analyze --no-pub`|119文件0改动；No issues，3.9s|
|after原生构建|按README命令，Firebase none、测试身份、广告disabled、无scenario，严格串行|iOS Simulator31.3s；Android debug APK10.6s|
|before基线构建|共同路线/测量策略、保留原QA诊断版本、旧Flutter棋盘、同UI基线，独立源码副本串行构建|iOS/Android均通过，日志保留|
|正常main原生路线|双端before/after各43步；每条实际指针＋原生sqflite|4–7瓶参考解、部分容量、4单位边缘/跨行、辅助、失败重试、双槽、回执/拼片/Next、设置路径通过|
|后台/强退|after真实OS后台samePID；早期4单位流水保存完成后同安装SIGKILL/force-stop→launch|双槽、设置、权益、回执、历史一致；实际Undo7→6且额外瓶保留。Android同设备时钟记录dispatch93.740ms/完成132.314ms；iOS完成16.818ms，均非负且<250ms|
|字号|Android320×568/font2；iOS accessibility-large；实际棋盘图|人工检查标签可辨认；覆盖值已还原；全页面非同时可见|

日志及完整FB/AC矩阵：[证据索引](../evidence/flame-full-board/README.md)。几何测试包含7瓶42个方向、1/2/4单位、15ms采样与窄屏/2x字号；另有实际绘制super调用顺序、原生语义tap、只读预览、保存故障、旧回调、实例替换、OS减少动态效果回归。旧失败日志是RED或QA调试记录，不计为通过。

## 录像、兼容及安装

[iOS新版片段](../evidence/flame-full-board/ios/after/route-clip.mp4)／[旧版片段](../evidence/flame-full-board/ios/before/route-clip.mp4)；[Android新版](../evidence/flame-full-board/android/after/route-clip.mp4)／[旧版](../evidence/flame-full-board/android/before/route-clip.mp4)。均为原速连续片段；原完整录像路径、SHA与UTC在对应`route-*-recording.json`。实际抽帧复核保留在ignored build目录，不合成/重定时动画。对应PNG和视觉状态JSON见平台`screens-route-*`目录。

实际兼容UI HEAD为`24bb1637f046e500946d770ca4808cef39687c74`。`comparison-source-provenance.json`核对受保护UI/原生/锁文件。before保留pre-review QA；after只增加elapsed诊断、初始生命周期日志和恢复早期流水条件，route/timed/startup端点策略未变，差异与原源码均保留；`runtime-source.zip`和清单冻结运行源码，`candidate-sha256.json`冻结双端前后候选。原件/既有样板冻结产物保持原状。before是在完整实现后从旧正式渲染器源码重建，以保持相同当前UI基线，不伪称所有基线在实现前采集。

仅使用iOS `F9C16DE7-01D8-4740-B796-A3A2DB8C3265` / `dev.pourlune.fullBoardValidation`、Android `emulator-5588` / `Pourlune_FullBoard_API36`，命名库`flame_full_board.sqlite`。同安装恢复检查过程中没有重装；基线采集完成后另行装回after用于验收，不能将这次安装当恢复证明。普通`b04_review_r2.sqlite`只读SHA仍为`dc94bbfd1e8b10cda675f139a822c39e83dcc38bdf830c3a245d2221da9978c6`。

## 测量与未验证范围

[完整诊断表](../evidence/flame-full-board/performance.md)。每平台/版本27次无PNG倒水，冷启动各3次，热入口每端点1次。 ios修复版build p50/p95为6.79/14.79ms，首次棋盘/Next单次值276.5/276.2ms。 android修复版build p50/p95为9.97/26.23ms，首次棋盘/Next单次值354.1/325.7ms。 初轮Android热进入增幅仍保留在pre-review，不用修复版较低单次值宣称稳定提升。冷启动仅Dart-main→Bootstrap后首个PourluneApp宿主帧，排除native pre-Dart及intro全部结束时间。空闲快照Flame已pause，但Flutter/QA仍产生帧；不称全App零重绘。

这是debug Simulator/AVD＋standalone正常main插桩，未声称DDS集成runner或真机性能通过，也未声称60fps、功耗/温控、profile/release运行、VoiceOver/TalkBack实际朗读通过。本批不新增真实广告获奖、Firebase收件、商业权属或正式身份/签名结论；七瓶和章节进度前缀是明确QA准备状态。新强退路线为非通关动作，未新增逐个通关事务时点强退矩阵；离线入口Firebase none/广告disabled，不等于新做飞行模式矩阵。AC15/16/28/32的既有资格/最终关边界依赖原自动覆盖，没有扩大原生证明。新实现尚未提交，远端CI未验证；由架构按原分工提交后检查精确实现CI。

## 最终审查与交接

一次全范围gpt-6-astra只读最终审查发现3个P2、无Critical：标签交叠、美术失败仍可点击、Android跨时钟新鲜度。执行者一次修复pass完成RED→GREEN、219完整套件及双端43步/后台/强退/字号/测量刷新；没有重复派发审查。两项Minor（并行解码、静态刻度几何缓存）留待后续，不声称优化已做。[审查与修复记录](../evidence/flame-full-board/author-final-review-and-fix.md)列出原发现、回归、证据及各未判断项的裁定。执行侧可送架构独立验收；本报告不替代整体视觉通过。FS-M01关闭仍以架构实际复验为准。

执行裁定：用户最新明确Flame授权覆盖旧技术稿“不用Flame”文字，代价是需要本批完整平台/视觉验证；沿用用户/架构已授权共享工作区，代价是必须冻结本批范围和源码哈希，不能打包其他聊天变更。架构独立验收及后续提交/推送仍按原分工；不合并main、不发布。
