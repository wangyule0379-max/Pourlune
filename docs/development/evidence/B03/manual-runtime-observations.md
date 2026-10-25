# B03 普通App操作与冷恢复记录

平台：GDF-Remaining-20261020 / iOS26.5 Simulator /4DF92321-95EC-4C8E-849C-0CF0AA6FE1D2，逻辑402×874；Flutter3.47.2/Dart3.13.2，2026-10-22。自动代理通过原生Simulator真实按钮操作，不是人类受试者或主观难度验证。命令工作目录app，`flutter build ios --simulator --debug --dart-define=POURLUNE_DATABASE=b03_manual.sqlite`，未传POURLUNE_SCENARIO或测试日期。

普通debug构建安装后，空进度首页显示Start，没有Engineering content横幅。进入主线1，实际IDmain-001/v1、原教学2色4瓶。观察到独立后层/前层、透明瓶窗、液体平边、形状＋目标色底、真实按钮/语义。倒水1→3后为1move/revision1，瓶1两份Green、瓶3两份Orange，其余不变。等Saved后截图，直接`simctl terminate`→`simctl launch`同一已安装App，中间没有安装或清数据。首页Continue→恢复同一实例ID/revision1/教学step2/棋盘。`manual-cold-before.json`与`manual-cold-after.json`逐字节payload比较一致，App继续页截图也一致；这是普通App进程恢复证据，不用集成运行器重装代替。

回首页→Daily，实际本地日2026-10-22，catalog v1 epoch2026-01-01得到独立题daily-025/v1（3色5瓶）。初始瓶3四份Green但固定Purple目标，验证临时错色允许存在且不算胜利。免费Hint显示3→5，提示不倒水，点目标后revision1、完整四份Green移入缓冲5并Saved。主线存档保持。截图`manual-daily025-hint-pour.png`。这只覆盖当日样本；全30目录/循环边界及90规则回放在自动检查单列。

画面发现短首页/日历背景只包内容高度，底部出现纯色接缝。已将Scaffold body改为SizedBox.expand，使同一独立背景图填满可用体积。初次普通App截图保留为诊断/冷恢复证据；修正后的完整UI由后续native-runtime截图证明。瓶窗初版在真实App中无液体越出针织侧框，空瓶明确有容量刻度；更多0～4及6/7布局由受控原生gallery补充。

音频在普通App连接真实GameAudio，不测主观听感。另一个native-audio测试在实际audioplayers iOS后端读取6资源时长140/840/280/1200/1050/24000ms，并逐份验证playing→paused→stopped。开关/暂停/后台策略由实际GameScreen桥接测试与运行控制路径检查；音量、循环衔接、设备静音/来电/蓝牙和Android实际播放未验证。

运行器可能在测试完成后卸载被测App并清理容器，故测试截图由宿主只读复制运行时沙盒文件到`native-runtime/`；不把这种重装称为冷启动。普通App冷恢复对照发生在此前，以上JSON/截图已单独保存。

三项表现修复后，另以最新普通构建重复main1首步冷恢复，文件manual-final-cold-*精确payload一致；随后Cua实际按钮完成原5步，Saved与绿色主题成功页见manual-final-completion.png。未注入scenario／测试日／进度。此组替代初版图作为最新表现的普通App证明，初版证据仍保留。
