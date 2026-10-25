# B05 AC-01～36 证据矩阵（执行侧）

2026-10-22；基线 ba78a62726754634788f9b3a70f90acf0eefeb33。不能将本表视为架构独立验收或商店发布批准。

证据层级：**H**＝本批 host Flutter/真实 SQLite FFI；**C**＝本批纯 Dart 核心；**N**＝本批 iOS26.5 Simulator、实际 Flutter/sqflite；**K**＝N中的受控广告/时钟/初始 QA 数据；**L**＝同一 B05 独立安装、原生 SQLite、SIGKILL→launch；**历史**＝已验收旧证据，未虚报本批复跑；**外部**＝尚未验证。H `flutter-final-after-label.log` 包含规则/控制器/事务/UI/迁移；C `core-baseline.log` 包含90题回放。N `native-candidate-final.log`／`native-candidate-final/`，L `lifecycle-final.log`／`lifecycle-final/`（首轮保留lifecycle-first.log／lifecycle/）。初次N另存 `native-candidate-first.log`／`native-candidate/`。

|AC|实现与有效自动检查（测试源码均在app/test，核心在packages/pourlune_core/test）|平台或恢复证据|实际通过边界／缺口|
|---|---|---|---|
|01|C core_test：独立手算容量截断、守恒、步数与撤销|N 11/16/13真实UI合法参考操作；历史B03默认90运行|精确容量边界由核心断言，不声称每个边界都人工点过|
|02|C core_test 非法操作保持身份/历史；H bottle_art/ui测试|历史B03-R01交互和反馈截图；本批N倒入按钮操作|物理触感未验|
|03|C core_test 错标签／缓冲非空不胜利；production_content90解|N 13受控额外瓶实际装液、倒空后完成；N 11/16完成|无广告瓶通关定义按原题不变|
|04|C offline_contract；H offline_store、B04 review回归，教学事件仅成功落盘后发布|历史B04独立普通App同安装1步教学恢复；本批普通App手动复核另见manual记录|不重跑已验的所有教学变体，Android真实流程未验|
|05|C hint_test 当前状态；H offline_controller异步/自动选源/取消|历史B03真实hint操作，本批L重复即时取消10次|本批L取消是即时竞态，不能冒充最坏棋盘求解性能|
|06|C hint_test：12状态无解图／no moves／budget各异；H hint_worker_test|历史B02真实isolate/native路径|反馈状态自动验证；真机2秒预算仍待测|
|07|C core_test 加瓶前后撤销/重开；H b04_ui/reward_store|N 13受控确认后使用空瓶并完成；L确认恢复与原实例检查|受控确认不是真实SDK获奖；物理设备未验|
|08|H hint_worker、offline_controller、hint_events、system_motion|历史B03 lifecycle取消；本批L10次pour/undo/即时hint cancel|L不模拟真实广告OS中断，硬件性能待测|
|09|H store事务阶段故障、offline_store重复Next；C纯状态|N12 receipt阶段真实事务回滚→Retry；L7结算边界、每次12回执/2资格/单份拼片|真实事务原子性和同安装进程恢复；没有半份奖励|
|10|H store/transaction rollback|L before、snapshot、completion、piece、receipt、after；完整旧局或完整新结算|故障屏障只在QA入口，通过生产store既有fault回调停住；非随机电源/磁盘损坏测试|
|11|H controller、offline_controller所有导航first intent/Retry；H b04_r03读故障独立于写故障|N12保存失败不发布新结果、Retry后拼片；L真实提交中断|R03 H真实SELECT异常→免费Next/后台回前台；后续写故障保持原实例和Retry|
|12|H offline_store揭示归属/确认分离；H completion_presentation|N12/16先拼片；L预解码4图后实际SceneArt opacity0.5364中SIGKILL→重进呈现→确认→再冷启动收藏不重播/不重复发奖|L揭示未确认保留、再次进入可呈现；不以画面丢失推定权益丢失|
|13|H b04_controller_ads 1～13/累计；b04_architecture_regression水位|N11无机会；N16 K一次show后17|实际插屏SDK展示未验；资格/导航K通过|
|14|H b04_controller_ads无库存13→14恢复；architecture迟写后14/15不提前展示|历史B04-R01-R02 native受控完整13→17资格链，本批复用H|真实库存恢复链未验；本轮不重复等待相同30秒timeout|
|15|H b04_controller_ads拼片16/章节40保护；production正式20/40/60|N16拼片归属与先揭示、Next才K展示、17一次；历史B03最终/章节UI|实际SDK与拼片衔接未验|
|16|H offline_controller新鲜Next、Home/旧结算；B04保存幂等|N16连Next/Home不双跳；L恢复结算不补广告（测试入口服务disabled）|真实广告迟到链由SDK Dart协议测试覆盖，不冒充原生回调|
|17|H b04_ads/policy179/180、后台/异常时钟；R02边界|N13 rewarded K实际写展示时间后立即Next跳I；历史B04受控时钟native|OS真实广告后台冷却未验；不新增4/session、8/day上限|
|18|H b04_ui/policy关闭/无库存/授权/额度与免费工具|N13说明先Watch、冷却页；实际SDK无库存历史B04主审二轮|缺真实可展示SDK；免费路径不受其阻塞|
|19|H b04_reward_store、controller_ads及SDK lifecycle Android/iOS真实Dart路由协议|N13 K确认→原局单瓶→使用→通关；L entitlement唯一|SDK合同使用mock native channel；尚无真实earned→SQLite证据|
|20|H b04_reward_store事务回滚/重开、原实例；H store失败Retry|L已提交确认pending_restore强退恢复；未确认和reward_grant事务未提交强退均无权益|已保存确认可恢复；未送达/未落盘确认不可承诺恢复。确认由QA控制|
|21|H b04_reward_store原局替换/完成不串奖；b04_review_regressions Reset|L第13局确认已保存、第3局不获瓶，显式恢复13只一份权益；N短屏确认操作|真实SDK极端乱序未验；用户替换确认/同槽边界有实际Flutter证据|
|22|H replay_navigation四种实际widget导航故障；offline_controller重玩继续|历史B02 replay_navigation_test原生/主审B02；本批H全回归|本批未再次运行全部Replay原生变体|
|23|C core_test嵌入版本与坏快照；production_content旧实例；H store reopen|L保存后的完整puzzle与undo_history精确相等|未实施真实商店跨版本升级；非空schema迁移见下段|
|24|H history_recovery主/备双坏仅影响一槽；offline_store两槽|N daily分支普通槽JSON未变；历史原生history_recovery；L QA库独立|B04审查库保护前后对照，不清普通用户库|
|25|H offline_controller跨日继续/取消/写失败；offline_ui确认|N昨日一步→跨日Keep playing→昨日完成→今日；两个日期印章|跨日使用明确QA LocalDay，不假称等了真实24小时|
|26|C offline_contract本地公历；H offline_controller/stores历史/未来/同日重玩|N两日期归属；历史B03 native历史只读/未来禁用/重玩|未进行系统时区矩阵，映射算法不依赖秒差|
|27|C daily旧映射/回拨/循环；H daily stamp唯一／旧实例固定|历史B03旧题与新题；本批N原日期局|真实OS时区操作未全面验；数据契约自动验证|
|28|H completion_presentation、offline_controller final；C正式60|历史B03全60/15拼片/15揭示、B02final普通App冷恢复|复用有效证据，未重复刷60局；无第61关|
|29|H offline_controller/Ui全通与当日状态、重玩次级继续|历史B02final/B03最终画面及次日状态；本批H回归|多设备真实次日留存未验，不虚构D1/D7|
|30|C offline_contract日期循环；H content_library/offline_controller缺目录主线仍可用|历史B03 native默认90；本批N实际catalog加载30|发布epoch/顺序仍是候选编排，真人难度/节奏未因自动解通过|
|31|H加载真实Nunito的b05_accessibility320×568/2x，实际切换两选择/保存/显式恢复；system_motion/audio_screen等|N实际短视口2x/减少动态设置/静音设置、bottle语义和服务页截图；历史B03七瓶同尺寸/标签/音频原生|不是VoiceOver、色觉用户研究或物理听感；实际安全区96px溢出与确认词被拆行已修复；初次Ahem与FFI等待错误另留档|
|32|H b04_ads/controller/architecture/sdk_lifecycle/R03|N16重复Next/Home一次展示/导航；L动画强退和恢复|N广告生命周期是K，真实覆盖层/OS中断待库存与设备|
|33|H motion/store、纯core动作完整提交|L普通第11关900ms动画实际motion=true时SIGKILL；重启完整保存局/undo归零；背景另见manual|真实进程终止，但仍Simulator，不是真机GPU或极端低存储|
|34|H b04_services超时/disabled/失败、offline_controller/core|L无网络服务QA启动/保存；普通Bootstrap disabled配置操作；历史B04真实30秒无库存免费路径|未将Mac断网或视觉WiFi图标当离线证据；实际网络隔离/弱网/Android须代表设备执行|
|35|C production_content全部60主线+30每日参考解，守恒/固定目标/空缓冲；Python严格release90＋catalog，结构等价去重|N11/12/13/16及两每日真实UI参考动作，历史B03代表关和15里程碑|参考解≠最短解/真人难度/留存；候选权属不因通过而改变|
|36|H b04_metrics/telemetry/hint_events/continuation，唯一实例/请求/机会去重|N/K原局发奖与展示记录/回执；真实Firebase配置缺失所以disabled|真实Analytics DebugView/Crashlytics符号收件/Remote Config控制台全未验，不写数据已送达|

## 迁移覆盖（AC10/20/23/24/33）

本批H重跑非空数据库1→5（`store_test`）、2→5（`offline_store_test`）、3→5（`b04_store_test`）、4→5（`b04_v4_migration_test`），各自检查保留原题、历史、进度及相应版本已存在的权益/偏好；快照1兼容→当前schema2由core/offline合同测试验证，当前schema2在L精确恢复。历史B04二轮 `ios-sqlite-native-final.log`／执行B04-R01-R02实际iOS sqflite4→5已有有效证据，未为凑数复制一次迁移实现。L检查本次schema5完整性，不冒充新做了一遍所有历史版本原生迁移，也不等同正式分发渠道覆盖安装升级。
