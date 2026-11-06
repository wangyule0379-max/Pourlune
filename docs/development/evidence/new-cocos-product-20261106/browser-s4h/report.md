# S4h 取消广告加载回归 · 2026-11-07

4199/qa/cancelled-ad.html，冻结 s4h-cancelled-ad-selftest-1；全部HTTP和广告回调为模拟，不代表真实Google或服务端。

Not Now→Play→Pause→Extra→Watch出现Finding a moment（loads1/shows0）→Cancel→Keep playing→Settings。工具Deliver cancelled load failure两次后仍在Settings，无广告提示；计数loads1/shows0/delivered failures2/intercepted POST0（late-failure-settings.jpg）。Back回首关原盘，瓶1→4为1 move，Undo回0；console error/warning为空。

未人工验证durable prepare等待中的取消窗口、真实SDK/网络或设备。

## 旧奖励到达第二次加载期间

冻结 s4h-cancelled-ad-selftest-2，4199/qa/reward-during-load.html，模拟广告及模拟时钟。首次Watch展示后Close without reward→Keep playing；工具推进模拟181秒，再次Watch停在加载，计数loads2/shows1。递送旧reward显示一瓶已保存；再递送第二次loaded及重复reward，仍loads2/shows1/POST0（reward-during-load.jpg）。Keep playing后六瓶，瓶1→4为1手，Undo回0且仍六瓶；console error/warning为空。模拟181秒不是实际冷却计时验证，未测真实GMA/后台及durable prepare取消窗口。
