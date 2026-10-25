# Android 原生驱动有界根因调查

架构已收到CLI-RELEASED.json明确QA文件与5590交接。用户允许总控亲自解决卡住项。首轮仅增加QA帧计数/生命周期诊断，不改生产、SDK、断言或等待界限；保持原25s失败以定位泵帧未完成原因。

已读原失败：android-drive-steps.log，Home controller存在，ready中pumpAndSettle外部25s超时，随后_pendingFrame断言为清理阶段次生异常；还不能推定产品死锁或动画无限循环。

本机固定SDK的LiveTestWidgetsFlutterBinding.pump会在Timer后scheduleFrame，并等待handleDrawFrame完成pending completer；pumpAndSettle反复等该Future。因此下一步记录framesEnabled/lifecycle/scheduled/schedulerPhase/瞬时回调数和实际frame计数，区分无帧、持续动画与后台。官方API依据：https://api.flutter.dev/flutter/flutter_test/LiveTestWidgetsFlutterBinding/pump.html 与 https://api.flutter.dev/flutter/flutter_test/LiveTestWidgetsFlutterBinding/scheduleFrame.html 。上游warm-up issue132969只作调查线索，不认定本例同根因。

只读检查时5590 awake，专属App已按交接force-stop，当前focus launcher；这不证明前一次运行期间状态。SDK git status为空，无本地patch。不得以改SDK/强制帧/延长sleep掩盖待定位原因。

当前功能独立审查占用CLI，诊断尚未运行。F9和采集限制保持，日志不是视觉通过。


## 架构复现1（保持原失败门槛）

android-frame-diagnostic-result.json exit1，41.8秒结束，非外层240秒强制终止。期间Home一直resumed、framesEnabled=true、busy=false，实际帧累计9→212，瞬时回调持续3–8；因此不能再把超时解释为无帧/后台/业务busy。仍在原25秒settle门槛失败。下一步只增加当前帧时间戳与一次瞬时回调注册栈，定位持续调度来源，未改等待/断言/生产文件。UI当前执行窗口期间不会启动第二个Flutter/Dart命令。


诊断2首次instrumentation错误：在idle Timer直接读取currentFrameTimeStamp触发SDK合法断言，16秒退出；不是产品失败，日志以invalid-timestamp保留。改为仅在persistent frame callback保存其timestamp参数，Timer输出已有数值。没有改SDK或抑制该断言，复跑同一诊断假设。


Root cause confirmed: registration stack shows audioplayers 6.8.1 FramePositionUpdater._tick scheduling frames throughout ReleaseMode.loop background music. Replaced global quiescence with bounded controller clean/not-busy + actual FadeThrough/SharedAxis completion + Flame art/motion readiness; all visibility, hitTestable, save and SQLite assertions retained. Music/SDK/production unchanged.

Actual Android normal-main run now exit0, 47.24s, no outer timeout; levels1-4, completions/reward, same-process SQLite reopen, controlled seven. This is simulator debug, no screenshots/audio evidence/SIGKILL; next production LY-R02/R03 changes still require final verification. Two style-only braces normalized afterwards; format and analyze passed.
