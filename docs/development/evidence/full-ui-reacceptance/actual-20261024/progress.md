# 2026-10-24 当前实际验收与 build10 准备

用户已明确解除专用测试设备截图/录屏重试限制，F9及其窗口继续完全保护。原开发按本人授权接手实际验收到TestFlight；下面历史“等待采集授权/视觉0页”已被本节取代。没有操作F9，没有修改TLS/代理、安全设置或普通用户库。

当前正常lib/main.dart在三台专用iOS模拟器上实际运行：常见手机255890D5、小屏375×667 FC9E05C9、大屏440×956 3D88FCFE；身份dev.pourlune.layoutValidation、full_ui_parent.sqlite、Firebase none、ads disabled。逐页P01–P21对原稿观察，独立reviewer实际查看65张图及七原稿，主要Critical/Important全部关闭，可进入精确CI/签名核包。P16/P17只核广告关闭说明/不可用合并状态；P18为明确受控七瓶权益，不是SDK奖励证明。详细[实际矩阵](actual-page-matrix.json)和[独立报告](../../../review/actual-ui-independent-20261024.md)。末条Bottle added文案也已获独立新图复核，528项最终冻结无漂移。

本轮修复：暂停透明Dialog继承外边框；普通手机提示理由裁切；小屏1.65×提示挤掉底排容量（按真实14px辅助按钮字体判换行，瓶子/flight几何不改）；P15今日直接Replay且不重发stamp/进度/拼片；P09 Keep playing主操作；失败SaveFailureNotice移出旧offset的滚动区，使Retry/Stay固定可见。最后补已获七瓶的Bottle added+check文案，原广告/奖励门控不改。

实际连续提示发现level13旧DFS在4→3/3→4循环，新增连续至通关回归先RED。最终使用有界A*：标准库SplayTreeMap，未锚定颜色组合法下界，固定目标保位置，仅无标签缓冲归一，best-g替换open；出队goal后返回最短剩余路径首步。2秒/50000预算、isolate取消、实例/revision/generation过期门控保留；没有扩大预算或套用参考解。中间BFS在extra预算失败已弃用，日志保留。

实际八代表13/20/21/28/40/41/53/60从初盘完成114次提示后手动目标点击，步数17/13/13/14/15/14/14/14，全部真实SQLite回执；20→21、40→41实际Continue衔接。其他此前进度仅隔离库明确seed，不能称自然全60首玩。独立reviewer按记录重放114动作，无重复盘面且与8份SQL收据完全一致。实际每日完成后Replay新实例、单stamp、不重奖；失败Home被拦→Stay→Retry→同安装SIGKILL/重开恢复已保存move1。原QA库已备份并恢复，小屏系统字号恢复large。

本轮实际检查（日志在actual-20261024/checks/）：完整核心38通过，含八代表有/无extra连续提示、90初/中、60四位置、旧非空及独立188有序盘BFS最短距离oracle；完整应用280通过；build工具Python57通过；app130/core14格式无变化；analyze clean；正常main原生build/install成功。文案差额后51相关UI/广告/布局回归、静态分析和build10原生重建/安装通过，已实际核对Bottle added+check；Settings实际AX读到0.5.0(10)。未改依赖与锁。设置进退/帮助/隐私有36.76秒原生录像，1103个30fps精确时刻抽帧、36个明显变化帧联系图，实际未见纹理损坏；不外推全帧或设备性能。

当前Apple会话可用，实际iOS构建及上传列表仅0.5.0(9)，已选择下一0.5.0+10；旧build5–9冻结。新版本尚未签名/上传，精确CI、签名核包、Apple处理及本人组可安装分别待完成，不重邀已有本人。Play/AdMob继续暂停。真机安装升级/音触觉/性能、人类首次难度、美术商业权属及真实广告仍未验，内部Beta不等于公开商店发布通过。

---

