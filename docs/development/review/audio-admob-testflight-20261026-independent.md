# TestFlight 16 独立发布审查

2026-10-26。父只读核包和平台回执，不运行工具链或操作设备。**发布完成：0.5.0(16) 已上传、Apple 处理完成、原 Pourlune Self 组正在测试。** 以下保留各阶段实际审查记录。

发布源 `2b364d62f060e3a537c47a9e1db987bb26c90fea`，相对已验 `48897d3` 仅版本 15→16 与发布资料。出水口、新音频、真实官方测试广告的运行验收复用各自已完成报告，不扩大本次检查范围。

候选 `build/package-review/0.5.0-16/ios-audio-admob-test-1`，IPA 86,500,225 字节，SHA256 `991b9b9e2d5aebb9b273739715a9c03ddf17fbadbf2c2fb5cb389662a3a1524d`。

父复用上一版独立核包脚本并调整本次明确差额，未运行作者核验模块。实际核对 561 个镜像文件、557 个候选索引、513 个运行输入与精确 Git 源及本地内容；147 个资源与包一致。60 主线＋30 每日、每日及目录 31 项、SDK/锁保持已验内容。ZIP 成员与解包内容逐一一致。

实际包和归档身份为 Pourlune / com.pourlune.app / 0.5.0(16)，正常 main、无 QA 场景或命名库注入。test 模式使用已登记 iOS AppID 与两个官方 sample unit；双端 owner 收费单元不在 AOT。Analytics/Crashlytics 默认关闭、NoAdID 核心依赖和既有隐私门控保持，24 份隐私清单可解析。

Dream Culture 为已选官方原字节完整 MP3；pour.wav 为已验剪辑字节，署名随包，旧 background.wav 不存在。尚不声称用户手机已听到或认可音量。

archive 和 IPA 深严格签名通过，沿用 profile `74a202b2-3b25-4e31-8fd4-0413bf15d486`、Team `T7U878Z8H6`、既有签名公钥 SHA1 `13362E4AF31A860FA6B705DB5192AF78613F7A58`。无调试 entitlement、无设备限定、未过期；5 份 dSYM 与两处二进制 UUID 相符。两处 Runner 无 integration_test 原生类/通道，生成 QA 输入已恢复。

原始结果 `evidence/audio-admob-testflight-20261026/package-independent.json` 中 51 项包内容检查通过，唯一未通过为额外的“镜像所有目录也须只读”检查：177 个目录为 755，所有文件均只读、源镜像和 IPA hash 不变。此为镜像权限描述差异，不是安装包缺陷；保留原始失败结果及 `mirror-permissions-independent.json`，不要求重建或增加发布关卡。父未修改候选权限或字节。

CI `40335786098` 已通过 GitHub 连接器核对精确 head；当前 iOS 成功、tests-and-android 进行中。继续等新 run 终态，再按既有 Custom 流程核实际上传变体与平台最终回执。沿用原 Pourlune Self 组及现有成员，不新增组或邀请。AdMob 商业账号/公开关联/app-ads 外部待办仍未完成，此包仅官方测试广告，不等待商业投放准备。

## 上传前实际变体：通过

父已实际查看 `organizer-review.png`：当前停在 Upload 按钮前，0.5.0(16)、既有 Pourlune App Store Beta 20261022 profile、Symbols Not included、正确 application-identifier。

`verify_organizer_independent.py` 实际运行 25 项全通过，结果 `organizer-independent.json`。真实 Xcode 队列、保存及只读镜像三份 IPA SHA256 均为 `405c7625647b9157f154cb0bd94ce9ce4f56b1b5172553ae2c3a675f8aa53cdb`，86,500,276 字节。没有新增/删除文件或 Apple Symbols；原 embedded profile 字节完全相同。10 项变化仅 Info 新增 TFInternalTestingOnly、CodeResources 及 8 个 Mach-O 的签名区，所有执行字节、资源与配置保持已验内容。实际上传包严格签名、既有公钥/分发 entitlement/profile、原生纯净及 5 份 dSYM UUID 均通过。

本次确为上传前核验。父已放行该精确变体，开发待精确 CI 终态成功即可点击 Upload 并完成原组分发，不需另一轮批准。尚不将准备完毕当成上传或可安装。

## 最终平台验收：完成

父实际查看 `upload-complete.png` 和 `self-group-ready.png`，并读取上传、构建群组、Self 群组与最终状态回执。Xcode 明确显示 0.5.0(16) uploaded；ASC 构建 `4db79882-0c24-4020-b0fc-a99c6022a9e7` 完成处理，已关联原 Self 组 `1853bacc-97d1-40f9-b0cb-ae9ef9d01c74`。实际群组显示 16“正在测试/90天后过期”，仍为原两名测试员，14/15 保持，无新增邀请或群组。

已读取新精确 CI `40335786098` 的终态回执：head 相符，两 job 及步骤 completed/success。此前父曾在线核对该 head 和运行状态；本次读保存的终态回执，没有重复查询终态。测试说明及沿用既有加密技术分类已保存。

最终逐项结果和九份回执 SHA256 见 `evidence/audio-admob-testflight-20261026/platform-final-independent.json`。本次 TestFlight 发布目标完成，无需重传/重查/重邀。包含出水口修复、所选音乐水声和官方测试广告；商业广告准备、用户手机实际更新与主观试听仍分别未验，不因此扩大通过范围。F9/D79/256及网络未由父操作。
