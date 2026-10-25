# Flame 样板精确 CI：提示事件测试同步修复

2026-10-22。原CI提示事件与隔离全套另行暴露的B05恢复等待问题，均已分别受控复现并修复测试同步。**精确样板提交加两个测试修复：182项全套通过、analyze无问题，可供架构独立验收；新的远端CI尚未运行。** 作者未暂存、提交或推送；完整棋盘、M与页面转场未验源码均未混入副本。

## 原失败与受控验证

原精确提交 `c529e8e2cac8afa8266cfd7a3a1b983946fcbc69`，CI [39743348698](https://github.com/wangyule0379-max/Pourlune/actions/runs/39743348698)：iOS build成功，Ubuntu tests-and-android 在 Flutter 阶段181通过/1失败，APK尚未执行。失败为 `b04_hint_events_test.dart:65` 第二次取消后预期2条pl_hint_result，实际1条。完整原始摘录由架构保存在 `../review/flame-sample-evidence/remote-ci-final.json`。

先运行原单测，本地1项通过；没有以重试通过掩盖远端失败。随后保留原25ms断言，仅用**真实SQLite事务写锁**阻塞第二次claim进行隔离实验：

- 第二次请求前：durableClaims=1 / sent=1 / telemetry.allowed=true。
- 第二次 hint Future 已结束，原25ms到达：sent仍为1，权限仍true，原断言稳定失败。
- finally释放写锁后：sent=2 / durableClaims=2 / distinct IDs=2。

证据：[controlled-claim-red.log](../evidence/flame-sample-ci-repair/controlled-claim-red.log)。不是以替身事件证明产品遥测正确：Firebase运输沿用现有host fake，控制器、ProductTelemetry、真实sqflite FFI transaction/唯一claim及调度均实际执行。它证明“await hint Future＋固定25ms”并不等待独立的持久claim→gateway调用，不能保证原测试的断言时点；没有观察到请求identity碰撞、重复取消多发或第二次claim丢失。实际远端25ms期间的数据库时长没有额外插桩，不能伪造该次延迟的测量值。

## 原CI问题的最小改动

只修改 `app/test/b04_hint_events_test.dart`：

- 用实际firebaseReady、实际hint事件完成条件和3秒有界失败，替换固定30/25/25ms的完成假设；轮询1ms仅让出事件循环，不是将sleep延长。
- 第二次取消增加真实SQLite写锁回归：确认hint Future结束不能绕过待持久化claim；释放后等待实际第二次dispatch。
- 保留并强化两次重复取消只产生两条总事件、同一已保存实例跨控制器重建、两行独立持久事件ID的断言。
- 不改控制器、持久化、SDK或产品遥测策略；不跳过测试、不增加测试重试或重发策略。

[单文件patch](../evidence/flame-sample-ci-repair/test-only.patch)、[范围与SHA](../evidence/flame-sample-ci-repair/scope.json)。

## 首轮检查及新增失败（历史，最终结果见后节）

根工作区app/：`flutter test test/b04_hint_events_test.dart test/b04_services_test.dart test/b04_r03_controller_test.dart`，**11项通过**。该单文件已dart format。

为避免将M、animations和在途完整棋盘纳入提交结论，从 `git archive c529e8e` 建立独立 `build/flame-sample-ci-repair/`，只覆盖上述单测，在该app/执行：

- `flutter pub get --enforce-lockfile`：成功，锁版本未升级。
- `flutter test`：**181通过/1失败**；本次提示事件用例通过。新失败为 `b05_accessibility_test.dart:153` 的 `B05 narrow2x earlier reward confirmation remains readable and actionable`：确认恢复后固定40ms，预期原实例ID，实际仍读到被替换实例ID。这不是RenderFlex溢出；根因尚未验证，不先归因UI布局、不悄悄修改共享页面。
- `flutter analyze`：No issues，4.2秒。

全部命令串行并使用 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`。日志分别在 `../evidence/flame-sample-ci-repair/`；命令串行包装最后analyze退出0不等于前面全套通过。没有因测试变更重建未改的原生平台；新的远端CI尚未运行。

首轮检查后按架构要求释放了UI短窗口，用于新实例滚动key修复及冻结验证；窗口期间未运行Flutter/Dart/native构建。UI随后明确归还窗口，才进行了下节B05独立定位与最终复核；历史失败没有被忽略。

## 后续补齐：B05 独立根因及最终结果

上述新增B05失败已独立核验，未修改UI页面。精确副本在确认按钮前用真实SQLite writer保持等待：确认后原40ms时 **old=true / restored=false / busy=true**；释放writer后 **restored=true / extra=true / saved=true**。这同样证明固定40ms不等于已完成原实例恢复；不是文字溢出、奖励丢失或需要更改产品恢复规则。[b05-controlled-red.log](../evidence/flame-sample-ci-repair/b05-controlled-red.log)。

追加且仅追加 `app/test/b05_accessibility_test.dart` 的同步修复：实际写锁回归确认保存等待期间仍保留被替换实例且busy；释放后以原实例ID、extraBottleGranted、busy结束及SavePhase.clean为完成条件，3秒有界失败。原320×568/2x字体、对话框、逐词不可拆、原实例及权益等断言全部保留。没有改任何生产代码、重试或跳过。最终变更因此是**两个既有单测文件**，见 [tests-only.patch](../evidence/flame-sample-ci-repair/tests-only.patch) 和更新后的scope.json。

精确c529e8e隔离副本只叠加这两个测试文件，最终：

- 两个修改文件聚焦 **3/3通过**，原提示及相关服务/控制器聚焦 **11/11通过**。
- 全套 **182/182通过**（109秒）；先前181/1失败日志原样保留，不覆盖为成功。
- analyze **No issues**（3.0秒），两文件已format；enforce-lockfile成功，不改依赖。

最终日志为 `both-focused-green.log`、`isolated-full-suite-final.log`、`isolated-analyze-final.log`。这两项均经历实际受控RED→GREEN和精确范围全套复核；**本次独立小修复现可供架构验收**。当前CLI归完整棋盘方，架构复验需明确窗口或等本方释放。作者不暂存/提交、不将新全棋盘或M/转场打包；后续远端CI须由架构提交后按新精确commit核对，当前尚未运行新CI。
