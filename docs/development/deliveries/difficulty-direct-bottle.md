# 主线节奏校准与关闭广告时直接加瓶

用户2026-10-25明确授权修改题库，当前没有广告接口时点击增加瓶子直接生效。当前实现由父亲自完成，未唤醒其它开发聊天。

## 内容

替换22题：13/14/15/16/19/20/21/28/32/35/36/37/39/40/41/44/48/51/55/58/59/60。前12题、其它26题、每日30题和目录逐字节保留；只有替换题 content_version+1，21原为v3故本次升v4，其余替换题v2→v3。运行资源与内容源同步，90题无等价/结构重复。

独立有序BFS按真实“连续同色尽量倒满”规则测量全部60题。阶段平均最短步数1–4=6，5–8=7.25，9–12=12.25；13–20由13.88→14.5，21–40由14.45→15.2，41–60由15.35→16.15。13由17→15缓和突升，20/40/60分别13→16、15→17、14→18。保留缓和关，不把每一步数严格单调当作人类难度。

所有60题均不加瓶可解。15/20/28/35/39/40/44/48/51/55/58/60有已回放的合法误走分支，进入无合法步后增加一个空缓冲能恢复通关；第20/40/60均只需两个误选动作即可验证此用途。它是救援选择，不强迫加瓶或看广告。完整新旧步数见 `../evidence/difficulty-direct-bottle/curve.csv`，具体堵塞与恢复路线在内容输入和逐关证据。

新输入 `docs/content/design/main60-rebalance-v3.json` 已冻结；`tools/content/rebalance_main60_v3.py --check` 可重放和重测。安装器先检查全部目的地，仅接受冻结旧题或完全一致新题，拒绝未知并发改动，不处理玩家数据库。旧v2作者工具保留历史用途。

## 领取与保存

明确 ads disabled（或无ServiceHub）时，主线4+和每日点击 Extra bottle 立即走本地事务，仍每实例一次。UI不出现Watch/暂无广告弹层。新瓶、权益原子写入SQLite，保存后才出现新增反馈；失败保留旧棋盘并由既有Retry恢复。不创建虚假 reward_attempts、fullscreen_attempts/shows 或广告确认。真实test/prod配置保持SDK回调路径，不将加载失败当观看成功。

旧非空v1/v2实例保留原定义、Undo/Restart、额外瓶和历史；新题只影响新实例。重复领取、重开、进程恢复不重复发放，首通/拼片/日期奖励不改。自动回归包括真实磁盘SQLite关闭重开、事务故障和19关QA准备。

## 验证

- 新直接领取回归先5项RED，实施后5项PASS；广告/存储/控制器相关19项PASS。
- 新难度门槛旧内容15个子断言RED，安装后内容工具47项PASS；严格release+catalog90通过，复现check通过。
- 核心39项PASS，含12个堵塞分支新增空瓶恢复、240个真实提示采样、16个偏离参考路径的提示采样与代表连续Hint。保持2秒/50000边界；本机采样最大28.6ms/2987状态，仅测试结果不等于手机性能。
- 应用全量400项已通过后，唯一旧全页库存用例仍等旧广告弹层而等待；终止该等待并改为新直领断言，单独重跑通过（含其页面/尺寸原矩阵）。其余400未因该测试变动重复执行。分析无问题；依赖锁未变。
- 正常main专用QA实际验证见下方补记。真实人工首玩难度和物理手机体验未测；不将算法或截图冒充真人难度标定。

本批不是已上传TestFlight11；不覆盖冻结发布证据。

### 正常入口原生复验

本轮正常 `lib/main.dart` / Bootstrap，ads disabled，无场景入口；仅63B专用QA/dev.pourlune.parentNormalValidation，402×874正常字号，使用新命名 `difficulty_direct_bottle.sqlite`。原 `parent_normal_closeout.sqlite` 完整iterdump哈希前后相同，不回滚历史状态。构建36.2秒成功，来源220项运行输入和实际Runner/kernel哈希见 `source.json`。

离线准备19次真实store结算仅用于到达第20关，不宣称人工玩过19关。实际UI点击Continue20，执行2→5、2→6，屏幕出现No moves available；点击Extra bottle直接新增米白第7瓶，出现成功条/光晕、按钮变成禁用Bottle added，无广告弹层。实际2→7恢复合法倒水；Undo后仍7瓶，Pause→Restart确认明确extra stays；重开回新题初盘+第7空瓶。随后终止/重启同安装正常App，再Continue20，7瓶/禁用已领按钮仍在，无重复新增动画。

只读SQLite证明同实例 `difficulty-v3-qa-20`：两步rev2→领取rev3→再倒rev4→Undo rev5→Restart rev6（0步），冷启动保持。唯一entitlement=1；reward_attempts/fullscreen_attempts/fullscreen_shows均0；既有19回执/4拼片及其它奖励表完整不变。变动仅active_slots、reward_entitlements、service_values。F9/Small11b/历史Large未操作。

本批未新增TestFlight包，手机仍为已发布11。若当前活动关来自旧版本，继续/重开沿用旧定义是保存契约；新关实例使用本次题库。

提交的工具日志仅统一行尾与尾随空格，保留检查结果和原失败记录。
