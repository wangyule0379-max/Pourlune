# 优化包原生检查 — 2026-10-28

设备 `C2BF8C5A-DBA9-4B3C-9987-FF887EEDC3F3`，Pourlune Optimization 20261028，iPhone 17 Pro / iOS 26.5 (23F77)，新建设备默认字号；08:57–09:00 台北时间。指定冻结 Runner.app，bundle `dev.pourlune.optimizationValidation`，正常 main；仅该沙盒 `Documents/optimization_20261028.sqlite` 使用指定种子。种子的 20 关进度是 QA 准备，不是人工完成 20 关。未运行 Flutter/Dart 或更改冻结包。

- Home 显示 Continue · Level 21，打开后五色、七瓶（5 个目标、2 个空缓冲）；截图 `home.png`、`board.png`。
- 1→6 合法倒水后 1 步、1 瓶减少蓝色、6 瓶新增蓝色；Undo 返回 0 步、恢复原盘。连续点 1、2 后 2 显示选中，无误提交。
- Pause 显示保存提示，Resume 返回同一棋盘；Music 1→0→1，Sound 1→0 后回棋盘再次 1→6，切后台并回前台保留 1 步和棋盘；返回设置 Sound 0→1。操作期间未观察到错误弹窗或崩溃；未采集完整系统日志，不能证明没有所有后台错误。
- App 结束后复制 `after.sqlite`，`PRAGMA integrity_check` 为 `ok`；普通实例 `optimization-qa-21`，`main-021`，move_count=1，board_revision=3，1 瓶 `[O,O,R]`、6 瓶 `[B]`，Undo 记录存在；设置 `music=1`、`sound=1`。`before.sqlite` 为原始授权 QA 种子副本。
- 没有可用的实际音频监听或播放位置测量：音乐暂停/续播、关闭声音后实际倒水声停止和重新开启后的声音均**未验证**，开关变化不作为音频通过证据。没有录制视频或日志；两张关键截图及数据库为本次证据。
- 仅按本轮范围检查，非全页、字号矩阵、真机或真实广告验收。App 已终止，指定模拟器已 shutdown 并释放，其他设备和库未操作。
