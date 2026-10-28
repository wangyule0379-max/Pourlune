# Build18 最终 CI 与既有签名候选衔接

2026-10-28，父独立检查通过，已交 Pourlune ｜ Use Computer 继续授权内的 TestFlight 上传。

- 实际从 GitHub API 读取 run 40653590242：head `a8e6be9323d97855de25bcfbcabc0e88337cf415`，completed/success；`tests-and-android` 与 `ios-build` 两 job 全部 success。终态证据见同目录 `gamemunchies-build18-ci-terminal-independent.json`，无需重复查询此终态。
- 将签名候选 `ea2bdee853559ddaa66e44e35fce7bac34a40d29` 的 554 项来源清单与最终 head 比对：547 项 Git 来源中仅 `.github/workflows/flutter.yml` 改动，把固定私有 SDK 恢复移至配置守卫之前，未跳过检查；546 项一致。另 7 项私有 SDK 保持此前实际核验的 `92f588200a1d80b1d0023122fcfc3037db87c53c` 固定来源及归档 SHA，恢复工具和固定清单未变。
- 现有包的 App、资源、配置、锁、SDK 和构建工具输入未变，复用此前独立通过的 IPA。86731598 字节，SHA256 `a37b9aa46932616744d04a2116a1b9c89acdd84a98a108eeccea46a6b7665541`。
- 为 Organizer 准备的可写 archive 284 文件，父本轮逐一比对已验冻结 archive 与上传清单，零差异。来源记录 `gamemunchies-build18-ci-bridge-independent.json`。

此前签名、身份、90 题、正式 GameMunchies 配置、官方测试广告、原生纯净和 dSYM 的核验继续有效，见 `gamemunchies-build18-package-independent.md`；本轮没有重复工具链构建或设备测试。首次 CI 因 SDK 恢复顺序失败的历史记录保留，最终成功不能表述成首次即通过。

Computer 使用既有 Apple 签名、原 Self 组 2 人，保留版本 18，不新邀、不提交公开 App Store、不上传生产测试符号。实际上传及处理、原组可测试仍须回读；此报告并非上传完成。若 Organizer 产生实际重新签名上传变体，只核该实际差额一次，不重造无差额候选。
