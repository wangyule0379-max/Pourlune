# BR03 提交前交接：三条路径均未就绪

2026-10-23（Asia/Taipei）。本批资料/候选索引与有限只读验证已收束，未上传、提交Beta App Review、开测试轨道、创建测试组或邀请。iOS TestFlight内部、外部与Google Play closed testing均为**不就绪**；本地签名IPA不等于完整可提交，unsigned AAB更不是上传候选。BR01工程/静态范围已有架构独立接受，BR02正式候选设备运行仍未验。

## 交接包与实际候选

- [精确索引（含来源/配置指纹/符号）](../evidence/beta-readiness/BR03/artifact-index.json)及[可读索引](../evidence/beta-readiness/BR03/artifact-index.md)。本地资料包位于build/beta-handoff/0.5.0-5-br03/，不包含私钥/密码/真实配置内容；原候选留在BR01 final3目录。
- iOS：build/beta-candidates/0.5.0-5/ios-br01-3/Pourlune-0.5.0-5.ipa；0.5.0(5)/com.pourlune.app，SHA256 0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5。既有证书手动本地导出；目前仅作冻结工程候选。
- Android：build/beta-candidates/0.5.0-5/android-br01-3/app-release-unsigned.aab；0.5.0/5/com.pourlune.app，SHA256 ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90。target36/min24，尚需授权上传签名，不能直接安装。
- iOS archive/dSYM保留，5个条目/4模块UUID逐份匹配导出二进制（objective_c有相同UUID重复条目）；Android AAB自带R8 mapping及9份三ABI原生符号，mapping已在新handoff目录独立保留并核对当前生成文件相同。未上传任何符号。没有Dart obfuscation/split-debug-info产物可虚构。

## 分平台交接与编号门槛

[三条提交矩阵](../evidence/beta-readiness/BR03/submission-matrix.md)逐项区分包、应用记录、签名、协议、隐私支持、权属、年龄地区及测试者。所有未知信息保留待持有人决定，不猜SKU、不勾政策/出口声明、不扩大IAM。TestFlight内部用户要求与外部Beta审核不同；Play internal不替代closed，适用新个人账号12人14天是后续生产访问条件。

|门槛|目前精确状态|何时可以关闭|
|---|---|---|
|BR-B01/B01-P|Apple AppID/profile已完成，但ASC记录/SKU未知；Play记录未建，政策/出口声明未签；账号控制台本批未重复回读|持有人确认SKU及实际协议/声明，应用记录实际建立并回读；不假定Schedule2 banner阻断免费Beta|
|BR-B02|iOS签名可用；Android无选定授权upload key，Play最终app-signing连续性未验|本地已有资产获授权解锁/签名，精确新包校验；Play处理/实际APK签名证据留到后续授权阶段|
|BR-B03|公共支持/隐私/反馈邮箱及处理责任人未定，App内目的地仍为空|批准归属和披露→允许范围内发布→真实可达/收件→编译配置接入并重建→实际点击验；本地HTML不代替公共URL|
|BR-B04|图像/派生图像权属UNCONFIRMED；OFL与程序音频来源已留档|持有人核实商业授权链，必要时只替换具体缺权资源并复验，不整套重画|
|BR-B05|年龄/受众/国家地区/trader/export/隐私及DataSafety未正式确认/提交|依据实际最终包、SDK/RC行为、权限及经营事实完成对应问卷；不能说默认off=零收集|
|BR-B06|缺连接真机/最低OS/16KB运行/同正式签名升级/读屏音画及正式截图；无授权测试名单；prod compile-only|适用设备与合法观察条件、生产运行授权齐备后按BR02定向验收；名单/组只准备，实际邀请另需后续决定|

[集中持有人事项](../dependencies/beta-readiness-user-actions.md)已归并为4组最小动作；无需再次下载profile、恢复已可用Apple登录或注册Firebase。可选广告仍关闭，未强加开启真实广告作为本候选前置。现有服务方案未变，无新网络/TLS试验。

## 最终重建与复验边界

[条件表](../evidence/beta-readiness/BR03/rebuild-and-revalidation.md)区分纯控制台资料和真正改二进制：当前构建工具没有最终支持地址/邮箱接入参数或Android上传签名路径，不声称用户填完资料就能立即上传。拿到已批准信息后仅定向补门控与测试，使用新目录/实际版本增号规则构建，核对签名/资源/SDK/符号并在适用设备复验。不得覆盖final3或无条件清档。以后若取得上传授权，再分别记录平台处理、审核、可见性及真实测试者安装，不预记成功。

本批实际检查：设备只读inventory；两包hash、两份394来源、4个prod配置文件指纹无变化；iOS5份dSYM UUID匹配；AAB内mapping和9符号摘要/保留；交付JSON、链接、无秘密打包和包未变检查。未再次构建/analyze或重复旧玩法套件，未追踪架构负责的BR01 CI。完整交接等待架构独立验收；执行方不stage/commit/push，不改计划/tracking/review。内部可做项结束后释放CLI，只剩上述具名条件，不做无效轮询。


一次fresh作者终审（gpt-6-astra）Critical0/Important0/Minor0；独立复核来源/符号/精确IPA UUID与文档边界。完整未判断项的裁定及代价见[终审记录](../evidence/beta-readiness/BR03/author-final-review.md)，不替代架构独立验收。打包与CLI最终释放由作者在终审后实际完成，终审没有预先验证未来ZIP。
