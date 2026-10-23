# 权属差额：只问两组，不重问每个文件

继承runtime/manifest.json的23图及runtime/ui/manifest.json的10图，全部保持UNCONFIRMED，不刷新任何原资源清单。rights-original-groups.json给原图路径/hash及使用证据；这里只把实际依赖收敛为两个确认问题。

1. **原视觉来源组**：Pourlune_Design_Pack/boards/00_Approved_Style_Reference.png、01_Entry_and_Chapters.png、02_Tutorial_Play_Pause.png、04_Win_and_Collection.png、05_Scene_and_Daily.png。它们是当前瓶/背景/三场景/图标/UI字标/框/纹理/日历/成功图的实际参考或裁剪来源。请一次说明原图是自有创作、委托授权还是其他来源，并提供能覆盖商业App、修改/派生和商店宣传使用的依据；同一作者/授权可合并证明，不要求逐PNG重复。原包其他页并非本批认定全部商用依赖；03_Hint_and_Recovery等旧原型裁片不是已打包正式资源，仅有旧原型证据不升级为当前阻塞。
2. **派生生成/裁剪组**：B03的23张（22运行art＋品牌源）、B03-R01的7张reference-derived生成UI和3张原图texture crop；各自prompt/reference/output/hash已在原manifest/其generation records记录。请确认生成工具和适用账号/条款允许上述商业/宣传使用，且原图授权允许这种派生。Codex/ImageGen执行记录证明来源，不证明账号套餐和商业条款；视觉验收也不能代替权属。

已由开发直接附据、不再要求用户重新证明的部分：

- **Nunito**：docs/design/production-candidates/fonts/nunito/source.json固定Google Fonts原始URL/blob/hash，OFL.txt是SIL Open Font License1.1；app/assets/fonts/nunito/保留OFL与元数据，字体/授权逐字节核对见delivery-checks.json。允许按该许可随App打包，保留版权/许可，不单独售卖字体或错误转授权；不把字体许可当图像许可。
- **6份WAV**：audio/AUDIO-AUTHORING.md及tools/assets/audio_generate.py记录纯数学波形/包络/stdlib seeded noise，无第三方录音/采样/旋律来源；B03授权制作，app副本与候选逐字节检查。无需去买额外音乐授权；设备听感/音触觉仍是运行验收，未由数字检查代替，也不作各法域人类作者版权结论。
- **依赖许可**：BR05真实AAB的base/assets/flutter_assets/NOTICES.Z（解压hash和1634组license headers见dependency-notice-index.json）包含Flutter/Dart及第三方包通知；原生SDK隐私/版本见BR01原生清单。已有Licenses UI由框架提供。MIT/BSD/Apache/OFL等通知的存在是履行依据，不宣称包内所有原生条款已完成律师审查。保留现有通知/SDK terms，不新引库、不将其用于覆盖图像权属。

本次实质增量是把“所有素材证明”缩小到5张实际原图的一组授权＋派生生成/裁剪的一组适用依据。没有为网站引入任何游戏图、字体或第三方媒体，公开网站不等待图像权属；App与商店宣传仍保留这两组缺口。
