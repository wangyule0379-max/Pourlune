# Pourlune UI 增量独立验收

验收日期：2026-10-21（Asia/Taipei）  
验收方：Pourlune ｜ 产品架构  
执行方：Pourlune ｜ App 设计 开发  
结论：**首轮不通过，需修复原型路径后复验。** D08 七瓶布局、D09 设置增量在本轮限定范围内通过；其余项目已有状态稿，但存在跨状态衔接缺陷。

## 1. 范围与方法

依据 [原稿审查 D01–D09](original-design-review.md)、[UI 交付约定](../../pmpowers/specs/UI-design-handoff-and-review.md)、[产品补充稿](../../pmpowers/specs/PRD-supplement-v1.1.md) 和 [验收清单](../../pmpowers/specs/acceptance-and-content-readiness.md)。

实际打开并检查交付的 D01–D09 九张流程总览，重新查看原始教学／棋盘、激励广告与设置视觉板作对照；在 Codex 内置浏览器打开本地原型，实际点击关键路径并独立截图。常规预览为 390×844 的手机容器；窄屏实查为 320×700 浏览器、原型 200% 字号及增强对比样例。复查了保存弹窗、每日替换和设置的滚动底部。

原始设计包的 15 个文件重新与下载 ZIP 按字节比较，一致。独立证据位于 [ui-addendum-evidence](ui-addendum-evidence/manifest.json)，包含本轮截图、尺寸读数及交付源文件 SHA256。没有以执行方自查结果代替本报告。

本次审的是状态图与有限交互原型。以下问题要求修正可点击路径的显示语义，不要求开发真实游戏引擎、数据库、广告 SDK 或全部题库。

## 2. 逐项结论

| 步骤 | 编号与范围 | 本轮观察和健康度 | 结论 |
|---|---|---|---|
| 1 | D01 保存与失败恢复 | Retry 可到保存成功；保存失败、结算锁定文案已补。Stay here 后使用 Undo 会抹去未保存提示，见 R02 | 需修复复验 |
| 2 | D02 提示与救援 | 等待、超时、已确认无解有明确区别；但超时后的重开取消路径凭空加瓶，见 R03 | 需修复复验 |
| 3 | D03 跨日与每日重玩 | Oct 20 / Oct 21 替换确认和取消返回正确，未来日期禁用；旧日棋盘使用 Undo 后丢失日期和模式，见 R02 | 需修复复验 |
| 4 | D04 重玩和结算变体 | 非拼片、拼片、章节和第 60 关按钮变体已呈现，最终完成无 Next；重玩棋盘使用 Undo 后变普通 Level 12，见 R02 | 需修复复验 |
| 5 | D05 激励与奖励待保存 | 两步说明、冷却、待保存及迟到恢复说明已补；待奖励状态使用 Undo 后重新开放加瓶，见 R02；重开路径见 R03 | 需修复复验 |
| 6 | D06 容量与目标辨识 | 容量刻度、蓝目标与蓝装饰、中性缓冲已有证据；Skip 会换成 Level 12 六瓶局面，见 R04；部分单瓶边缘有残片，见 R05 | 需修复复验 |
| 7 | D07 收藏一致性 | 手动选同一进度状态时共享相同遮罩，但 4/5 首页进入收藏却变 3/5，见 R01 | 需修复复验 |
| 8 | D08 七瓶尺寸 | 原框架合成和自适应样例为 4＋3；独立实测 320 宽、200% 字号时七个瓶按钮均为 64.25×147 CSS px，底部操作滚动可达 | 本轮布局范围通过 |
| 9 | D09 设置与适配 | 原设置稿保留，新反馈入口可打开表单；200% 样例长文案和底部按钮可达，版本文字保留 | 本轮入口与排版样例范围通过 |

D08 通过不代表原生触控或真实动态瓶体通过；D09 通过不包括真实反馈发送、平台最大字号、读屏顺序、对比度合规和设置持久化。

## 3. 必须修复的问题

严重性以本轮原型验收为范围：P1 为核心流程显示与既有规则相悖，P2 为局部交互或视觉交付缺陷；均不表示已经发布的 App 存在这些故障。

### R01　P1　收藏跨页面进度回退（D07）

复现：评审选择器选 `home-4` → 页面显示 4/5，下一关 Level 17 → 点击 Collection → 到 `collection-3`，变 3/5、还差 8 关。来源是 app.js 的 collectionPage 对 Collection / Back to home 写死 3 片目标。

期望：同一进度的首页、收藏、详情、返回按钮始终保留 n。3、4、5 片均须走完整往返；顶栏 Back 也不能回到不相干的重玩首页。只需修正状态映射，不需要接存档。

![首页4片](ui-addendum-evidence/03-home-four.jpg)

![点击收藏变3片](ui-addendum-evidence/04-collection-regressed.jpg)

### R02　P1　辅助操作丢失当前实例与待处理状态（D01／D03／D04／D05）

四条独立复现路径都落到通用 `hint-undo`：

| 起点与操作 | 实际结果 | 应有结果 |
|---|---|---|
| `reward-pending` → Stay here → Undo | Reward pending 和 Retry 消失；Extra bottle 重新可点 | 保留待奖励状态与重试入口，禁止重复领取 |
| `pause-stay` → Undo | Progress not saved 和 Retry 消失 | 在明确的保存成功事件前保留未保存提示 |
| `daily-old-board`（Daily · Oct 20）→ Undo | 变普通 Level 12，日期消失 | 保留每日模式、Oct 20 身份与原实例 |
| `replay-board`（Replay · Level 3）→ Undo | 变普通 Level 12 | 保留重玩标识与关卡身份 |

定位：app.js 的 boardMarkup 将 Undo / Hint / Back 指向共享默认状态；hint-undo 又用默认 boardMarkup 渲染。修复时保留最小的原型上下文或建立明确的状态返回映射，并检查 Hint → Cancel、暂停 → Resume、已加瓶局面的辅助操作同类路径。不得通过禁用免费辅助掩盖问题，也无需实现真实撤销或持久化。

![奖励待保存](ui-addendum-evidence/11-reward-pending-board.jpg)

![Undo后重新开放加瓶](ui-addendum-evidence/12-pending-undo-reenables-ad.jpg)

每日身份对照：[操作前](ui-addendum-evidence/20-old-daily-board.jpg)、[操作后](ui-addendum-evidence/21-daily-undo-loses-identity.jpg)。未保存提示消失：[证据](ui-addendum-evidence/27-undo-clears-unsaved.jpg)。重玩身份消失：[证据](ui-addendum-evidence/28-replay-undo-loses-identity.jpg)。

### R03　P1　取消重开会凭空获得额外瓶（D02／D05）

复现：`hint-timeout` 的背景为六瓶 → Restart → 重开确认 → Keep playing → 到 `seven`，显示 Extra bottle added。未经过任何获奖确认；直接确认 Restart 也被写死指向 seven。

期望：取消保持原局与原瓶数；确认重开保持实例身份及已存在的额外瓶权益，不能凭空添加，也不能收回已获赠瓶。至少分别验证六瓶未加瓶、七瓶已加瓶两种上下文；每日和重玩沿用 R02 的身份保持。

![取消重开后错误到账](ui-addendum-evidence/08-restart-cancel-adds-bottle.jpg)

### R04　P2　Skip 换关且开放额外瓶入口（D06）

复现：`tutorial` 显示 Level 1、两色四瓶，点击 Skip → `board`，显示 Level 12、四色六瓶与 Extra bottle。

期望：仅移除教学引导，保留 Level 1、当前局面和瓶数；首关仍隐藏加瓶。原型可以使用同一静态局面的自由状态，不需要实现教学引擎。

![跳过前](ui-addendum-evidence/05-tutorial-before.jpg)

![跳过后错误换关](ui-addendum-evidence/06-tutorial-skip.jpg)

### R05　P2　单瓶裁片边缘残留细条（D06／D08）

在六瓶较大展示中，橙瓶和蓝瓶右侧可见与瓶体分离的竖向残片，缩到七瓶后仍能看到细线。定位已使用的 bottle-0 / bottle-3 等裁片，参考 [六瓶截图](ui-addendum-evidence/06-tutorial-skip.jpg) 和 [七瓶截图](ui-addendum-evidence/08-restart-cancel-adds-bottle.jpg)。

清理图像边界残片，同时保留容量刻度、透明通道和统一缩放；复查原框架与自适应两种呈现。不要求重新生成整套瓶体或改变视觉风格。

## 4. 已确认的改善与证据

- 保存失败明确区分内存保留与已落盘，直接 Retry 的结果正确：[保存成功](ui-addendum-evidence/02-save-retry.jpg)。200% 窄屏弹窗底部可滚动到 Retry / Stay here。
- 每日替换写明替换的是 Oct 20，保留普通主线；取消回到旧日继续入口：[取消结果](ui-addendum-evidence/10-daily-cancel.jpg)。
- 第 60 关提供 Daily puzzle / View collection / Replay levels，不出现 Next：[最终完成](ui-addendum-evidence/19-final-complete.jpg)。
- 七瓶两行尺寸一致，窄屏大字号的操作区可滚动到达：

![七瓶窄屏大字号底部](ui-addendum-evidence/14-seven-narrow-large-bottom.jpg)

- 设置保留原针织视觉，并新增反馈入口；大字号研究与原稿复用明确分开。发送目的地未配置，不伪称已发送：

![设置大字号底部](ui-addendum-evidence/25-settings-narrow-large-bottom.jpg)

## 5. 后续生产与运行边界

Color Studio 的矩形遮罩目前只用于阶段映射说明，Garden Nook / Seaside Corner 仍为缩略素材。正式三场景透明分层、字体分发授权、真实反馈地址属于已登记的开发准备项，本轮不要求扩大 UI 任务去完成全部生产素材、注册账号或后台。

本轮没有验证真实写盘、强退恢复、SDK 回调、广告时钟、真实求解、液体动画、数据库迁移、全题库、原生触控与读屏、完整对比度或帧率。36 条 App 验收仍待执行。静态样例的通过项不能扩大为 App 或发布通过。

## 6. 修复与复验要求

执行聊天只在 `docs/design/ui-addendum/` 修复 R01–R05，更新相关文案、覆盖说明和真实截图，提供各复现路径的修复前后结果。不得修改原件或以改产品规格消除缺陷。复验由产品架构聊天重新点击路径并保存新证据；在复验通过前，整体状态保持未通过，保留跟进。
