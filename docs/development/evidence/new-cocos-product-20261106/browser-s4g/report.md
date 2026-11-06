# S4g 发布配置隔离冒烟 · 2026-11-07

4199/qa/release-smoke.html，冻结web s4g-release-config-selftest-2；mock native目标、服务HTTP受控拦截，非生产网络验收。

- case=qa：Not Now→Play，瓶1→4实际1 move；Pause→Resume保留盘。工具显示 intercepted QA 1 / production 0 / POST 0；浏览器捕获 error/warning为空（qa-resume.jpg）。
- case=wrong：故意生产服务标记配QA身份，工具显示 QA 0 / production 0 / POST 0；Not Now→Play，瓶1→4实际1 move，Undo可用（wrong-one-move.jpg），捕获 error/warning为空。

仅隔离模拟目标及拦截计数，不代表真实服务连通、原生部署或生产上报通过。
