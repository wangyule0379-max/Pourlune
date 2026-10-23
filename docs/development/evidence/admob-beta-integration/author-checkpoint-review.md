# ADM01 fresh author checkpoint and one fix pass

2026-10-23，一次fresh Astra/high只读审查，Critical0/Important1/Minor1。审查未执行平台CLI、设备或账号/私密签名操作。不是架构独立验收，不是完整ADM01完成。

Important已同一轮修复：外部公开registration中途变化会让beta早期metadata A与wrapper/native后读B不一致。先实际跑出三类RED：解析App ID A却hash B、构建委派时原登记改B导致包fixture B与metadata A不一致、iOS实际产物Android sample AppID仍被当iOS候选接受。随后 selection同一份bytes解析/hash；beta在新output冻结只读registration副本、从副本解析/委派/事后核hash，副本计入产物hash；iOS实际Info.plist再核AppID。原文件可变不改变本次构建选择。修复后的完整Python guard54/54 exit0，见python-guards-after-review.log。

未为此重新构建/重签build7或生成下一候选。Android最终AAB仍须按既定独立核包门槛用bundletool读实际AppID；本批实际debug sample manifest已核，后续owned登记候选未存在。没有新增解析器/工具依赖或第二轮审查。

Minor deferred: disabled模式对已提供的Dart平台/AppID/identity字段不全部核对（native sample AppID本身仍核对）；该模式不发广告，当前wrapper生成一致值。保留问题及准确表述，不为了轻微建议扩本轮fix pass。直接无定义debug仍允许官方sample默认。正式/自有收费unit不在本工作流。

Reviewer其他结论：405来源初始snapshot匹配；test exact官方units/默认disabled、现有奖励事务/SDK锁未改；已有Python51和Flutter47日志支持预修复检查；真实UMP资格不替代timeout后的展示/关闭/奖励。网站源可按已授权站点发布，版本区分与SDK数据说明方向准确，无新增采集元素，不是法律签核。

Declined-to-judge / executor rulings:
- Account/real apps/units/messages: console unavailable, retain unknown and no duplicate signup. Cost if wrong: wrong account resource; no resource creation occurred.
- Real ad load/show/close/reward: both inventory timeout, retain unverified; no substitute rewards. Cost if wrong: tester cannot verify ad loop; candidly gates final distribution readiness.
- New candidate/CI/store/phone: no corresponding artifacts/results, remain pending parent/CI/account/next-build gates. Cost if wrong: unreviewed upload; not authorized by this verdict.
- Public site deployment: reviewer only source, separate push and HTTP readback recorded afterward. Cost if wrong: stale disclosure online; require byte comparison before claiming deployed.
- Age/region/legal/rights/signatures: current factual inputs incomplete and signing material outside this checkpoint, no certifications inferred. Cost if wrong: submission/commercial readiness blocked; test-only modes and prior package gate remain.
