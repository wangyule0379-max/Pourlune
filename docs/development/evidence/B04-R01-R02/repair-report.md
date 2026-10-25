# B04-R01 / B04-R02 repair delivery

2026-10-22。基线仍为1b6b477，分支codex/offline-foundation，未提交／推送，未进入B05。**执行修复交付，待架构复验**；不改写 `docs/development/review/`、tracking、plans、原设计或原始独立RED证据。主审运行副本 `app/test/b04_architecture_regression_test.dart` 已接管、格式化并扩展为正式回归。

## R01 — keep ownership after actual show confirmation

原始主审用例和更强SDK路由用例均先在旧实现失败：`architecture-red.log`、`sdk-route-red.log`。根因是同一watchdog在shown后仍调用finish(timeout)，正常等待被误作关闭并dispose。修复：

- 120秒命名为 `preShowTimeout`，只限制等待展示确认；shown立即取消计时器。后台／前台与经过时间不会解除已展示所有权或推进Next。
- 已收到shown后的平台show Future迟到异常也不擅自关闭；以SDK真实dismissed／failed回调结束。尚未shown／平台Future不回仍保留有界超时和去重。
- 正常关闭后的dispose保留，符合 [Google官方激励广告说明](https://developers.google.com/admob/flutter/rewarded)。没有为未接入mediation添加任意延迟，也没有历史奖励回查承诺。
- ServiceHub是App级所有者，页面导航不销毁它；整个owner／engine终止不承诺收到或保存尚未送达的奖励。

`b04_sdk_lifecycle_test.dart` 使用实际锁定google_mobile_ads9.2.0的AdInstanceManager、AdMessageCodec与生产GoogleAdsTransport；仅原生MethodChannel端为替身。Android与iOS各验证有earned／无earned，共4项：load→show→shown→后台跨过期限→原adId仍可路由、Future未结束、未dispose→重复earned只到账原实例一次→正常dismiss删除路由并dispose一次；仅关闭不发奖。不可把它称作原生广告展示成功。

Controller回归另证Next仍停在13、双击/Home不改导航；真实关闭后只进入14一次。Reward Controller在跨期后送达确认时仍向原实例落盘，到账期间保持展示所有权，随后关闭。已有预展示超时／平台调用悬挂测试继续保留，并覆盖shown后迟到platform Future错误。

## R02 — durable, idempotent qualification boundary

旧事务重试把重试时全部计数置0。`architecture-red.log` 保留expected1/actual0的原始复现；调整API后仍保留“13展示后14的1”断言。

SQLite升级为 **schema5**：

- `fullscreen_attempts(show_id PK, kind, qualifying_boundary)` 在SDK show前由 `prepareFullscreen` 与当前intent一起原子保存；准备不代表展示，也不消费资格。Controller此时已锁定该次意图，不能在等待展示时继续棋盘操作。
- `qualifying_clear_total` 单调增加；`qualifying_consumed_total` 是消费水位。有效interstitial展示记录原子插入一次，水位只前进至该次已保存边界；当前资格=total−consumed。rewarded不前进水位。
- 13边界为3，写入失败回滚后14使total／资格到4；旧13记录重试只消费至3，剩1。重复showId不再次消费；旧重试不能清除另一个当前intent，持久时间保留最新值。
- Reset把消费水位提升到当前total，total不回拨。迟到旧记录不能消费Reset后新增的首通；它不恢复已删除进度。
- 补充整链复现还发现Controller缓存4会在持久计数已变1后过早放行14；`stale-counter-red.log` 已先观察失败。Next现在先锁first-intent，再读取最新持久progress检查资格，免费导航与正常保存失败处理仍可用。读检查失败只跳过可选广告，不把广告读操作变成离线玩法门槛。

`b04_architecture_regression_test.dart` 的Controller链：13shown事务故障→仍可进入并完成14，count4→Retry1→重复Retry1→冷却结束且库存ready的14仍不展示→15 count2不展示→16 count3，拼片先揭示，再展示后count0／进入17；旧13再重试仍0。

## Migration and restart rulings

1/2/3/4→5不清存档；非空v3和字面SQL的非空v4夹具均保留。共享v4夹具由host ffi与实际iOS sqflite分别运行，包含双槽原定义／历史／extra、已确认待恢复奖励、receipts、偏好、privacy、事件去重、旧展示和非零资格。

新序号从**原有剩余资格**初始化，旧消费历史不伪造。旧v4 uncertain intent没有可靠边界／展示确认，保留原计数并使用既有保守180秒重启窗口，不能把它当成shown或在升级时清掉后续进度。schema5 prepared记录同样不是实际show证明；若进程在确认事务成功前终止，不能凭SDK不存在的历史查询补写确认。进程仍持有已送达回调的Retry使用持久边界；测试重开文件验证边界和重复写幂等，不声称能恢复从未落盘的展示事实。已提交的旧showId重复写不消费；Reset也不会使旧边界消费新进度。

## Actual verification

命令工作目录为 `app/`；核心为 `packages/pourlune_core/`；资源脚本在根目录。工具链Flutter3.47.2 / Dart3.13.2，依赖和公开测试ID未变。

|检查|实际证据／范围|
|---|---|
|原始两条独立回归RED|`architecture-red.log`；主审原review证据未修改|
|锁定SDK Dart路由RED→GREEN|`sdk-route-red.log` → `targeted-final.log`；真实Dart插件＋mock native messages，非原生广告|
|旧缓存资格RED→GREEN|`stale-counter-red.log` → `targeted-final.log`；真实SQLite＋生产Controller|
|R01/R02专项|`targeted-final.log` 19通过：SDK4、ads8、architecture6、迁移1|
|完整Flutter|`flutter-tests-completion.log` 159通过（包含双平台SDK协议与lateFuture用例；先前修复集156也通过）|
|源码format／analyze|`format-final.log` / `analyze-final.log`；限定lib/test/integration_test，避开生成依赖副本|
|核心／资源|`core-tests.log` 30通过；`asset-tests.log`23通过，两份manifest检查通过；源码美术几何未变|
|Android debug|`android-build.log` 成功；保留既有FlutterFire KGP兼容警告，无Android运行设备结论|
|iOS正常debug|`ios-build.log` 成功；`FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter build ios --simulator --debug`，不是集成测试入口|
|iOS实际sqflite＋Flutter整链|`ios-sqlite-native-final.log` 1通过；`native/native.json`与两张PNG；fixture4→5／原槽奖励保留／13等待所有权／4→1→1→2→3→0并到17|

iOS设备：GDF-Remaining-20261020 / iOS26.5 Simulator，UDID4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2。原生聚焦命令：

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test integration_test/b04_repairs_native_test.dart -d 4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2
```

该harness只清理b04_repairs_migration.sqlite和b04_repairs_flow.sqlite，使用实际sqflite／Flutter，但广告事件和前后台由Controller受控输入；不是OS后台切换或真实原生广告覆盖层。内容别名复用参考夹具，非60关正式题库／真人试玩。第一次原生测试把预展示期限设40ms，渲染一帧后才注入shown，按预展示超时正确释放而使测试注入route为空；失败记录 `ios-sqlite-native.log` 保留。最终测试改用2秒预展示裕量，在shown后等待2.2秒再断言，`ios-sqlite-native-final.log`通过；未放宽生产默认或取消未shown超时。

## Unverified and handoff

真实广告库存此前超时；本轮未把受控事件或真实Dart SDK路由契约称为原生展示／earned成功。实际Google测试广告跨后台超时、earned→保存→真实dismiss仍待可用库存补验；未接mediation，不要求任意迟到保证。Firebase真实项目／控制台、正式身份、AdMob消息归属、支持域名邮箱、权属与代表真机仍依既有台账，不自行造配置或升级验收状态。没有新增账号／服务器／货币／发布行为。

后续由架构复验决定两项关闭和B04验收；本报告只提交实现与实际运行证据。
