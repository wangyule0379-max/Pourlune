# M 收尾：一次定向补证

2026-10-22。沿用用户已授权的 M01–M08 范围。T、FB 已验实现及精确 CI 均通过；本批补齐现存证据缺口，不重新实施或重跑已通过的整批工作。

执行：「Pourlune ｜ App 设计 开发」；独立验收：本架构聊天。依据 `docs/development/deliveries/motion-polish.md` 和 `docs/development/review/motion-polish-coverage-audit.md`。

## 范围

|编号|任务|验收边界|
|---|---|---|
|MS01 / M02|用专属 QA 入口调用正常 product.main，分别记录 Dart 计时起点、初始化壳首 post-frame、Home 代表按钮 enabled/hitTestable、首次真实手势被控制器接受的时点。双端可用独立设备各做同安装三次冷启动。|宿主 launch 命令另列，不能冒充 native 首像素；明确采样间隔、探测开销、准备状态及实际导航状态变化。首次观测接受不称理论最早可交互。数据仅为当前候选，不能与旧 M 不同端点拼成性能提升。|
|MS02 / M03|补代表原生按钮与棋盘的 Enter/Space 激活行为测试：一次激活只提交一次，busy/disabled 不提交，按键释放与焦点切换不触发额外动作。|依据平台/Flutter 实际支持键位；检查动作/实例/revision 或导航变化，不只断言动画常量。先补测试，仅有真实生产缺陷才改代码。既有触控/语义/焦点证明复用。|
|MS03 / M06–07|一次能力核查：已有合法可用工具能否观察实际音频输出及最后一倒→持久回执→成功/拼片的音画关系。可行则用专属 QA 做有界观察并核查静音/开关；不可行则记录具体工具/设备限制，保留未验证。|调用日志只证明门控/运输，不等于听感、实际音轨或物理触觉通过。不得重复或变换方式规避本聊天此前 Cocoa513/EPERM 屏幕录制/截图限制，不得为补证改系统权限。代表真机及物理触觉仍外部待验。|

现有 M01/M08 历史基线与新 T/FB 不完全可比，按版本分别保留，不另做整套全 App A/B。正式拼片为 SceneArt 局部显现，Flame 飞行仍是独立样板；不迁移全场景、不新增缓存框架、不修改产品规则或 SDK 配置。下一页按需预热的实际覆盖范围如实说明。

## 设备、文件与构建

- **用户 F9C16DE7-01D8-4740-B796-A3A2DB8C3265 / dev.pourlune.fullBoardValidation 完全保留，不安装、启停、输入、重置或切换其 Simulator 窗口。** 不用全局 shutdown/adb 清理。
- 可复用已关闭的独立 iOS 255890D5-B4A3-42F9-B1A2-409E77118348 与 Android 5588，先核对实际 inventory，使用新的专属 QA 身份与 `motion_supplement.sqlite`，保护旧 FB/Firebase/普通审查库。运行操作不得抢占用户正在体验的窗口；无法保证时记录限制。
- 架构此前 CLI 已释放，本次明确将有界补证窗口交给原开发；Flutter/Dart/pub/SPM/iOS 串行，`FIREBASE_ANALYTICS_WITHOUT_ADID=1`。结束明确释放。UI 本批无并行构建。
- 原开发拥有新增 QA/专属测试/交付，架构拥有计划/tracking/review。先保留当前已验源码与哈希，不改未验旧 M 大录像或历史 RED。若必须改 UI 所有的生产文件，先向架构说明具体缺陷与文件以协调。

## 交付

`docs/development/deliveries/motion-polish-supplement.md`，证据 `docs/development/evidence/motion-polish-supplement/`。记录源码/安装/设备/数据库、三次原始样本与端点定义、聚焦测试、实际修改、失败尝试、能力限制和 CLI 释放。不要自行提交或宣布 M 整批通过。

架构独立核对 QA 是否真实接受输入、复跑新增必要测试，并用独立设备核验适用运行行为；已有 T/FB 独立记录只按原范围继承。报告 `docs/development/review/motion-polish-acceptance.md` 按 M/适用 AC 区分通过、设备限制及未验证。仅通过范围提交推送，代码变化才核对精确新 CI；不为纯文档追加 CI。
