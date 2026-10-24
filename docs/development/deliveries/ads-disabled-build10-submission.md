# Pourlune 0.5.0(10) TestFlight 更新

**已更新 TestFlight：0.5.0(10) 在现有 Pourlune Beta 内部组显示“正在测试”，90天后过期；测试员仍为原1人，未重邀或新增。** 实际 UI 验收、精确 CI、最终签名候选/Organizer变体独立核验、上传/Apple处理及本人组分配均已完成，F9未动。实际手机安装/升级仍未验。

用户 2026-10-24 已明确授权专用 QA 截图/录屏重试及继续修复直至更新 TestFlight。F9 与其窗口完全保护；Play/AdMob 保持暂停。正常 main 的 P01–P21、三台专用 iOS 模拟器与八代表共114次实际提示倒水操作，范围、修复及 SQL 回执见 [实际验收](full-ui-reacceptance.md) 和 [独立图审](../review/actual-ui-independent-20261024.md)。物理手机与人类首玩难度不由这些证据代替。

最终受验源：`05220d7124519b72ca8366df38d936b9dac2544c`，分支 `codex/offline-foundation`。构建输入419项逐一与 Git exact commit 相同，其中 app/core/assets371项与实际验收源 `ff25d43` 完全相同。应用0.5.0+10，正式身份com.pourlune.app / Pourlune，正常lib/main.dart、Firebase prod、ads disabled、Analytics/Crashlytics独立默认关闭。无生产运行或符号上传。

精确 [CI 40053916204](https://github.com/wangyule0379-max/Pourlune/actions/runs/40053916204) 的 iOS 与 tests-and-android 均 completed/success；两真实 job 日志都含上述最终 SHA。工具63、核心38、应用280，以及格式/分析/Android debug构建、iOS模拟器构建通过。此次只读终态证据见 [ci-final.json](../evidence/beta-build10/final/ci-final.json)，不复用旧9或首次10的CI。

首个本地10候选被独立核包拦住原生integration-test残留，未上传。固定Flutter3.47.2在iOS release仍主动包含dev plugin，旧9亦存在同残留；“正常pub刷新即可排除”的旧判断已纠正。现在正常生成后，仅在手动AppStore archive/export期间精确去掉本App生成注册器/SPM的integration_test，finally恢复两生成文件；不修改SDK、依赖、pubspec或locks。未知格式/dev plugin拒绝；archive和signed IPA实际Runner都拒绝测试类/通道，unsigned维持不可上传的compile-only能力。首包阻断与最终修复报告分别保留。

最终原始签名候选：`build/beta-candidates/0.5.0-10/ios-ui-content-3/Pourlune-0.5.0-10.ipa`，59273190字节，SHA256 **8eae6eafbbae3eabdefeebddc43b3ff12d7f40c9172c49967b4b6bac8c7216e2**。完整538文件同字节只读冻结，独立复核实际资源/90题、prod定义、广告关闭、正常入口、无native测试插件、codesign deep/strict、profile与UUID，见 [最终核包报告](../review/build10-package-acceptance-final.md)。沿用既有iOS叶证书C859…与20261022 AppStore profile，没有新建/重置签名资料。

Organizer仅操作新工作副本 `build/store-submission/0.5.0-10/ios-organizer-attempt-3/Runner.xcarchive`；原候选和只读镜像不变。实际待上传IPA为该目录 `prepared-upload.ipa`，59273226字节，SHA256 **6714344141e848c43d15dc43518857d6dc5c3a7f92370aedae4f17c20a4ff057**。界面固定Symbols Not included、Manage version/build关闭、TestFlight internal only开启，版本10、Team与entitlements正确；原包到待上传包差额为8 MachO签名、Seal及Info.plist新增TFInternalTestingOnly=true，变体独立核验通过：256项payload文件中246完全相同、8仅LC_CODE_SIGNATURE真实签名blob变化、Info仅内部标记新增、Seal精确随动；其余代码/资源/签名身份/UUID保持一致。见[独立变体证据](../evidence/beta-build10/final/organizer-independent.json)。

支持站点只更新了广告关闭版本范围到9/10，处理政策未变。独立公开仓3c26b2a，两页HTTP200且与本仓canonical字节相同；未发布私密工程或新增网站。新版本What to Test已在Apple界面保存并完整读回匹配（已保存），内容位于证据目录。

未验仍保留：实际iPhone安装/升级、音频/触觉、性能、辅助功能、人类无提示首玩难度、商业美术权属、真实广告库存/展示/奖励、邮件收件。内部本人Beta不等于公开AppStore发行或法律全面认证。升级时通过TestFlight更新并保留安装，不卸载清档。

Apple回执：Xcode“pourlune_dev 0.5.0 (10) uploaded”，Organizer为2026-10-24 10:39 Asia/Taipei/Uploaded to Apple；ASC新build ID `0bda375a-e242-4d5c-b3a0-281deede4886`。处理后的缺少出口合规状态按新Flutter实际BoringSSL字节及[Apple当前文档](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption)选择操作系统外标准加密；本次仅本人内部TestFlight、未分发法国App Store，法国选择否，不把应用声明为无加密、不改Info.plist、不接受法律协议。后续扩大分发须复核。

服务端读回：构建页群组(1)为Pourlune Beta/内部/1，组内构建0.5.0(10)内部与旧9均为正在测试/90天后过期；已有测试员及旧9均保留。见[最终状态](../evidence/beta-build10/final/store-state.json)和[原生浏览器回读截图](../evidence/beta-build10/final/asc-self-group-testing.png)（仅裁去含私人账号联系方式的顶部70像素，其他像素未编辑）。完整私密截图仅在ignored本地工作区，不入Git。
