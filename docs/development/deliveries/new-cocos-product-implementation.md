# 新Cocos玻璃花园 · S1/S2代表阶段

2026-11-06。开发自测已交付，**待总控独立验收**。本阶段没有安装包、构建号或商店更新。原型设计PASS不等于新工程、原生或SDK通过。

## 来源与范围

工程 `glass-garden/`，既有checkout/分支 `codex/pour-flight-size-fix` 增量新增；开工前仅既有.scratch未跟踪。旧Flutter、只读站点、受验原型、原存档及冻结候选未修改。基准R1-5732d17bf059及新增三份refactor约定，精确路径/hash见 `../evidence/new-cocos-product-20261106/s2-input-contracts.json`。

407条输入源hash核验：404条游戏文件及3份只读reference。rules/campaign/progress/game/render/main六文件原字节保留，100关顺序、难度、规则、瓶阵、轨迹和时长不变。仅在新bridge、复制的HTML/project脚本接线调整。`product-model.mjs`拥有round/解锁/快照/收据，`storage.mjs`负责IndexedDB事务，`product.mjs/views.mjs`承接原型，未增加运行时npm依赖。

## 已修缺陷

- 原倒水开始已改Session，却等finish动画才保存，通关写两次。现在after局面/完整Undo/通关收据同事务即时提交；重复checkpoint加入同次写入，旧round/flow回调被拒绝。保留原return阶段排队与动作时长。
- transaction complete才确认保存，put success后abort不假Saved。保留已确认与待提交快照，Retry不换实例；故障阻止依赖操作/导航。revision冲突、损坏和空记录区分，显式替换原子保留quarantine。
- Next恢复下一关原盘/历史/round，产品与gameProgress.current同步。损坏指针、游离round、坏历史不静默清档。
- 电脑首查实际发现Home→Game所有按钮disabled残留，已补页面切换/弹层关闭后的refresh并复验，初始失败截图保留。
- 隐藏/弹层停止绘制水声，Hint取消终止Worker并令晚结果失效；Esc不能绕过通关/存档门槛。子资源失败向父显示Retry，避免Play永久等待隐藏iframe。

## 冻结与检查

候选绝对路径 `/Users/wangyule/.codex/worktrees/testflight17-fixes/Pourlune/glass-garden/build/s2-r1/`：415玩家文件，14240210 bytes；artifact-manifest SHA256 **8310e20e1ddfa7a5bbdef52ca9a238626f7258f4eac9712b00acd4b2bf095d3b**。逐文件清单副本 `../evidence/new-cocos-product-20261106/s2-r1-artifact-manifest.json`。候选未覆盖，不含QA/reference/npm依赖/samples.js。精确源码提交随交接发送总控。

在glass-garden执行 `npm ci --ignore-scripts`、`npm test`、`npm run verify -- --inputs`；`npm run package -- <new-name>`拒绝覆盖。Node22.23.2，22项PASS/无跳过，原407条源与六核心/100关核验通过。RED/GREEN原始日志保留。自动覆盖真实规则恢复/Undo/Next、完成幂等/旧round、写入中止/竞争/损坏隔离、设置与拒绝保留、未执行动画回调时动作/最后通关已落盘、输入刷新和加载Retry。动画测试只替代绘制端口，不当实际动画或SDK证明。

Use Computer实际Chrome390×844、320×568及独立IAB新玩家：拒绝/关闭后可玩，刷新不重问；倒水/Undo/Pause/Resume/Restart取消与确认；真实首关9手→2关1手→重玩1关9手→Next保持2关原盘/1手，刷新Continue保持且Undo可用。正常标签console error/warning空。

隔离4198 QA：实际put success后abort显示Not saved yet，Stay后瓶子/暂停不可继续，Retry恢复完整2手，刷新同盘且Undo回1手。隔离4199 QA：本地engine一次故障后父显示Retry，重载后Continue恢复原一手且Undo可用；浏览器接口未暴露HTTP状态明细，不称网络面板独立核验503/200。故障工具不进玩家包。完整实际记录及截图见 `../evidence/new-cocos-product-20261106/browser-s2/report.md`。

## 未验与下一门槛

总控尚未独立接受S2，因此外围页推广、原生构建及SDK未推进。真实慢Hint取消未捕获（真实搜索过快）；自动取消/晚结果已过。后台原生生命周期、return窗口快操作、同屏几何稳定与性能基线仍需实际证据；不以Node替身或截图代替动态验收。

当前无广告/GameMunchies/Firebase客户端或远程队列，CSP连接仅本地源；选择允许也不启动采集，真实接线前须重新告知/选择。音乐/震动禁用是能力占位，不是正式默认策略，已有布尔值不覆盖。旧60关→新100关同身份迁移未实现，奖励玩法/频次/匹配SDK另列待定。

**没有广告超时修复或真实展示/奖励通过结论，没有签名、上传、审核或发布。** F9、原设备/库及旧iOS19/Android19未动。未启动设备，UDID/serial不适用。预览HTTP进程仅供验收，结束后由开发清理。按总控实际结果继续返工，不能将本阶段自测写成TestFlight就绪。
