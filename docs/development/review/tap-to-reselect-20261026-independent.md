# 点击换选独立验收 · 2026-10-26

结论：通过用户确认的普通点击换选范围。代码源 `1da13c6387e3530fe5edb0cb6cc79449a3cbfcf7`。满瓶／不匹配有水瓶直接成为新源，不再要求先取消，不显示普通拒绝条；合法倒水及真实教学、动作锁、保存失败边界保留。本轮不是新商店发布，TestFlight 14 不变。

## 父实际检查

独立核对本批56个证据文件、508个提交内输入、冻结Runner/kernel、六个关键源码hash、七个短片和两个原片hash，全部吻合。记录为同名evidence目录 `parent-source-check.json`。父没有运行Flutter/Dart/iOS或操作专用设备。

实际查看13张正常main原生图／关键帧：full-reselected、mismatch-reselected、hint-before、hint-reselected、final；selection的13.65/14.00/14.30/43.30/120.70/195.80；hint的45.95/70.00。

- 13.65选中1号，14.00/14.30已换为满的2号，旧1号落回，新2号抬起，未见Can't pour/Bottle full条。目标垫和瓶下读数未随选择移动。
- 不匹配的未满6号缓冲瓶也能直接换选；43.30及120.70实际显示换选后的新源进行下一次合法倒水。
- Hint前为1→2建议，有箭头和两端标记；手点满3号后，旧箭头、建议条及旧端标记清除，仅新源3号抬起。70.00从该新源实际倒入6号，final正常归位。
- 195.80取消／空瓶操作结束后无选择残留。其没有改变水体由回执比对补证，不凭静态图独立推断点击过程。

父另用独立Python读取交付回执，比较四对完整活动payload摘要、board、instance及计数：initial↔full-reselected、first-legal↔mismatch-reselected、second-legal↔cancel-empty、second-legal↔hint-reselected均相等。从原始board独立重放零起索引1→5 G2、5→6 G2、2→5 O1，三份后续board均精确相等，moves/revision/history依次0、1、2、3，每个合法动作只增1。记录 `parent-receipt-check.json`。这核的是已留存回执，不是父重新查询SQLite；完整payload相同也不独立证明没有同值写盘。

## 代码与自动验证

父读过完整五文件diff及新增测试：生产仅controller.tapBottle和RulesPage练习。先沿用输入守卫／同瓶取消；普通非教学的满瓶或顶色不匹配目标非空时，取消旧Hint、换选、选择反馈和notify后返回。未调用失败的controller.pour，也未改核心pour、_change、奖励、动画或持久层。初次选择也清旧交互提示；保存失败notice未被清除。教学active仍走真实核心拒绝。

读取已核hash的作者日志：7项FFI用例由5RED+2既有守卫GREEN转7GREEN，练习同类换选由RED转GREEN；8相关文件64项通过，5文件analyze/format与正常main构建34.7秒成功。父没有重复运行工具链。snapshot零写调用、迟到Hint不能抢回选择、Undo、动作锁、教学及保存失败通过有效自动断言覆盖；未把普通换选改动用于删除显式pour的真实拒绝检查。

## 有限范围与接续

正常字号、D79隔离tapReselectValidation/tap_reselect.sqlite、正式main31准备QA；不是自然解锁或人类首次游玩。作者动作之间有截图和读库等待，不称原生亚秒连点验证；已有快速选择回落自动回归保留。父看了所列关键帧，没有连续看完两部长录像，物理手机声音触觉和所有题目／字号未重验。橙色、瓶口间距和既有水流冻结结果未被本批改动。

本项验收关闭，保存新交付与短片供用户查看；不重复同批构建／采图，不自动新发包，不扩十二瓶或题库工作。F9及窗口保护不变。
