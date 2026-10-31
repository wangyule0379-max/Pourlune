# Build18 上传传输故障（未交付）

2026-10-28 Taipei。已验 Organizer IPA SHA256 `49dd07b913d2b4cfe9701ffc8280c5d0e24dcfd0971ca8276c190824fb4ce115` 内容及签名通过，但首次 Upload 未成功。

Computer 实际看到 Sending analysis to App Store Connect，ASC 当前最新仍 17。父仅读 ContentDelivery.log 的脱敏错误片段，发现最早传输错误为 16:26:55 `NSURLErrorDomain -1202` / CFNetwork `-9843`：请求 `northamerica-1.object-storage.apple.com`，却收到主体 `courier.sandbox.push.apple.com` 的证书。随后 asset-description（1666016 字节）第 1 段反复显示 Checksums do not match；父读取时有 379 条。证书主机不匹配属实，但不能据此断言后续 checksum 的全部根因，更不能称 App 代码或 IPA 已坏。

已让 Computer 取消本次持续失败的传输，保留原件及上传记录，确认无成功回执后排查网络/官方传输路径；不关 TLS 校验、不信任错误证书、不改 App、不加版本、不并行重复上传。原始日志含会话 Cookie 和签名 URL，留在原私密临时路径，不复制到报告或公开仓库。

来源：临时 Runner_2026-10-28_16-22-42.790.xcdistributionlogs/ContentDelivery.log。正式状态仍为未上传；CI、运行联调和候选验收继续有效。


## 新会话结果

Computer 随后确认可信浏览器 TLS、ASC 无 18，未修改网络配置；对同一 archive 新建一次官方 Organizer 会话。父验第二变体 `6e39f3ad4073d70cb0c3f076e03655125d01a4cfffa378185b2ab456df51c034` / 86731625 字节：269 文件无增删，差异仍仅签名区，deep strict codesign 0。随后 Computer 回报 18 上传并处理完成，ASC ID `6956eb73-ec07-4ff7-a449-76867836c112`。待最终截图/原 Self 组回读后再认定可测试。

新会话成功支持失败与旧传输状态有关，但无法单凭此断言最初证书错配的全部网络根因；未改 App、版本或 TLS 策略。

加密问项沿用既有已确认事实：实际 Flutter 二进制含 third_party/boringssl 源路径、TLSv1.2/TLS13 实现标识，GM 使用 package:http 的标准 HTTPS；选择操作系统外标准加密，而非无加密/专有算法。本次仅原 Self 内部 TestFlight，未在法国公开 App Store 分发。Info.plist 未设置免重复问项键，保留原包，不为这次发布另建版本。依据 Apple 官方出口加密文档与既有 audio-admob-testflight-20261026 交付。
