# T01–T06 页面转场独立验收：首轮需修复

2026-10-22。结论：页面内转场与保存/输入保护在当前冻结候选通过本轮检查；**整批尚未通过，T-R01 冷启动白屏衔接需修复后复验，因此不提交该批实现**。不将作者200项通过直接当架构验收。

## 精确候选与独立证据

源码冻结zip SHA256 `8cbcd2e50b05dbeaab56c14cc8b2bd10fa46ab672d9455ba446edc776e178500`；本聊天核对归档和冻结源码清单无漂移。不是当前包含全棋盘未验代码的主工作树。iOS安装候选35个关键文件全部与artifact-manifest匹配；Android安装base.apk SHA256 `5144557ba16e30f65573094a9f25bdfebd3974da1c7b6e5c3e5de2534e0d5ba4` 匹配。

独立在 build/page-transitions-baseline/app 运行 page_transitions_test、motion_primitives_test、motion_polish_test、startup_motion_test：17 passed；analyze无问题。日志在 page-transitions-evidence/。测试覆盖旧页输入/焦点/语义隔离、快速返回、后台与销毁、模态防重、应用减少动态、窄屏大字号、保存失败、实例与场景滚动位置。

本聊天重新启动两端已安装独立QA，实际跑102步/11个GamePage，各errors=[]；读取新route报告并比较动态dev实例ID，确认本轮新运行，四个固定进度夹具ID不应被解释为旧报告。iOS设备3497E78D-608C-415C-8326-26E46F1B6E29；Android emulator-5586 / Pourlune_Transitions_API36。只有page_transitions.sqlite被runner重置。

人工iOS操作：设置/减少动态关闭/规则/重复返回、重置确认取消、返回首页保留收藏与重玩、继续重玩/暂停/Home。真实语义树、按钮和显示状态均核对。作者双端录像由本聊天抽取关键时段审阅，和独立实际操作相互补充，不能称本聊天录制。独立录屏一次被系统Cocoa513/-12204权限拒绝，未绕过或重试。

## 逐项结论

|任务/关联AC|结论|独立依据|
|---|---|---|
|T01 页面/模态盘点|页面内通过，启动覆盖缺口|代码清点、11页面102步、T-R01|
|T02 官方animations依赖|通过|精确3.0.0锁文件、实际官方FadeThrough/SharedAxis/FadeScale、17测试与analyze；未顺带升级服务SDK|
|T03 页面接入；AC11/12/16/24|当前候选通过|控制器权威；页面/实例/场景key而非动作revision；不保留旧棋盘双实例；两端新流程|
|T04 模态；AC31/32|当前候选通过|暂停/重开/重置/替换/每日日期/隐私/额外瓶/许可证路径；返回值门控保留，旧页不透点，单模态门控|
|T05 生命周期/保护；AC28/31/32/33/34|已测范围通过|独立17测试+保存失败Retry原生流程；人工取消保持状态；不冒充VoiceOver实测|
|T06 启动衔接、双端交付|需修复|双端实际流程正常，但录像及native源码证实系统白色启动页跳到蓝色Flutter启动；正式main冷启动仍需补证据|

## T-R01（P2）：原生冷启动仍白屏

iOS `ios/navigation.mp4` 在约2.6–3.8秒为白色启动页，4秒才出现蓝色品牌画面。Android `android/navigation.mp4` 约3–4秒为白底图标，5秒仍在跨色衔接。这里是录像位置，不是性能计时或设备达标结论。独立抽帧：page-transitions-evidence/ios-launch-frames.jpg 与 android-video-frames.jpg。

冻结 `app/ios/Runner/Base.lproj/LaunchScreen.storyboard` backgroundColor RGB全1；Android `res/drawable/launch_background.xml` 使用white，NormalTheme又用系统背景。Flutter StartupView的蓝色页面不能覆盖引擎首帧前的原生阶段。原有问题仍属于本次“启动→首页连续背景”的要求，不应按新增范围搁置。

修复给App UI：保持现有美术，以匹配Flutter首帧的原生品牌底色和允许的静态资源衔接iOS及Android（包括Android12+系统启动主题、普通主题和夜间配置）。不得加延时/假进度，不改核心规则或服务。实际查官方平台资料，双端重新取原生冷启动到首页证据；须包含正常main入口的专用QA身份/库，不只测试runner。保留当前页面内路线结果，仅复跑受影响检查，再由架构独立复验。

## 共享M与后续提交边界

审查了冻结候选依赖的M启动资源预热、按钮反馈、成功入场、旧BoardView入场和单位相关倒水时长；本轮未把M01–M08整体标完成。T候选task-only.patch相对M检查点，并非可直接套HEAD。通过后需按冻结版本明确纳入必要已验依赖，不能git add整个app夹带原开发正在写的Flame全棋盘、容量修复或控制器变更。

完整棋盘FB01–FB08、FS-M01容量同步与两批组合回归均仍待独立验收。模拟器debug不证明代表真机FPS、音触觉或读屏质量。受控进度/参考解/sqflite故障hook不等于自然通关、磁盘满、SDK成功或进程恢复。Firebase none与广告disabled；普通审查库、原UI及FirebaseQA未操作。
