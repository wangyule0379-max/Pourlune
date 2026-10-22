# BR03 独立验收：交接资料通过，三条提交路径未就绪

2026-10-23 Asia/Taipei。架构实际读取交付与候选索引、符号清单、三条提交矩阵、重建条件、范围清单和最小持有人事项，检查作者校验脚本后独立执行，并另写 [独立检查脚本](beta-readiness-BR03-evidence/independent_check.py)。作者fresh审查不替代本结论。

结论：**BR03资料/冻结索引通过；内部TestFlight、外部TestFlight和Play closed均不就绪**。无新生产实现；完成当前授权和条件下可独立收束的准备工作。

## 实际复核

- 双端各394来源与当前文件一致；4个prod配置文件仅比对指纹，未输出配置内容。候选仍0.5.0+5/com.pourlune.app，未重新构建或覆盖。
- IPA SHA256 `0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5`；AAB SHA256 `ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90`。
- 对5份dSYM执行dwarfdump，逐一与导出Mach-O UUID比对，并确认导出Mach-O字节等于精确IPA zip成员；4个模块匹配，objective_c重复条目保持事实。没有上传符号。
- AAB内R8 mapping及9份原生符号逐个摘要匹配，保留mapping副本字节相同；没有JAR签名块，仍unsigned。未把嵌入符号匹配称作运行符号化成功。
- 本地 `build/beta-handoff/0.5.0-5-br03/BR02-BR03-handoff.zip` SHA256 `574773a1a3f916ab4cac0f96675d9db7f320671875bda74a53f7d4985462fc5a`：27成员、CRC通过，清单与实际一致，26仓库文档逐字节对应，README为交接说明。未包含候选二进制/配置文件/签名资产；常见API key/私钥模式扫描无命中，该扫描不宣称证明所有可能秘密均不存在。
- 独立执行交付脚本验证相对链接、未执行模板null字段和三条not-ready标记。结果见 [delivery-check.log](beta-readiness-BR03-evidence/delivery-check.log) 与 [independent-check.json](beta-readiness-BR03-evidence/independent-check.json)。独立脚本仅修正证据中的符号名称标签后重跑，未改变验收条件。

## 真实边界与后续

BR01精确提交33433c76的CI39809177137已由架构GitHub连接器核对completed/success，iOS和tests-and-android均成功，见 [终态证据](beta-readiness-BR01-evidence/remote-ci-final.json)。不再轮询旧CI，纯资料提交无需新CI。

[最小持有人事项](../dependencies/beta-readiness-user-actions.md)四组涵盖应用/受众/地区/联系方式及图像权属、必须本人确认的控制台声明、本机Android上传签名选择、适用设备及生产运行/合法观察条件。iOS已有签名准备无需重做，Firebase四App无需重建。

资料到位后由原开发完成批准的支持地址/邮箱配置及Android签名门控、定向测试、新候选构建与适当设备验证，再由架构验收。当前包不能因资料填入文档就自动成为最终提交包。生产运行授权不等于上传/送审/开轨道/邀请授权；后者仍后续交接。真实Firebase收件、真机及商业权属没有通过。无新增缺陷需要无效重复派工。

本轮没有构建/安装/运行生产包、登录控制台、接触私钥、影响用户F9或更改任何网络安全设置；BR02的独立inventory只针对允许的只读端点。验收不包含旧未验motion-polish历史文件和后台变化的emulator日志。
