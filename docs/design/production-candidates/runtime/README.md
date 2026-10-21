# B03 运行美术候选

`manifest.json` 固定23张独立PNG：瓶后/前/阴影3张、游戏背景1张、三场景各底图＋5物件18张、品牌源图1张。22张场景/瓶/背景在 `app/assets/art/` 有逐字节一致副本；图标源图经标准尺寸导出到平台目录，记录见 `docs/development/evidence/B03/platform-icons.json`。原稿不修改，图像未做自动抠图或像素修补。生成输出的透明区包含少量alpha≤8散点，原样保留；工具检查不等于视觉验收。

所有图像为以用户提供的原视觉作对照的ImageGen候选，原视觉的商业使用权未确认，不写成已获商用授权。精确提示词、参考路径、原生成文件、SHA256、尺寸/格式/alpha及原稿hash在manifest及其引用记录中。Nunito/OFL和原创合成WAV在相邻 `fonts/`、`audio/` 独立记录，不能用其授权覆盖图像来源。

## 瓶体与逻辑绘制

`app/lib/presentation/bottle.dart` 是逻辑几何权威，`board_page.dart` 是运动/瓶口连接权威。每个按钮184高，瓶图148高，固定标签36高；瓶图框左偏−.15W、宽1.3W，素材透明边界保留。前层下移148×.0130208。液体窗口在按钮瓶图框x=.24W～.76W、y=.32H～.86H；clip圆角.08W，容量4，每单位占窗口高度的1/4。后层在液体下、前层高光在液体上；阴影单独层opacity .4。无预烘液体或目标标签。

瓶口锚点逻辑坐标(W/2,24)，旋转枢轴(W/2,84)，移动时由board_page同一变换连接源瓶口和目标瓶口。源/目标当前业务状态始终是完整新棋盘；fractional bands只控制表现。反向旋转液体保持屏幕水平，动画令牌结束仅解除表现锁；不在动画回调中存档或发奖。正常900ms、减少动态180ms；暂停/导航/后台取消表现并显示完整状态。6瓶3+3、7瓶4+3共用同一宽度公式，不缩小第7瓶。

标签由真实文字/色底/形状绘制，缓冲为破折号；颜色可用形状辨别。空瓶、单位液体、选中、建议、错误轮廓和胜利图标均是原生控件/CustomPainter。状态图标使用Flutter自带Material Icons（框架许可通过Licenses页提供），没有把整张界面栅格化。

## 场景物件身份

| 场景 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color Studio | Window | Desk & paint | Stool | Plant | Table |
| Garden Nook | Flower arch | Garden table | Chair | Potted plants | Tea and flowers |
| Seaside Corner | Dock | Cabana | Life ring | Coastal plant | Seagull |

每4主线关一个物件，依次对应1～20/21～40/41～60，共15次独立事务奖励。Color Studio沿用原映射。`scene_art.dart` 的normalized Rect是摆放权威，所有页面复用同一个SceneArt和拥有ID；0～5状态只增加已拥有层，不改变底图。物件5在解锁物件2之后出现，茶花与桌/海鸥与码头的具体接触位置由实际Flutter截图校准。底图中的墙饰/低墙/海岸属于基础环境，不作为奖励。

复核修正：每单位按有效瓶窗截面积的1/4计算，直立及倾斜共用圆角窗面积分位求水平液面，替代上文简单的直立高度分段。业务单位仍由核心管理；像素覆盖测试验证0.5～4单位在不同倾角及回位的可见面积。系统或应用减少动态均生效。

本目录仍为候选，独立视觉验收由产品架构记录。实际运行与图层检查的证据和限制索引在 `docs/development/deliveries/B03.md`。
