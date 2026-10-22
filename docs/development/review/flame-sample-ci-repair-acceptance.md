# Flame 样板 CI 修复独立验收

2026-10-22，架构独立审查。结论：FS-CI01 的测试同步修复通过；新提交远端 CI 尚待核对。B05-M01 中本次恢复断言的固定等待问题同时关闭，其余非本次范围不扩大结论。

## 根因与范围

失败 run39743348698 已终态，不重复执行或轮询。两个测试以固定25/40ms推断异步SQLite处理完成，在调度延迟下错误观察中间态。执行方受控写锁 RED 日志显示：锁持有时第二提示事件尚未持久化；锁释放后达到两事件且ID不同。恢复场景在锁持有时旧实例且busy，释放后原实例恢复并clean。没有发现需修改产品规则的证据。

仅修改 app/test/b04_hint_events_test.dart 与 app/test/b05_accessibility_test.dart。改为有上界等待真实条件；保留两事件、实例ID、奖励权益、窄屏等原断言，新增真实SQLite阻塞下的中间态验证。没有加长固定sleep、跳过测试、减弱结果断言或更改生产实现。

## 独立验证

本聊天以 git archive c529e8e2cac8afa8266cfd7a3a1b983946fcbc69 建立 build/architecture-ci-review，并仅覆盖两测试文件。不是在含未验全棋盘的工作树上运行。

- hint测试 SHA256：5f9bc263f6194aabde9ce3cf001400345f2cfadc37d3a5ebbd8c4fa37cd77579。
- B05测试 SHA256：3466eb11ff95ac683b86dbc3344def8505927721d427ea17ad7ff6519b871603。
- flutter pub get --enforce-lockfile 成功。
- flutter test：182 passed，退出0。
- flutter analyze：No issues found，退出0。
- 本聊天逐项核对作者受控RED证据与当前代码，确认等待条件对应业务完成而非延时假设。

独立日志：flame-sample-ci-repair-evidence/{pub-get,full-tests,analyze}.log。作者复现与交付：../deliveries/flame-sample-ci-repair.md 和 ../evidence/flame-sample-ci-repair/。

## 边界

本次是宿主测试修复，不声称真实Firebase/广告收件、设备性能或全棋盘通过。远端Ubuntu与平台构建由本次精确推送CI继续验证。完整棋盘与页面转场另行验收，不能夹带其未验实现。
