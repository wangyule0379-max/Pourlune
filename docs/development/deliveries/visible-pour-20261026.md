# 可见连续倒水修复 · 2026-10-26

状态：本次可见连续倒水修复已获父独立实际验收通过，限正常字号、七/八瓶代表及44项聚焦检查。本次未发布，TestFlight14冻结。

## 问题与修复

源提交3a52129。仅修改既有geometry／game／paint三个生产文件，新增visible_pour_test.dart四个真实回归。
复用上一轮原速片，未重新制造before：bounded瓶口距离约4.83逻辑px，水流约2px，且Flame序列把几何时间压入旧的另一总时长。
单层实际Flame中间可见转移窗口仅140ms；水流只画到接收口，玻璃颈内断开，水池却在下面增长。

修复沿用同一out／delivered／head／tail及水层：

- 流出设计时长依水量为560／660／760／860ms，整个动作1160–1460ms；Flame实际使用同一几何总时间，不再二次压缩。
- bounded口距为瓶宽*.30，按小画布保留8–26px边界；正常约24px。原有边界适配、选择起点和归位路径保留。
- 有色水柱约3–4px，并继续保留细高光。它从真实源口连续落到接收液面的实际位置；接收颈部以下严格clip到玻璃内腔，避免穿壁。
- 接收水面由当前frame水层总量计算，水流尾段随同一进度收束，再归位；没有另建一套业务状态。

新五色调色保持；静止布局／固定目标／米白缓冲不变，没有恢复整排临时读数。规则、动作一次提交、题库、Hint、存档／奖励、依赖及12瓶九色讨论方案均未改。
减少动态仍走原120ms短呈现，无强制完整倒水；原有后台／换实例／卸载的取消与token门控保留。

## 验证

在app/、固定Flutter3.47.2／NoAdID环境串行运行：

- enforce-lockfile成功，锁未变；四个相关源码／测试局部分析无问题，format通过。
- 新回归先RED：口距4.83<18、实际单层中间窗口140ms<250；修复后GREEN。
- 首轮正常实拍仍暴露接收颈内无水柱，补真实raster回归先RED（空玻璃内流入颜色0行），最终GREEN（至少20行连续颜色），不是RGB常量镜像。
- 最终10个相关测试文件44项通过：visible_pour、flame_full_board_geometry、motion_arrival、selection_pose_geometry、flame_session、flame_full_board_widget、motion、liquid_volume、p05_geometry、five_color_board。
- 保留原有液量、水平液面、墙内裁剪、边界、选择／归位、取消、减少动态守卫；未删守卫换绿。
- 正常lib/main.dart iOS Simulator debug最终构建成功25.9s。未重复全60、全平台发布或新字体矩阵。

## 正常main原速证据

目录`docs/development/evidence/visible-pour-20261026/`。native-source.json记录source／Runner／kernel及身份，runtime-inputs.json记录506个源码/资源输入（清单含测试）。与a9b4159相比只有上述三生产输入改变。

专用D79BD258-6E80-4B71-9A7D-E806F5321460（iPhone17／iOS26.5），独立身份dev.pourlune.visiblePourValidation、独立visible_pour.sqlite，正常字号、1206×2622原生图，Firebase none、ads disabled。
旧liquid_color_reference.sqlite及其App身份未覆盖；F9／普通2AE／历史保护设备库均未操作。

| 原速短片 | 真实操作，索引从0开始 | 原片区间 |
|---|---|---|
| single-original-speed.mp4 | 七瓶0→6，1层玫红，跨行向右 | single-original.mov 9.45–11.35s |
| double-original-speed.mp4 | 七瓶1→5，连续2层绿，跨行向左 | double-original.mov 10.65–12.55s |
| eight-right-original-speed.mp4 | 八瓶4→7，连续4层玫红，右侧第八瓶 | eight-original.mov 10.9–13.0s |
| eight-left-original-speed.mp4 | 八瓶7→4，连续4层玫红向左 | eight-original.mov 41.9–44.0s |
| eight-up-original-speed.mp4 | 八瓶5→3，连续4层蓝，跨行向上 | eight-original.mov 69.85–72.35s |

三段原片保留工具操作等待，所以另提供1.9–2.5秒无变速passthrough截段；没有插帧或用慢放冒充可见性。
clips.json记录区间／hash，video-metadata.json由系统AVFoundation读取时长、尺寸和source-to-presentation映射，均1:1。
录屏为可变帧率，原片含大量静止等待，其nominal fps与剪掉等待后的短片不同；这些数值不是性能测试或帧率保证。
单层／双层／八瓶目录关键帧覆盖起流、流中、收流和归位；作者实际查看中间水柱和两端水面，未发现新实质遮挡或穿壁。

七瓶另实际第三次合法倒水中点击Simulator Home进入后台，按AX先确认动作disabled，再回同一PID24087；3步已保存，瓶子归位、输入可用。
证据cancel-active.txt／cancel-resume.txt／cancel-resumed.png／seven-cancel-receipt.json；不是重装当恢复。
八瓶随后实际完成三次4层操作，最后正常回执23步、同实例1回执、integrity ok，见eight-receipt.json和eight-completed.png。

QA准备明确：历史QA快照只读克隆到新命名库；七瓶为正式main31初始盘，八瓶为参考解前20步及完整undo历史＋一个额外空瓶的准备状态。不是自然解锁、人类首玩、完整通关或真实广告奖励。
first-pass/保存第一次实拍及源哈希，仅用于解释接收颈断流的追加修复，不是最终通过证据。

## 未验及后续

父已实际检查11张最终原速时间对应帧，核69项证据、506项输入及当前Runner/kernel，并独立读取3原片与5短片容器时长和1:1映射。结论通过，见`docs/development/review/visible-pour-20261026-independent.md`和`parent-independent.json`；父未声称连续观看全部原片，也未重跑工具链或独立查库。`author-report.json`保留冻结送审时的pending状态，最终结论以独立报告为准。
未验实体手机、全题库／全字体和商店新包；本批没有新CI／签名／上传，不修改已发布14。
本任务范围是可见倒水，后续仅按实际问题反馈返工，不扩物理引擎、十二瓶九色或其他制作。

留存边界：本批提交最终5段原速短片、25张原生关键帧、恢复/完成截图、来源清单和聚焦检查日志；3个完整MOV与first-pass历史仍保留本机原路径，不纳入本批Git提交。69项冻结哈希也记录这些本地原件，独立验收时全部在场核符。
