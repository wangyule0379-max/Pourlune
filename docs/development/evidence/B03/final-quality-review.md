# B03 一次新上下文整树质量审查与一次修复

2026-10-22；reviewer `/root/b03_final_review`，gpt-6-astra/high/fork none；只读，无二次审查或子审查。范围为已接受基线c5aa1514之后tracked+untracked B03工作树，包含计划/规则/代码/自动验证和实际图。原结论“With fixes”：3 Important、1 Minor，未发现新增事务/奖励幂等/题目版本兼容阻断。本文由执行方记录原反馈与修复，不是架构独立验收。

## Important一次修复

1. 倾斜窗反向旋转＋直立固定高度导致可见液量变化（review采样1unit24.76%→9.57%，.5unit12.11%→1.44%）。`liquid_volume_test.dart`真正渲染BottlePainter，按绿色像素覆盖比较.5/1/2/3/4units在0/−1.05/.6/+1.05/回位的面积，先有效失败，再以旋转圆角窗的水平面积分位点绘制色段。只用stdlib几何采样/二分，不引入流体模拟或依赖。测试以4x像素容许4%抗锯齿误差。所有25姿态通过；不再只计算model单位求和。测试初始FakeAsync截图需runAsync的harness问题已修正，不拿编译/等待错误作为有效RED。
2. 应用开关false、系统减少动态true时仍移动/倾斜/摇晃。`system_motion_test.dart`先有效失败（选择抬升），然后BoardView消费MediaQuery与应用/动作标记的有效偏好，倒水180ms静态高亮、选择不抬升、拒绝不摇晃、无水流。新增用例同时检查位置/角度/流/180ms回调，无业务状态改变。系统变化仅影响表现，不改持久化偏好。
3. 普通主线/每日/重玩通关无独立动效。`completion_presentation_test.dart`先缺少feedback失败，再增加每实例key的局部标题700ms淡入/轻微缩放，低动态150ms仅淡入。仅clean且有成功receipt才出现；失败保存仍显示待保存文本。验证三种真实核心完成与SQLitereceipt、opacity由0→中间→1、rebuild不重播、低动态时间、没有额外receipt或状态变化。动画不提供保存/发奖回调。

有效RED日志：review-liquid-red.log、review-system-motion-red.log、review-completion-red.log；针对GREEN：review-fixes-green.log（3/3）；修复后全量Flutter82/82，analyze无问题，format45文件0改动，双端debug重建通过。核心/内容未改，保留30Dart/27Python/release90/10资产检查。原生校准追加系统减少动态、主线/每日/重玩标题midfade/settled实际组件，10秒通过；`native-runtime/calibrated/`最终29张PNG。实际原生midpour已查看液量，标题中间/完成帧已查看，系统减少动态帧无倾斜/移动/水流。QA输入与真实玩家进度区分，不声称设备系统开关被操作。

## Minor deferred

同一连续同色区仍逐单位绘制形状（满蓝4方形），原规格偏好每连续色段1标记。功能/语义可用，不改规则；按本轮复核流程保留为独立视觉验收可见的轻微待办，不包装成已修复。

## 复核方Declined to judge的执行裁定

- 商业权属/最终独立视觉认可：维持候选和UNCONFIRMED，不由执行质量检查升级；符合批准B03边界。代价：发布前仍需权属、架构独立视觉验收。
- 真人难度/重复感/主观听感：保持未验证，自动参考操作/求解/解码不冒称真人体验。代价：内容节奏与音量仍需人类评价。
- Android实际运行/物理设备性能/系统音频中断/真人读屏：保持明确未测，双端构建不替代。代价：设备问题可能在后续专项验证发现。
- Firebase/AdMob/支持地址/签名：维持批准B04范围，缺失时界面诚实反馈，不引入假SDK或占位服务。代价：本批不能发布商业上线。
- tracking/B02验收等其他聊天文件：不编辑、不覆盖它们，也不把它们的外部diff归本任务。代价：最终阶段状态由架构方整合。

没有第二次复核；三个Important由执行方按有效RED→GREEN和全套回归关闭。保留一个Minor和所有真实外部依赖。批准计划/规格/原图不改，无提交/暂存/推送/进入B04。
