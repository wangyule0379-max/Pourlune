# AdMob 恢复接入独立复核 — 2026-10-26

当前结论：激励测试广告真实展示、回到 main004 后新增一个空瓶及对应一次落盘权益，有限接受；整项 AdMob 商业就绪尚未完成。

父实际看 rewarded-test-visible.png（Test mode、奖励已发放）、reward-return-five-bottles.png（Level4、5瓶、加瓶入口禁用），以及 iOS/Android 各两个激励/插屏广告单元控制台图。配置 registration.json 两 App ID 与 console-registration.json 相同；源码 admob_config.selection 只替换 App ID，官方 sample unit 保持，ServiceConfig test 同样固定官方 sample ID。

父以 mode=ro&immutable=1 读取作者 reward-sdk.sqlite 备份：integrity ok；reward_attempts 仅一条 done/confirmed1，instance dev-1793019635488753-1229746559、attempt dev-1793019696750194-194901328；仅一条同实例 entitlement 和 rewarded show。活动实例为 main004、五瓶/extra true/revision1/0步，和截图、摘要一致。不是父亲自操作或全链路录像重放；原生重复回调及未奖励关闭不在本批实际采集中。

双平台广告单元登记图通过回读，账号审核、商店关联、隐私消息/app-ads.txt 未因此通过。cn-pair-exception-run.json 已记录13:10UTC恢复且持久配置不变，此为作者恢复回执，父未修改网络。插屏仍待当前实际交付；后续无需重做本批激励。

源证据和只读快照核验见 evidence/admob-resume-20261026/parent-reward-independent.json。F9/D79及其他模拟器父均未操作；工具链仍归开发。音频接入另按用户选定 Dream Culture / Pouring Water 继续。

## 插屏最终差额

开发提交 d06ffb3。父实际看 interstitial-test-visible.png（官方Test mode插屏）与 interstitial-return-level22.png（关闭后进入22），并以只读immutable核 interstitial-sdk.sqlite：integrity ok，1 interstitial show及同show_id的fullscreen_attempt，qualifying_boundary11；total11/consumed11/remaining0，active22/0步和next实例一致。既有milestone工程种子（main001别名）来源已明确，不等于正式关卡20/21难度或自然首通21关。此次实际插屏展示/关闭/既定资格消费有限接受，20跳过路径为作者操作记录，父未全片重放。

激励与插屏测试接入通过，不代表账号/商店关联、隐私消息、app-ads.txt或真实收费投放就绪。没有新商店上传。
