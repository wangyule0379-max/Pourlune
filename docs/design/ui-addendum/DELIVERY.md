# Pourlune UI 增量交付

最终验收更新（2026-10-22）：产品架构聊天已独立复验并关闭 R06，D01–D09 在静态设计与有限 HTML 原型范围通过。依据见 [独立报告第 9 节](../review/ui-addendum-acceptance.md#9-第三轮独立复验与最终结论2026-10-22)。以下保留执行方交付时的自查状态，不代替最终报告。仓库不分发本机系统字体文件，原型改用 CSS local()；没有 Arial Rounded MT Bold 的设备回退 Arial / sans-serif，精确外观以已验环境及截图为准。

日期：2026-10-21（Asia/Taipei）\
交付层级：可查看的UI状态图册＋有限交互原型，不是完整App。**第二轮独立复验已将R01–R05通过并关闭；R06已修复并完成自测，D01/D05/D09待本轮独立复验。** D02/D03/D04/D06/D07及D08的既有通过范围按独立报告保持。

本轮优先查看 [R06修复说明与变更文件](REVISION-R06.md) 和 [同条件修复前后截图](revision-r06/index.html)。24/24响应式组合、41/41原路径回归通过；字号未降低。独立报告 `../review/ui-addendum-acceptance.md` 及tracking保持未改。历史R1交付见[REVISION-R1](REVISION-R1.md)。

## 直接打开

根目录绝对路径：`/Volumes/data/App Development/Pourlune/docs/design/ui-addendum/`

- 交互图册：`/Volumes/data/App Development/Pourlune/docs/design/ui-addendum/index.html`，直接用浏览器打开可离线使用；`#pause-failed`等锚点直达状态。左侧下拉选择状态、100/150/200%文字样例和增强对比。
- 按流程排列的真实导出稿：`/Volumes/data/App Development/Pourlune/docs/design/ui-addendum/evidence.html`。9条流程，点图查看原尺寸PNG，点“定位状态”进入图册。
- 当前本地预览：[图册](http://127.0.0.1:4173/#pause-failed)；[截图流程](http://127.0.0.1:4173/evidence.html)。仅本机，未发布。
- 如果预览服务已停，在项目根目录运行：`python3 -m http.server 4173 --bind 127.0.0.1 --directory docs/design/ui-addendum`。也可直接打开上述HTML，不依赖服务。

交付清单：`STATE-COVERAGE.md`（D01–D09与UI-01～12）、`UI-copy-addendum.csv`（实际UI文本、状态键、目的地和禁用状态）、`COMPONENTS.md`（尺寸／区域映射）、`IMAGE-EDITS.md`（局部编辑输入／提示词与弃用候选）、`verification.json`（渲染尺寸、按钮及缺图检查）、`design-qa.md`（当前自查及独立验收状态区分）、`original-inventory.json`（原件当前SHA256清单）。

## D01–D09 结果与证据

| 项目 | 本轮交付状态 | 最短定位证据 |
|---|---|---|
| D01 保存 | 设计增量已补；运行写盘未实现 | `#pause-failed`, `#settlement-failed`；`screenshots/D01-overview.png` |
| D02 提示 | 等待／取消／超时／已确认无解已补；只模拟动作接受，无求解或液体变化 | `#hint-search`, `#hint-timeout`, `#hint-unsolvable`, `#hint-found`；`D02-overview.png` |
| D03 每日 | 跨日选择／替换／取消／旧日章／历史只读／未来禁用／Replay已补 | `#daily-old`, `#daily-replace`, `#daily-old-complete`, `#daily-replay-complete`；`D03-overview.png` |
| D04 结算变体 | 普通、拼片、重玩、20/40章节、60全通和首页变体已补 | `#normal-complete`, `#patch16-reveal`, `#replay-complete`, `#chapter20`, `#chapter40`, `#all-complete`, `#home-story-replay`；`D04-overview.png` |
| D05 激励 | 冷却／确认待写入／迟到恢复确认已补，保留两步主动确认 | `#reward-offer`, `#reward-cooldown`, `#reward-pending`, `#reward-stay`, `#reward-late`；`D05-overview.png` |
| D06 瓶体可读性 | 局部图像编辑及教学目标一致性修正已补 | `#tutorial-fidelity`原框架、`#tutorial`, `#board`组件样例；`assets/tutorial-edited.png`, `assets/bottles-edited.png`, `D06-overview.png` |
| D07 收藏一致性 | 三入口共享3/4/5进度、0～5区域映射样例已补；最终物件透明分层未交付 | `#home-3`, `#collection-3`, `#scene-3`, `#scene-stages`；`D07-overview.png` |
| D08 七瓶 | 4+3同图盒同缩放、末排居中已补并导出窄屏 | `#seven-fidelity`原框架、`#seven`自适应布局；`adapt-seven-320-1x.png`, `adapt-seven-320-2x-contrast*.png` |
| D09 设置／适配 | 原P19＋反馈直接复用稿及独立响应式研究已补；收件目的地待提供 | `#settings-reuse`, `#settings`, `#feedback`；`D09-overview.png`, `adapt-settings-320-2x*.png`及长文案适配图 |

所有PNG都在根目录的 `screenshots/`。完整状态清单由实际渲染生成，不要求重新画P01–P21；其中少量标为“Review”的状态是评审夹具，不是App页面。已经从正常产品按钮路径移除这些夹具；只在评审下拉中定位。

## 原稿复用及改动边界

已实际查看7组原图与PDF第3–9页的渲染；读取原PRD、英文文案、目录、动效规格和本次三个产品文档。原件仍在 `/Volumes/data/App Development/Pourlune/docs/design/original/Pourlune_Design_Pack/`。本轮所有写入限定在 ui-addendum，未改产品架构聊天维护的 specs 或归档原件。

原料复用：天蓝底、奶油针织纹理、青柠按钮纹理、Back、Logo、日历、完整房间、章节缩略图，来自原板裁切。R1中暂停／提示／奖励弹窗改以当前上下文组件为inert背景，保留模式／日期／瓶数和待处理标记；不再用固定Level12背景替代其他实例。设置主稿直接复用原P19，加反馈行并保留Pourlune · 1.0；`settings`是单独的大字号排版研究，不声称重新定稿原设置页。内置image_gen局部编辑了瓶体与两个原框架，全部采用输出已复制进本项目；一张不满足七瓶一致性的候选被弃用。P18原框架通过清空瓶区后叠放同一瓶体组件来保证尺寸，不依赖图像生成尺寸猜测。

保留：原P15每日Replay、原P19版本、P16说明→Watch确认的两步流程、P21 Keep progress主操作、原P06成功文案与原P08无合法移动。后两者是已有证据，不能当作本次新增规则。

## 冲突位置与采用依据

| 位置／冲突 | 本轮选择与原因 |
|---|---|
| 原 PRD §6.3、§10广告示例、§13仍写4次首次通关／最早14关；归档PDF第14页§6.3、第19页广告示例、第23页广告依据旧口径 | 采用 `docs/pmpowers/specs/PRD-supplement-v1.1.md` §6.2及原设计核验报告§4：从第11次首次通关起累积，满3次具资格，最早13；只在新的主线首次结算且玩家Next意图上检查。原件不覆盖。 |
| 13/16/19理想序列容易被误读成固定点 | 不设固定关卡表。无展示不清零，13跳过后14新结算可再检查；实际插屏展示才清零。Home／收藏／旧结算／重启不补弹。 |
| 冷却曾被误述为仅前台时间 | 按补充稿§6.4，上次任意全屏广告实际开始展示至今至少180秒，后台经过时间计入；激励不清零主线累计资格。01:42仅是显示样例，不是假定已运行计时。 |
| 20/40额外章节保护 | 本轮补充，采用补充稿§6.3；章节奖励优先，跳过该次插屏且资格保留，之后新首通过渡可再检查。60无Next及插屏。 |
| 原 P13 3/5锁定区与首页／收藏整房间不一致 | 统一完整P11底图与同一组区域遮罩。3/5只揭示前三块，5/5不再带原详情图的烘焙锁。不是重新创造三场景。 |
| 字体与布局精度 | 原图字体仅视觉参考；用圆体与原纹理重排新增文字。基础／窄屏／200%为本次样例，不当成最终系统支持范围或无障碍认证。 |

本轮不采用尚无独立确认的“单会话4次／滚动24小时8次”建议。广告法务、平台政策和SDK行为没有在本轮验证。

## 自查完成与未验证

R1补充：首轮多步导航自查不充分，独立验收发现R01–R05。已通过最小上下文及返回映射修复，详情与41项实际路径结果见REVISION-R1。图册现为87状态。未更改D08已验布局或D09已验页面；原框架／组件的五张瓶体由同一原片重新拆分，不再带邻瓶细条。评审下拉／直接URL是新样例；页面内按钮才保留当前上下文。

已完成：打开交付HTML及真实导出图；逐组检查文字／按钮／目标标签／3→4→5进度；修正初轮锁烘焙、绿纹理字母残留、教学标签、截图继承滚动、待写入仍可再请求、原图服务路径缺图问题。检查390×844、320×700、200%弹窗顶部／底部、增强对比与七瓶同尺寸。`verification.json`记录无JS页面异常、水平溢出和最终缺图检查；运行记录见QA文件。并在Codex内置浏览器点查保存Retry、每日取消替换、提示点目标与重玩／待奖励的按钮变体。

未验证：真实保存事务／强退／原实例快照／迟到奖励去重、实际求解及2秒预算、所有广告加载／展示／授权／冷却时钟与后台／连点竞态、题库参考解、原生触控命中、平台最大字号、读屏顺序／焦点循环、对比度数值、真实动效／帧率／内存。36条运行验收没有标记为通过。原型液体是静态单瓶图片，点提示目标仅显示动作接受回执；不是可玩解谜引擎。

遗留：反馈目的地（邮箱或支持链接）未提供，所以仅准备反馈，不发送；Color Studio遮罩是区域构图证据，最终透明物件分层及Garden／Seaside完整0～5资源仍待内容制作；真实App平台字体／触控及SDK由后续实现验证。本轮未接SDK、未建完整题库／后端、未发布。

## 复现截图与交付

工具脚本位于 `tools/`。`export.cjs`使用本机安装Chrome的无头页面从已保存HTML导出，不控制用户现有Chrome会话；仅用作可重复的截图／布局读取。需本机Node、Playwright、sharp及脚本中记录的依赖路径；普通审阅直接打开HTML或PNG即可，不需要这些依赖。`compile-evidence.cjs`生成流程图册。原片和导出证据均在项目内，不依赖生成缓存目录。
