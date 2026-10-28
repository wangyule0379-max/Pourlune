# GameMunchies 正常入口隐私说明与真实测试广告验收

2026-10-28。属于原完整统计/广告控制任务；与已完成的地址专项分开，不表示新商店版本已发。

## 实际验收

- 源 `a928c13575a32e9efe30e9f99a57a5909b0c7021`：父读取差额，只有GM配置可用性的只读getter与隐私说明条件/文案，无采集或奖励规则变更。16相关检查、F15反馈4项及分析/格式为作者实际日志结果，父不重复工具链。
- 冻结normal-main iOS `0.5.0(18)` 独立QA，父重算361文件SHA全符。Runner `8a032d27b49446744b46b2d425c7b59a76f38d2b9878d6831124908e805ae9be`，kernel `46109851d3faa65f0a1c168c82a05c0268cc2584000aae1d0be82ddeddb17a5c`。新API、原test登记、Firebase none、官方sample广告。
- 父实际看隐私页：GM可用时不再误称全部诊断不可用；准确说明Crash当前不可用、Gameplay analytics按已保存选择执行。Analytics保留开启。
- 父实际看官方广告的Test mode与奖励已发放画面、后台展示计数。Computer只恢复已有每日局并点一次广告。test/iOS展示1→2，活跃2/开局14/失败28保持，时间15:23:50。
- 首次reward-return.png误存iOS Home，父实图检查后要求纠正。现图是恢复原每日局后补拍，父已实际看六瓶和禁用Bottle added；不是原关闭瞬间截图，不重放广告补证。
- 父以SQLite只读方式独立核对既有before/after私密备份：reward_attempts、reward_entitlements、fullscreen_shows各0→1；attempt为daily/done/confirmed1，entitlement匹配该attempt及同一每日实例，extra由false变true，瓶子5→6，题目与步数保持。报告不输出私密实例ID。

证据：`../evidence/prelaunch-closeout-20261028/gm-privacy-ads-r2/` 的report、5图及sqlite-aggregate。前后数据私密备份位于集成工作树ignored `build/gamemunchies-live-qa/ios-privacy-r2-private-before/`。父仅读文件与数据副本，不操作设备。

## 结论与限制

接受本批正常入口隐私说明、一次真实官方测试激励展示及后台统计、原实例持久权益差额；复用先前远程总开关/场景开关v2/v3/恢复v4和双端原生补传证据，不再重复同类测试。独立原生callback日志未输出，本次依据实际SDK广告、落盘事务及后台展示+1；不称真实商业收益、物理设备或Android手动广告验收。包核、实际TestFlight上传/处理/组安装仍属于之后原完整发布任务，本次地址切换没有上传。

按用户最新沟通要求，后续开发完成必要工作后一次性交付，父集中验收；不逐测试/提交/构建汇报。
