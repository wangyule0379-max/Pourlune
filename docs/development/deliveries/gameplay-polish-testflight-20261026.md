# 游戏交互修订 TestFlight 15

2026-10-26。已更新 TestFlight：Apple处理完成，原 Pourlune Self 组显示 0.5.0(15) 正在测试、90天后过期，仍为2位既有测试员。未新建组、未改成员或重新邀请。

本批包含已独立验收的原稿液体颜色、连续可见倒水、橙色加深及瓶口间距、不能倒入时直接换选。题库、每日目录、SDK和锁文件均未随发布改变；普通字号及现有核心规则保持已验版本。正式版本 0.5.0(15)，精确源 `70d9b5909e6a1d8c158df349f59fd4cfb043b99e`。

## 验证与候选

CI [40287545684](https://github.com/wangyule0379-max/Pourlune/actions/runs/40287545684) 两个 job 成功：工具64、核心45、应用423项通过，格式/分析、Android APK及iOS Simulator构建通过。首轮CI发现两份测试仍期待旧的普通点击拒绝行为，已按换选契约修正，并保留显式倒水时真实拒绝/详情/状态保护；本地相关12项通过。失败的首轮记录与候选1保留且未上传，不复用其通过结论。

签名候选2：`build/beta-candidates/0.5.0-15/ios-gameplay-polish-2`，IPA 80,311,850字节，SHA256 `fde95b02f7bd0e8c00245f893c9a4a89403ba88d983ebc148410c2c2f5660513`。只读镜像 `build/package-review/0.5.0-15/ios-gameplay-polish-2`；总控45项独立包核通过，558文件及508运行输入核对、146资源及90题保持、签名与5份dSYM UUID、实际Runner无原生integration_test、prod Firebase/ads disabled/NoAdID/24隐私清单均已检查。详[独立报告](../review/gameplay-polish-testflight-20261026-independent.md)。

自动合规扫描退出2，命中localhost等拒绝列表、跨文件订阅/URL关键词等已定位误报或本次iOS内部测试不适用项；未改扫描器或安全代码掩盖结果。详 evidence 中 preflight-delta.md。手机安装、升级、音触觉和人类首次难度不由这些自动检查替代。

## 实际上传与偏差

使用字节核对过的可变归档副本 `build/organizer-upload15/Runner.xcarchive`。操作“TestFlight Internal Only”→Next 后，Xcode 直接准备并上传，没有出现原计划的最终Review页。开发在发现自动上传时尝试Cancel，以保留实际变体上传前核门，但自动审批拒绝中断正在进行的已授权上传；未绕过。实际变体核验因此发生上传启动后，不能倒写为上传前通过。

实际队列IPA、保存副本与只读复核副本hash相同：95,141,354字节，SHA256 `aa25b84dcf09956466f47fd8070f09aa80ac17d56e38fab2a2353edbfa56075e`；保存于 `build/store-submission/0.5.0-15/ios-gameplay-polish-2/prepared-upload.ipa`，只读镜像 `build/package-review/0.5.0-15/organizer-gameplay-polish-2/prepared-upload.ipa`。实际直接分发方式附带4个Symbols文件并更换embedded profile；未按计划关闭符号上传，实选情况如实保留，不声称沿用手动导出的全部选项。上传对象为Apple，不是Firebase符号服务。

Xcode显示“Upload completed with warnings”，4个供应商预编译SDK缺失dSYM警告，归档列表显示15 Uploaded to Apple。应用与已有5份可用dSYM的核对保持，不伪造供应商符号或为此重建/重复上传。实际结果见 `organizer-upload-result.txt` 与 `organizer-actual-state.png`。

## 分发范围与未验

按用户最新明确要求复用既有 Pourlune Self（1853bacc-97d1-40f9-b0cb-ae9ef9d01c74）当前2位成员。取消新组方案，未创建组、未改成员、未重发邀请；旧Beta组保持。F9及其窗口未操作；本批未操作Google Play或AdMob，也未启动生产应用。ASC build `74f1d564-5166-4735-960c-e1a17ffc860e` 已处理完成。出口分类的“标准算法与Apple系统加密同时使用／本次不在法国分发”保存被自动审批要求具体确认后，用户明确答复“同意，按这两项保存并继续”，才执行保存。已保存测试说明，15仅关联原Self组1个；Self组构建页实际显示15正在测试、90天后过期，原14也保留。回执见 `testflight-ready.json`、`testflight-self-ready.txt`、`build-group-readback.txt`。手机是否已更新15仍未验。

实际上传变体由总控在上传启动后独立补核24项PASS，详 `organizer-independent.json`：原266个payload文件保留，8个Mach-O只在原代码签名区域变化，执行代码/UUID/资源/配置不变，新增4个Apple Symbols与已验dSYM UUID对应。Xcode本轮生成团队Store profile（UUID以ead60500开头），不是原手动profile；实际同Team/AppID、既有证书pin与分发权限正确，未有生成新私钥的证据。此次profile更新、默认附带Apple Symbols、上传开始后才核变体三处偏差保留记录；后续回到可核对选项的Custom流程，不使用直接内部上传按钮。
