# LY UI 独立聚焦验证设计（待CLI窗口）

本文件是待执行设计，不是通过记录。不能在当前共享app或受保护设备执行。先由架构给出最终差额和串行CLI窗口，在可写独立副本准备依赖；本轮未创建副本、未运行命令、未改冻结快照。

## 可直接重跑的已有聚焦命令

工作目录：独立审查副本的app/，FIREBASE_ANALYTICS_WITHOUT_ADID=1。精确Flutter/Dart与pubspec.lock保持原值。

```sh
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter pub get --enforce-lockfile
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/one_screen_layout_test.dart test/one_screen_geometry_test.dart
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/flame_full_board_widget_test.dart --plain-name 'formal BoardView uses one Flame canvas'
FIREBASE_ANALYTICS_WITHOUT_ADID=1 flutter test test/motion_supplement_keyboard_test.dart --plain-name MS02
```

后两条只验证原语义/键盘基础，不能替代下面新增有界case。无需重复内容、所有SDK或功能审查方事务套件。

## 独立补测case（尚未实现/执行）

新增测试只能放可写审查副本 `test/ly_ui_independent_review_test.dart`，不向原开发源码写入；设计实现后再执行 `flutter test test/ly_ui_independent_review_test.dart`。

1. **正常首屏全部必要内容**：真实Nunito/原图加载，五套viewport/SafeArea，1.0/1.3，4–7瓶及九结算分支。开页后禁止drag/ensureVisible；读取board-accessibility-viewport、completion-details、reward-details与session-explanations实际ScrollableState，记录pixels/min/max。明确主必要内容与可滚次要长文；对每个必要Text/ScenePreview/瓶/容量/操作/关卡/步数/保存状态检查global rect位于SafeArea及最近可滚viewport交集内，并且文本无省略/溢出、主内容没有因局部clip被截断。normal board maxExtent<.01，pixels≈0；completion/reward必要内容若不全在当前viewport，保存bounds而不是先滚后判通过。重点final/chapter/reward-final在320×568及360×640/1.3。一次性记录全支路bounds帮助架构判断，不靠反复修改预期。
2. **信息状态的大字号裁切**：320×568/2.0、360×640/1.5；教程、pending hint（Completer保持未完成）、七瓶保存失败、pending reward分别激活。固定底栏必须始终可见。针对cancel-hint/skip-tutorial/retry/stay/retry-reward，先找最近说明viewport，断言完整48×48区域位于交集；使用实际按钮enabled状态与点击回调/控制器状态证明可用，不仅hitTestable。允许大字号说明受控滚动，但不得通过整页滚动发现主要操作。若某说明操作不属于“必须持续可见”，在报告中明确归类，不能静默豁免。
3. **小屏七瓶焦点与语义**：ensureSemantics；对7个瓶及固定操作采集语义rect与getRect对应关系，禁用节点没有tap action，启用瓶有完整内容/目标/容量标签。通过原生Focus/Tab找到首屏可见对象，验证焦点没有跳到画外或被滚动裁切；Enter/Space只选一次，语义tap只触发一次，busy时不可重复。对完成预览检查无tap action、无可用button标记；静态标签仍可读。不能以该host测试宣称VoiceOver/TalkBack实听通过。
4. **动态与clip映射的补充观察**：复用原几何case；对实际320/360小屏分配出来的BoardLayout高度记录值，确定它们被geometry test覆盖。正常/临时说明56高、1.3/2.0各一个跨行倒水，检查moving bottle和stream global bounds始终位于棋盘viewport，且不交fixed header/actions/所有label。运动时不靠中心hitTest说明全图未裁切，不与功能方重复事务/token测试。

## 需要最终差额复核

逐文件对最终候选与当前280文件清单比较；如果board_page、collection_pages、game_screen、Flame board/geometry、knit_components/service_views或布局测试变动，重新读相关hunk及更新case/结果。作者日志必须绑定最终源码/身份，不继承早期通过。无截图/录屏/录音或采集重试；所有F9/窗口与Cocoa513/EPERM边界保持。
