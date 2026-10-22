# B05 fresh 作者侧代码审查

2026-10-22；执行计划要求的一次全新上下文只读审查，gpt-6-astra/high。不是架构独立验收，不修改review目录。范围为相对ba78a62的B05未提交生产UI、测试、QA入口、生命周期工具与报告；不把已验B04整体重新审计。审查期间最终验证明确为pending。

审查结果：0 Critical、1 Important、1 Minor。生产对话框改动范围小、保留原奖励归属/事务/导航；host165/core30/Python27/assets23/90题证据已核对；QA身份/PID/库隔离合理；初轮L记录11次SIGKILL均作用于QA应用。

**Important P2：揭示中断覆盖不足。** 原QA在viewPatch之后立刻发布barrier，没有等实际帧或确认SceneArt tween处于进行中；Python把reveal与普通after等同，没检查未确认揭示、重进收藏、确认后不重复。即使尚未动画也可能通过。要求仅QA同步实际渲染，并补重启后呈现/确认/再访不重播/不重复权益断言；或收窄AC12声明。不是发现生产揭示事务有缺陷。

**Minor P3：widget固定20/40ms等SQLite易受时序影响。** b05_accessibility_test的隐私与恢复检查在real async zone用短延时等待；pumpAndSettle不保证FFI完成。建议以后换按预期持久选择/实例的有界等待。当前多轮精准与全量运行通过；按executing-plans对Minor的规则记录后续，不在本次Important修复轮扩大修改。

审查主动保留的范围（Declined to judge）：

1. 真实AdMob/Firebase、发布主体/支持/商业权属：既有外部依赖，受控回调不能证明。
2. 真机性能、Android运行、实际读屏/物理音频：没有对应设备。
3. 架构独立验收：作者侧代码审查无权替代。
4. 已验B04整体：只读取相关调用，未另开审计。
5. 最终执行当时pending：如实声明的执行状态，不额外视为代码缺陷。

作者裁定：1/2继续作为发布门槛，代价是这些条件满足前不能发布；3由架构复验，4不重开已关闭范围，5完成最终运行后冻结报告。没有把这些项默默丢弃，也没有为消除缺口伪造项目/库存/设备结果。P2接受，在一次修复轮中补有效RED→GREEN与本批双槽L全流程；不派发第二个reviewer或重复审查。最终关闭证据附后。

## 首次逻辑链验证（未作为最终像素通过）

旧QA二进制上新增活动揭示断言实际RED，reveal-red.log明确拒绝没有rendered opacity证据的page-intent barrier。QA-only修复遍历实际SceneArt/目标物件Opacity，等待帧、观察进行值并复制中间PNG，再采样并及时SIGKILL。恢复后重新进入揭示→观察活动值→确认→收藏场景无reveal Tween→再次SIGKILL/cold launch→仍已确认且不重播/不重复权益。lifecycle-render-first.log完整矩阵退出0、B05_LIFECYCLE_PASS；实际12次SIGKILL、普通/每日双槽精确保存，揭示barrier opacity=0.4697306203842163。lifecycle-render-first/reveal-interrupted.png、reveal-restored-presentation.json/png、reveal-acknowledged-no-repeat.json/png和lifecycle.json留存。该轮逻辑链完成，但首次中断PNG早于图片解码，不能当作已显示拼片的截图。QA补充实际SceneArt图片预解码并重新进入揭示，最终全矩阵复跑后再冻结P2关闭证据。生产揭示代码未改，P3仍为轻微工具维护项，没有派发复审。

## 最终像素与全矩阵冻结

最终QA明确先对实际SceneArt的4个ResizeImage provider解码（base＋3个已拥有物件），不写揭示确认，再重新进入动画；这属于QA起点，不能当作冷素材加载性能。lifecycle-final.log退出0，完整矩阵B05_LIFECYCLE_PASS，实际12次SIGKILL，场景资源已解码、揭示采样opacity=0.5364295049756765，中间PNG实际包含场景像素；恢复/确认/再冷启动不重播与两槽不变均断言通过。原首次解码不足的PNG留于lifecycle-render-first，不用它代替最终像素证据。Important P2关闭（作者修复验证，非第二次审查）；唯一Minor固定20/40ms等待留在维护台账。
