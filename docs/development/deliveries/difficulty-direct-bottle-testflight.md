# 难度与直接加瓶 — TestFlight 发布

当前状态：发布准备中，尚未上传或进入测试组。新版本为0.5.0(12)，不把本次代码称为已进入构建11。既有Pourlune Beta内部本人1人组为唯一目的地。

实现基线 `5767e01919a581a6079ec7eb5bc27d8d57f61ed2`。本次发布仅追加版本和发布说明，完整保留此前P14/P15、缩略图及取消临时读数条的已验改动。题库22关重排、关闭广告时每实例一次本地原子加瓶、旧活动定义/奖励隔离，详 `difficulty-direct-bottle.md`。直接领取不是观看广告，不创建SDK观看确认或广告记录；test/prod广告配置路径不变。

复用已验内容47、核心39、90题release/catalog及正常main专用QA证据；此前全应用400项后旧inventory等待已取消广告弹层，修正该用例后单独通过。不得把上述记录称作完整新全套成功；新的精确提交CI将完整执行。

新签名候选、只读镜像、来源/身份/锁/90题/无原生测试插件/签名及dSYM、精确CI、父独立核包、实际Organizer变体、Apple上传处理和既有组回读结果将在实际完成后记录。沿用既有Apple证书/profile，不新建key、不上传生产事件或符号。Play/AdMob暂停；F9和其它受保护设备/库不操作。

证据目录：`docs/development/evidence/difficulty-direct-bottle-testflight/`。物理iPhone实际安装升级、真人首玩难度及真实广告SDK展示/奖励仍是独立未验范围。
