# 首次上传传输异常（进行中，不代表18分发成功）

2026-10-28。总控与Computer实际定位：Xcode提交asset-description（1,666,016字节）第1段出现379次checksum mismatch，取消无界重试；未见IPA上传成功，ASC仍无18。更早日志有NSURLErrorDomain -1202/CFNetwork -9843，northamerica-1.object-storage.apple.com请求收到了courier.sandbox.push.apple.com证书。此证据指向TLS端点/路由异常，不能推断已验IPA内容损坏或重造App/升19。总控/Computer独占实际网络和GUI，开发仅读脱敏诊断，未并行上传。

[Apple Transporter官方指南](https://help.apple.com/itc/transporteruserguide/en.lproj/static.html)明确上传主机northamerica-1.object-storage.apple.com使用HTTPS443并支持IPA与恢复；表列地址仅交叉核验，不用作强制DNS映射。[Apple企业网络说明](https://support.apple.com/en-us/101555)指出HTTPS interception会使Apple服务失败。保持TLS校验与已验包，先由Computer核现有路由/解析与可信证书。

[Apple-Actions上游README](https://github.com/Apple-Actions/upload-testflight-build#readme)记录altool断连后可出现无限Checksums do not match，并通过放弃旧未完成上传/清理失败resume状态重新开始处理。它仅支持恢复会话死循环这一可能机制，不证明本次Xcode的确切checksum根因。可信连接恢复后，仅由Computer对同18同IPA采用一次新的官方GUI会话/受支持路径；不复用签名URL、删真实已处理构建、创建新凭据、关闭TLS校验或新开并行上传。

原ContentDelivery日志含cookie/签名URL，保持原地受限，不复制原文进Git/聊天。本文只含脱敏事实与公开官方资料。此为失败历史，后续终态另记。
