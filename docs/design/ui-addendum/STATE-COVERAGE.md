# D01–D09 状态覆盖

最终状态（2026-10-22）：D01–D09 的静态设计及有限原型已通过独立验收，R01–R06 关闭；以下自查记录保留交付时状态。最终依据见 [独立验收报告](../review/ui-addendum-acceptance.md) 第 9 节，App 运行验证尚未进行。

2026-10-21，设计／交互呈现交付。**第二轮：R01–R05独立复验通过并关闭；R06修复已提交，D01/D05/D09待复验。** [R06路径／24组合前后截图](REVISION-R06.md)。下列“已补”指可查看的 UI 状态，不表示实际 App、存档或 SDK 通过验收。打开 `index.html#状态ID`；同名 PNG 位于 `screenshots/`；完整目录见 `screenshots/manifest.json` 和 `evidence.html`。

| 增量 | 原页 | 已补视觉证据／状态 ID | 保留原稿与范围界线 |
|---|---|---|---|
| D01 | P06 / P10 | `pause-saving`, `pause-failed`, `pause-stay`, `pause-saved`, `pause`（当前上下文暂停／Resume）, `settlement-saving`, `settlement-failed`, `settlement-stay` | 成功才出现 saved；写入中禁用离开；失败 Retry / Stay here；结算失败停留锁定。没有实现真实写盘或待办导航恢复。 |
| D02 | P07 / P08 / P09 | `hint-search`, `hint-timeout`, `hint-unsolvable`, `hint-found`, `hint-executed`, `hint-undo`, `restart` | 等待可取消，超时不等于无解；源1预选，点目标5才出现操作回执。P08 无合法移动原稿登记为原始 03 板中间；P09 保留免费重开与额外瓶保留。没有求解器、倾倒动画或性能测量。 |
| D03 | P14 / P15 / P09 | `daily-old`, `daily-old-board`, `daily-replace`, `daily-replace-failed`, `daily-today`, `daily-old-complete`, `daily-new`, `daily-history`, `daily-unavailable`, `daily-complete`, `daily-completed-entry`, `daily-replay`, `daily-replay-complete` | 旧题归属 Oct20，今日 Oct21；取消保留旧局；新实例保存成功才替换；历史只读、未来禁用；保留每日 Replay，重玩不再发章。日期为明确固定样例。 |
| D04 | P02 / P03 / P10 / P11 | `home-replay`, `ordinary-replace`, `replay-board`, `replay-complete`, `normal-complete`, `patch-complete`, `patch-reveal`, `patch16-complete`, `patch16-reveal`, `chapter20`, `chapter40`, `all-complete`, `home-story`, `home-done`, `home-story-replay`, `all-collection` | 非拼片 Next，拼片 View patch → Next；重玩 Replay again / Choose level / Home；20/40 Continue；60 无 Next。广告检查说明见 DELIVERY，SDK outcome 为评审夹具。 |
| D05 | P16 / P17 / P18 | `reward-offer`, `reward-cooldown`, `reward-pending`, `reward-stay`, `reward-unconfirmed`, `reward-unavailable`, `reward-late`, `reward-resume-confirm`, `reward-late-complete`, `reward-complete13`, `next14`, `seven` | P16 两步确认沿用；冷却不自动播放；确认待写入与到账分开；迟到奖励绑定原实例，恢复先确认替换；已完成原局不重开。未接 SDK、未计时、未做权益持久化。 |
| D06 | P04 / P05 | `tutorial-fidelity`原框架、`tutorial`, `tutorial-free`（Skip保留Level1四瓶）, `board`, `screenshots/D06-overview.png` | 局部编辑原瓶体：4档刻度、P04蓝目标外套与方形标签一致、浅色液体和无标记透明缓冲瓶区分。教学各色段2单位；棋盘各段1单位。没有修改归档。 |
| D07 | P02 / P11 / P12 / P13 | `home-3`, `collection-3`, `scene-3`；相同的 `*-4`, `*-5`；`scene-stages` | 共用完整原房间＋同一组区域遮罩／进度；R1已实际走查3/4/5片首页→收藏→详情的按钮及顶栏Back往返，不再写死3。无重新生图；0–5阶段为构图映射样例。三场景完整分层资源仍属内容交付，不宣称已完成。 |
| D08 | P18 | `seven-fidelity`原框架、`seven`, `adapt-seven-320-1x`, `adapt-seven-320-2x-contrast` | 4+3同图片盒、同缩放、末排居中；基准与窄屏均有截图及尺寸记录。像素点击盒不等于真机触控测试。 |
| D09 | P19 | `settings-reuse`原稿保留、`settings`排版样例、`feedback`, `feedback-ready`；`adapt-settings-320-2x` 顶／底；`adapt-pause-failed-320-2x` 顶／底；`adapt-daily-replace-320-2x` 顶／底；`adapt-board-390-1x-contrast` | 复用设置项目、默认值、1.0版本与隐私入口；新增反馈入口。200%是原型样例最大值，不是最终系统最大字号承诺；反馈收件地址待提供，没有发送。 |

## UI-01～12 覆盖框架登记

| 框架 | 本轮证据 | 原已存在证据／未验证范围 |
|---|---|---|
| UI-01 入口 | D04 首页重玩、替换、全通 | P01–03 原01板；锁定关保留，完整选关逻辑未实现 |
| UI-02 教学／棋盘 | D06 容量及语义，D08 排列 | P04–05 原02板；倒液、非法反馈、教学恢复待 App |
| UI-03 提示 | D02 | P07–09 原03板；2秒预算、取消竞态待 App |
| UI-04 保存 | D01 | P06成功状态保留；事务与强退恢复待 App |
| UI-05 结算 | D04 | P10–11 原04板；结算去重待 App |
| UI-06 插屏衔接 | `patch16-*` → `next17`；独立 `ad-check` 评审夹具 | 无仿真广告画面；累计资格、实际展示回调、一次导航、时钟与后台待 SDK |
| UI-07 激励 | D05 | 原06板的 P16说明／P17不可用／P18到账保留；请求就绪及授权待 SDK |
| UI-08 迟到恢复 | `reward-late`, `reward-resume-confirm`, `reward-late-complete` | 原实例快照、领取意图持久化待实现 |
| UI-09 每日 | D03 | P14–15 原05板；映射目录、时区切换、保存替换待 App |
| UI-10 收藏 | D07，章节完整态 | 原04/05板；当前遮罩构图非最终透明分层；三场景完整18状态资源未交付 |
| UI-11 全通 | D04 `all-*`, `home-story`, `home-done`, `home-story-replay` | 不生成61关；跨重启主入口选择待 App |
| UI-12 设置适配 | D09和适配截图 | P19–21 原07板保留；真机读屏、对比度测量、平台最大字号待验证 |

原板均在 `../original/Pourlune_Design_Pack/boards/`；PDF对应页3–9，原件未覆盖。36条运行验收均未被本轮标记为通过。

## R1上下文衔接覆盖

`puzzle-board`为辅助返回视图，不是固定Level12；`pause`／`restart-confirmed`分别用于当前实例暂停返回和同实例重开回执。`tutorial-free`只去引导；`reward-applied`表示明确的奖励写入成功模拟事件。五种起点reward-pending、pause-stay、daily-old-board、replay-board、seven的Undo／Hint取消／暂停Resume与重开保留身份和标记；完整路径及结果JSON见REVISION-R1。

选择评审下拉／直接URL／重载会进入新的确定样例，页面内导航保留上下文；未扩成跨进程存档。R05重新拆片的各图均保持396×793 RGBA，实际六瓶／七瓶和原框架PNG已重导出。

## R06 横幅响应式验证

未保存／待奖励及已有复合状态，在320/390宽、100%/200%字号、增强对比开／关共24组合检查，完整单词、字体、点击可达和状态往返均通过。200%字体保持28.16px；Retry、Retry save、Retry reward按内容宽度排版，必要时单独一行。Undo、Hint取消、暂停Resume不清标记，只有显式Retry模拟成功才清对应状态。R01–R05的41项回归通过，七瓶同尺寸保留；独立结论仍待R06复验，见REVISION-R06。
