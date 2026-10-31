# 橙色与可见瓶口间距 · 2026-10-26

状态：源9006a25实现、45项相关检查和正常main实拍完成；父已独立实际验收通过，限正常字号七/八瓶代表范围。本轮不发布，TestFlight14保持。

## 对应要求与改动

依计划2026-10-26-visible-pour.md末节，仅两处生产修改：

- bottle.dart共享橙O由#ff9f46加重为#ff8218，更接近饱满的橙色针织圈。另四色、渐变及高光不变；静止、流出、接收、完成页复用同一palette。
- geometry.dart不再只留水流接点的固定距离。按原素材顶部17%口圈/接缝的保守包围范围，算旋转后相对源lip向下的延伸，加接收圈上沿及8–16逻辑px的可见余量。此延伸随运输scale缩放，与画布拟合共用同一线性anchor/delta。

paint/game/frame、560–860ms流出和1160–1460ms总节奏、体积进度、垂直接点和归位保持；未改控制器、规则、题库、Hint、存储/奖励、锁或静止布局。未恢复临时整排读数。上排仍沿用画布边界缩放，实际运输大小会随新间距变化，提供真实图供独立判断，不声称飞行尺寸字节不变。

## 自动与构建

新增orange_pour_gap_test使用真实BottleArt和paintBottle分别渲染原素材top17%口圈，取实际不透明像素外沿，独立于生产包围计算；左/右/跨行、1/4层、起中尾共18采样。
先RED：4→7单层10%时实际外沿间距-11px（重叠）；最终GREEN：采样均≥8px空隙。首次未将口圈延伸耦合scale的试验会让上排源被裁空，已被同一素材守卫拦住，日志green.log保留失败，最终以green-coupled.log为准。

app/中固定Flutter3.47.2/NoAdID串行运行：enforce-lockfile、3文件format/局部analyze、原44项加本次1项共45相关检查通过；没有删旧边界/液量/选择/归位/取消守卫。正常lib/main.dart iOS Simulator debug构建34.4秒成功。未做无差额全题库、全字号或商店发布构建。

## 同源正常main实际证据

目录docs/development/evidence/orange-pour-gap-20261026/。native-source.json记录9006a25、已安装Runner/kernel、独立身份与冻结只读副本定位；runtime-inputs.json共507项（含测试）逐项与工作树/提交核符。before.json直接引用上批原件，不重做before。

专用D79 iPhone17/iOS26.5，dev.pourlune.orangeGapValidation、orange_pour_gap.sqlite，正常字号，1206×2622，Firebase none、ads disabled。旧visible_pour/liquid_color库不覆盖，普通2AE、F9及其窗口不动。

mixed-main31.png为真实七瓶混色；completed.png为实际五目标完成页。作者已看单层20.20、下倒17.50、左倒45.20、上倒24.60/25.00、蓝色78.80及两静态页，所看帧口圈有清楚空隙，流到接收液面，颜色饱满一致；自查不代替父验。

| 原速片 | 真实动作（0起索引） | 原片区间 |
|---|---|---|
| single-original-speed.mp4 | 七瓶2→6，O1 | single-original.mov 19.5–21.5s |
| down-original-speed.mp4 | 八瓶0→7，O4，右下边缘 | eight-partial-original.mov 16.7–19.0s |
| left-original-speed.mp4 | 八瓶7→6，O4，向左 | eight-partial-original.mov 44.35–46.65s |
| up-original-speed.mp4 | 八瓶7→0，O4，跨行左上 | up-original.mov 23.9–26.2s |
| blue-final-original-speed.mp4 | 八瓶5→3，B4，跨行右上/完成 | up-original.mov 77.85–80.35s |

系统AVFoundation passthrough截段，未变速/插帧；clips.json给区间/hash，video-metadata.json映射1:1。完整原片含工具等待，VFR数值不是性能保证。single/eight/up-frames为原生提帧，非合成动画。

QA准备：历史隔离快照只读克隆到新命名库；七瓶为正式main31初盘，八瓶为前20步参考解/完整undo历史及额外空瓶。首次两步作者实际操作21/22后，CUA报告用户更改Simulator；freshAX见29步，额外7步不归作者，原片与interrupted-eight-receipt.json完整保留。待状态稳定后从已观察29步继续作者7→0和5→3，最终31步/完成/integrity ok；没有重置或掩盖额外操作。此为准备QA，不是自然解锁、人类首玩或完整自主求解证明。

## 未验与接续

父已实际看11张新图/原速时间对应帧并核48项证据、507项提交输入和冻结二进制，通过本次颜色/间距范围；详docs/development/review/orange-pour-gap-20261026-independent.md、parent-source-check.json。父未操作设备、重跑工具链、独立查库或连续看完整原片。上排缩放如实记录，不扩大返工。author-report保留送审pending历史，最终以独立报告为准。未验物理手机/所有轨迹/全部字号。本批完整MOV在本地原路径保留，Git仅收有限短片/帧/来源/检查与报告。

橙色/间距来源与已安装二进制已冻结；后续tap-to-reselect独立提交/证据，不将其混入本次采集。未签名或上传新包，不改变TestFlight14。
