# 新Cocos玻璃花园 · S1/S2代表阶段

2026-11-06。S2/S3网页阶段已由总控独立有限接受；当前继续S4原生与服务。S4基础QA壳已编译，真实原生运行/SDK仍待验，尚无商店更新。原型设计PASS不等于新工程、原生或SDK通过。

## 来源与范围

工程 `glass-garden/`，既有checkout/分支 `codex/pour-flight-size-fix` 增量新增；开工前仅既有.scratch未跟踪。旧Flutter、只读站点、受验原型、原存档及冻结候选未修改。基准R1-5732d17bf059及新增三份refactor约定，精确路径/hash见 `../evidence/new-cocos-product-20261106/s2-input-contracts.json`。

407条输入源hash核验：404条游戏文件及3份只读reference。rules/campaign/progress/game/render/main六文件原字节保留，100关顺序、难度、规则、瓶阵、轨迹和时长不变。仅在新bridge、复制的HTML/project脚本接线调整。`product-model.mjs`拥有round/解锁/快照/收据，`storage.mjs`负责IndexedDB事务，`product.mjs/views.mjs`承接原型，未增加运行时npm依赖。

## 已修缺陷

- 原倒水开始已改Session，却等finish动画才保存，通关写两次。现在after局面/完整Undo/通关收据同事务即时提交；重复checkpoint加入同次写入，旧round/flow回调被拒绝。保留原return阶段排队与动作时长。
- transaction complete才确认保存，put success后abort不假Saved。保留已确认与待提交快照，Retry不换实例；故障阻止依赖操作/导航。revision冲突、损坏和空记录区分，显式替换原子保留quarantine。
- Next恢复下一关原盘/历史/round，产品与gameProgress.current同步。损坏指针、游离round、坏历史不静默清档。
- 电脑首查实际发现Home→Game所有按钮disabled残留，已补页面切换/弹层关闭后的refresh并复验，初始失败截图保留。
- 隐藏/弹层停止绘制水声，Hint取消终止Worker并令晚结果失效；Esc不能绕过通关/存档门槛。子资源失败向父显示Retry，避免Play永久等待隐藏iframe。

## 冻结与检查

候选绝对路径 `/Users/wangyule/.codex/worktrees/testflight17-fixes/Pourlune/glass-garden/build/s2-r2-final/`：415玩家文件，14240361 bytes；artifact-manifest SHA256 **ca42924a5b2ac6403b2f439870d8d1212be9cd840110e04f120877bff8264978**。逐文件清单副本 `../evidence/new-cocos-product-20261106/s2-r2-final-artifact-manifest.json`。候选未覆盖，不含QA/reference/npm依赖/samples.js。精确源码提交随交接发送总控。

在glass-garden执行 `npm ci --ignore-scripts`、`npm test`、`npm run verify -- --inputs`；`npm run package -- <new-name>`拒绝覆盖。Node22.23.2，24项PASS/无跳过，原407条源与六核心/100关核验通过。RED/GREEN原始日志保留。自动覆盖真实规则恢复/Undo/Next、完成幂等/旧round、写入中止/竞争/损坏隔离、设置与拒绝保留、未执行动画回调时动作/最后通关已落盘、输入刷新和加载Retry。动画测试只替代绘制端口，不当实际动画或SDK证明。

Use Computer实际Chrome390×844、320×568及独立IAB新玩家：拒绝/关闭后可玩，刷新不重问；倒水/Undo/Pause/Resume/Restart取消与确认；真实首关9手→2关1手→重玩1关9手→Next保持2关原盘/1手，刷新Continue保持且Undo可用。正常标签console error/warning空。

隔离4198 QA：实际put success后abort显示Not saved yet，Stay后瓶子/暂停不可继续，Retry恢复完整2手，刷新同盘且Undo回1手。隔离4199 QA：本地engine一次故障后父显示Retry，重载后Continue恢复原一手且Undo可用；浏览器接口未暴露HTTP状态明细，不称网络面板独立核验503/200。故障工具不进玩家包。完整实际记录及截图见 `../evidence/new-cocos-product-20261106/browser-s2/report.md`。

## 未验与下一门槛

历史S2检查点当时未推广；其后S2/S3已获总控有限接受，当前推进S4。真实慢Hint取消未捕获（真实搜索过快）；自动取消/晚结果已过。后台原生生命周期、return窗口快操作、同屏几何稳定与性能基线仍需实际证据；不以Node替身或截图代替动态验收。

当前无广告/GameMunchies/Firebase客户端或远程队列，CSP连接仅本地源；选择允许也不启动采集，真实接线前须重新告知/选择。音乐/震动禁用是能力占位，不是正式默认策略，已有布尔值不覆盖。旧60关→新100关同身份迁移未实现，奖励玩法/频次/匹配SDK另列待定。

**没有广告超时修复或真实展示/奖励通过结论，没有签名、上传、审核或发布。** F9、原设备/库及旧iOS19/Android19未动。未启动设备，UDID/serial不适用。预览HTTP进程仅供验收，结束后由开发清理。按总控实际结果继续返工，不能将本阶段自测写成TestFlight就绪。

## r2定向返工

r1保留冻结并置REWORK，不覆盖。当前r2-final相较r1仅product.mjs与game-bridge.js两个玩家文件变化，413文件原字节不变，详s2-r2-difference.json。前后台入口补refresh，修复禁用残留；原Pause回前台不自动关闭。受控晚到保存Promise复现了同round恢复成另一Session时旧win音效仍播放；现回调核原Session与state引用，队列开始新动作后不插入旧noMoves。代码提交cc385d89d7ae8b013b31bf55934b7955137ecb22；RED→GREEN日志保留。

Computer实际切Chrome标签后原盘/输入保留，Pause仍在且Resume/Undo可用；但visibilityState持续visible，未证明真实hidden事件触发，因此只记切标签路径通过。4200预览已切换r2-final；4198冗余QA服务已关闭，4197普通和4199隔离QA暂供独立验收。没有设备。本次文档更新不改变候选字节。

## S3外围阶段

总控已在主目录 `docs/development/review/new-cocos-s2-independent.md` 接受r2代表网页范围并放行S3；不升级为原生/SDK/发布通过。本阶段继续原型既定视图，仅新增一个玩家行为修复：滚动后立即选关时，listScroll随enter完整快照保存，避免200ms debounce尚未执行便丢位置，不增加事务或round。真实UI handler RED→GREEN。

当前S3冻结 `glass-garden/build/s3-r2/`：415文件/14240517B，manifest SHA256 **b919deb73826311f53df65dabf1dd61287a3b8cc8288047d829fbf29c8cb3a0b**。与S2-r2-final只改product-model.mjs/product.mjs两玩家文件，413文件保留；完整差额及清单在本证据目录s3-difference.json/s3-r2-artifact-manifest.json。28项Node PASS无跳过，407源/6核心/100关核验不变。

S3新增隔离QA检查点生成器，逐关实际R.solve＋Session重放固定100关，校验合法历史，构造16最后粉色收集前、39开罩前、100最后一手前的状态；只导入4199独立QA库，保留旧QA快照，不进玩家包，不当自然玩家100关通关。生成输入/下一手/hash见s3-qa-checkpoints.json。自动核16收集/39开罩及Undo、100最后一手原子完成/无101/保留100份历史；保存音乐与震动true等显式选择不因能力未接被覆盖。

Computer实际正常库：游戏→设置→帮助→两次返回同盘/1手；sound off、reduced on刷新保持；允许统计刷新保持、再拒绝与政策进出同盘；锁关未进入、分组和滚动返回保持。隔离QA实际16收集满并胜、39开罩后Undo及刷新恢复罩/4手、100实际最后一手→52手/100结算，仅Play Again/Levels/Home，首页与选关无101。报告与截图见browser-s3/。紧200ms人工点击未测（自动handler已覆盖），本轮320补验结果待Computer追加；不重复未改S2的拒绝刷新/故障恢复。

当前无新增设备或网络规则/SDK变动；原生壳/真实后台/精确return快点/广告统计仍待S4。S3其后已由总控有限接受（主目录new-cocos-s3-independent.md）；未上传TestFlight。

S3 320x568 supplement: Computer checked final100 Play Again/Levels/Home all visible, actual39 cover removal with stable board/target/tools, settings bottom Credits and nested Back to same one-move board. QA toolbar obscures the top title only; this is explicitly excluded from player UI acceptance. Evidence browser-s3/report.md and 320 images. No device started.

## S4a基础手机壳与匹配SDK核查

S3已由总控有限接受。基础独立QA壳 `dev.pourlune.glassgarden.localqa`、0.1.0(1)，Android debug及iOS generic simulator编译成功；不覆盖旧com.pourlune.app或签名。AndroidX WebKit1.15.0、Gradle9.3.1/AGP9.1.0/Java21、SDK36；iOS Xcode26.6/17F113、SDK26.5、min16，均串行worker≤2。Android首次offline缺AGP缓存，正常HTTPS取依赖后offline重编成功，未改TLS/代理。XML兼容/Gradle弃用警告如实保留。

基础包冻结 `glass-garden/build/native-candidates/s4a-baseline-1/`，精确逐文件索引见native-s4/baseline-artifact-index.json。Android APK10341913B/SHA815e244424eae11b4795f8b081116ae2be24b996b3bdda8aea8a6beb00dd0cd9；其414资源与S3同hash，唯一平台剔除vendor/.gitignore非运行元数据。iOS.app420文件，全部415玩家资源同S3；没有SDK接入或上传。

Android固定HTTPS虚拟资产源，ESM MIME、同源限制、系统Back/生命周期/安全区接线；本基础包没有INTERNET权限。iOS固定127.0.0.1:43177只读资产服务与WK持久数据，端口失败不换源，原生前后台接既有controller。实际macOS运行同AssetServer实现，GET/模块MIME/HEAD/404/symlink/越界/POST拒绝通过，临时listener与文件只清本测试；不能替代iOS原生运行。

Computer只读排期：Fruplop QA Launch 74DA9C44-B2C0-436A-A6E0-F2A608D85324仍Booted且无释放证据，adb无设备。遵守单设备规则，未启新设备/安装；拟复用已关闭的Pourlune Liquid Color QA D79BD258-6E80-4B71-9A7D-E806F5321460/iOS26.5，待持有人自然释放窗口。真实资源/Worker/非空进程恢复/hidden/return时序/音触觉/性能仍未验，不以编译或host测试替代。

连接器只读核私有gamemunchies主树d34a7448后找到匹配的JavaScript0.3.0。按官方固定交付0a806fda242f55c3b7180fb63969323276f1cd4d获取归档，14670B/SHAf737166865a0d658273b53e372bce87e2e8fc1a24162305d11c7ac570831d796及8文件全部hash通过，源码6b2d595f；完整公开定位/hash元数据在glass-garden/sdk-manifest.json。私有包/源码仅在忽略目录，不提交、不公开、不从浮动工作区引用。匹配SDK存在，不再把旧Dart七文件当无匹配SDK的证据。

SDK单实例、严格失败无内存回退、统计拒绝不POST、保存成功才新局事件/恢复不重复、失败Retry只一次、旧允许须新通知而旧拒绝保留等接线正在实施；实际私有SDK＋受控HTTP/IndexedDB自动检查5项通过，不称真实网络或平台接入通过。基础冻结包尚不含该SDK。继续独立接线，无需用户操作。

## S4b统计撤回修复冻结

本节覆盖上述“尚无SDK”的阶段状态。`s4b-consent-final`已包括固定官方JS0.3.0八文件，不修改SDK或公开其源码；QA平台标记只连接Pourlune test scope。32基础检查、13真实SDK定向检查全部通过，双端独立QA0.1.0(2)编译成功。原407来源/六核心/100关原字节核验通过。连接策略仅本地与api.gamemunchies.com，无网络规则/TLS/DNS变更。仍无原生广告SDK、真实设备上报/奖励或TestFlight通过结论。

总控提出延迟启动期间允许→拒绝→允许旧事件复活反例，实际SDK测试复现后修正：同步撤回、历史选择串行处理、generation作废旧意图。另补跨进程拒绝清理token及按scope持久ACK；SDK完成旧队列清理并成功ACK前不能重启共享。合法重新允许后新队列在下次启动保留，ACK失败停止统计但不阻断游戏。拒绝偏好写入失败时只承诺本窗口暂停，Retry前不显示已保存。实际SDK初次前台启动漏通知同样RED→GREEN；背景测试初次失败是等待微任务不足，不能当产品缺陷证据。证据在native-s4/services/。

只读真实配置GET（stats=false，拒绝POST）iOS200/remote v4、Android200/remote v1，已修正fallback缺kind/scene白名单导致200却config_invalid。此探测不是WebView/广告请求通过。配置场景识别不批准新的插屏策略。

冻结web424文件14294634B，manifest `2d6316937c565d4b2df681fc1c3e6fc508882f353566405f0e8ec09f10d5bf4b`；原生目录`glass-garden/build/native-candidates/s4b-consent-final/`索引SHA `0aedffd8de2f23ef0cadc92075324a7b8f95ea7aa8b10dccc7f3e1de95153256`。APK10368280B/SHA `d2770cbe063e25123b14b00f5fec055640d1de0ed991a382503f150027a9733f`，423运行资源精确一致，唯一省略非运行vendor/.gitignore；iOS424玩家文件一致。中间s4-services-5保留REWORK，不安装。不启动设备、不占用Fruplop/F9。

用户现已确认更新原com.pourlune.app、保留旧存档原件及明确设置、新100关首次第1关，及每局真实激励一次额外普通空瓶、Restart保留/Undo不撤销；上述奖励待选文字仅历史。迁移、原生广告与加瓶事务正在继续，未实现部分不写成完成。
