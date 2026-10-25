# BR01 AC01–36继承登记

原B05逐项实现/自动检查/平台/外部缺口完整保留于[原矩阵](../../B05/ac-matrix.md)，独立通过范围以对应review为准。下表不是重新测试36条或整条AC全部通过。当前生产Dart规则/状态/存储无变化；只改native名称/版本及候选构建工具。新T/FB/MS证据分别按原验收边界补充，不把不同端点拼成性能提升。BR02针对正式身份、签名、构建模式及真实配置差异执行。

|AC|继承的自动检查范围（历史，不是BR01复跑）|当前候选差异/剩余门槛|
|---|---|---|
|01|C core_test：独立手算容量截断、守恒、步数与撤销|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|02|C core_test 非法操作保持身份/历史；H bottle_art/ui测试|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|03|C core_test 错标签／缓冲非空不胜利；production_content90解|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|04|C offline_contract；H offline_store、B04 review回归，教学事件仅成功落盘后发布|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|05|C hint_test 当前状态；H offline_controller异步/自动选源/取消|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|06|C hint_test：12状态无解图／no moves／budget各异；H hint_worker_test|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|07|C core_test 加瓶前后撤销/重开；H b04_ui/reward_store|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|08|H hint_worker、offline_controller、hint_events、system_motion|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|09|H store事务阶段故障、offline_store重复Next；C纯状态|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|10|H store/transaction rollback|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|11|H controller、offline_controller所有导航first intent/Retry；H b04_r03读故障独立于写故障|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|12|H offline_store揭示归属/确认分离；H completion_presentation|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|13|H b04_controller_ads 1～13/累计；b04_architecture_regression水位|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|14|H b04_controller_ads无库存13→14恢复；architecture迟写后14/15不提前展示|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|15|H b04_controller_ads拼片16/章节40保护；production正式20/40/60|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|16|H offline_controller新鲜Next、Home/旧结算；B04保存幂等|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|17|H b04_ads/policy179/180、后台/异常时钟；R02边界|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|18|H b04_ui/policy关闭/无库存/授权/额度与免费工具|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|19|H b04_reward_store、controller_ads及SDK lifecycle Android/iOS真实Dart路由协议|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|20|H b04_reward_store事务回滚/重开、原实例；H store失败Retry|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|21|H b04_reward_store原局替换/完成不串奖；b04_review_regressions Reset|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|22|H replay_navigation四种实际widget导航故障；offline_controller重玩继续|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|23|C core_test嵌入版本与坏快照；production_content旧实例；H store reopen|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|24|H history_recovery主/备双坏仅影响一槽；offline_store两槽|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|25|H offline_controller跨日继续/取消/写失败；offline_ui确认|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|26|C offline_contract本地公历；H offline_controller/stores历史/未来/同日重玩|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|27|C daily旧映射/回拨/循环；H daily stamp唯一／旧实例固定|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|28|H completion_presentation、offline_controller final；C正式60|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|29|H offline_controller/Ui全通与当日状态、重玩次级继续|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|30|C offline_contract日期循环；H content_library/offline_controller缺目录主线仍可用|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|31|H加载真实Nunito的b05_accessibility320×568/2x，实际切换两选择/保存/显式恢复；system_motion/audio_screen等|T/FB/MS适用模拟器/实际输入证据可补充；正式设备/物理音触觉/实际网络隔离另验|
|32|H b04_ads/controller/architecture/sdk_lifecycle/R03|广告状态机/SQLite证据继承；候选adsdisabled，不宣称真实SDK展示或earned通过|
|33|H motion/store、纯core动作完整提交|T/FB/MS适用模拟器/实际输入证据可补充；正式设备/物理音触觉/实际网络隔离另验|
|34|H b04_services超时/disabled/失败、offline_controller/core|T/FB/MS适用模拟器/实际输入证据可补充；正式设备/物理音触觉/实际网络隔离另验|
|35|C production_content全部60主线+30每日参考解，守恒/固定目标/空缓冲；Python严格release90＋catalog，结构等价去重|BR02正式身份/发布模式/同签名安装升级与设备差异；SDK/物理条件依原缺口|
|36|H b04_metrics/telemetry/hint_events/continuation，唯一实例/请求/机会去重|改为既有prod匹配配置编译，采集默认off；不得继承旧无配置说法或声称生产收件|
