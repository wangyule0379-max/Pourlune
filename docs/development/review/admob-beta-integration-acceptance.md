# ADM01 独立验收：测试广告工程通过，账号及实际广告闭环未完成

2026-10-23。本次接受显式测试广告工程与已核实披露差额，可精准提交并推进新精确 CI。ADM01 整体、账号登记、实际 SDK 展示/关闭/获奖及手机联测仍未通过。未制作或上传新的广告候选。

## 已实际检查

- 读取当前交付、405 文件来源清单、登记冻结修复及原生探针；405 个来源哈希均匹配当前工作树。
- 实际独立运行 `.venv/bin/python -m unittest discover -s tools/validation -v`：54/54、exit0；运行前后 Python/原生 shell 检查源码未变。包含登记解析/hash同源、候选冻结登记、iOS错误AppID拒绝、调用参数门控；替身构建不等实际候选签名。
- 读取 Dart test-unit 精确平台匹配、双 wrapper、双原生入口、登记选择及其测试。默认 wrapper disabled；显式 test 只选官方测试 unit，未扩展收费广告路径或奖励业务。
- 直接 HTTPS 读取帮助与隐私页，两页 HTTP200，逐字节匹配本地已审稿。披露区分 build7 广告关闭、后续显式测试广告及 SDK 数据处理，未添加表单或采集脚本。这是技术内容核对，不是法律签核。
- 核对 Google 当前官方测试广告与双端数据披露资料：[测试广告](https://developers.google.com/admob/flutter/test-ads)、[iOS 数据披露](https://developers.google.com/admob/ios/privacy/data-disclosure)、[Android 数据披露](https://developers.google.com/admob/android/privacy/play-data-disclosure)。样例 unit 不关联自己的广告账号；测试模式不等于 SDK 零数据处理。

独立证据：`admob-beta-integration-evidence/python-independent.json`、`python-independent.log`、`site-independent.json`。

## 保留状态与下一步

- 作者 iOS 真实探针：UMP allowed；插屏、激励均 unavailable/timeout。该 JSON 已独立读取，但未独立重跑；exit0 和本地动作落盘不能证明广告加载、展示、关闭或奖励到账。Android 只有原生编译/manifest 证据，未运行。
- AdMob 后台连接关闭，真实账号、publisher、自己的 AppID/unit 与消息配置未知。不重复失败连接、不改变 TLS/代理，不从样例 AppID 推断登记完成。
- 登记时序修复已读并独立运行回归；下一真实候选仍须检查实际双端 AppID、来源、资源、签名和符号。旧 build7 验收不能覆盖它。
- disabled 模式未逐一核对显式 Dart身份字段为已有 Minor，仍校验 native sample AppID；当前 wrapper一致且该模式无广告请求，不扩大为本轮阻断修复。
- 原开发最终明确 CLI RELEASED 后，父独立运行交付列出的9个 Flutter 文件：47/47 exit0；flutter analyze 无问题；3个改动 Dart 文件 format 无变化。前后405来源无漂移。对应日志及 `independent-final.json` 已保存；没有重跑 LY/FB 全套。
- 后续：仅此已验工程提交并核新 CI；成功后可在新目录准备安全测试模式候选，真实账号配置与运行闭环继续分开核验。账号/网络诊断由原开发根据其直接收到的用户授权推进，未授权的代理/安全策略变更不由本次工程验收放行。

本轮使用已明确释放的短 Flutter CLI 窗口，未运行原生构建或操作设备/私密签名。全部父检查结束，CLI 释放。用户 F9 及旧冻结包保持不动。

## 分项结论

|范围|结论|
|---|---|
|ADM01-1/2 真实账号、平台登记|未完成，未知不能当作不存在|
|ADM01-3 显式测试模式与拒绝门控|本地工程独立通过|
|ADM01-4 支持/隐私技术披露|源码与实际HTTPS正文核对通过，具体商店声明未提交|
|ADM01-5 聚焦业务与构建校验|独立通过；新签名候选/真实广告闭环另验|
|ADM01-6 分发与本人结果|待推进，无安装/广告到账通过结论|

工程已精准提交推送 `18f8c8b0fdf94acb9bb8ffcc71193723ce805a58`，仅跟该SHA的CI `39938640955`（2026-10-23T10:33:11Z终态completed/success）。原始证据日志保留工具输出空白，代码与文档diff-check通过；旧motion日志、未验icon-selection及网络后续未纳入本实现。

父独立回读该精确CI及jobs：ios-build、tests-and-android均success，精简终态证据`admob-beta-integration-evidence/remote-ci-final.json`。已通知原开发继续下一未占用build的安全test双端签名候选；本CI不再查询。账号/SDK实际闭环仍未通过。
