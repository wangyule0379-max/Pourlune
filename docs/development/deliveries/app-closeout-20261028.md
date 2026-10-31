# Pourlune 统一收尾 — 2026-10-28

用户授权总控处理剩余问题，不逐项提醒。当前已完成下列代码、公开资料和签名包差额；GameMunchies 双端实际验证仍在进行。没有上传新商店版本、启用商业广告或改动受保护设备。

## 已完成

### 公开支持与隐私说明

修正两个页面中“所有广告关闭”等过时表述，区分已分发 iOS 0.5.0(16) 官方测试广告、Android 0.5.0(13) 关闭广告，以及尚未进入商店包的 GameMunchies 独立测试。按实际事件字段、同意门控、离线队列、保留与关闭行为披露，不声称测试广告不处理数据，也不声称关闭统计会删除既有队列或服务端记录。

Use Computer 已发布到既有支持仓库；父另行 HTTPS GET 两页，均 200 且与本地字节相同。发布提交和 SHA 见 `../evidence/prelaunch-closeout-20261028/support-site-published.md`、`support-site-independent.json`。未改域名、身份或 app-ads.txt。

### iOS 隐私清单

按 Apple TN3181，构建阶段只移除已核验的 14 个无代码资源 bundle 中空的 `NSPrivacyAccessedAPITypes` 键。保留所有有效 API 原因和其他声明；未知 bundle、框架、已签名资源或带代码资源拒绝自动修复。先检查全部输入，再写入；旧冻结 IPA 和 SDK 缓存不动。

新增手动 archive 签名前构建阶段，并在 archive 与最终 IPA 分别执行只读检查。11 项 iOS 聚焦测试、31 项 Firebase 构建配置测试、12 项 beta 工具测试通过，Xcode 工程 plist 检查通过。

实际本地签名 archive/export：`build/package-review/0.5.0-16/ios-privacy-closeout-1`。25 个清单中，14 个只删除空键、10 个已有有效清单保持、1 个为新依赖的有效清单。archive/IPA 都通过 deep/strict 签名检查，正式身份准确，无 integration_test 类/通道；530 个冻结输入在该次核验时一致。IPA SHA-256：`52b7cd06cace24053e245dfaa2c38ef8d0b099c8fbdf185f577188084d799ee6`。

**这是本地验证包，版本 16 已被占用，禁止上传此候选。** 其中 GM 未配置启用；它也早于后续隐私竞态修复，不能冒充最终 GM 发布源。实际包证据见 `../evidence/prelaunch-closeout-20261028/privacy-package-independent.json`。

### 素材权属记录纠正

找到 10 月 23 日已有用户确认：五张原稿由 ChatGPT 生成；相关派生资源能回溯到原稿、生成会话或既有制作记录。因此撤销前次“一律缺商业权属确认”的阻断，不重复索取不存在的授权证书。42 张实际 PNG 来源和 8 个引用副本哈希已记录；没有据此保证不存在任何第三方权利。详 `../review/asset-rights-reconciliation-20261028.md`。

### GM 统计开关竞态

父审发现快速开启后关闭统计时，旧保存完成回调仍可能重新开启客户端。开发用实际 SQLite 写入、只延迟完成回执的 4 个用例复现，旧实现 3 失败。新增选择代次守卫后，仅最新保存结果能修改失败状态及统计开关；dispose 使旧回续失效。35 项相关测试和分析通过。父已读实现、RED/GREEN 和用例，接受此定向修复；新双端 QA 包另冻结，旧原生证据不冒充该修复的运行证据。

## 仍在完成或依赖外部条件

- GM：iOS 已实际核对 active/new round 到达及恢复/重开不额外计局；断网补传、去重、Android 运行和真实广告 impression 尚未全部完成。由原开发和 Use Computer 继续，最终结果另见 GM 交付；不伪造事件或把 No ad available 当展示成功。
- ASC：本轮后台已退出到 Apple 登录，正式发布资料尚不能回读，需持有人恢复登录。
- Play：封测已发布，但后台当前 0 人实际 opt-in，12 人持续 14 天的正式申请条件未满足；不擅自邀请陌生人。现有无广告声明对应已分发 Android 13，未来行为变更后再核对新声明。
- AdMob：账号仍验证中、双端待审核/商店关联，隐私消息详情未能载入，不能称商业投放就绪。
- 真人首次游玩难度、实际手机听感/性能仍未获人类验证；此前算法、生命周期测试和模拟器结果不替代这些体验判断。

平台只读事实见 `../evidence/prelaunch-closeout-20261028/platform-blockers.md`。先做完内部工作，再集中告知确需本人参与的事项；不因此重复全页 UI、特殊字号或微小纹理审计。

## 官方依据

- [Apple TN3181](https://developer.apple.com/documentation/technotes/tn3181-debugging-invalid-privacy-manifest)：空 API 数组应移除键。
- [OpenAI Terms of Use](https://openai.com/policies/terms-of-use/)：输出权利安排不免除输入权限和第三方权利责任。

当前交付只说明这些具体修复和验证结果，不宣称“所有 App 问题已全部解决”或“已获公开发行批准”。
