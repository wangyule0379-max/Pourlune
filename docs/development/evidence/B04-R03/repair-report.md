# B04-R03：关闭广告后读取失败不遗留导航锁

2026-10-22，执行侧修复交付，待架构独立复验。复用 HEAD `1b6b477` 的共享未提交工作树；未 stage/commit/push，未进入 B05，未修改 tracking/review/plans 或设计原件。

## 问题与最小修复

`GameController.nextLevel()` 已在插屏资格预检查时容忍读取失败，但 `ads.show()` 完成、`retryTiming()` 后的第二次 `_refresh()` 未保护。此时 SQLite SELECT 抛错会直接离开方法，既不进入 `advance()`，也不执行其中释放 `_adFlow` 的 finally，造成免费 Next、Home、Replay 等操作被锁住。

仅修改 `app/lib/application/game_controller.dart` 的这次后置 `_refresh()`：捕获可选刷新失败后继续原流程。前台立即 `advance()`；后台仍等回前台才 `advance()`。下一关继续经过 `_startNew()`／`_persist()`，真实快照写入失败保持 `SavePhase.failed`、原实例和候选 Retry，不伪造成功。没有宽泛捕获正在展示中的 `ads.show()` 异常来提前释放原生展示所有权；R01 展示生命周期逻辑不变。

对应 B04-R03、B04-03 免费 Next 与广告失败不阻塞（AC-13–17／32 范围），并验证现有保存失败语义：写失败不前进，Retry 成功后才发布下一关。该精准回归不替代 AC-11 的全部通关保存与导航场景。

## 有效读故障回归

新增 `app/test/b04_r03_controller_test.dart`，四种组合：前台／后台关闭 × 下一关快照写入成功／失败。

- 使用真实 sqflite FFI 临时 SQLite 库。仅测试库将 `revealed_pieces` 包成条件视图；实际展示记录已落盘、原关卡尚未链接下一实例时，SELECT 产生真实 SQLite integer overflow。未给生产 GameStore 增加故障接口。
- 广告前 `store.progress()` 成功，且控制器进入 fake transport 的 show，证明预检查成功。等待真实展示时间记录后，显式验证相同 SELECT 已抛 `DatabaseException`，再发送关闭回调，确保故障发生于目标后置读取阶段。
- 验证 Next 不抛出该异常；前台可推进，后台不提前推进，回前台后释放锁。
- 快照正常时精确保存第14关及原 receipt 的下一实例链接；快照故障时停留第13关、保存失败且无链接，解除广告流程锁，清除故障后 Retry 保存同一候选并恢复 Home 操作。

`harness-wait-failure.log` 保留初次测试自身的等待条件错误：shown 后误等展示锁解除，尚未到目标断言。修正为等待真实展示时间落盘后重新跑旧代码；有效 `controller-read-red.log` 的4项均在目标 `nextError` 断言观察到实际 SELECT 异常。生产修复后同文件4项通过，见 `controller-read-green.log`。

## 实际执行

工作目录：`/Volumes/data/App Development/Pourlune/app`。

```sh
/Users/wangyule/development/flutter/bin/flutter test test/b04_r03_controller_test.dart
/Users/wangyule/development/flutter/bin/dart format lib/application/game_controller.dart test/b04_r03_controller_test.dart
```

- 精准测试：**4 passed**，退出码0；有效修复前 **4 failed**，退出码1。
- 格式：2 files，0 changed；见 `format.log`。
- 只检查本轮控制器差异与新增文件，并执行 `git diff --check -- app/lib/application/game_controller.dart app/test/b04_r03_controller_test.dart docs/development/deliveries/B04.md docs/development/evidence/B04-R03`。

遵循主审正在独立验收的协调约束，本轮未启动全量 Flutter、analyze、平台构建或原生测试。R01/R02报告的159项、双端构建和原生证据属于上轮快照。本轮广告回调／前后台由测试驱动，SQLite 读写真实；不宣称真实广告、OS 后台中断或 Firebase 控制台验证通过。
