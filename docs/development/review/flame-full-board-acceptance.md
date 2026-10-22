# Flame 完整棋盘独立验收

2026-10-22，产品架构独立验收。结论：**FB01–FB08 在下列可用环境与证据范围通过；FS-M01 容量同步关闭。允许提交并推送开发分支，远端 CI 待该精确提交运行。** 不合并 main、不发布；本结论不扩展为代表真机性能或外部服务通过。

## 候选与隔离

基线 `24bb1637f046e500946d770ca4808cef39687c74`（含已验页面转场）。独立校验交付冻结清单 115 个运行源码文件及双端候选二进制，零不匹配，见 [source-verification.json](flame-full-board-evidence/source-verification.json)。运行源码包 SHA256 `5b596b426cb6b57dcfaa91da109737d60fdcc882634d26e6bc7af5b68b083eb4`。

本轮创建隐藏 iPhone 17 / iOS 26.5 验收设备 `255890D5-B4A3-42F9-B1A2-409E77118348`，安装冻结 after 包，身份 `dev.pourlune.fullBoardValidation`；Android 使用独立 headless `Pourlune_FullBoard_API36` / `emulator-5588`，身份 `dev.pourlune.pourlune_dev`，APK SHA256 `5d59032ac2f9de11fd71fa50feefa6e9924a8756ae99edd63115477f172b2fdd`。两端仅使用 `flame_full_board.sqlite`。

用户正在体验的 `F9C16DE7-01D8-4740-B796-A3A2DB8C3265` 本轮未安装、启动、停止、重置或注入输入，也未切换其 Simulator 窗口。普通安装、Firebase QA、原 UI 原件保持保护。普通 `b04_review_r2.sqlite` 只读摘要另见 `protected-state.json`。

## 独立执行与证据

- 实际读取生产 Flame 组件、BoardView 接入、控制器 presenter 计数、样板同步差异、测试与正常 main QA 驱动。核心/事务/奖励逻辑无改动；表现层不写奖励或保存半动作。
- 本轮独立 `flutter test` **219/219**，`flutter analyze` **No issues**，源码及交付文档 `git diff --cached --check` 通过（原始构建日志保留工具尾随空格，不改写证据哈希）；日志见 [flutter-tests.log](flame-full-board-evidence/flutter-tests.log)、[analyze.log](flame-full-board-evidence/analyze.log)。Dart格式检查119文件0改动，Python 驱动时间域检查 **2/2**。未把作者 30 个 core 自测写成本轮独立复跑。
- 在以上两个设备分别运行冻结 App 的正常 `main()` / Bootstrap，使用真实 Flutter 指针、真实 Flame 绘制和原生 sqflite。独立每端 **43 步**，包括主线 4–7 瓶、部分容量、跨行多单位、暂停、Home、每日双槽、重玩、保存失败/Retry、真实本地结算/拼片/Next、设置。结果见 `ios/after/independent-route.json`、`android/after/independent-route.json`。这是 standalone 正常 main 插桩，不是 DDS 集成 runner，也不是 HTML 或替身 SDK。
- 独立各 **45 张**实际棋盘关键帧及状态。逐张数值核对整数容量和连续液量（含在途水流）守恒、0–4 边界、同尺寸点击区域，见 [independent-frame-check.json](flame-full-board-evidence/independent-frame-check.json)。人工查看靠近、中段、落稳、跨行回倒关键帧；同时读取作者前后原速连续录像并按时间抽帧复核，见 `video-ios/`、`video-android/`、`video-before/`，不把单张截图当动态或运行验证。
- 独立真实 OS 后台/前台保持同 PID；同安装 SIGKILL 后启动为新 PID，安装签名/路径未变。恢复普通/每日槽、设置、额外瓶、首通/回执/拼片一致；动画 token 清空、展示贴合完整落盘结果；原生 Undo **7→6** 且保留额外瓶。两端证据 `same-process-background.json` 与 `same-install-restore.json`。

## 逐项裁定

|任务 / 适用 AC|独立依据与观察|结论|
|---|---|---|
|FB01 / AC01–04|正式 BoardView 仅一个 Flame 画布，正常入口使用真实实例。生产代码不导入样板夹具；只读预览不 attach presenter。219 测试及双端43步核验实例切换与结算。|通过|
|FB02 / AC01/02/31|4/5/6/7 同尺寸两行；几何测试覆盖七瓶42方向、1/2/4单位、15ms采样、320宽/2x字号标签避让；双端原生上下跨行与边缘实绘。四种符号/目标标签与高对比保留。大字号原生作者证据经审阅，未扩展到全部真实手机。|通过，环境限制保留|
|FB03 / FS-M01|靠近时尚为4/4、0/4；四单位流水实测中段2/4、2/4，落稳0/4、4/4。iOS中段 out=2.649、arrived=2.336，连续差额在水流；整数来自两端共同 round((out+arrived)/2)，总量一致。存档已一次提交完整动作，不因显示分段写库。语义/文字同源；样板专属实际 widget 回归包含本轮219测试。|通过，FS-M01关闭|
|FB04 / AC02/05/06/07/08/31|选中抬升、取消/非法反馈、免费提示/撤销/重开、额外瓶权益、收流回正、按设置减少动态与静音。实际双端辅助路径；错误美术禁止指针/语义动作，Retry不改业务；真实资源载入失败/卸载回归通过。|通过；真机音触觉未验证|
|FB05 / AC09/10/11/12/24/33|旧 token/revision/实例回调测试、presenter 替换计数回归；双端保存失败留在棋盘，Retry后只导航一次；真实后台/同安装强退恢复完整动作，撤销历史及双槽权益一致。通关事务各时点故障仍由已有自动回归覆盖，本轮新原生中断为非通关四单位动作。|通过；不扩大原生事务时点范围|
|FB06 / AC04/09/11/12/15/16/22/24/28/32|已验T基线与Flame组合实际流程：初入、恢复、暂停、Home、每日、Replay、奖励/Next。活跃棋盘1、画布1；离开Home后0。旧 Effects/资源释放、首次点击在入场中就绪、减少动态和返回门控保留。AC15/16/28/32特殊广告/最终关边界仅沿用未变的自动覆盖。|组合回归通过|
|FB07 / AC01–12/22/24/31/33|219独立测试、双端43步、后台及同安装SIGKILL。iOS观测→kill完成24.7ms，Android118.2ms，时间域与原250ms门槛保留。|通过|
|FB08 / AC31/34|源码/包哈希、设备与模式、原速前后录像、关键帧、作者诊断样本和局限完整。Firebase none/广告disabled核心入口可用；未新增完整飞行模式矩阵。|交付证据通过|

## 异常、诊断与保留范围

没有发现需阻止本批提交的生产 P0/P1/P2 缺陷。

1. **Android 独立恢复取证的两次未通过尝试保留**：首次 `am force-stop` 完成距流水快照355.6ms，脚本250ms门槛拒绝（不计早期中断通过）；独立重启后所有保存字段一致。第二次准备命令未捕获 `out<1` 窗口而超时（不计通过）。见 `restore-first-timing-limit.json`、`restore-first-during.json`、`restore-first-after.json`、`restore-second-prepare-timeout.json`、`restore-recheck.log`。原因未确证到产品，不能简单归咎网络或主机。
2. 随后用同 App UID 的显式 PID **SIGKILL** 替代 ActivityManager force-stop，对齐 iOS 的精确进程终止方法；保留正时间域与250ms断言，实测dispatch113.9ms、完成118.2ms。首次启动命令与Android Activity退出发生竞态，确认无PID后再次显式启动，原待处理恢复命令完成；没有重装/清库，恢复及原生Undo全部断言通过。`review_driver.py`为架构独立设备和SIGKILL变体，未修改作者实现/工具。首次失败不被成功记录覆盖。
3. 本轮独立 `simctl screenshot` 写到工作区遇 Cocoa513/EPERM，已停止该取证途径，未更换路径/权限绕过或重复同尝试。没有新增架构 OS 全屏录屏；视觉依据为上述实际运行捕获、作者连续录像和独立操作路径，明确不同证据层级。
4. 继承 T-M01/P3 iOS轻微蓝色色阶；并行图像解码/静态几何缓存为非阻断优化候选。没有据此宣称真机60fps或启动性能达标。debug Simulator/AVD、资源/语义测试不证明代表真机性能、VoiceOver/TalkBack朗读、真实声音/触觉或生产签名运行。
5. Firebase Analytics/Crashlytics真实收件、真实AdMob展示/earned、Apple注册/签名、代表设备与权属等既有外部依赖不在本批通过范围。M01–M08仍需按原范围逐项收尾，不能仅因T和FB通过自动整批完成。

## 提交边界

只提交本批生产组件、BoardView/控制器及样板同步、相关测试/QA工具、已审阅交付与证据、本独立报告和tracking。页面转场源码/依赖锁/原始UI不重做；不夹带 `docs/development/evidence/motion-polish/` 未验内容。实现推送后记录精确CI，旧终态CI不复查。用户F9模拟器继续保留运行状态。
