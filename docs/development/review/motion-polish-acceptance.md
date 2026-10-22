# M01–M08 收尾独立验收：第一轮

**最新裁定（2026-10-22，MS-R01复验后）**：下列首轮RED完整保留。MS-R01已定位为新增测试的宿主/虚拟时钟边界错误；最小修复后独立4/4、analyze与格式检查通过，已关闭。本次接受MS01有界计时/真实手势证据、MS02修复后的行为测试与MS03能力限制记录，可继续作为封测准备依据；实际音画、真机性能/触觉、真实读屏以及全App等条件A/B仍未验，不能将M原计划全部条目无条件标完成。

2026-10-22（Asia/Taipei）。用户已接受当前效果，本轮按既定 MS01–MS03 补证及封测准备范围检查，没有继续扩大动效打磨。**M 收尾尚未全部通过：新增 MS02 键盘测试独立复跑 0/4，MS-R01/P2 待定位修复。** 未发现足以从该失败直接确定生产产品缺陷的证据。BR01 的其他工程准备继续。

## 本轮实际检查

- 读取 `deliveries/motion-polish.md`、`motion-polish-supplement.md`、两份新增 Dart QA/test 和构建/运行脚本、原始样本/命令/失败日志。继承已独立验收 T/FB 范围，不重跑整套。
- `motion-polish-supplement-evidence/independent-source-check.json`：冻结 a19f2ed 的188生产源码/资源逐文件核对无差异；两份新增文件和两锁文件哈希匹配；iOS候选全树与Android APK哈希匹配。
- 在作者明确释放 CLI 后，于 `build/motion-supplement-source/app` 用固定 Flutter 执行 `flutter test --no-pub test/motion_supplement_keyboard_test.dart`，环境 `FIREBASE_ANALYTICS_WITHOUT_ADID=1`。**四项全部失败**，完整输出保留于 `motion-polish-supplement-evidence/keyboard-independent.log`；测试文件与交付 freeze 哈希相同。没有重复跑到绿，也没有修改等待时间。
- 独立 `recheck.py` 在已安装MS专属 iOS255890 / Android5588 各做一次冷启：真实正常 main/Bootstrap→Flutter指针→控制器→native SQLite；没有重建、重装、录屏、截图或录音。两端均只有一次手势、一个实例、一次快照，动作0/revision0且已存实例匹配；PID、安装身份/包哈希和原FB库保留检查通过。新QA库在测量后由其入口重置以备下次，非普通数据恢复测试。
- 原生结果：iOS壳首帧268.410ms、Home帧654.264ms、enabled/hitTestable669.719ms、响应719.226ms、落盘导航1103.093ms；Android分别384.471、1395.687、1423.442、1498.983、1881.910ms。均为同一Dart时钟、debug、每端N=1独立复验；作者各N=3另存原交付。**不是native首像素、可见首页时延、最早交互或代表真机性能**。点击前祖先Fade含0.0，证明接受输入不能证明页面已完全可见；采样/注入开销未单独计量。没有与旧M不等价端点计算提升比例。
- MS03能力核查报告明确无合法可用音轨/同步观察证据。该限制记录接受，实际声音/音画/物理触觉仍未验证；未重试或绕过既有Cocoa513/EPERM限制。

本轮独立证据目录：`docs/development/review/motion-polish-supplement-evidence/`。作者证据和独立运行严格区分。用户F9及其窗口完全未操作；没有全局设备操作。复验结束已明确把CLI及MS专属设备窗口交还原开发继续BR01，无在途命令。

## 按 M 与适用 AC 裁定

|项目 / AC|继承与本轮依据|当前结论|
|---|---|---|
|M01 / AC31、34|已验T/FB统一有限参数；原M before与当前版本/入口不可直接等条件比较|实现范围可继承；不补称全App同条件性能提升|
|M02 / AC34|T-R01原生连续背景、重试与资源检查；本轮双端真实手势和一次native落盘及端点核对|可用运行与有界计时方法通过；未承诺可见首帧/真机性能|
|M03 / AC31、32|已有触控/语义/焦点/禁用证据可继承；本轮Enter/Space测试4项到动作完成边界均失败|MS-R01/P2不通过；焦点转移请求没有直接断言实际primaryFocus变化仍为Minor，不伪称该覆盖完整|
|M04 / AC04、22、24、31、32|T双端11页/102步及FB双端43步组合，活动页输入隔离、保存门控与滚动恢复|继承原范围通过，保留T-M01色阶P3|
|M05 / AC11、24、31、32|真实DialogRoute/单模态与暂停重开、保存失败Retry原证据|继承原范围通过；保存错误面板并非模态，不补称全部SDK弹窗实测|
|M06 / AC01、02、05–08、31、33|FB完整倒水/守恒/数字/七瓶及中断恢复已验，用户接受效果|功能表现继承通过；真实音画/触觉保留外部待验|
|M07 / AC09–12、15、16、28、32、33|已验实际回执→成功/SceneArt显现→观看确认落盘→Next；独立Flame拼片样板范围单列|继承原范围通过；无全场景Flame飞行迁移，真实音画与广告不在本次通过范围|
|M08 / AC31、34|T/FB精确源码/包/有限运行视觉证据，本轮补真实输入端点|按实际覆盖继承；真机profile、读屏、全AppA/B及实际音画未验，不自动关闭所有原M要求|

## MS-R01 / P2：新增键盘测试未能独立复现通过

触发：在冻结副本运行交付的 `motion_supplement_keyboard_test.dart`，iOS/Android × Enter/Space 共4项。全部在测试第150行调用 `settleFlameBoard`，由 `test/support/flame_board_ready.dart:46` 报 `Flame art/action did not reach the actual ready boundary`。键盘触发后前序断言没有报错；不能把尚未执行到的最终实例/快照/落稳断言算通过。

作者工作区日志4/4通过与冻结副本0/4存在差异，当前不能归因于负载、固定等待不足或生产故障。已将精确路径/命令/源码哈希/日志交原开发：先比较实际测试依赖、资源加载、动画回调与时钟状态，保留RED，定位后最小修复。禁止加长sleep、跳过或削弱once/busy/持久化/动作完成断言求绿；修复交付后架构复验。独立冻结样本保留不覆盖。

本轮仅保存架构报告、独立证据和跟踪状态。新增MS代码/作者交付及BR01在途实现尚未合并本次提交，不宣称可封测或完成商店准备。

## MS-R01 最小修复复验与提交边界

已读取作者原始诊断：真实SQLite已clean、Flame art ready、未暂停且有调度帧；宿主2971ms内仅pump31次16ms，动作几何进度从18.927ms持续前进到586.732ms。原helper使用宿主3秒作为期限，尚未推进足够虚拟表现时间即退出。该证据与首轮四项在同一完成边界失败相符；作者旧通过记录保留，不能保证其可重现性。

修复只在新键盘测试中将等待换为 `pumpAndSettle(16ms, sendSemanticsUpdate, 3s)`，依然由真实Flame ticker和回调结束，随后新增 `motion == null` 与 `busy == false`。实例/步数/revision/history/快照次数/SQLite完整相等断言均保留；没有手动completeMotion、加sleep、改生产行为或放宽超时数值。实际焦点转移仅发request没有直接断言的Minor仍保留。

架构在明确CLI窗口中，于新冻结 `build/motion-supplement-r01-source/app` 独立运行四项测试，12秒全过；`flutter analyze --no-pub`无问题，两个新增文件`dart format --output=none --set-exit-if-changed`零变化。`r01-source-check.json`记录244冻结生产/资源/测试依赖与旧冻结逐字节一致，新测试SHA256为 `1914ae65942b30e7cb84f5b6a8ee8c9c4e05fdc94f6423d949d427849576bcae`；原生QA入口未变，因此不重做MS01原生测试。对应日志在本独立证据目录，首轮RED未被覆盖。

MS-R01/P2关闭，M03键盘一次激活/禁用/持久化去重按上述范围通过。准予精确提交两份新增QA/test、已审阅MS执行证据及交付、本独立报告与tracking。新MS不是生产功能改造；BR01在途原生身份/签名/服务/构建/CI等文件、临时根目录诊断test及旧M未验大录像不夹带。本次代码提交后核对精确远端CI，纯跟踪文档不额外要求CI。CLI已明确归还原开发，无在途复验；用户F9和设备均未操作。

## 远端提交记录

已验MS专属范围已提交并推送 `78feb805d540a28addf12e457b8d34e48a720482`。精确SHA的GitHub Actions查询暂未返回run，记录于 `motion-polish-supplement-evidence/remote-ci-pending.json`；远端CI尚未确认通过，下次按该SHA继续发现并核对。BR01实现未夹带，继续由原开发推进。
