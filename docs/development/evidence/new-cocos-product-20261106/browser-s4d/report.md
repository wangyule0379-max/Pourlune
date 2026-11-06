# S4d 迁移与受控音效端口 · 2026-11-06

4199/qa/migration-effects.html，冻结web s4d-migration-effects-selftest-2，开发提供manifest SHA-256 8ddfb6dedfa68b544514f549671d6b5b799c87a29ef79232c1cde3b535e8d839；未独立核包。QA页面明确 CONTROLLED NATIVE PORTS — NOT HARDWARE，三个case使用独立QA库。

- present首次 Legacy reads 1；首页0/100、Play Level1；Settings music on、sound off、haptics on、reduced on、analytics Not allowed。实际倒1手后设music off/sound on/haptics off；Back保留1手。刷新 Legacy reads 0，设置保留，Continue恢复同1手，Undo回0。
- 受控music request：进入游戏true、Pause false、返回true；Audio interrupt false且输入禁用，resume true且可用；Settings false。仅命令状态，不证明实际音频/震动，也未独立捕获旧pour音频是否重播或慢Hint中断。
- 320支持页滚动到底：邮箱、mailto、网站及复制按钮可见；复制操作返回 Could not copy 并显示邮箱fallback（320-support-bottom.jpg）。未打开外部网站或邮件客户端。Credits展示Dream Culture、Kevin MacLeod、CC BY4.0及其他授权，底部Back可见（320-credits.jpg）。
- missing首次Play出现未选择隐私弹层；error直接显示Could not read your previous save及Retry，无新用户Play，Retry后错误仍在（320-read-error.jpg）。
- 控制台抓取error/warning见当次工具输出；未测原生硬件、真实旧SQLite、外部链接跳转、性能或真实广告。
