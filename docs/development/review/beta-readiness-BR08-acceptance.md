# BR08 build7 独立包验收

2026-10-23：**0.5.0+7关闭广告基线的本地签名/来源/包内检查通过。** 最新用户要求AdMob同批测试，本包冻结留存，不作为满足广告联测的最终上传候选；没有商店接受、生产运行或手机通过结论。

架构已读交付与预检分诊，并在本聊天实际执行独立verify_independent.py及17条只读Java/codesign/CMS/UUID命令，全部exit0；不是复述作者自查。未调用Flutter/原生构建、重新签名、读回显口令、运行生产或操作设备，原开发串行CLI仍可继续ADM。

- 双端各401个冻结来源逐一比对Git已验LY提交cd335efc5d293549d97a4b6c44420e605b665297，唯一期待差额为pubspec的0.5.0+6→+7；锁与实际功能代码相同。两端source manifest完全一致，候选清单所有产物hash回读。审查时共享树已有在途ADM test_firebase_config.py差额，不属于这两个冻结包，未被纳入通过。
- IPA SHA256 `2a23d891cee81975feb0ddfaa5fff9b7d2c21c315b40a17009db67fbc52b8a1c`；signed AAB `cec8cb62b952bb58c44b6d673f9c8addd5e7c3ef40c4020496834a608cac1ffd`。均身份com.pourlune.app/Pourlune/0.5.0/7、prod配置、广告disabled；不把manifest中的production_run_or_upload=false当审计外所有操作的证明。
- 每端136运行资源/90题逐字节核验；AOT iOS及Android三ABI均含既定支持、隐私、邮箱。未刷新或改变图像，未继承旧包hash。
- IPA ZIP完整性、解包树每文件相等后codesign deep/strict通过；真实entitlements的AppID与get-task-allow=false、App Store profile匹配且未过期。24份隐私manifest；5个dSYM检查对应4模块UUID，与实际导出二进制匹配。
- AAB bundletool validate及实际manifest确认code7/min24/target36；公开证书与BR05既有pin E098618C2D82DDE870552B7ECD7659E6EB428EE32EE53B7455393D754B3685E2一致，既有信任项下jarsigner strict通过。571个signed/unsigned非META payload一致，mapping及9份native符号hash已读。另独立解析12个32/64位ELF全部PT_LOAD静态对齐≥16KB；不当真实16KB手机运行通过。
- 旧build6清单三产物hash未变。实际账号/商店未独立登录；作者搜索无记录/已有内部测试资格仍属作者观察，正式操作前核实。未独立重编译或在手机安装。

证据：本报告同名前缀evidence/independent-final.json、verification.log、verify_independent.py及elf-alignment.json。源码版本差额只有build号，生产功能已由LY精确CI成功验证；本基线不新发上传或触发一轮仅供废弃候选的全量回归。版本/新增AdMob实现最终候选仍需独立验收、精确代码CI和核包，不自动继承本包结论。

当前动作：已告知原开发BR08作为冻结基线通过，继续ADM01账号/测试广告工程。后续使用下一未占用build号、显式beta测试广告模式与实际SDK/隐私参数一致，再父核包后已授权TestFlight/Play closed。AdMob账号/正式投放审核与测试广告可用分开；不重复询问已有通用上传权限。
