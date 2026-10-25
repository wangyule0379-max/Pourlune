# LY 一屏布局独立验收

2026-10-23：**LY01–LY05与LY06本地交付范围通过，LY-R01/R02/R03/R04关闭。可提交本次实现；精确远端CI、新版本签名候选与商店提交另行跟进，尚不标商店通过。**

## 用户要求与结论

正常字号1.0/1.3、五种手机视口及安全区覆盖下，4–7瓶、标签/容量、可用Extra bottle、Undo/Hint/Restart均在首屏，不靠拖动发现主要操作；七瓶同尺寸且交互目标至少48逻辑像素。普通、拼片、章节、最终、每日、重玩及Reward/Reward-final的主要按钮完整可见且可命中。正常字号必要保存/章节/场景结果首屏完整；最终长故事和大字号说明允许局部滚动，主要操作固定。

架构读取实际源码、真实日志、独立探针，并亲自操作自动化正常main原生路径。受既有采集权限限制，本批没有新增人工截图/录像审美验收；bounds/点击/语义与键盘验证不冒充人工视觉、读屏实听或真机性能。受保护F9设备及窗口未操作。

## 精确来源与独立验证

- 最终192生产/资源/依赖集合：`6260033bed815e271c6e8de32d4d06781c05823226a3dbbb3c2baf537d2cadf3`，与UI独立R04冻结一致。含QA的194逐文件SHA重新核对无漂移，见final-native-source.json。
- 最终QA：`e17380cf95249919535ae4b5ba49fd5ecfd7fbb998cf32b84e731f6aae32897f`。双端实际命令均exit0、outer_timeout=false、显式ads disabled、无Firebase生产配置/调试scenario。
- UI隔离副本27/27：2495必要bounds观察零裁切，五viewport/真实Nunito、七瓶八种结算变体、Cancel/Skip初始及局部滚动后固定/真实激活、键盘Enter/Space/语义/禁用；另R04独立2/2、40帧保留旧页的布局/输入/焦点/语义隔离通过。父已读完整report与精确源对应。
- 功能隔离19项通过：4新保存失败Retry/Stay与同Flame生命周期、3hint身份/过期、12反馈；17命令日志hash核对。源码不更改规则、事务、奖励/广告门控。
- 父修复Host：38布局通过；四文件组合56通过+1新增浮点精确比较测试失败，改该断言为1e-9容差后几何2/2通过；R04先RED0/2、修后布局/转场48/48。完整analyze无问题，最终QA analyze无问题，最终lib/test/integration_test/test_driver 125文件format零变更。UI manifest真实check通过，像素和资源未改；父首次两种Python环境缺Pillow属工具环境失败，改用已有bundled依赖运行，未装包/刷新清单。

|平台|最终实际运行|首屏与保存结论|
|---|---|---|
|iOS独立模拟器255890|14阶段，exit0，总95.82秒；402×874，上62/下34|零SafeArea/48目标违规；正常main真实1–4/拼片/Next，七瓶实际手势完成，章节20/最终60受控已保存结果入口；SQLite同进程重开一致|
|Android独立5590|14阶段，exit0，总62.72秒；411.43×914.29，上51.81/下24|相同14阶段及零违规；相同最终生产与QA源码|

总时间含构建/连接/操作，不是启动或性能指标。完整报告及二次运算在ios/android-final-report.json、final-audit.json；原生只覆盖字号1.0，其他字号/全部变体是独立Host证据。七瓶10为明确extra entitlement QA状态，不是真实广告发奖；20/60为纯规则参考解+真实SQLite settle受控存档，通过Home saved-result进入，不冒充自然闯关。真实七瓶Next另外断言board、第11关、新instance。此次恢复仅同进程SQLite关闭重开，不新增SIGKILL证据；旧FB同安装SIGKILL仍属历史已验范围。

iOS构建bundle为dev.pourlune.layoutValidation，Runner哈希已保存；flutter test退出后已移除本测试安装，未伪称取得安装后hash。Android最终APK哈希已保存。上述均是QA二进制，正式release包需新构建与独立签名/来源核验。

## 缺陷关闭与失败保留

- LY-R01：整页滚动与冗余高度改为可用高度布局、固定主要操作、紧凑只读结果预览。初始Level10首屏RED及原开发73项通过属前序证据。
- LY-R02：Cancel/Skip从多行说明滚动区分离，同高固定至少48；真实2.0裁切及1.5滚动丢失的RED保留，独立复验通过。
- LY-R03：只读4–7瓶正常字号改为单行紧凑预览，必要场景/保存信息优先，结算按钮保持可读16字号与48目标。交互棋盘未缩成只读尺寸。
- LY-R04：最终原生新增Home→saved-result暴露109px溢出；保留出页LayoutBuilder错误读取实时页面类型。捕获当次renderedPage，仅固定旧页布局策略，保持转场及隔离，独立逐帧复验通过。
- QA就绪：背景音乐FramePositionUpdater持续请求帧使global pumpAndSettle条件无效，改为25秒有界业务/路由/Flame实际就绪；未关闭音乐/改SDK/削弱业务断言。
- QA拆卸：旧版iOS14阶段报告passed但最终exit1、2音频frame callbacks残留。原因Bootstrap异步audio.dispose与DB关闭独立；QA卸载后等待同一幂等dispose Future再结束，保留25秒超时和框架残留检查。UI只读独立复核通过；修后双端整体exit0。ios-teardown-red与Android修前成功记录完整保留，未用阶段报告掩盖失败。

源与命令、测试/诊断误用、历史失败均保留在本证据目录及one-screen-independent。无错误吞掉、SDK修改、盲增sleep、权限绕过；父修复均有另一聊天独立审查。过程旧状态见acceptance-working-history.md，不代表最终结论。

## 下一阶段

精准提交本次生产/QA及必要记录，跟踪新精确CI；通过后使用已有Apple profile与BR05 upload key生成新版本目的地候选，旧0.5.0+6冻结。逐包验证来源/身份/资源/签名/符号后按已有授权推进TestFlight与Play closed。13+目标、仅本人首测、ChatGPT生成原图来源已记录；商店实际必填未知事实不得猜，协议不代签。真机分发后测试、音触觉/读屏/性能与商店接受状态仍未通过。

实现已精准提交推送`cd335efc5d293549d97a4b6c44420e605b665297`；新精确CI39928698433正在运行，iOS与tests-and-android均in_progress。唯一CLI明确交还原开发，其已接收BR08，当前只读准备，green后新候选核包再分发。跟踪文档提交不要求额外CI。

最终远端CI：39928698433已于2026-10-23T09:09:22Z completed/success，精确head cd335efc5d293549d97a4b6c44420e605b665297，父通过GitHub连接器独立回读ios-build和tests-and-android均success；remote-ci-final.json已保存，禁止重复查询。已明确通知原开发进入BR08新签名候选；新包/商店提交尚未通过。
