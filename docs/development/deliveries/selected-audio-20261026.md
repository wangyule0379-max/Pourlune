# 已选音频接入 — 2026-10-26

## 改动与边界

按已确认规格接入 Dream Culture（Kevin MacLeod，CC BY4.0）完整原始MP3，源文件SHA256与运行复制一致，原生测得214360ms，音乐线性音量0.12、整曲循环。水声取 edschaefer 的官方HQ MP3（CC0，并非无损WAV）实际解码，取1.2–3.2秒稳定片段，mono44100Hz PCM16、16ms余弦首尾淡化、峰值归一0.24；运行音量0.65、自然音高，不变速。保留select/error/win/reveal四个原始WAV逐字节不变。旧合成背景从App资源移除，历史候选原文件保留。

正常main不再在GameFeedback.pour刚提交动作时响水声。生产FlameBoardGame在既有动画的290ms出水起点调用开始，在flow结束或取消/后台/移除时调用结束；短长倒水沿原有geometry时长，减少动态沿既有120ms短流程。两个回调经现有BoardPage/BoardView和大字后备路径转给GameAudio；未改动画、业务提交、棋盘、存档或广告策略。GameAudio.finishEffect使旧排队请求失效，慢解码不得在出水结束后才开始水声；暂停/后台/禁音沿用已有同步门控和停止处理。

既有LicenseRegistry增加Dream Culture/Pouring Water，加载app/assets/audio/ATTRIBUTION.txt，含作者、来源、CC BY4/CC0链接及实际编辑/播放处理说明。audio_generate现在只生成四个原效果；选定两文件按冻结hash/运行副本验证，生成命令不能写入/覆盖所选音乐或水声。audio_verify逐个解码5个PCM，MP3只核原文件hash/复制，真正MP3解码与循环另由原生检查证明。复现记录在production-candidates/audio-selected-20261026/runtime/。

## 实际检查

- 红→绿：原GameAudio在出水结束后仍执行排队pour，新增回归实际失败后修复；新BoardView回调测试先确认未支持，接入后通过。
- app/ 聚焦audio＋Flame原生按钮/控制器共25项通过；补齐普通/减少动态、1和4单位、结束/后台分支的8项真实Flame检查通过。各分支停止只有一次，前进/回落阶段无水声开始。
- app/ 改动9项分析无问题，最终新增/修改测试两项再次分析无问题。未跑无关全量矩阵。
- audio_generate --check、audio_verify通过；使用已带Pillow的bundled Python运行assets单元27项通过。项目venv缺Pillow首次导入失败已明确改用既有bundled runtime，未安装依赖或刷新视觉清单。
- 专用256788BA、dev.pourlune.admobResumeValidation，实际audioplayers Darwin原生检查：6素材解码/播放/暂停/停止通过；水声2000ms，音乐214360ms。尾前250ms起播放，700ms后位置分别回绕到265/336ms，随后200ms内继续前进>50ms，证明真正循环；不只检查设置值。
- 首次原生检查因循环尾端Dart PlayerState.completed失败；读固定audioplayers6.8.1/Darwin6.5.0发现其循环也发送onComplete，原生底层会seek0/resume。改成上述直接原生位置验证后通过；未改/升级SDK，没有把失败掩成播放器修复。
- 正常lib/main.dart无scenario构建46.6s成功；包内七个音频/署名文件核同字节、旧background.wav不存在、无Firebase plist、独立身份正确。装到同一个独立QA，使用新selected_audio.sqlite，广告disabled，已启动普通Welcome/教程入口；正常入口实际操作/署名可见性由后续独立验收补记。

## 试听与未验

正常入口已留在Pourlune AdMob Resume QA（256788BA），本机镜像http://localhost:3200/。当前main001教程Step2；视口变化及首步不是本轮输入所为，已停止进一步QA输入并请父协调，避免与本人操作冲突。F9/D79及其窗口/库未动。原始控制台/原生检查日志在ignored .superpowers/sdd/2026-10-26-admob-resume/，可审摘要在evidence/selected-audio-20261026/。

原生解码/位置与策略检查不等于人类主观听感、外放音量或物理手机/静音拨片验收；尚不声称这些通过。安卓本批未跑；未上传新商店包、未改TestFlight15冻结候选。最终通过以父的独立报告为准。
