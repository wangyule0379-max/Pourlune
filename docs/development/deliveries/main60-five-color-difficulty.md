# 主线60关五色完整候选交付

日期：2026-10-25。状态：完整实现、自动验证与作者原生差额已完成；**父独立验收接受整套阶段Beta候选，进入新包准备；尚无新TestFlight上传**。

本批按完整60关执行。1–20逐关复核并保留原定义／版本／字节；21–60实际改为五色、
7初始瓶，改题content_version各加1。每日30题与catalog原字节保留。固定目标、容量4、
每色4单位、两个空缓冲和每实例一次额外瓶保持；未增加收费或更改倒水规则。

## 实现与来源

- 核心／schema接受2–5色，R浅玫瑰红液体＋星形；旧快照结构不变，不迁移清档。
- 7瓶4+3、8瓶4+4，交互状态、按压、选择与动画路由均覆盖第8位置；真实文字／语义保留。
- 第五色覆盖液体／针织口与底／目标垫／星形／本地化语义。正常五目标结算3+2；极短异常
  字号庆祝区可单排以保留可读性。实际图发现徽章遮中间瓶口，e9ff19d已修正并补RED/GREEN守卫。
- ads disabled一次原子加瓶保持，无广告展示或SDK获奖宣称。Firebase／AdMob均未恢复。
- 旧v1/v2/v3非空活动定义、历史、加瓶和每日槽位保留。重开仍用嵌入的旧题；首通／拼片／资格
  计数与奖励不因新题重发。

源提交：45096f0五色契约；9e35b80七／八瓶表现；7ea1b4f完整题库与证据；997d320报告行尾；
648cb63存档／Hint／原生专项及小屏修复；e9ff19d五目标徽章遮挡修复。
生产源与资源清单见`evidence/main60-five-color-difficulty/task4-source*.json`。

## 完整内容证据与难度边界

作者输入：`docs/content/design/main60-five-color-v4.json`；60行契约：
`main60-five-color-contracts-v4.json`。证据位于`docs/development/evidence/main60-five-color-difficulty/`：

- `curve.csv`：全60新旧版本、颜色瓶数、规划点、下界／合法上界／最短状态、策略对照。
- `levels/main-XXX.json`：逐关参考解全程回放、真实腾空与复用事件、关键局面、两条完整合法续路。
- `stage-dependencies.md`：21–30／31–40／41–50／51–60真实入口、释放条件和换序后的具体链条。
- `simple-strategies.jsonl`与`strategy-summary.json`：旧／新每关两策略各64固定种子，最多120次合法动作；
  win、第三次同局面循环、无合法步、预算耗尽分开，含实际动作和终态。
- `extra-space-comparisons.json`：20／30／40／50／60加瓶可立即接另一色与不加瓶换序／一步Undo对比，
  两边均有完整解；不承诺任意死局可救，也不把加瓶说成必须或保证更短。
- `fixed-buffer-limit.json`：全部40新题另有固定两缓冲用途的合法解，完整回放反例保留。

旧21–60 greedy446/2560、random400/2560；新候选59/2560、75/2560。
旧greedy也仅17.4%，但用户真实轻松到28，因此新低通关率**不能当作真人挑战通过**。
当前关键节点均可在一空口选择的两种不同顶色间换序，续路常只差1步；更深的依赖只能按
实际路线解释，不能包装成已证高难。参考复用并不证明所有解必需复用。完整曲线已由父在独立回放全60及实际无辅助操作22／33／42／59后接受为分阶段Beta候选；
不将其升级为真人首玩或每相邻关更难的证明。没有改成让用户先批准几道样题。

## 实际检查

根目录Python3.12：内容全量54项通过；90题严格release＋catalog通过；
`author_candidates.py --check`打包一致；新`author_main60_v4.py --check`只读复现通过。
安装器先核全部120目标仅为冻结旧或准确新字节，未知最后一文件也在任何写入前拒绝。

`packages/pourlune_core/`：format通过、analyze无问题、全量45项通过。真实Dart默认Hint对
全60开局／中盘及后40两条替代分支共200局面全found，max9608状态、66.426ms；
`dart-hints.json`保留局面与结果。2秒／50000预算、取消与revision门控未改，未做参考解替代。

`app/`：本轮应用定向14项通过；首次全量406通过／3失败，定位为旧四色测试动作和五目标短屏
尺寸回归，修复后相关55项通过，整合全量409项通过，analyze无问题。实际图再发现徽章遮挡后，
新增守卫先RED，修复及扩展到8瓶的完整几何／结算相关14项GREEN，focused analyze无问题。
无需为同一微小差额反复重跑所有平台。

原生：使用正常main/Bootstrap、真实Flutter／sqflite、自动指针、正式60+30资源；1–59进度
为明确QA准备，21／60按已看参考路线并用过Hint操作，不是盲玩或人工通完60关。
第一轮正常402×874与新建小屏375×667均通过；正常五目标徽章修复后normal-2复验通过，实际图片已查看，瓶口无遮挡。
旧四色活动从新五色库启动后保留原字节；7→8、第8瓶、同／跨排倒水、Undo、Restart、
Hint、5目标完成、60关首通15拼片以及无广告记录均由实际专项断言。

## 专用设备与尚待完成

正常QA：63B0908A-15C4-4CE1-A1AC-7E8DD958A645；新小屏：A4A83180-67E1-48B4-9BE8-D8DFFC387DFB。
独立身份`dev.pourlune.parentNormalValidation`，新命名库`main60_five_color.sqlite`。
旧专用QA Documents已备份到ignored build，普通入口安装后已按哈希恢复5个保护文件，未覆盖新QA库。
F9／Small11b／4188／历史Large／普通与Firebase库和冻结发布包未作为本轮操作目标。

普通`lib/main.dart`已在两台设备完成同安装SIGKILL／launch：容器、Runner、kernel保持一致，
活动快照、2条本地权益、61条收据不变，完整性ok；重新点击Continue后实际渲染八瓶已确认。
证明见`native/normal-main-process-restore.json`与`normal-main*-restored.png`。正常入口Runner SHA256
`983c210a0e51be890e68838bbd96dda6fc1efdfa1b9c67adba745efe897753bf`，kernel
`3d11c8b1ce6299cf527b92ed6b336296aa4b4cce26bca86ec0aa83c42a73ccd9`。

父结论见[独立验收报告](../review/main60-five-color-difficulty.md)：22／33／42／59分别20／22／22／23步，
不用Hint／加瓶／Undo；四次重玩无拼片／权益重复，正常和小屏未见新阻断问题。
还需：新精确CI、签名候选独立核包、上传与商店处理。未在实体手机首玩、未新签名／上传／商店处理。TestFlight12／Play13既有包未覆盖。
本轮父已接受整套阶段Beta候选，现准备0.5.0+14签名新包；包与发布门槛仍须逐项完成。
