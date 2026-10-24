# 2026-10-24 实际矩阵更新

当前P01–P21已在正常main专用QA逐页观察，独立报告已关闭本轮Critical/Important。实际图、设备/字号、受控权益与广告关闭边界见[实际矩阵](actual-20261024/actual-page-matrix.json)、[独立报告](../../review/actual-ui-independent-20261024.md)。下面是2026-10-23历史自动布局矩阵，不代表当前仍为视觉0页；真机/真实SDK与未采样条件继续未验。Bottle added文案已以build10新原生图及528项冻结独立复核关闭。

---

# 全页面复查矩阵

已读取全部7组原稿，并检查本批当前presentation。**下表全部行的当前实际视觉/正常主入口原生/手机验收均未通过，未采集新截图/录屏。** 自动布局、真实SQLite与受控运输测试只证明各自范围，不能升级视觉状态。

|页|内容|当前实现/修复|自动证据|实际画面|
|---|---|---|---|---|
|P01|欢迎|短屏减logo/装饰占用，Start保留原行为|page-layout-inventory.json / P01; 3尺寸×1.0/2.0|未验|
|P02|首页|复用场景/进度/继续，未改保存与全通路由|page-layout-inventory.json / P02; offline_ui_test/page_transitions_test|未验|
|P03|章节|恢复分章场景/完成数/关卡网格；状态门控保留|page-layout-inventory.json / P03; motion_polish_test|未验|
|P04|教学|保持独立Skip、教学步数与四瓶；说明区留出核心操作空间|one_screen_layout_test LY04 tutorial / LY-R02 tutorial; offline_ui_test|未验|
|P05|核心|Extra与辅助按钮10px分隔；去底部多余4px，保留4–7瓶和标签|r01-red.log/r01-green.log; full_ui_reacceptance_test UI-R01; one_screen_layout_test LY04|未验|
|P06|暂停|原KnitPanel竖排主次操作保留，保存/内存状态分离|page-layout-inventory.json / P06; offline_ui_test|未验|
|P07|提示|保留提示说明+固定Cancel；未将搜索无结果当无解|one_screen_layout_test LY04 hint / LY-R02 hint; offline_controller_test|未验|
|P08|无移动|沿用内联反馈和免费救援；未擅加自动阻塞弹窗|one_screen_layout_test LY04 noMoves; 原稿模态/当前内联差异保留待视觉复审|未验|
|P09|重开|统一奶油边框/圆角/字体主题，取消/确认逻辑未改|page-layout-inventory.json / P09; offline_ui_test|未验|
|P10|通关|默认双排完成棋盘、成功/标题、进度卡；主按钮独立全宽。章完/最终以完整场景为主体|full_ui_reacceptance_test UI-R02; one_screen_layout_test LY03; completion_presentation_test|未验|
|P11|拼片|取消无条件96缩略；场景按剩余空间主体展示、拼片卡、全宽主按钮|full_ui_reacceptance_test UI-R03; one_screen_layout_test LY03 reward|未验|
|P12|收藏|保留三场景卡、0–5归属、窄屏与大字重排|page-layout-inventory.json / P12; b03_collection_design_test|未验|
|P13|场景|保留主场景/进度卡，增加主次按钮分隔|page-layout-inventory.json / P13; page_transitions_test|未验|
|P14|每日|保留日期/月历/今日与旧日入口，未改跨日替换|page-layout-inventory.json / P14; offline_ui_test/offline_controller_test|未验|
|P15|每日完成|日历与成功标记作为主体，印章保存文案，回每日/首页|one_screen_layout_test LY03 daily; completion_presentation_test|未验|
|P16|额外瓶说明|复用已有空瓶分层图、说明、Watch与Not now；不模拟广告成功|page-layout-inventory.json / P16-P17; b04_ui_test|未验|
|P17|广告不可用|同卡不可用反馈/Retry/免费返回，真实门控不变|page-layout-inventory.json / P16-P17; b04_ui_test/b04_services_test|未验|
|P18|到账|七瓶统一尺寸与4+3，额度禁用/保存失败优先逻辑保持|one_screen_layout_test LY04 reward/failed save; b04_reward_store_test/b04_review_regressions_test（受控运输，非真实广告）|未验|
|P19|设置|恢复针织分组面板，透明Material承载真实开关，操作间隔8px|page-layout-inventory.json / P19; b05_accessibility_test/offline_ui_test|未验|
|P20|隐私|统一奶油主题，保留独立Analytics/Crash与真实SDK状态；无自造ATT|page-layout-inventory.json / P20; b05_accessibility_test/b04_ui_test（非真实UMP表单验收）|未验|
|P21|重置|主题一致，Keep progress优先及保留设置/隐私不变|page-layout-inventory.json / P21; offline_ui_test/offline_store_test|未验|

## 主要变体

|页|变体|范围与证据|实际画面|
|---|---|---|---|
|P02|普通继续/重玩/全通/今日已完成|offline_ui_test; page_transitions_test|未验|
|P05|四/五/六/七瓶×五尺寸×1.0/1.3/1.5/2.0字号|one_screen_layout_test LY04; one_screen_geometry_test|未验|
|P05|失败Retry/Stay、恢复、容量与跨行倒水|one_screen_layout_test LY04 failed save; offline_ui_test; flame_full_board_widget_test; flame_geometry_test|未验|
|P07|搜索/取消/建议/超时/已证无解/过期|LY04 hint/LY-R02 hint UI; offline_controller_test/hint_worker_test覆盖取消/超时/过期；已证无解文案本批仅源码复查，未新跑纯核心求解测试|未验|
|P10|普通/拼片/20或40章完/60最终/每日/重玩/七瓶|LY03 matrix; offline_ui_test; completion_presentation_test|未验|
|P10|保存中/失败/回执Retry/恢复不重复奖|LY03 failed completion; completion_presentation_test; offline_store_test/controller_test|未验|
|P11|首次揭示/重访/章完/最终|LY03 reward/reward-final; b03_collection_design_test; offline_ui_test|未验|
|P14|今日未开/进行中/完成/旧日/替换/历史未来只读|offline_ui_test; offline_controller_test|未验|
|P17-P18|无库存/冷却/额度已用/确认待保存/迟到原局恢复|b04_ui_test/b04_services_test/b04_reward_store_test/b04_review_regressions_test; 真实广告暂停，不能当SDK运行通过|未验|
|all|出入页/系统返回/独立滚动策略|page_transitions_test; motion_polish_test; LY-R04 saved result|未验|

自动尺寸：320×568(top20)、375×667(top20)、390×844(top47/bottom34)、430×932(top59/bottom34)、360×640(top24/bottom24)；核心与结算1.0/1.3/1.5/2.0。逐页新inventory为320/390/430×1.0/2.0，使用真实90题目录、加载Nunito、真实SQLite，且不引入工程场景。它调用生产PourluneApp组件，但**不是原生正常main启动证明**。

P08仍采用内联无移动反馈，P20仍使用真实可滚动隐私表单，不能声称逐像素复刻原图或完整SDK原生表单通过。全部页面均需父实际看过修复效果后才能验收；受限采集不可重试/绕过，未产生新候选。
