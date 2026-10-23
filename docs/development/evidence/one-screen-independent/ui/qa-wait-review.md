# LY QA 等待改动独立只读审查

2026-10-23。仅审查QA等待差额、诊断来源和既有成功报告，不运行CLI、不操作设备、窗口或采集，不重跑功能19项，也不代验LY-R02/R03修复。下列结论由实际文件比较与Python摘要/报告审计得出。

**结论：当前QA改动未删弱原有bounds/hitTestable/SQLite断言，没有发现伪造就绪或强制完成业务/动画的改动。将全局pumpAndSettle替换为实际输入/落盘/页面动画及棋盘资源/动作边界，符合本正常入口操作测试意图。当前readiness不等于所有装饰动画或所有SDK已空闲，不能据此宣称完整视觉稳定、音频/性能或整批验收通过。**

## 实际对比

对比架构保留的 `review/one-screen-layout-evidence/qa-handoff-before.dart` 和 `app/integration_test/one_screen_layout_test.dart`：

- 增加官方animations导入；新增routeSettled读取实际树中FadeThroughTransition/SharedAxisTransition的primary、secondary动画isAnimating。PageMotion包括Home首入在内均经这两个真实组件，退出页的动画也被实际树遍历覆盖；没有另设“ready=true”、改动画值或跳过点击。
- ready每次先实际pump20ms（单次10秒超时）并检查框架异常；25秒wall-clock上限内等待controller不busy和上述路由动画停止。退出循环仍**断言**不busy、SavePhase.clean、routeSettled，超时不会自动成功。
- controller.busy包含saving、导航、motion、广告流程、奖励保存/SDK展示。board页仍调用原settleFlameBoard：真实GameWidget数为1、实际art非空、不busy，3秒上限。Game.onLoad中art赋值、painter初始化、artStatus.ready之间没有异步间隙；真实倒水回调和controller token完成才清motion，QA没有调用强制结束代替等待。最后仍检查t.takeException。
- firstScreen整个函数前后**字节相同**：finder唯一、四边界在SafeArea、宽高≥48、hitTestable、viewport/padding/text_scale/未滚动报告全部保留。Home ensureVisible仍只为工程关卡入口，未延伸到游戏或结算。
- close到最终report赋值前的流程**字节相同**：真实main启动、正式60题、main1–4按参考解真实点击、completed/receipt、拼片与Next、完整状态SQLite保存后读取相等、同进程关闭再open/resume后id及toJson相等、显式受控七瓶状态与未滚动按钮断言都保留。隔离库/disabled ads/Firebase none/no scenario保护未删。没有mock SDK获奖或把重装当恢复。

## 根因证据的独立核对

`android-frame-diagnostic-3-callbacks.log`直接记录Home resumed、framesEnabled=true、业务busy=false、仍有实际pump帧与transient callbacks。注册栈callback94为audioplayers的FramePositionUpdater._tick→SchedulerBinding.scheduleFrameCallback；callback95/96为ImplicitlyAnimatedWidgetState.didUpdateWidget启动的Ticker。故音频连续调度是有直接栈支持、足以使“全局不再调度帧”不成为可靠就绪条件的来源；**没有把三条全部说成音频，也没有证明所有持续帧只来自它**。测试不需要关掉音频、伪造无帧或修改SDK才能继续。

等待语义现在有意限定到业务输入和页面导航，不等待按压/释放、棋盘入场、700ms局部拼片reveal或成功提示全部idle。本测试没有截图或对装饰动画终帧的断言，原有输入/保存/可见范围断言仍有效；如未来任务需要证明某个局部动画终帧，须另加该对象的真实完成条件，不能把本ready函数作全局视觉稳定证明。当前未发现因此漏过本11阶段的必需断言。

## 运行来源与报告审计（只读既有证据）

- QA交接前SHA256 `f8a06d4a45bc8a70b7d015b897983c2321acc69f1fb06e0d8340173ffad6e9dd`。
- Android成功运行QA SHA256 `5d91605e46efdd00b6864013ec4714cbfeb9e88aa76a1e3d88d4f0f04c2f79cf`。
- 当前QA SHA256 `317f7e3a118f9cdce5da0fb74f3df8aca68ba78f5a586b7915bfb87163adf5fd`。
- 将当前routeSettled的单行if与Home if两处仅去括号，反向重建字节SHA与成功运行的5d91605e…精确相等；因此317f7e3a…相对成功运行版本确实只有这两处braces style。此审查未运行analyze，analyze通过属于架构既有记录。
- native-green-attempt-source.json去除QA harness/driver后的192生产文件集合SHA重新计算为 `7fee8c543972767564a96955d9ed2e095de3cc281d07657c9a280d4c001e109e`。成功证据属于R02/R03修复前这个生产集合，不能自动覆盖后来实现。
- android-fixed-pass-result.json记录官方host driver、emulator-5590、隔离ly_runtime.sqlite、显式ads disabled；exit0、outer_timeout=false、总47.240396秒。该总数含测试准备/构建与操作，不是App冷启动或性能指标。
- 从android-fixed-pass.log的完整LY_NATIVE_DRIVER_REPORT解析所得对象与android-normal-main-report.json**完整相等**，11阶段：level1/complete1/level2/complete2/level3/complete3/level4/complete4/reward4/sqlite-reopen/controlled-seven。
- 独立重新计算11阶段每个control的SafeArea四边界和48尺寸，无违规；所有scroll_before_action=false。实际viewport411.4286×914.2857、padding上51.8095/下24、字号1.0。hitTestable保持在运行源码并随该测试通过；JSON本身不能重新执行命中测试，本方不将纯bounds运算冒充新设备操作。

## 保留未验范围

不证明其他viewport/最大字号、全部结算分支的原生运行、人工画面、VoiceOver/TalkBack实听、触觉/音频、SIGKILL恢复、真机性能或商店发布。既有R02/R03独立Host失败及作者修复待复验状态不被本Android11阶段通过覆盖。这里只关闭“QA改动是否通过删弱断言换成功”的审查疑问，不关闭产品问题。

## 来源摘要

- `docs/development/review/one-screen-layout-evidence/qa-handoff-before.dart`：`f8a06d4a45bc8a70b7d015b897983c2321acc69f1fb06e0d8340173ffad6e9dd`。
- `app/integration_test/one_screen_layout_test.dart`：`317f7e3a118f9cdce5da0fb74f3df8aca68ba78f5a586b7915bfb87163adf5fd`。
- `docs/development/review/one-screen-layout-evidence/native-green-attempt-source.json`：`40d3ce4dd6e61b48dc1362835133c29b1279575e76bcd042b815cee7eedb15f2`。
- `docs/development/review/one-screen-layout-evidence/android-frame-diagnostic-3-callbacks.log`：`8edf2b3c5e8cc8265ae845ed9f55dbb302ef1e2b7d9b6b027c3b997c40b1efb6`。
- `docs/development/review/one-screen-layout-evidence/android-fixed-pass.log`：`697aac65bb853dc4fa619b48bf4e7b00d595709dd1a327608d4f2c2553fca9e6`。
- `docs/development/review/one-screen-layout-evidence/android-fixed-pass-result.json`：`7e87a10ea2230b402866bf86038afaf39a5479195dc3f373e841c3033c61e6bb`。
- `docs/development/review/one-screen-layout-evidence/android-normal-main-report.json`：`659d29400c7cb398ca33c6389e668ba19ba246d95481d39c1efa355c675ad336`。
- `app/test/support/flame_board_ready.dart`：`bd24c315e0c0cd90e2ef072b64a50c23d3c1c936459eadcdeb3adf49b9390280`。

本轮仅写本ui目录qa-wait-review.md；无CLI、设备、共享实现修改或git提交。

## 最后QA生命周期收尾增量独立核查

2026-10-23，只读补记。当前QA SHA256 `e17380cf95249919535ae4b5ba49fd5ecfd7fbb998cf32b84e731f6aae32897f`。从当前源码只移除close中“卸载前捕获GameScreen.audio”和“卸载后runAsync等待dispose25秒”的增量，精确重建先前9be9df8eb5488073ea2c51a4f3b071d5a3a204a99ff85b603df5b71117c12ea9。其余代码字节一致，Next的board/level11/新id和受控20/60的七瓶四个新增expect全部仍在，原bounds/hitTestable/SQLite/框架异常/最终binding约束未削弱。

### 生命周期同步判断

1. main.dart Bootstrap.dispose先controller.dispose/services.dispose，随后unawaited(audio.dispose)与store.close独立发起。close原来只等db.isOpen==false，不能推出两个播放器及其帧回调已经释放。这与iOS RED的“14阶段报告passed，但teardown尚有2个FramePositionUpdater._tick transient callbacks”吻合；这是整体exit1，不能按阶段报告说整轮通过。
2. 新close在unmount前取到真实GameScreen.audio引用，先pumpWidget(SizedBox)触发正常Bootstrap生命周期，再在runAsync等待audio.dispose().timeout25秒。没有在任何玩法/倒水/切页阶段预先停音乐，没有更换transport或修改SDK，仍先完成原14阶段断言。
3. GameAudio.dispose同步设置_disposed、关闭音/乐gate并更新revision，然后将真实_sync/transport.dispose串入_pending。重复调用时直接返回同一_pending。因此QA第二次调用是等待生产卸载已经开始的同一清理Future，不是重新创建播放器、清空调度器或另造成功状态。
4. _AssetAudioTransport真实await音乐player.dispose，并在finally处理effects.dispose。runAsync给原生异步回执实际完成机会；25秒超时不会当成功，也没有catch超时/取消测试断言。其后原DB关闭循环/断言仍保留，最终测试框架仍检查残留callback。
5. 生产音频本来使用best-effort _attempt捕获音频失败，QA没有新加吞异常。但“dispose Future结束”本身不能额外保证任何假设中的SDK资源都已正确释放；本轮整体exit0及binding teardown无残留才是成功条件。不要单凭result段passed重新掩盖收尾失败。

**结论：这段改动是合理的QA卸载同步，未发现通过停止玩法音频或抑制断言换通过。** main.dart与game_audio.dart的SHA均与既有生产冻结一致，未将生命周期测试修正混作生产/SDK改动。本方未运行CLI或设备；新生命周期同步后的最终双端结果仍由架构正在执行的命令决定，不在此预判。

### iOS RED核验与来源

已从ios-teardown-red.log实际解析14阶段result=passed及全部14个stage标签，同时找到2条FramePositionUpdater._tick注册栈。ios-teardown-red-result.json记录exit1、无outer timeout、运行QA为9be9df8e…；不能把该版本的Android成功与iOS阶段成功合并成双端整体成功。

- `app/integration_test/one_screen_layout_test.dart`：`e17380cf95249919535ae4b5ba49fd5ecfd7fbb998cf32b84e731f6aae32897f`。
- `app/lib/main.dart`：`3dc0ac83ee0b6c5e60f8be4b3fa98e958a1d7c99595e38c3c31497cb330d009a`。
- `app/lib/application/game_audio.dart`：`be18a8521a8f0874a5135dfa814bdca8ac153a25cc47ff65726a711a86817b8d`。
- `docs/development/review/one-screen-layout-evidence/ios-teardown-red.log`：`593aedddd12bfb3b38e0505d7e4c39c81d3ec1af03e70ee70d2f46c89196060a`。
- `docs/development/review/one-screen-layout-evidence/ios-teardown-red-result.json`：`5047075e663cd0491af2a0c739b44372c30a7a5164ccb830d276a368e5e2bbcd`。

本补记仅只读并更新ui文档，不占CLI、设备；既有RELEASED状态不变。
