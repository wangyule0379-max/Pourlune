# 难度与直接加瓶 — TestFlight 发布

当前状态：**TestFlight0.5.0(12)已进入既有Pourlune Beta内部本人1人组，实际回读“正在测试 / 90天后过期”**。Apple处理、测试说明保存及组内分配已完成，可在本人TestFlight获取更新；物理手机实际安装尚未验证。新版本为0.5.0(12)，不把本次代码称为已进入构建11。既有Pourlune Beta内部本人1人组为唯一目的地。

实现基线 `5767e01919a581a6079ec7eb5bc27d8d57f61ed2`。本次发布仅追加版本和发布说明，完整保留此前P14/P15、缩略图及取消临时读数条的已验改动。题库22关重排、关闭广告时每实例一次本地原子加瓶、旧活动定义/奖励隔离，详 `difficulty-direct-bottle.md`。直接领取不是观看广告，不创建SDK观看确认或广告记录；test/prod广告配置路径不变。

复用已验内容47、核心39、90题release/catalog及正常main专用QA证据；此前全应用400项后旧inventory等待已取消广告弹层，修正该用例后单独通过。不得把上述记录称作完整新全套成功；新的精确提交CI将完整执行。

新签名候选、只读镜像、来源/身份/锁/90题/无原生测试插件/签名及dSYM、精确CI、父独立核包、实际Organizer变体、Apple上传处理和既有组回读结果将在实际完成后记录。沿用既有Apple证书/profile，不新建key、不上传生产事件或符号。Play/AdMob暂停；F9和其它受保护设备/库不操作。

证据目录：`docs/development/evidence/difficulty-direct-bottle-testflight/`。物理iPhone实际安装升级、真人首玩难度及真实广告SDK展示/奖励仍是独立未验范围。

## 已冻结候选（上传前状态）

精确发布源 `54a7fc148f2762918262146f2f4ac0bd084b5f6e` 已push，分支codex/offline-foundation；新CI40180964750。签名候选 `build/beta-candidates/0.5.0-12/ios-difficulty-direct-1/Pourlune-0.5.0-12.ipa`，80305199bytes，SHA256 `9cb7e20397476236dff0c9239153bd7676d63df446667605a513620f64e38ffa`；558文件只读镜像在package-review/0.5.0-12同名目录。

父已独立核495精确源、146资源/90题及22关差额、已验QA219输入同字节（另1项版本11→12）、实际archive和IPA原生测试类/通道缺席、既有签名profile/pin和3组IPA/archive/dSYM UUID，PASS_PACKAGE_GATE。无生产运行或符号上传。

全新Organizer工作副本 `build/store-submission/0.5.0-12/ios-difficulty-direct-1/Runner.xcarchive`；实际待上传IPA80305220bytes，SHA256 `7e08b0df30d23166082608964f1e87980742431cd5ea233d92f761c0a887313a`，只读镜像 `build/package-review/0.5.0-12/organizer-difficulty-direct-1/prepared-upload.ipa`。实际Review为0.5.0(12)、既有Team/profile，symbols=false、manageVersion=false、internalOnly=true；最终Upload尚未执行，仍待CI及变体独立终态。

既有支持站只补build12版本范围及本地一次加瓶事实，公开仓提交 `e2a6128c6656ec443f2417f0ec7697fbfaa23bc4`。两页HTTP200且与canonical逐字节一致，其他隐私处理未变。没有把本地发瓶称为SDK广告确认。

## 精确CI与最终上传门槛

CI40180964750的iOS121131737502、Linux121131737695均completed/success，所有步骤成功；真实job日志含精确源54a7fc148f2762918262146f2f4ac0bd084b5f6e。工具63、核心39、应用401，以及格式/分析/Android debug/iOS模拟器构建通过。这是本次完整新全套结果，不复用此前400项加单项结果或旧CI。

父实际Organizer变体核验通过：10项差额仅8个Mach-O实际签名blob、Info新增internalOnly及对应seal；其它代码和146资源完全保持，既有签名/profile/entitlements、dSYM和原生纯净通过。点击Upload前再次核对精确HEAD与真实queue/工作副本/只读镜像SHA全同。没有再次签名或改动已验字节。

## Apple与既有测试组实际回读

Xcode实际确认0.5.0(12)uploaded，ASC构建ID `48875434-8ae6-4c81-877a-9645eb4c74d1`，上传列表17:45 Asia/Taipei创建。2026-10-25T17:56:28.238738+08:00 回读现有Pourlune Beta内部组：4个保留构建，12为“正在测试 / 90天后过期”，仍1测试员。无新增邀请、未过期旧版本、未公开发行。

What to Test已保存并完整回读同字节，明确22关、一次本地空瓶、旧实例定义保持、更新时保留安装。按实际Flutter/BoringSSL及现有仅内部范围填写标准加密、无法国AppStore分发；没有选择无加密、改Info.plist或接受法律协议。实际Apple字段状态、组内AX摘录与签名上传回执见本次证据目录；完整商店截图含账户页眉，只保留ignored本地工作区，不加入Git。

本次发布复用了父的正常main真原生及SQLite验证，没有操作专用QA、F9或其它设备/库。未验仍包括真实iPhone安装升级、音频/触觉/性能、真人首玩难度、真实广告SDK库存/展示/奖励；内部组可获取不等于这些外部验证已通过。
