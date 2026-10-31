# 液体按原稿调色 · 2026-10-26

状态：实现、有限检查和正常入口实图／动态已完成，父独立验收通过。未更新TestFlight14。

## 调整

按用户批准的P07无遮挡原稿调整既有五色。代码提交e61deb1；仅两个生产文件11行替换：
`app/lib/presentation/bottle.dart`共享palette，`app/lib/presentation/flame_board/paint.dart`白色提亮占比。
橙／绿／紫／蓝分别改为#ff9f46／#8fd342／#ad72e5／#38b5e8，玫红#e56c9a保留星形和独立色相。
主体横向渐变的大面积白色混合由.38降为.18，液面.48降为.32；其余局部玻璃高光、弧形液面、边缘和图层顺序保留。

细流原本直接读取源水层的共享palette，完成页原本复用paintBottle，均随共享调色生效，未复制新绘制分支。
同一混色盘实际查看：五色更鲜明，白边符号清楚，水层按自身身份显示；针织固定目标和米白缓冲外圈保持原资源。
未改布局、规则、题库、Hint、存储／奖励、动画时序、依赖、12瓶或九色讨论方案。

## 检查

在app/使用固定Flutter3.47.2及NoAdID环境串行执行：

- flutter pub get --enforce-lockfile：成功，锁文件未改。
- dart format两个修改文件：0变化；flutter analyze两个文件：无问题。
- 现有five_color_board_test、buffer_bottle_material_test、liquid_volume_test、completion_presentation_test：11项全部通过。
- 正常lib/main.dart iOS Simulator debug：before83.0s／after27.9s，两次构建均成功；独立身份和命名库，Firebase配置none、ads disabled。

本次是已批准视觉调色，以实际before偏浅画面作为问题证据，没有虚构自动RED或增加只断言RGB常量的测试。
不重复完整60题、全平台发布、字号矩阵或无关CI；本轮没有新分发。

## 正常入口证据

证据目录`docs/development/evidence/liquid-color-original-20261026/`：

- user-reference.png原字节保留；只参考左P07，不采P08／P09蒙层色。
- before-main31.png／after-main31.png：同一正式main31 v3初始混色盘，含五色、七瓶、米白缓冲。
- green-pour.mov：原生录屏17.458s；green-pour-short.mov为原片6.2–7.8秒的passthrough截段，无插帧／变速。
- green-pour-6.5s／6.7s／6.9s／7.0s.png：原片10fps提取的真实关键帧；after-green-pour.png为落定状态。
- after-five-target-completion.png：五目标完成页，真实最后一倒并取得正常保存完成回执。
- before-source.json／after-source.json／runtime-inputs.json：正常入口、设备、Runner／kernel与输入哈希。
- author-report.json／native-receipt.json／evidence-hashes.json及命令日志保存验证范围和来源。

本次inventory中旧63B／A4／F9均不在，故新建专用“Pourlune Liquid Color QA”
D79BD258-6E80-4B71-9A7D-E806F5321460（iPhone17／iOS26.5），未操作正在运行的普通2AE设备。
身份dev.pourlune.liquidColorValidation，库liquid_color_reference.sqlite。默认正常字号，原生图1206×2622。

QA准备明确：从历史QA只读快照克隆到全新专用库，替换活动实例为正式main31初始盘；不是自然解锁或人类首次试玩。
完成页阶段准备参考解前20步及完整undo历史，再以CUA实际点击第6→4瓶完成第21步。
首次准备漏了20条history，被正常解析器正确拒绝；仅修正QA准备脚本后重开正常入口，未改产品存档代码。

## 边界

父已实际对照P07、main31前后、6.5／6.7／6.9／7.0秒倒水帧、落定和五目标完成页，核24项证据及505运行输入。
本次五色与高光调整范围独立通过，见[父验收报告](../review/liquid-color-original-20261026-independent.md)及parent-independent.json；未以自查替代独立通过。
F9及其窗口、既有保护设备／数据库／TestFlight14冻结证据均未改。本次颜色未进入已发布14。
未验实体手机、完整首玩难度、其他字体／机型；这次小修不扩大这些验证范围。

代码与有限代表图／1.6秒短片和命令记录精确提交；17秒原片、其余逐帧图及父自有资料保持本地原字节，均有hash可核。命令原始日志保留终端进度尾部空白，不为格式清理改写原回执。
