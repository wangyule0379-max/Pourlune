# Flame 样板独立验收

2026-10-22，验收方：Pourlune ｜ 产品架构。

结论：**两瓶倒水与拼片入藏样板的实现、状态安全及现有双端运行范围通过，可提交为独立调试样板并供用户评审效果。用户视觉满意确认、完整棋盘扩展、代表真机性能均未通过/未授权推进。** 未将 M01–M08 或 T01–T06 页面转场标为完成。

## 被验版本与隔离

- 执行交付：`../deliveries/flame-sample.md`；计划 S01–S06：`../../pmpowers/plans/2026-10-22-flame-sample.md`。
- 冻结源码基线 `4a1120d7a2acf8618653b80cc72ecaae4e53cdeb`；源码 ZIP SHA256 `ec0e64b8739e23184b0039d8069317d0eda805ebfa918558e0ada8bcb6ac6cde`，架构实际校验并重建隔离副本。
- iOS 实际已安装 kernel SHA256 `cc61737d6675ae03e99947f4f251c6d14c81570c00ab22cf77b259aced51fae1`，与交付清单一致。Android 候选 APK SHA256 `72c53c300a979276e177a3eb54438d191b17030bf5d8b6a27870f6cbfc6bf1f7` 已复算。
- 双端真实 Flutter + Flame + sqflite 的独立 QA 入口；iOS `9B172C50-E5CB-4F3F-8F16-0A3DB04F495D`，Android `emulator-5584`。库只使用 `flame_sample.sqlite` / `flame_patch.sqlite`。
- 两轮 host 复验：冻结完整交付副本，以及基线仅叠加 Flame 专属源码/测试、GameAudio.finishEffect、Flame 依赖的独立提交副本。两轮分别 **25/25 测试通过，analyze 无问题**。第二轮避免把未验 M 和正在制作的 animations 实现打包提交。公共美术/sceneObjectRects 接口保持原基线；冻结原生录像包含当时 M 公共按钮表现，不将其视为 M 批次通过。
- 首次新副本缺少生成目录 `build/ios/SourcePackages` 导致 Flutter 插件复制失败；创建目录后通过。未修改 SDK、TLS 或依赖版本来掩盖失败。

## 独立证据与结论

证据根目录：`flame-sample-evidence/`。所有 architecture 原生路线、恢复结果均为本聊天新执行；作者的自查不替代这些结果。

|编号|实际核验|结论与范围|
|---|---|---|
|S01|读取入口/debug 命名库保护、session 隔离、main 无样板引用；校验冻结包；实际进入已安装样板，触发四单位倒水和拼片重播；对照原 Flutter 首页/棋盘录像帧|通过样板接入范围；前后不是相同瓶数/负载，不声称提速|
|S02|检查 geometry 的世界坐标多边形面积填充、瓶口同一变换、流出/流入/在途量；复跑几何测试；双端 1–4 单位左右方向各 8 路线；检查本轮原生截图、iOS 实际点击及录像 8.7–9.7s 连续关键帧|通过：瓶体弧线靠近、水平液面、对准、收流与回正可辨，未发现所检画面穿壁或末端脱口；不是物理流体仿真|
|S03|真实选中/倒入、取消、非法动作、不变形瓶体；本轮原生 snapshots、语义测试、窄屏2x字号测试|通过所覆盖动作；目标标签/缓冲瓶身份保留。下述容量文案提前显示最终值列为 P3 打磨项|
|S04|检查 reserve/instance/revision 和实际主线4回执；双端原生合法准备→完成→保存→贴合；录像26.2–27.2s关键帧及本轮 patch-flight/attached；手动重播|通过：拼片是实际窗户，飞至 Color Studio 左墙既有位置；揭示确认先保存，动画不写奖励，重播不重复入账|
|S05|host 覆盖保存失败、后台/返回、旧 reservation、reduced motion、重复回调、语义与音频结束；原生失败重试/重置取消/关闭声音触觉；两端分别实际同安装进程终止与重启|通过覆盖的状态安全；iOS PID 78153→86349，316.666ms 倒水中 SIGKILL；Android PID 22064→23910，433.333ms force-stop 并核对进程消失。完整 instance/saved/settings/first_clears/receipts/pieces/revealed 一致、锁释放、无半笔动作。非重装恢复|
|S06|本轮双端各13个原生路线通过；dispose/有限effect/订阅/两张图片资源所有权代码及host测试，作者idle/dispose证据交叉审查；新帧耗时样本1411/1128|证据交付通过；真机性能不通过。原生QA使用LiveWidgetController实际pointer和真实插件，不是成功DDS integration runner，也不是无取证开销的正式入口性能|

AC 映射：AC-01 仅样板合法转移/守恒范围；AC-02 取消/非法无动作；AC-09、AC-12 真实隔离奖励/揭示去重；AC-11 样板保存失败/重试门控；AC-31 窄屏2x字号、语义、减少动态效果/开关；AC-33 双端同安装恢复。AC-32 只覆盖样板连点/返回安全，本批无广告展示，不重标真实广告 AC 通过。

## 视觉与性能限制

架构实际操作 iOS 样板，并检查双端本轮原生截图、原交付录像抽帧序列及原 Flutter 对照帧；不是把一张静态图当作动画或帧率验证。可播放完整录像保留于 `../evidence/flame-sample/ios/route-review.mp4` 和 `android/route-review.mp4`，由用户最终确认是否达到期待的游戏感。

本轮混合 debug/JIT/取证/同机其他工作负载下，iOS build/raster p95 为 23.788/1.489ms；Android 为 119.781/48.651ms。明显不能宣称稳定60fps，也不能直接与作者另一时段的数字作提升/退步对比。数据见 `native-summary.json`。代表真机 profile、原生音效听感/触觉、Android 系统读屏遍历仍未验；不因已运行样板就关闭这些边界。

P3 / FS-M01：倒水尚在表现时，瓶下容量与语义先显示已提交最终值（例如源0/4、目标4/4，液体仍在流动）。不影响权威存档或动作安全，但会削弱视觉与数字的一致感；进入完整棋盘前应明确“已提交值”或统一表现时机，不应为了动画延迟落盘。此项不阻止两瓶样板效果评审，不作为全棋盘已完成。

没有发现阻止本轮样板交付的 P0–P2 缺陷。用户尚未确认满意，**不得自动扩展完整棋盘**。Firebase收件、AdMob、正式签名/商店和代表设备等既有外部边界维持原状态。

## 并行转场交接

原执行方于 `2026-10-22T15:27:10+08:00` 明确 RELEASED。App UI 已实际接手 T01–T06 并解析 animations 3.0.0；两个短架构 CLI 窗口结束后均明确释放，记录在 `../deliveries/ui-transition-handoff.md`。App UI 使用独立模拟器/身份/库，不覆盖 Flame 或普通安装。其测试中的在制问题由其修复，未被本报告验收。

普通 `b04_review_r2.sqlite` 只读 SHA256 仍为 `dc94bbfd1e8b10cda675f139a822c39e83dcc38bdf830c3a245d2221da9978c6`，未启动、重装、清理普通设备。后续提交只含 Flame 专属边界及独立验收，animations/M 工作区保持未验状态。

## 提交与远端状态

Flame 专属实现、交付及本报告已在 `c529e8e2cac8afa8266cfd7a3a1b983946fcbc69` 推送到 `origin/codex/offline-foundation`。冻结 Flame pubspec/lock 已按文件内容单独暂存，工作区 animations、M 与页面源码保留未提交。新 push CI `39743348698` 已确认指向该精确提交，初读为 in_progress，尚不宣称远端通过；后续由跟进记录终态。纯文档记录不要求重新执行代码CI。

## 后续用户确认与扩展授权（2026-10-22）

用户明确表示“样板效果可以”，并授权完整棋盘扩展及容量数字/动画同步修复。此前效果确认门槛现已满足；执行按 `docs/pmpowers/plans/2026-10-22-flame-full-board.md` FB01–FB08 推进。FS-M01 转入该批必修事项，尚未复验关闭。本记录不把后续完整棋盘或真机性能提前视为通过。

## 远端 CI 收尾（2026-10-22 08:19 UTC）

精确提交 c529e8e 的 run 39743348698 终态 failure：iOS 构建成功，Ubuntu Flutter 测试 181 通过、1 失败（b04_hint_events_test.dart:65，预期两条提示结果事件，观察到一条），Android APK 构建未执行。证据 `flame-sample-evidence/remote-ci-final.json`。FS-CI01 已派原开发定位修复；25ms 固定等待是待验证时序假设，不认定网络问题或简单重跑。此前独立样板运行结论保留，远端整体验证尚未通过，修复需独立复验及新提交 CI。
