# Pourlune 数据与状态契约 v1.0

日期：2026-10-21。依据 [技术方案](technical-architecture-v1.0.md) 与 [产品规格](PRD-supplement-v1.1.md) 细化工程数据，不新增玩法。题目格式可用于内容准备；数据库与状态机仍需在 Flutter 实现中验证。

## 1. 题目格式

机器可读约束见 [puzzle.schema.json](../../content/contracts/puzzle.schema.json)，转换样本见 [main-012.reference.json](../../content/fixtures/main-012.reference.json)。样本是参考夹具，不代表完整题库或难度验收通过。

| 字段 | 约定 |
|---|---|
| schema_version | 整数 1；格式版本，未知版本不得静默按当前格式解释 |
| puzzle_id | 稳定字符串；主线使用 main-001 至 main-060；不随文件排序改变 |
| content_version | 正整数；同一题目定义变化时增加，不改变首次通关归属 |
| mode | main 或 daily；重玩是实例属性，不是另一份题目 |
| content_status | reference_fixture 或 production_candidate；候选状态不等于已通过验收 |
| main_level | 主线序号 1–60；每日题为 null |
| capacity | 固定 4 |
| initial_bottom_to_top | 按稳定瓶序排列的数组；每瓶自底向上，最后一个元素是顶部；空瓶为 [] |
| target_labels | 与瓶数组同长；O / G / P / B 或 null；null 为缓冲瓶，不用字符串 empty |
| reference_moves | 每项含 from_index、to_index，均从 0 开始；不存可由规则计算的倒入量作为指令 |
| difficulty_intent | 设计意图，不能用参考步数冒充难度或最短解 |
| source_reference | 可选的项目内来源路径，用于追溯，不参与玩法 |

颜色枚举沿用原 JSON：O 为橙色圆、G 为绿色三角、P 为紫色菱形、B 为蓝色方形。内部索引从 0 开始，玩家可见瓶号从 1 开始；布局变化不能改变瓶子身份。不得在不同模块中混用顶部至底部和底部至顶部。

数据文件中的数值用十进制整数 token，不使用小数或科学计数法；JSON 对象不允许重复键，不接受 NaN / Infinity。这样版本和索引不会被二进制浮点舍入后误接受。内容工具同时检查 Schema 和此解析约束。

JSON Schema 负责静态形状；以下跨字段条件必须由内容验证器检查：

- N 为 2、3、4；初始瓶数为 N＋2，每个使用颜色恰好 4 单位，每个使用颜色恰有一个目标标签。
- 目标标签的颜色集合与液体颜色集合一致；恰有两个初始空缓冲瓶，每瓶不超过容量。
- 参考操作索引在实际瓶数范围内、源目标不同，每步按最大连续同色段规则合法执行。
- 参考解结束时所有目标满且颜色匹配、所有缓冲瓶为空；整段验证不添加广告瓶。
- 主线目录 ID 和序号唯一且覆盖 1–60；每日目录至少 30 道，引用存在且均已验证。

## 2. 原第 12 关的转换规则

只生成新夹具，不修改原文件。`level: 12` 映射为 `puzzle_id: main-012`、`main_level: 12`；`capacity_per_bottle` 映射为 capacity；原 initial_bottom_to_top 原样保留。

原 target_bottles 按数字 1–6 读取，将 empty 转为 null；原 moves 的 from_bottle / to_bottle 分别减 1。原步骤中的 color、units 和逐步 board_after 作为独立回放断言，不作为求解指令。原 solvable、verified_replay 和搜索耗时是历史声明，不直接继承为新的验收结论。

## 3. 活动实例与撤销

| 字段组 | 约定 |
|---|---|
| 身份 | instance_id、slot（ordinary / daily）、is_replay、puzzle_id、content_version |
| 原题 | 创建时完整题目定义快照；后续题库更新不替换它 |
| 当前局面 | board、move_count、board_revision、undo_history、extra_bottle_granted |
| 教学 | 教学版本、当前步骤、跳过标记；全局完成标记独立保存 |
| 每日身份 | puzzle_date 为本地 YYYY-MM-DD、创建时区标识及偏移、catalog_version；普通局为空 |
| 领域状态 | active 或 completed；保存、广告和动画状态单独描述 |

每次接受的棋盘变更、撤销、重开或加瓶都增加 board_revision。提示结果携带 instance_id 和 board_revision，二者都相同且实例仍 active 才能使用。搜索取消、超时、已证明无解和找到解是不同结果。

撤销项保存倒入前的棋盘与步数，不把奖励权益存成可撤销对象。撤销跨越加瓶时点时，若历史快照只有原瓶数，恢复它并追加已获赠的空瓶；历史已经包含额外瓶时恢复其当时内容。重开恢复原题、清空历史和步数、保留已获赠空瓶，实例 ID 不变。

## 4. 持久化与结算键

以下是逻辑约束，具体 SQL 表及索引由实现落实，不强制建立通用仓储框架。

| 记录 | 唯一性或约束 |
|---|---|
| 活动槽 | 每个 slot 最多关联一个当前实例；替换在事务成功后生效 |
| 主线首次完成 | 稳定 puzzle_id 唯一；重复版本或重玩不重复解锁与发拼片 |
| 实例结算回执 | instance_id 唯一；可保存 completion_id 供事件与导航关联 |
| 拼片归属 | scene_id＋piece_index 唯一；首次达成里程碑的事务中写入 |
| 每日印章 | puzzle_date 唯一；当天重玩不重复授予 |
| 额外瓶权益 | instance_id 唯一；领取尝试 attempt_id 独立去重 |
| 数据库版本 | 与 schema_version、content_version 分开维护；升级有显式迁移 |

通关事务统一包含完成、解锁、应得拼片、广告累计计数和结算回执。参考 AC-09～12、AC-20～24。Analytics 事件发送不是事务成功条件；本地结果是玩家权益的依据。

## 5. 保存与激励状态

保存使用 clean / saving / failed 表示当前待办操作的持久化状态；failed 保留内存结果和待保存内容。Retry 重试同一笔结果而非再做一次业务操作；Stay here 仅留在当前页面。涉及离开、替换实例或结算后广告时，事务未成功就不继续。重启只恢复已提交的数据及可恢复的持久记录。

激励广告采用分开的确认、发放和展示状态，避免“关闭”覆盖“已获奖”：

| 事件 | 状态与操作 |
|---|---|
| 用户确认观看 | 持久化 attempt_id、原 instance_id、槽与实例快照，再请求展示 |
| 实际展示 | 记录全屏展示时间；不表示已获奖 |
| 收到有效奖励确认 | 标记已确认，原子写入对应实例权益及发放结果；失败保留待保存状态 |
| 关闭但无确认 | 只结束展示等待，不发瓶；保留必要的请求关联以识别迟到确认 |
| 重复或迟到确认 | 先按请求识别，再按实例权益去重；不能发给现在正在玩的另一个实例 |
| 原局被替换 | 保留原实例的有效恢复数据；按规格提供明确替换确认后恢复 |
| 原局已经完成 | 记录归属，不重开、不重复通关、不重新分配给新局 |
| 进程终止且无持久确认 | 不推测获奖；按 SDK 实际能力处理未确认请求 |

一笔请求尚未结束或已确认待处理时，同一槽不开始新激励领取。已关闭且仍未确认的历史请求与新的活动领取意图区分保存；过期或清理策略不能破坏已确认奖励，也不能在 SDK 行为尚未验证前假设回调绝不迟到。对应 AC-18～21、AC-32。

## 6. 开发前应覆盖的样本

第 12 关提供原始参考解，其他案例在纯 Dart 核心开发时建立自动验证。重点包括：容量截断、异色顶层、同色但目标错位、加瓶前后撤销、重复结算、保存失败重试、跨日替换、提示过期、奖励回调乱序和数据库迁移。以原 AC 定义预期结果，不复制实现输出充当预期值。

准备工具已增加两色与三色手工夹具，位于 docs/content/fixtures/；所有样本均为 reference_fixture。工具及对应行为测试见 [运行说明](../../../tools/content/README.md)，不替代 Dart 或事务测试。

## 7. 每日目录与日期映射

[目录 Schema](../../content/contracts/daily-catalog.schema.json) 使用 schema_version、catalog_version、epoch_date 和有序 puzzle_ids。至少 30 个不同每日 ID，全部引用已经校验通过的题目；正式 epoch 与题目顺序仍待内容编排，测试日期不是发布设置。

使用本地公历年月日的日历日差 d，长度 n，0 起始索引为 `((d % n) + n) % n`。epoch 当天取第 0 项，之后逐日轮换；epoch 前日期按同样算法回到末尾，不引入在线校时或日期封禁。不能用本地时间戳差除以 86400，避免夏令时造成差一天。

这明确既定固定循环的技术算法；没有改变跨日继续、印章归属或旧实例保留规则。实例创建时存入 catalog_version、puzzle_date 和原题定义，目录更新后正在玩的实例不重新映射。Python 准备工具已验证跨年、闰日和 epoch 前日期；Flutter 实现仍需一致性测试。
