# Android QA 与 CLI 交架构（LY05/LY06未完成）

**CLI RELEASED。** 无 Flutter/Dart/pub/SPM/Xcode 命令在途；不再续开 Android 重试。架构接手下列 QA 文件/Android 独立设备的写权，原作者仅继续交付整理，不并发修改或重启。完整机器字段/源hash见 `CLI-RELEASED.json`。这不是整体验收通过。

## 稳定输入

- 194项全图 fingerprint：`fc336052ca53a805ab4ac01edba36980604c59e132b476914993adba4852a96c`，清单 `native-source-scope.json`。
- 其中192项App/core/assets/pubspec+lock fingerprint：`7fee8c543972767564a96955d9ed2e095de3cc281d07657c9a280d4c001e109e`；与 `tests-final.log` 73/73通过后完全相同。此后差额只有QA文件，未改生产页面。
- `app/integration_test/one_screen_layout_test.dart`：`f8a06d4a45bc8a70b7d015b897983c2321acc69f1fb06e0d8340173ffad6e9dd`。
- `app/test_driver/one_screen_layout_driver.dart`：`7b594d681a4fa56630bc99c9dbd2acc6b1612aebce790b93e42ce5f704aa8248`。
- 最后QA文件已format；最后Android编译成功，但其运行在首页初始 `ready()` 的 `pumpAndSettle().timeout(25s)` 失败。源码行49附近，按日志实际行号定位。不得以编译或先前无限等待记通过。

## 独立设备/库

- Android `emulator-5590`，AVD `Pourlune_Layout_API36`，本轮由原作者用已安装的Android36 PlayStore arm64镜像新建（没有下载新SDK/接受新协议）；当前仍booted。进程 PID **47536**，可用`adb -s emulator-5590 emu avd name`再核对。
- 启动：`/Users/wangyule/Library/Android/sdk/emulator/emulator -avd Pourlune_Layout_API36 -port 5590 -no-window -no-audio -no-boot-anim -no-snapshot`，执行会话74708仅承载长驻emulator，不是Flutter编译。日志 `android-emulator.log`仍可能追加，别当冻结文件。
- QA身份 `dev.pourlune.pourlune_dev.layoutValidation`；仅 `/data/user/0/dev.pourlune.pourlune_dev.layoutValidation/databases/ly_runtime.sqlite`。最后该App已force-stop，保留设备与QA数据供架构。无其他普通App数据需要清理。
- iOS独立255890D5-B4A3-42F9-B1A2-409E77118348 / `dev.pourlune.layoutValidation`；安装前plist校验见 `ios-identity.json`。结束时已无该进程；设备原本booted，不shutdown。
- F9C16DE7-01D8-4740-B796-A3A2DB8C3265和窗口、旧库、冻结build6完全不操作；既有采集限制不重试/绕过。

## 已试与最后复现

工作目录 `app/`；始终 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`。

1. 默认 `flutter test integration_test/one_screen_layout_test.dart -d emulator-5590 --dart-define=POURLUNE_DATABASE=ly_runtime.sqlite`：构建/独立身份安装成功，DDS `getVersion112 Service has disappeared`，App仍活着。`android-native.log`与`android-startup-diagnostic.log`。该早期命令未显式关闭debug测试广告，不作为最终环境通过。
2. `flutter test --no-dds ...`：当前固定Flutter3.47.2工具在 `_listenToVmServiceForGoldens` 无条件订阅其自定义golden stream，该stream在直连VM不可用，报-32602；没有调用截图/golden功能。`android-native-final.log`。没有改SDK/版本。
3. SDK自带 `integration_test/integration_test_driver.dart` 官方host adaptor + `flutter drive --no-dds` 可连接VM。新增harness门控要求显式广告disabled、Firebase none、无scenario，避免debug默认测试广告/UMP干扰；进入正常main首页/controller，但初始settle等待未完成。最后增加逐步日志、10秒pump/25秒settle/20秒home ensureVisible界限，在25秒明确失败，driver退出1。**最后完整结果 `android-drive-steps.log`**；`android-drive.log`是之前人工安全结束的无限等待，不算通过。`android-drive-diagnostic.log`是一次诊断参数书写错误导致编译拒绝，已纠正，不是产品缺陷。

最后复现命令（独立Gradle身份覆盖仍在ignored build目录，公开副本 `android-layout.gradle`）：

```sh
GRADLE_USER_HOME='/Volumes/data/App Development/Pourlune/build/one-screen-layout/gradle-home' POURLUNE_LY_ANDROID='/Volumes/data/App Development/Pourlune/app/android/app' FIREBASE_ANALYTICS_WITHOUT_ADID=1 /Users/wangyule/development/flutter/bin/flutter drive --no-dds --driver=test_driver/one_screen_layout_driver.dart --target=integration_test/one_screen_layout_test.dart -d emulator-5590 --dart-define=POURLUNE_DATABASE=ly_runtime.sqlite --dart-define=POURLUNE_AD_MODE=disabled
```

`build/one-screen-layout/gradle-home`是本轮独立Gradle home（caches/wrapper/native链接既有缓存；init.d只有本项目精确路径的applicationId覆盖），未改用户全局init脚本/工程ID。`POURLUNE_LY_ANDROID`须指向实际app/android/app。公开复现xcconfig见 `layout.xcconfig`，仅Runner使用 `POURLUNE_BUNDLE_IDENTIFIER`。

已读诊断：Android进程可响应VM查询，isolate Resume/runnable；widget树显示真实Bootstrap/GameScreen/HomePage，PageMotion ticker inactive，尚无关卡实例/receipts。`dumpsys power`为Awake，目标window有焦点，screen_off_timeout为原值2147483647，未修改设备休眠设置。日志见 `android-widget-diagnostic.json`（技术widget树，无图像采集）；只检查自己的QA库/进程。尚不能将初始pumpAndSettle超时定性为产品缺陷。

## iOS与剩余验证

`ios-native-final.log`先前完整11阶段通过（402×874、安全区62/34、scale1.0）：正常main1–4、通关、拼片、Next、SQLite同进程关闭重开、七瓶首屏命中。该轮使用debug官方测试广告默认值，**不能标为最终无广告轮通过**。第一次七瓶QA替换被真实确认门控拒绝后，显式test-only replace:true才重跑通过，不是SDK发奖。

最终harness需下列命令（架构统筹，尚未运行）：

```sh
XCODE_XCCONFIG_FILE='/Volumes/data/App Development/Pourlune/build/one-screen-layout/layout.xcconfig' FIREBASE_ANALYTICS_WITHOUT_ADID=1 /Users/wangyule/development/flutter/bin/flutter test integration_test/one_screen_layout_test.dart -d 255890D5-B4A3-42F9-B1A2-409E77118348 --dart-define=POURLUNE_DATABASE=ly_runtime.sqlite --dart-define=POURLUNE_AD_MODE=disabled
```

没有最终Android游戏/结算全流程通过、最终iOS disabled复验、SIGKILL/真机视觉/性能、作者fresh终审、架构独立通过或新CI；未签名/上传新候选。现先给架构/UI/功能两段有界独立窗口，后续顺序由架构安排，作者不再抢CLI。保存证据仅移除了过期本地VM URL鉴权路径，命令/异常/断言/结果保留；没有签名秘密或真实账号token写入。
