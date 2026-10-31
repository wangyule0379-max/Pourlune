# GameMunchies 接入与 TestFlight18 最终验收

2026-10-28 Asia/Taipei：0.5.0 (18) 已实际上传、完成处理并加入原 Pourlune Self 内部测试组。父亲自看过 Xcode 上传成功与组内“正在测试 / 90 天后过期”两张真实回执；原组仍 2 人，未新邀、未公开 App Store 发布。用户物理手机安装及该手机的首笔正式统计尚未观察。

## 交付版本

- 实现及签名候选源 `ea2bdee853559ddaa66e44e35fce7bac34a40d29`，包含已验统计、广告控制、API 域名与隐私文案。
- 最终 CI head `a8e6be9323d97855de25bcfbcabc0e88337cf415`，run `40653590242` 两 job 终态成功；与签名候选唯一构建清单差额为 workflow 中固定 SDK 恢复顺序。实际 App/SDK/锁/构建工具未变，来源桥接已独立核。
- 实际成功上传 Organizer IPA：86731625 字节，SHA256 `6e39f3ad4073d70cb0c3f076e03655125d01a4cfffa378185b2ab456df51c034`。父核 269 文件与原候选仅签名区不同，签名严格验证成功；保持 com.pourlune.app / 18 / 既有 profile / 原生无测试插件。
- ASC build ID `6956eb73-ec07-4ff7-a449-76867836c112`，Xcode 实际成功时间约 16:43；原 Self 组 5 个构建中的 18 显示正在测试。外部测试列“准备提交”不代表内部组不能测试。

## 本次接入与验证

客户端统一使用 `https://api.gamemunchies.com`，末尾无 /api。正式 gameId `8feaf0dc-ec12-4308-ac58-16b2180f2d63` / iOS / production；SDK `gamemunchies_client 0.1.0` 固定源 `92f588200a1d80b1d0023122fcfc3037db87c53c`，不为域名更换另写或升级 SDK。管理员凭据不进入客户端。API/default/test/build 配置及来源详见地址独立报告和开发最终交付。

独立测试游戏的真实配置读取、生命周期活跃、新局、断网缓存、同安装重启补传与原事件 ID/首次时间去重均有实际 ACK/后端记录。iOS 重试 0/3；Android 重试批含一个新生命周期事件为 1/3，两个原事件已去重，不能写成 Android 纯零接收。旧地址 QA 状态保留、未迁移重播；已分发 17 无 GM 状态。

iOS 正常 main 的官方测试广告实际展示、奖励确认与同实例额外瓶持久去重已核，后端展示计数 1→2；奖励合法发放不依赖统计成功。远程总开关、场景开关和恢复配置实际生效。广告仍为官方测试广告，未开启收费投放。Android 真实广告展示和物理手机验收未覆盖，不能借 iOS 结果标通过。

客户端统计默认关闭。用户更新到 18 后，在 App 设置开启 Share gameplay analytics；正常游玩后在 GameMunchies 的 Pourlune → 正式统计 → iOS 查看正式数据。广告规则读取独立于统计选择。测试游戏已有数据不等于用户手机已产生正式数据。

## 上传故障与处理

首次 Xcode 会话遇 Apple object-storage 主机证书错配，后续 asset-description checksum 无限重试，已取消。未改 App/版本/网络设置/TLS 信任；新官方会话重试成功。父只读脱敏日志，原含 Cookie/签名 URL 日志未复制入仓库。详 `gamemunchies-build18-upload-transport.md`。不再重复上传或查询已完成 CI。

## 操作事件

用户明确允许私有 SDK 归档仅供 GitHub Actions 构建。配置时 Computer 的 AX 工具记录意外回显了 SDK 源码归档值；这是代码归档，不是登录令牌/密码。父未读取或复制该载荷，当前没有公开仓库发布证据。此失误保留记录，不声称已删除工具历史或以重传同一源码冒充撤回泄露。

## 实际回执

- `evidence/prelaunch-closeout-20261028/gm-build18-upload/xcode-upload-complete.png`，SHA256 `ab3fe94544a2b9f270cf171943e24850cc770a9918973b0d1ca1fe14fa424985`。
- `evidence/prelaunch-closeout-20261028/gm-build18-upload/self-group-build18.png`，SHA256 `fa4a2081504268213a74c89ba3981b87cff82951c7b10541bccae060632a2076`。
- 独立报告：`gamemunchies-api-domain-20261028.md`、`gamemunchies-normal-privacy-reward-20261028.md`、`gamemunchies-build18-package-independent.md`、`gamemunchies-build18-ci-bridge-independent.md`、`gamemunchies-build18-organizer-retry-independent.json`。

后续仅处理实际新反馈；不为了小细节重建发布、不重复已验矩阵。F9 及既有设备存档保护保持。
