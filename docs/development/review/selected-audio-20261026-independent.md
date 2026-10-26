# 已选音频接入独立复核 — 2026-10-26

结论：素材身份、授权署名、正常入口音频接线及本批播放证据通过，可留专用测试版给本人试听；不等于主观听感或新商店包通过。

父逐字节核 Dream Culture 客户端 MP3 与已下载官方完整源一致（SHA f12cbb52…，8,576,659字节），未换曲/截音乐；运行背景音量0.12。Pouring Water 客户端 PCM 与指定HQ来源的处理记录/候选SHA da8b211c…一致，2秒/44100Hz/16bit/mono，截1.2–3.2秒、16ms边缘淡化、原速原调，循环仅在出水期间。app/assets/audio/ATTRIBUTION.txt含两作者、来源、CC BY4.0/CC0链接和实际编辑说明；main.dart已注册至既有Licenses页面。独立记录见 evidence/selected-audio-20261026/parent-assets-independent.json。

父阅读正常入口差额：main的GameFeedback.pour不再提前播放；GameScreen→BoardPage→BoardView→FlameBoardGame传实际出水起止回调，原290ms靠近/对齐无水声，flow/drain结束与取消均停止；小/大量与减少动态按当前动画收束。finishEffect同步推进revision，旧排队水声不能在结束后才开始；背景音与四个其他音效保留。audio_generate/verify已改为4原创+2已选资源，保护选定音频不被合成覆盖。

已读作者25项聚焦、最终8项出水/取消/减少动态、27资源工具检查及分析通过记录；原生独立256788BA测试记录两文件实际解码、seek近尾后的回绕/继续前进，以及pause/stop。Darwin循环时Dart completed事件不能单独判停，改以原生位置验证与固定SDK源码相符。父未重跑工具链，未录到或亲耳听到扬声器输出，不能声称已独立听过最终混音或无可闻循环接缝。

作者已把正常lib/main.dart、selected_audio.sqlite、ads disabled/Firebase none装入专用256788BA。镜像视口/教程Step2有未归属变化，父没有输入；保留状态给本人，不重置、不把额外动作算成作者验收。Licenses实际页面尚待现成截图，源码与随包文本已经核，不为这一点重新构建/操作竞争设备。Android原生试听本批未做；无新商店上传。F9/D79未动。

## 最终交付补核

开发提交 d8d7d00 已交付。父逐项核 source-and-build.json 的12个运行源文件和实际 app/build/ios/iphonesimulator/Runner.app 内7个音频/署名文件，19项SHA一致；实际包身份 dev.pourlune.admobResumeValidation，旧background.wav已移除。正常main已运行的事实与所验包相符，保留上文主观听感/未归属输入边界；无需重做本批检查。
