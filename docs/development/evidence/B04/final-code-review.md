# B04 fresh code review and one fix pass

2026-10-22。唯一一次新上下文整批只读审查：gpt-6-astra/high，`b04_final_review`；不是架构独立验收，也未创建提交或推送。审查包含 HEAD1b6b477 后的 tracked diff 与 untracked B04 源码；既有 tracking 变更排除。审查者仅在临时副本复现，没有修改项目工作区、索引或分支。原始结论为 With fixes：0 Critical、4 Important、1 Minor。

|发现|根因与本轮处理|验证|
|---|---|---|
|Important：前台返回／有效远程更新后库存不恢复|更新使旧加载代号失效并清空库存，却没有预加载缺失库存；在安全更新后集中补充，仅 load，不 show|`review-three-red.log` 第一项；`review-fixes-green.log`，前台＋远程关闭／恢复边界|
|Important：Reset 残留旧奖励提示与门禁|DB 已清，Controller pending/确认/关闭/失败提示未清；成功重置后同步清除 B04 内存态，旧回调仍由未知 attempt 拒绝|`review-three-red.log` 第三项；controller Reset 与既有 store unknown-after-reset 测试|
|Important：教学完成事件永不发送|在 current 已替换后才判断旧教学 active，且错误等待整局完成；改为变更前捕获 completed/skipped 转换，在实际存档后消费，保存失败 Retry 保留|`review-three-red.log` 第二项；前三步完成但整局未赢／保存失败 Retry／不重复／skip 分开|
|Important：广告后继续率缺数据|增加 session-only `pl_ad_continue`，仅已实际展示并关闭的 request 开窗，120秒累计前台内第一次合法倒液计一次；退出无继续事件，非法动作不计、后台不耗时、撤回清窗|`ad-continuation-red.log`、`continuation-window-api-red.log`；控制器实际合法/非法 pour＋120/121秒、后台、重复关闭与去重|
|原 Minor，执行方重评 Important：提示取消遗漏／重启身份碰撞|这会系统性漏计真实提示请求与取消结果，影响最低诊断数据而非单纯润色；本轮一并改为每请求随机身份，结果和主动取消共享一次性消费|`hint-events-red.log`；同一存档 Controller 重建后两次取消各计一次，重复 Cancel 不重复|

上述 RED 均在实现相应修复前实际运行；首三项的独立复现复制到 `app/test/b04_review_regressions_test.dart`，另加本轮覆盖。`review-fixes-green.log` 为8项通过；整套最终结果见 `flutter-tests-completion.log`，不是由另一轮审查替代测试。未派发二次审查。

## 审查明确暂不判定项与执行裁定

- 真实广告展示与 SDK 获奖：初始10/30秒及修复后30秒官方测试库存等待均超时，无显示或权益记录；保留未验证，不能以替身或设置 seed 通过。代价：真实奖励 SDK 顺序、关闭、音频/系统中断仍须可用网络库存＋设备验证。
- mediation 关闭后迟到奖励：未配置 mediation。Controller/SQLite 接受已经送达的原请求迟到回调；插件 dispose 后移除原生路由，无法承诺回查历史或恢复未收到回调。代价：未来加入适配器必须重新验证回调与生命周期。
- Firebase 控制台、符号、真实撤回网络效果：无已交接项目，保持 native-ready=false/disabled；替身只证应用门禁。代价：正式接入仍需要项目、原生配置、收件与网络验证。
- 正式身份、域名/邮箱、商用权属、ATT/地区政策和真机体验：不自行创建身份、代签、发布或宣称认证；当前不请求 IDFA/跟踪。代价：发布仍被交接与独立验收阻塞。
- D1/D7 队列及 Asia/Taipei 控制台报表：项目缺失，未配置或宣称报表通过；已有匿名业务活动事件只提供实现基础。代价：项目就绪后必须核对实际分析口径。

本轮无以“Minor”标签留下的代码修复项；外部待验证项仍真实保留，不自行标记整个 B04 验收通过。

## 后续独立验收与修复轮

架构第一轮仍发现B04-R01/P1与R02/P2并退回，不能以本文件的作者整批审查代替独立验收。最新修复及新增RED→GREEN、schema5持久边界、原生证据在 `../B04-R01-R02/repair-report.md`；独立review/tracking未由执行方改写。
