# LY 验收后的新候选与已授权封测提交

2026-10-23。LY本地验收已通过，提交cd335efc5d293549d97a4b6c44420e605b665297；精确CI39928698433正在运行。唯一实施仍为「Pourlune ｜ App 设计 开发」，父聊天独立核包与监管；UI/功能审查结束，不再重复派发。用户已经授权通过后提交TestFlight及Google Play closed，无需再询问通用上传许可。

1. CI等待期间只准备当前候选命令、既有Apple/Android签名定位、商店记录与本人首测资格的只读事实。不得提前上传旧build6。CI失败由父核对实际job，必要时有限修复；成功后直接生成新候选，无需等用户提醒。
2. 新候选版本0.5.0+7（先核对商店未占用；若冲突选下一真实未用编号并记录），正式双端com.pourlune.app；目的地/邮箱沿用已验真实值。使用现有beta_build.py与Apple专属profile/BR05独立upload key，在新ignored目录冻结；不得覆盖旧0.5.0+5/+6，不重建key，不读/回显口令。compile-only阶段不运行生产或发送测试事件。
3. 交付docs/development/deliveries/beta-readiness-BR08.md及evidence/beta-readiness/BR08/，包括源相对已验LY差额（版本/生成物明确）、锁/资源/90题/符号、双端实际产物hash、IPA身份/签名/entitlements/profile、AAB证书pin/unsigned与signed payload相等/权限及发布参数。不得继承旧包验收。父对实际新包独立核验后才进入上传。
4. 父核包通过后原开发连续推进TestFlight与Google Play closed实际提交及必要Pourlune记录/Beta路径；先检查已有记录，不重复创建。Apple本人已有合格内部身份则使用内部路径，否则按实际外部Beta审核；不扩大IAM。Google目标closed，不偷换internal。实际平台要求查官方当前资料；收集精确包版本/目标轨道/上传处理和审核终态、可用安装入口，未通过真实记录。
5. 最新本人事实：目标13+（不代替平台内容评级），首批仅本人测试；五原图ChatGPT生成且原会话/官方输出条款依据已记录，不要求空泛商用授权书；具体第三方输入疑点才提出。发布主体changjiang li、支持wangyule0379@gmail.com与GitHub Pages已确认。现有账号中能准确只读核实的事实直接复用；测试商店地区、具体本人账号、适用私人审核字段等真实未知必填一次集中问，不猜、不将私密字段入Git。不代签协议、购买、扩大IAM、邀请未知人或公开生产发布。
6. 用户远端手机通过TestFlight/Play安装，不能要求USB或开发者模式作为普遍前置。分发实际可用后提供本人安装与最小验证步骤（七瓶/完成按钮、离线、重启恢复、音触觉/读屏），手机结果未回报前保持真实未验。父及执行方不将模拟器自动bounds称为人工截图或真机性能。

CLI明确交原开发；所有Flutter/Dart/pub/SPM/iOS串行、FIREBASE_ANALYTICS_WITHOUT_ADID=1。父核包只读命令无需抢Flutter但需要构建结束的冻结交付。用户F9设备/窗口完全保护，受限采集不得绕过。旧motion日志与未验icon-selection不夹带。代码/版本通过后父精准提交推送检查新CI；纯文档不要求CI。执行卡住且不能解决时明确交接文件/设备/CLI给父，父按用户授权直接处理，避免循环派发。
