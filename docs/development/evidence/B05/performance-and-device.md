# B05 性能、稳定性与设备边界

2026-10-22。当前可运行设备只有 GDF-Remaining-20261020，UDID4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2，iOS26.5 Simulator；Mac为Apple Silicon。Flutter3.47.2/Dart3.13.2，QA debug构建。未连接Android或iOS物理设备。按[Flutter官方性能说明](https://github.com/flutter/website/blob/main/sites/docs/src/content/perf/ui-performance.md)，profile性能应在物理设备测量；Simulator/debug不代表release表现。

## 已测诊断（不是移动设备阈值通过）

`lifecycle/diagnostics.json` 原始样本、`diagnostic-summary.json` 汇总。QA standalone入口加载随包90题、实际sqflite、可选网络服务disabled。该启动不是完整生产Bootstrap端到端耗时；Stopwatch从Dart入口开始，排除原生进程/Flutter引擎启动。主机测量另从simctl launch前到ready文件，二者不能混为同一个冷启动指标。

初轮8次启动：Dart入口→首帧486～617ms，中位515.5ms；主机launch→ready1,423.97～2,459.01ms，中位1,504.33ms。同一模拟器/同一二进制，样本小且debug影响大，不能宣传“冷启动达标”。重跑双槽后的数据单列lifecycle-final，不把两批混池。

第11关10次真实倒液/撤销，900ms生产动画参与；并做10次**即时**提示请求/取消（不是持续2秒的最坏棋盘搜索）。521个Flutter FrameTiming：build中位5,352µs／p9516,556µs／最大39,726µs；raster中位649µs／p95883µs／最大3,213µs；total中位23,456µs／p9533,037µs／最大57,838µs。total包含调度与流水线等待，不能直接作为raster时长或“60fps通过”。10次取消完成中位213µs、最大7,639µs；旧提示未应用。取消包含isolate调度竞态，不代表困难题求解速度；现有core90题求解预算检查是桌面样本。

RSS从498,860,032到517,718,016bytes，过程峰值618,266,624bytes（含Simulator/debug引擎/缓存/诊断开销）。这是短序列的操作系统ProcessInfo RSS，**不是泄漏证明、Dart retained heap或真机内存预算通过**。本轮未运行长时 Instruments/Android memory profiler 或物理设备压力测试。没有为这些数字设定虚构通过阈值。

## 稳定性与离线边界

- 实际sqflite事务/动作保存、七个保存/揭示阶段SIGKILL、动画中SIGKILL、同安装原库精确恢复，SQL integrity/schema5和奖励归属由lifecycle脚本断言。
- 本批H实际SELECT错误（R03）和snapshot/receipt等写故障分开验证；网络SDK的失败/超时/disabled不阻塞本地核心，完整host回归包含相应测试。N与L使用本地题库，未等待Firebase或真实广告库存。
- 普通Bootstrap手动检查使用真实音频/界面与明确disabled服务配置；没有把WiFi图标或Mac仍联网状态当作实际断网。真实网络隔离、弱网、OS广告覆盖层中断仍是代表设备待验项。
- 旧已验B03七瓶同尺寸、固定标签、系统Reduce Motion与音频回归继续有效；B05服务页面新增实际短屏大字/语义/滚动/确认检查。不以widget semantics代替VoiceOver/TalkBack或物理听感。

## 代表真机复现步骤（可直接执行；本批未运行）

1. 由设备负责人连接授权设备，记录型号/系统/刷新率/电量/温度/低电量/工具链。`flutter devices`确认真实设备，禁止选择Simulator为profile测量替代品。使用明确隔离数据库，保留普通用户存档。
2. 在app/运行 `FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter run --profile -d <physical-device-id> --dart-define=POURLUNE_DATABASE=b05_device_profile.sqlite --dart-define=POURLUNE_AD_MODE=disabled`。Android无需iOS环境变量。iOS需要负责人提供正式授权的开发签名条件；没有就记录受阻，不伪造签名。该场景测离线核心，不计真实服务性能。
3. Dart DevTools Performance录制：冷启动5次、相同第12关倒液20次、6/7瓶及大字号/减少动态、提示正常完成与取消/重开/后台各10次。导出timeline JSON，并记录frame count/build/raster/错过设备帧预算的比例。Dart入口、首个可操作画面与原生启动分别计时，不用肉眼估计ms。
4. DevTools Memory做warmup→snapshot→50轮pour/undo/hint/导航→强制GC后snapshot，记录Dart heap/retained对象；iOS Instruments Allocations/Leaks或Android profiler另记native/RSS峰值。避免将一次RSS增长定性为泄漏；需要稳定复现与对象归因。
5. 在系统真实断网及弱网条件重复启动、Continue、昨日每日、免费提示/撤销/重开与保存；核对SDK不可用文案、恢复网络不自动弹广告。恢复网络设置；不要把测试环境写成产品配置。
6. 在有真实官方测试库存、合法UMP配置及外部项目后，另测展示/奖励→SQLite、仅关闭无奖、锁屏/来电/后台/读屏/音频焦点；这部分不能由disabled基线或B05受控回调代替。保存原始日志、设备录像/截图、SDK请求结果与独立验收结论。

真机测量前不填写“性能达标”“零泄漏”或“全设备无障碍通过”。

## 最终双槽/揭示补强重跑数据

lifecycle-final/diagnostics.json与diagnostic-final-summary.json：8次入口首帧492～687ms、中位528.5ms；主机launch→ready1,457.64～2,465.89ms、中位1,471.975ms。519帧build中位5,796µs/p9514,501µs/max60,365µs，raster中位654µs/p95877µs/max1,166µs，total中位23,703µs/p9531,785µs/max62,077µs。10次即时hint取消中位186.5µs/max7,256µs，无旧提示应用。RSS517,636,096→456,359,936bytes，峰值667,762,688bytes。不同轮RSS一升一降体现缓存/GC/环境差异，不能断言有/无泄漏。最终L12次SIGKILL，两槽保留；揭示前明确预解码4图、重新进动画，opacity0.5364295后及时终止，恢复/确认/再冷启动不重播。该资源预热仅保证中断像素可检查，不是冷素材加载时间指标。所有数据仍是Apple M4/iOS26.5 Simulator/debug诊断。
