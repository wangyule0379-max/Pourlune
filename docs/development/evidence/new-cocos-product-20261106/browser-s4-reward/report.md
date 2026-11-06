# S4 受控奖励浏览器自测 · 2026-11-06

冻结候选 s4c-reward-selftest-1；开发提供 manifest SHA-256 587f5876511b7dea15b5232d7cdf3275ab838c2d21b33373d431b4255563a1aa，本次未独立核包。4199/qa/rewards.html，独立QA库、规则重放检查点及受控确认回执；不是AdMob回调，也不是自然用户通关。

390×844及320×568截图显示Level1/16/39/61/100分别6/11/12/14/15个瓶与收集器（fixture-snapshots.json）；人工复看小屏和大屏未见瓶体、收集器目标与操作栏重叠。未逐个在两尺寸点击每只瓶。

Level1真实Hint箭头指瓶1→4，按提示倒后1手；重开确认后仍6瓶，重新倒一手Undo回0。Level16瓶2→固定收集器，11/12→完成（17 moves）。Level39瓶9→11实际满蓝开罩，Undo恢复罩与4 moves；刷新Continue仍12瓶同盘，随后Undo可回3 moves。Level61小屏瓶10→收集器4/16→7/16，1 move。Level100瓶3→9实际最终一步，52 moves进入100/100结算。截图位于同目录。

浏览器error/warning为空。Hint/重开/刷新Undo只在上述代表关实际验证，未逐个组合全部关卡及尺寸；无native广告入口/真实广告SDK、真机或性能验收。
