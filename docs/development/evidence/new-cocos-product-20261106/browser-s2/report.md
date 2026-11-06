# S2 浏览器首查 · 2026-11-06

Chrome，390×844，独立 http://127.0.0.1:4197/，首页0/100。Play → Read the full privacy notice → Back 返回选择弹层 → Close。Level 1 瓶阵正确渲染，但超过4.5秒后五瓶、Pause、Settings、Hint、Restart均显示 disabled，点击瓶1无变化，0 moves。浏览器捕获 error/warning 为空。截图 390-home.jpg、390-disabled-after-close.jpg。版本身份：页面本地 build 0.1；精确源码提交/构建hash未核验。

此阻断发生在首次隐私选择关闭分支，未完成 Not Now/刷新、正常倒水/Undo/Hint/暂停/通关与320布局。未用模拟器或旧站点，未接真实广告/统计。等待开发修复后针对性复验。

## 修复后定向复验 · 2026-11-06

普通刷新原4197数据后，Settings为 Analytics Not allowed；Continue→Level1瓶子及控制可用。瓶1→4为1 move，Undo恢复0；Pause→Resume可用。1手时Restart→Keep Playing保留1手，Restart→确认回初始0。真实Hint快速返回箭头，未能及时捕获真实搜索取消。

首关实际九手完成→Next进入2；2关瓶1→4一手→Home→Levels重玩1关实际九手→Next，2关同瓶阵1 move；刷新→Continue仍同一手，Undo恢复0。独立IAB新玩家Play→Not Now可操作，倒一手后刷新→Continue无再次询问且恢复一手。

320×568截图 320-home-fixed.jpg、320-level2-resume.jpg；390×844 390-level2-fixed.jpg。控制台error/warning为空（此次标签）。关键本地文件SHA-256：index.html dcef78f082eb80fba67dfa842b8d8d84ed30c505880345dfbccdaac199631beb；game-bridge.js 22a53577bd5b79f0d68a452beb9ca0977badcb44bf724105cf8eb4ad5a4f574a；game/src/game.js b32fda93afbc29181308ed149992da0b5c35b5908edb3e7733dfe1ac0b13b9fb。目录未跟踪，以上为复验结束时文件身份，并非完整构建哈希。

未验证慢搜索取消、全量外围、真机/性能、真实广告或统计SDK。初始阻断截图保留，不与修复后结果混同。

## 隔离 QA 真实事务中止

4198/qa，独立 QA 数据库；Play→Not Now→瓶1到4正常保存1手。点击 QA “Abort next save after put success”，瓶2到4后 QA 显示 Aborted after put success，玩家界面显示 Not saved yet / Save transaction aborted（qa-real-abort.jpg）。Stay 后显示未保存横幅；分别点击画面瓶子及暂停位置，未离开或改变界面。Retry 后2手完整瓶阵恢复，约2秒后输入和Undo可用。刷新→Continue，仍2 moves、瓶1青紫青、瓶2橙紫橙、瓶3橙青青橙、瓶4紫紫、瓶5空；Undo回1手并恢复瓶2原四层、瓶4一层（qa-retry-undo.jpg）。QA按钮为故障注入工具，不是玩家UI。未验证全部导航或真实设备故障。

## 加载失败恢复边界

当前浏览器接口未提供按标签、单次拦截本地引擎请求的能力；未改动资源或网络配置，也未在运行中注入加载失败。父界面 Couldn’t open the garden → Retry 的真实运行时路径因此未验证；开发方报告自动 handler 回归覆盖，不能将其当作本次浏览器实测。

## 隔离 QA 引擎加载故障

4199/qa：先首关瓶1→4保存1手，再点击 QA “Fail next local engine load”。刷新后父页面显示 Couldn’t open the garden 和 Retry（qa-engine-503.jpg）；点 Retry 后回首页，Continue 恢复相同1手瓶阵，Undo回初始0步（qa-engine-retry-undo.jpg）。故障按钮据QA设计令下一次 CCBoot.js 返回503，Retry 后引擎实际可运行；本浏览器日志接口未返回HTTP状态明细，故没有独立网络面板证据确认各次503/200。console捕获error/warning为空。QA工具非玩家包，未更改4197或4198数据。
