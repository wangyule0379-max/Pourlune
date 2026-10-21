# B03 Flutter实际画面复查

执行方自查，非独立验收。2026-10-22，iOS26.5同一模拟器；所有图由实际Flutter RepaintBoundary或普通App simctl截图取得，不是图像工具合成界面。`native-runtime/runtime.json`逐图记录页面/实例/修订/尺寸/设置/QA输入；流程运行6:01通过。校准测试另7秒通过，受控组件不声称奖励或真人玩过。

- 瓶0/1/2/3/4、混色、满但错标签：`native-gallery-empty-1-2-3-4-mixed-mismatch.png`。实际标签、刻度、圆角clip、单一顶面光、连续前层高光和原生形状可见；暖浅色背景上空瓶仍可辨。液体不从针织框边漏出。源PNG低alpha散点原样保留，已记录，不做“已完美抠图”承诺。
- 6瓶3+3、7瓶4+3：`native-gallery-{six,seven}-320-text2x.png`，自动读取两者width66/height184相同，第四列也≥48触区；第二行居中。第7瓶是明确受控核心权益seed，非真实广告奖励。
- 实际main60在320宽/2x/减少动态下操作：`narrow320-text2x-reduced-{real-board,after-pour}.png`。按钮自动换行、纵向滚动可达，字体不溢出。截图可能位于滚动后的棋盘视口，顶部ID在AppBar下方是滚动裁切，不是初始页面缺失。图形标签尺寸固定，读屏完整语义另有自动测试；未做真人读屏播报。
- 正常动画350ms实际原生帧：初版`main012-native-mid-pour-stream.png`发现源瓶口被后绘制的静止瓶遮挡。新增foreground回归先得到有效失败，再将移动源瓶提为Stack最后绘制。`motion-foreground-green.log`9项通过，仍只保留4个瓶控件；全79回归通过。最终`calibrated/main012-foreground-pour.png`显示完整瓶口在前景、流连接目标、液面水平；业务已完整提交，动画结束不发奖。受控截图与真正App生命周期snap/保存证据分别记录。
- 首页/日历短内容背景接缝由SizedBox.expand修正；`default-welcome.png`及后续正式UI已填满body。背景独立图层，文字、按钮与日历仍为真实控件。

## 18场景组合与15里程碑

最初真实GameScreen/ScenePage逐场景0～5全18状态、各15个milestone奖励页截图在 `native-runtime/scene-*-progress-{0..5}{,-composition}.png`、`milestone-*-reward.png`。每4关真实核心胜利及SQLite事务后才拥有新层，非仅切换数字；事件核对15唯一pieces和18个scene_progress。ColorStudio1～5为Window/Desk&paint/Stool/Plant/Table，保持原映射。

逐图查看全部18组合：Studio0–4各物件落点/遮挡正常；5号边桌初版脚接近地台边界，向上.04画布。Garden0–4正常；5号茶具初版悬在桌后，y .43→.49后茶托位于桌面。Seaside0–1正常；2号棚脚下移.015与码头接触，3号救生圈向岸内移，4号盆栽移开救生圈上缘，5号海鸥从海面移动到右后柱头（Rect .62/.40/.18/.24）。图像像素不改，只校准运行摆放。

最终校准后再原生渲染全部18组合至 `native-runtime/calibrated/{color_studio,garden_nook,seaside_corner}-{0..5}.png`，另3个full-ui与前景倒水，共22张。查看三套最终5层与海边2/3/4中间态，确认茶托/柱头接触和物件间遮挡；未变几何的0–4沿用前次逐态检查。物件未碰画布裁切边界，新增层不会替换原有层，环境底图不当作奖励。首页/列表/详情共用SceneArt；scene_art_test还验证非前缀拥有ID只展示真实层。

这些图像仍是参考风格的候选；小透明边缘散点和生成纹理尚可由独立视觉验收进一步评价。自查通过不替代独立报告、物理设备表现、商业权属确认或真人难度/听感评估。

最终质量修复补充：初次foreground图之后复核发现倾斜可见液量与系统Reduce Motion问题，已按有效RED→GREEN修复。最新calibrated覆盖图共29张：midpour剩余各色段可见，系统低动态无位移／流；像素覆盖测试25姿态另验证面积，不以肉眼代替。主线／每日／重玩标题中间帧与结束帧是同一CompletionPage受控组件；真实普通App绿色主题页另见manual-final-completion.png。3项Important已修，逐单位形状Minor仍待独立视觉判断。
