# 正式候选安装／升级复用步骤（本批未执行）

适用事实：双端com.pourlune.app、0.5.0(5)、Firebase prod编译配置；当前没有生产运行授权。步骤是后续执行契约，不是已发生的测试。不得运行当前候选来试探网络是否静默，也不以临时改为none/dev替代正式候选。

## 安装路径与前提

|平台|真正可用的路径|本批缺项／禁止替代|
|---|---|---|
|iOS AppStore IPA|持有人完成ASC应用记录／适用声明后，取得后续上传授权→平台处理→内部或外部TestFlight条件完成→获授权测试者在真机安装|当前尚未上传；AppStoreprofile无ProvisionedDevices，不是AdHoc／development授权。不得直接simctl安装iphoneos包、重签成其他身份或把Simulator包作为同一候选。|
|iOS本地设备验证的另一种路径|今后如已有获授权的适用设备profile／证书及设备，可另行导出匹配的本地测试包并明确与Store IPA差异|本批没有这些设备和profile，不创建资产、不擅自改签；即使将来本地测试通过也不是TestFlight平台分发通过。|
|Android AAB|已有上传密钥授权并本地解锁→新文件JAR签名→验证签名与包散列→后续上传／Play App Signing→测试轨道处理→实际设备安装|AAB是上传容器，不能adb install；当前unsigned不是可上传候选。未经授权不创建/重置密钥或开启轨道。|
|Android本地APK集验证|未来在获授权签名资产、设备及生产运行条件齐备后，可从精确AAB用bundletool生成显式签名APK集，记录每个APK的证书及hash|bundletool省略签名参数会尝试debug key，本批未生成APK。上传证书与Play最终APK app-signing证书可能不同；本地上传密钥签APK不能证明Play覆盖升级。|

官方依据：[bundletool](https://developer.android.com/tools/bundletool)、[Android签名](https://developer.android.com/studio/publish/app-signing)、[TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)。2026-10-22回读，仅用于路径与签名区别；没有据此进行上传或安装。

## 条件齐备后执行的顺序

1. 领取串行CLI窗口，核对独立、可清空的测试设备和正式App沙盒归属；排除F9及普通／Firebase／历史QA库。记录设备型号、OS、ABI、页大小、允许观察/采集方式、候选hash、版本/构建号、服务模式和实际安装签名证书。生产运行须先取得明确授权；默认off仍可能初始化SDK/RC，断网不能代替授权。
2. 干净安装仅在明确可丢弃且无原有Pourlune用户数据的设备上执行。记录安装来源及平台处理后的构建标识。正常main进入，真实操作主线/每日/辅助/拼片/设置路径；不注入QA关卡、替身奖励或测试入口。建立一次真实保存和可辨识进度。
3. 升级先有一个真实安装的正式旧构建N，记录实际版本、证书/平台签名关联和进度，再准备同身份同签名连续性且构建号大于N的新包。当前只有5一个本地构建，旧4为不同开发/QA身份，不能充当正式升级基线。不能卸载、清数据或还原空库后称升级。
4. 更新前后至少比对：主线/每日槽、puzzleID与题版本/原定义、实例ID、revision、完整瓶层/目标标签/历史、免费与奖励权益、首通/拼片/揭示回执、服务及无障碍/音频选择、schema版本。正常关闭后再开，并对一次已保存动作同安装强退恢复，再进行Undo验证。预期仅新动作带来的变化；奖励不凭关闭广告或旧QA回调产生。
5. 正式release沙盒不保证可用adb run-as/任意SQLite导出；仅使用获授权平台诊断/备份或已有可用方法。未获允许完整快照则只记录可观察字段并保留完整一致性未验，不能开启debuggable或插入测试命令伪装原候选。需要单独QA验证保存故障时，明确它的身份/签名/服务差异；不能升级成生产候选通过。
6. 安装/升级失败先保留原安装与数据，不卸载回退、不降构建号、不覆写旧库。记录平台错误、签名/版本/空间状态；缺陷定向修复后在新目录增构建号复验。SQLite变更保留非空历史迁移，不能以重置清档恢复。候选通过前不分发；已分发版本的恢复优先后续兼容修复版，停止分发需后续授权。

证据字段见同目录runtime-evidence-template.json。当前各运行字段均null/未执行，没有把步骤执行结果预填为成功。
