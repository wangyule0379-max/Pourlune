# T01–T06 转场证据索引

最终结果：冻结副本200项Flutter测试通过、analyze无问题、format0改动、双端debug构建成功，最终双端均102步/11类页面/errors为空。作者执行结论，架构独立验收未代写。

- `final-app-tests.log`、`final-analyze.log`、`final-format.log`、`final-ios-build.log`、`final-android-build.log`：最后滚动修复后的检查，CWD根build/page-transitions-baseline/app。
- `red.log`、`modal-red.log`、`scroll-red.log` / `scroll-green.log`：官方组件缺口、模态防重、实例滚动的有效RED→GREEN。
- `source-freeze.json` / `artifact-manifest.json`：源码资源native/core冻结与二进制哈希。源码zip、APK、Simulator.app和原始大录像位于Git忽略的根build/page-transitions/，不覆盖Flame冻结包。
- `native-summary.json` / `native-coverage.md`：最终双端102步、实际目的地和范围。每端`run/route.json`含实例/修订/阶段/奖励记录，`run/*.png`为实机渲染的像素比1截图。
- `ios/navigation.mp4`、`android/navigation.mp4`、`android/system-back-reduced.mp4`：iOS完整代表路径；Android主录像限180秒，尾部减少动态与真实系统返回另补录，不合成伪装单一连续录像。
- `ios/contact-sheet.jpg`、`android/contact-sheet.jpg`、`scroll-before-after/comparison.jpg`：关键截图与新实例offset修复前后。
- `task-only-final.patch`：相对M/Flame交接源码快照的可归属变更，避免把其他聊天工作当本任务新增。
- `preparation-and-history.md`、旧日志、`runner-*-error.json`和`pre-scroll-fix`为历史，不算最终通过。

普通/Firebase/Flame安装、b04_review_r2.sqlite未动；仅page_transitions.sqlite。Firebase none，广告disabled；真实Flutter+sqflite，但受控进度、参考解和事务故障hook不称自然玩家/真实SDK/真实磁盘满。模拟器debug与无错误记录不证明真机帧率，录像无音轨。完整Flame棋盘与容量同步的后续代码不属于此冻结候选。
