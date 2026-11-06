# S5 受控插屏浏览器自测 · 2026-11-07

4199/qa/fullscreen.html，冻结s5-fullscreen-selftest-2，三个独立QA库；模拟广告与网络，不等于真实native SDK、后台或自然通关。

- ready：13末手瓶5→收集器，完成27手；Next前requests1/shows0，Next后requests1/shows1/overlay true。工具Background→Real close input后overlay false但等待页仍在，Foreground后Level14。Pause→Extra→Watch显示No ad right now，requests仍1/shows1；未测完整180秒结束。
- late：13同样末手完成，Next直接Level14，requests1/shows0；Deliver late inventory后仍Level14、shows0/overlay false。
- protected：20末手瓶4→6完成20手；关卡及结算时requests0/shows0。Next进入Level21后显示requests1/shows0/overlay false。若要求跨入21后仍无任何load，与预期不符；是否21预取需开发核对。
- 相关截图ready-show.jpg、late-delivered.jpg、protected-21.jpg；console error/warning为空。QA工具栏覆盖区域不评安全区。

## 保护关策略澄清

开发方核对源码及旧 PRD 6.4：保护的是第20关结算后不展示插屏；进入第21关后的1次请求是为未来第21关首通预加载。原始观察保持不变：第20关及结算时0请求/0展示，Next后第21关1请求/0展示；本次没有展示插屏。此前“整个过程无load”的操作预期过严，此计数不按失败处理。
