# 原生QA七瓶/章节/最终增量独立只读审查（收尾）

2026-10-23。**新增Next目的地断言缺口已关闭。** 只读比较最终QA及既有原生结果；未运行CLI/设备、未改QA或生产。先前Android14阶段成功QA SHA256 `9be9df8eb5488073ea2c51a4f3b071d5a3a204a99ff85b603df5b71117c12ea9`，与final-native-source.json和Android实际成功运行result均一致。

## 最终新增断言已核对

- 七瓶实际手势完成后，真实点击Next并ready，新增直接断言page==board、mainLevel==11、instanceID!=seven.id。因此此前“只点Next、随后受控准备覆盖状态可能掩盖no-op”的新增尾段缺口已关闭，不再列待办。
- 受控20/60存档通过Home真实saved-result进入后，保留ID/receipt断言，新增board.length==7，将“七瓶”标签直接绑定实际恢复状态。
- 从最终源码只去除上述四个expect语句，精确恢复05c47eefa4baf56c30e6d9f3abdd507a8f27ae9367465da5b805df6b138aae42。这证明此轮仅增加断言，没有删除等待、bounds/48/hitTestable或SQLite检查。
- 在05c47eef版本移除新增七瓶/章节/最终块，又精确恢复前次已审317f7e3a118f9cdce5da0fb74f3df8aca68ba78f5a586b7915bfb87163adf5fd，原11阶段仍完整保留。最终源码没有FlutterError.onError或LY_ERROR_DETAIL诊断；没有异常忽略逻辑。

## 入口及受控范围

navigation_pages.dart真实Home逻辑在ordinary.completed时提供saved-result，回调c.resumeSlot('ordinary')；resume属于未完成继续入口。旧错误resume改为saved-result是选对现有生产入口，不是改生产UI绕过门控。

main10的明确extra entitlement QA起点先经历受控七瓶首屏检查，再按真实t.tap逐参考动作解题，验证completed/receipt、complete-seven按钮，Next现在还验证真实新实例/第11关。它不是自然从1闯到10或真实广告发奖证明。

main20/60仍明确属于controlled：纯规则对象直接参考解完成，真实store.settle(replace:true)，关闭widget/数据库后正常main重开，经Home saved-result恢复。检查七瓶/实例/receipt、章节或最终主要按钮bounds/hitTestable，并真实点击view-collection，断言章节→scene、最终→collection。这证明受控结果存档和入口/布局/导航，不能说成手势自然闯到20/60。

## 校正后的精确版本时间线

前次文中把非诊断05c47eef和诊断版写成同一个SHA，是读取期间源文件变动后表述混淆，现以保留result和字节重建核清：

|阶段|QA SHA256|证据/结论|
|---|---|---|
|新增路径误用resume|a75c6994a7504399c6de31f560aba03af0ef87bede02f6143e5a2cbbee7d4f78|wrong-entry-red日志/exit1，No element；不是产品恢复失败|
|正确saved-result，无临时错误观察器|05c47eefa4baf56c30e6d9f3abdd507a8f27ae9367465da5b805df6b138aae42|R04修复前暴露Home/结果过渡RenderFlex溢出；不得记通过|
|正确入口＋临时错误详情观察器|ed9535adb38fa1c427d0330cbc7e1244ce1dc637473320acd42146b777b0f782|android-final-layout-overflow-diagnostic-result.json：exit1，60.236秒，定位溢出来源；诊断并非最终QA|
|移除诊断、补四个expect的最终QA|9be9df8eb5488073ea2c51a4f3b071d5a3a204a99ff85b603df5b71117c12ea9|Android最终14阶段exit0，无外层超时，61.567秒|

诊断ed9535ad版本可由05c47eef插入原错误详情观察器精确重建SHA；最终9be9df8e去四断言精确回05c47eef，版本关系有字节证据而非仅口述。观察器曾转发原测试错误处理器并在teardown恢复；最终已全部移除。生产R04修复另有独立Host2/2及新原生源指纹记录，不与QA源码混作一个修复。

## Android最终结果的只读审计

从android-final-layout.log的完整LY_NATIVE_DRIVER_REPORT解析对象，与android-final-report.json完整相等；14阶段包含原11，以及complete-seven、controlled-complete-20-seven、controlled-complete-60-seven。重新计算所有control的SafeArea四边和48尺寸，无违规，所有scroll_before_action=false。hitTestable/新Next与七瓶断言由最终QA运行exit0支持，本方未另做设备动作。

实际为Android指定独立模拟器、字号1.0、viewport411.4286×914.2857、上安全区51.8095/下24、隔离ly_runtime.sqlite、ads disabled、正常main/no scenario；result总61.57秒含准备/构建/操作，不是启动性能。该运行生产192文件集合SHA256 `6260033bed815e271c6e8de32d4d06781c05823226a3dbbb3c2baf537d2cadf3`。iOS在父架构执行中，本收尾不提前给iOS通过。

即使Android14阶段通过，也不证明自然20/60进度、SDK奖励、SIGKILL、所有字号/viewport的原生视觉、VoiceOver/TalkBack实听、真机性能或商店。原生firstScreen仍主要测按钮，场景/状态严格局部clip属于本方Host证据，不混作同一原生测量。

## 来源摘要

- `app/integration_test/one_screen_layout_test.dart`：`9be9df8eb5488073ea2c51a4f3b071d5a3a204a99ff85b603df5b71117c12ea9`。
- `app/lib/presentation/navigation_pages.dart`：`08d77bd1e52181c66ceffffa3c2828746af5844cb057b1a30dfe0d064bb6d971`。
- `docs/development/review/one-screen-layout-evidence/final-native-source.json`：`5f89f4440fbdd0e3833973e62f5a88ce82fc20f87b89cb42b790d9fddad17847`。
- `docs/development/review/one-screen-layout-evidence/android-final-layout-wrong-entry-red-result.json`：`5729b4939c64328235c5fc52496733befd2ba3ad39c0622a065958f66d061474`。
- `docs/development/review/one-screen-layout-evidence/android-final-layout-overflow-diagnostic-result.json`：`0961e35be90445fe584204dfbae8f2f2cd03a118584bd35ef1ef9841ca51d2d1`。
- `docs/development/review/one-screen-layout-evidence/android-final-layout.log`：`6007c0570e63e8e605ea7c418d94c383e9109fa35f352cff58e1897b184ccb74`。
- `docs/development/review/one-screen-layout-evidence/android-final-layout-result.json`：`6da5febad03866ab0ce44d777c1e0e1d7bdccbbdc192ef7e971bd1f4a049c00d`。
- `docs/development/review/one-screen-layout-evidence/android-final-report.json`：`90e2bef627cab2c0d98062d82e204d8ea9c268f717ae8f79bb2e8fd3567a9420`。

本轮一次收尾，仅更新本ui审查文档及其摘要索引；无CLI、设备或发布动作。

## 后续仅收尾同步的QA版本

9be9df8e是之前Android成功、iOS阶段完成但teardown失败的同版QA，不能称最新双端通过。最新QA仅在close增加对真实音频幂等dispose Future的卸载后等待；四个Next/七瓶新断言和全部阶段保持原字节。其独立只读核查及精确新SHA见qa-wait-review.md最后一节；不预判架构正在跑的最终双端结果。
