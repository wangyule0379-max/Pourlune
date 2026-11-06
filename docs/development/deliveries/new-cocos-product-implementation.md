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

## S4c加瓶与原生广告接线：开发自测检查点

已实现获准单局一次加瓶：prepare先落盘原puzzle/round/attempt，真正reward输入才把一个容量4空瓶与receipt原子写入。Restart保留puzzle ID/权益但换统计round；Undo的完整历史同步扩瓶，不回收已兑权益。重新游玩已完成关创建新局、移除旧局attempt；晚到奖励只兑原保留局，当前另一关不动。未知/重复/跨新局回调不重复加瓶；保存中止保持瓶与receipt同一pending供Retry。统计失败、初始化延迟或撤回不阻断已确认游戏奖励/广告关闭。原存档读失败先保留native reward，不以空新档身份ACK丢弃。

原100关初始数据/六核心原件保持hash；extra-bottle.mjs只生成单实例emptyCount+1定义，普通瓶在collector前插入，历史/遮罩/collector索引同步转换。game-runtime.js为严格按原game SHA和三个唯一替换点生成的集成副本：loadLevel新增activeLevel参数，restore/layout使用它；原game.js不改。最大普通14→15最后一排五列；密集长collector13→14侧列追加位置。瓶宽、液体unit、collector容量及原初盘不变。全部100扩瓶状态/合法历史/Undo验证通过，1/16/39/61/99/100用原求解与动作实际算至胜利。

原生独立QA0.1.0(3)双端编译成功。iOS GMA13.11.0/UMP3.1.0固定旧已核版本；Android GMA25.5.0/UMP4.0.0及锁文件。官方平台sample AppID/unit，NPA、PG、UMP canRequestAds、无ATT和两AD_ID权限排除；不强制地理、不重置隐私、不改代理/TLS/DNS。主本地域主frame桥接，实际reward/impression/shown/close/failure分流；native观察保留首ID/时间并留至游戏/统计确认，已shown不因后台或elapsed销毁回调。原生离线回执读坏保留原文件、广告关闭，不覆盖成空。原生策略与connected notice不符会在构建守卫失败（双端负向执行并恢复staged元数据）。当前没有新增插屏触发/频次批准或实现。

新增通知version3说明真实Google测试广告及可选广告事件；已有declined保持，旧allowed2须更新通知选择后才采集新范围。自测发现配置延迟取消后仍可能晚启动，已RED→GREEN；统计version带括号被SDK拒绝，改用0.1.0+3并用实际SDK检查所有漏斗上下文无拒绝。背景测试初次微任务/奖励冷却混淆属于测试假设修正，不算SDK缺陷；rewarded impression不消费interstitial专属冷却，真正受控interstitial impression在statsOff仍持久生效。页面history pageshow补回前台；Home后台不再用旧scene覆盖新读入盘。

52基础/UI/控制器与14真实官方SDK定向检查PASS（HTTP受控，后者不是真广告）；匹配SDK8文件未改。Computer代表浏览器开发自测报告browser-s4-reward/report.md：390/320实际6/11/12/14/15瓶，无已见瓶/target/tools重叠，1 Hint倒/重开保留/Undo、16满收集、39开罩/Undo/刷新同4手、61小屏粉色收集、100最后52手胜利；未逐瓶逐尺寸点击、不等于AdMob或原生通过。根开发复看320的61/100图确认代表几何，仍等总控后续独立复测。

冻结web s4c-reward-selftest-2：427文件14346810B/manifest 12aeb843aa658fddf5a8b58144775c655993c2d0b5aa070f2ed07292fe544d07，相较浏览器实测selftest-1只改ads.mjs：426文件（全部渲染、UI、题库）同字节。原生最终自测路径glass-garden/build/native-candidates/s4c-reward-selftest-2-guard/，indexSHA 04b9064bc82b494109bed9dba3b95886a9b2bc7e14e1866fd6fab0dea1d9cad7，APK 2e3f3a9f929d2de8556e40c064b42ddcb0c3eea3078ff870154dee4151db479d；426/427双端玩家文件精确核对，唯一Android非运行.gitignore省略。中间native selftest-1/2均保留，不安装。stage守卫重编令iOS debug dylib字节改变，已另冻guard目录，不拿前index冒充。

证据native-s4/reward/。Fruplop74DA仍唯一Booted、无释放，未启Pourlune设备；真实native UMP/广告load/impression/reward/close、路由原日志、SDK test后台回读、进程恢复/性能尚未验。迁移、音乐/震动/支持实际能力及必要发布工作仍推进。本检查点不交总控代做未完成的开发自测，不宣称完整验收或TestFlight更新。

## S4d迁移、原生能力与晚到奖励：开发自测检查点

本节覆盖历史占位状态：现已实现只读旧SQLite的复制读取、幂等导入明确设置与隐私拒绝、新100关从1开始，旧60原库/题目/记录不改不映射。读取失败或孤立WAL等异常显示错误与Retry，不假作新安装；存在新存档不再导入。旧Dart SDK内部ID/队列保持原件，未导入JS SDK，不称完整统计身份迁移。

音乐与震动接入原生能力，沿用旧默认true、保留已选false；原批准Dream Culture MP3原字节/完整循环/0.12音量、作者与CC-BY4.0归属保留。Home/Pause/设置/后台/广告/中断停止音乐，旧WebAudio短音停止后不在恢复时重放。iOS ambient遵从静音且不夺其他音频；Android不申请音频焦点或震动权限。邮件支持和复制失败回退已实现，不自动发送。

定向修复包括：bootstrap晚于原生前台回调时仍取当前状态；加载失败Retry同步恢复原生owner状态；晚到奖励停在Settings仍保留该页，返回同局已是6瓶，后续保存/Undo正常；成功音效须当前已落盘胜利且满足前台/页面/偏好门控。69核心/UI/控制器检查、14实际官方SDK受控HTTP检查PASS，原407来源/六核心/100关及音乐hash核验通过。原app/core无源码差额。

旧Flutter GameStore真实API生成非空schema5夹具：20首通、普通21两手并获真实事务权益、每日13及明确设置/隐私。真实Swift LegacyReader在host读取该夹具并核main/WAL/SHM不变，实际Product导入/动作/重开保持新进度通过；坏布尔、坏库、未知schema、孤立WAL、软链等读取反例通过。第一次夹具失败为FFI相对路径的最终文件断言问题，原产物完整保留，不算产品故障。此项不等于商店安装升级或手机容器实测。

Computer浏览器自测browser-s4d：390/320迁移设置、真实动作/Undo/刷新不重导、支持/署名/错误Retry均通过；音乐及震动仅mock端口，不称听到或触觉通过。browser-s4d-late在独立库/受控GM HTTP与假广告回调中验证无奖关闭后Settings晚到重复奖励不跳页，返回6瓶→动作落盘/Undo→真实9手首通，console空。不是AdMob/native/后台数据证明。

冻结web s4d-migration-effects-selftest-4：432文件22933677B，manifest SHA16918dc04448cb2486a066a23641f0598833d1741a4ab96e1989a84df214fe82。与浏览器迁移selftest2差额仅六文件、426不变，详差额；晚到奖励实际使用web4。双端QA0.1.0(4)最终候选glass-garden/build/native-candidates/s4d-migration-effects-selftest-4-retry/，index SHA95f17cacd5635de6be0cea2c9c70a7d858fe6129b2d177681b5f36052c5f7611，APK SHA351803aa580238d0422f9869a96a109dede05da5193046c912cde1a858d68b64。旧2/3/4包不覆盖，不安装；最终差额是原生Retry owner恢复，玩家web仍4同字节。

证据native-s4/migration-effects/及browser-s4d、browser-s4d-late。Fruplop占用期间未启动新设备，UDID/serial不适用；F9未动。真实native资源/进程恢复/音乐/UMP/广告/实际路由/测试后台尚未自测，插屏完整旧策略与共享冷却继续集成。此检查点不请总控代做未完成开发测试，不称完整验收、签名或TestFlight更新。

## S4e完整旧插屏策略与共享冷却

已按旧PRD/最终控制器/持久化契约移植11起首通、3次资格、20/40保护、只本次首通首次Next、真实展示消费prepare时边界、任意fullscreen共享180s与保守重启；最终100无Next。SDK远配只进一步限制，加载晚到不自动展示，未shown120s上限，shown等待真实关闭，后台关闭仅前台同源实例推进。原生双库存/单展示路由、真实load_requested及blocked分开。旧库公共广告时钟保留，不改私有SDK状态。详情及反例证据见native-s4/fullscreen-policy/policy-and-validation.md。

80核心/UI＋15真实官方SDK受控检查通过，双端QA0.1.0(5)编译、清单与资源字节核验通过。Computer实际新Next差额browser-s5通过：ready/后台关闭/前台14、共享冷却、late不展示、20结算不展示。进入21预取1次符合后续首通策略，原始计数保留；先前作者“整个20→21不能load”预期过严，已明确纠正而未改代码。上述不是真实AdMob或后台通过。

冻结s5-fullscreen-selftest-2（434文件22948122B/manifest0cd092080c00508ab76baf18d9e4f3a4bd5e0f45b286f49408c7240bbbd0981d），原生s5-fullscreen-selftest-2-privacy（indexb9abaad5b5a45e385af429ee033dd9928a48c39967d9f503ad1e2af9035e9600/APK2874dc8cd0d3d1a6322207ebe9c15b55f2320a581c6ea5e23bd2393f683ff664）。已补App自身统计隐私清单并核SDK两份原清单；尚无商店声明修改或上传。新增CI仅复制来源与核心/服务关闭原生编译，不上传私有JS SDK，不把它当完整SDK运行CI。

本阶段边界Fruplop74DA仍占用且无释放，adb无设备；未启动Pourlune设备/未安装新包。真实原生/升级/广告/路由/后台/性能自测仍等自然窗口，电脑已排完整批次；F9及旧App/库不动。继续独立发布准备，不请总控代做未完成开发原生测试；尚未通过最终实际验收或更新TestFlight。

S4e预检差额：App未直接调用需申报理由的API，移除空NSPrivacyAccessedAPITypes键，不虚填理由。新native s5-fullscreen-selftest-2-privacy-final/index3c760dee2424db5f63263e1310be955bd40c9ae3826ef854d233986a35b1d281，仅根PrivacyInfo.xcprivacy一文件变、445文件同字节，web/Android不变；旧冻结保留。preflight-triage.md逐项记录scanner误报与真实待验，localhost是只读本地资源源，不把它改成公网。仍不称clear to submit。

新CI首跑42253305276（精确864084d）：80核心/来源核验和iOS服务关闭编译真实成功；Android工具安装失败在setup-android默认请求已不存在的SDK tools包，尚未进入编译。依据该Action官方README将packages显式空、下步只安装已指定API36/build-tools，不升SDK/AGP、不弱化TLS。下一精确提交另跑，首失败保留，不重跑旧终态。

## S4f真实本地服务Retry竞态修复

Host真实NWListener/URLSession补测复现停止后立刻重绑同端口POSIX48；仅等cancel回调也失败，TCP流可能仍持有端口。改为健康服务复用、失败owner取消完成再重试，openRevision阻止旧打开回调；不延时/换origin/端口共享/清档。20次同origin实际Retry及独占端口冲突→释放后恢复通过。双端QA0.1.0(6)编译通过，web仍s5-fullscreen-selftest-2全434字节一致；新native冻结s4f-native-retry-selftest-1，hash见retry-recovery。仍未做真实WK进程终止/原生验收，不拿host通过冒充。7c925f8的CI42254066125三job已真实成功，最新本原生源码另跑。

S4f追加版本维度修复：Android桥仍固定+4，现双端从真实包metadata构造SDK appVersion并JSON转义；新freeze在实际DEX核版本，旧6包真实RED、新6重编PASS。最终native s4f-native-retry-selftest-2-version，原6不覆盖/不安装，web不改。详retry-recovery/version索引。此差额不代表真实广告/后台验收已通过。

## S4g正式身份配置预备与压缩QA包

未占设备期间完成现有App发布配置：显式prod＋com.pourlune.app＋已核商店版本/构建号才允许正式作用域；默认仍独立QA/test，错配/双flag/production Debug或install/无版本/CI快捷包均拒绝。正式广告仍只官方测试模式，不重开商业AdMob或Play。复用原已发行图标逐字节；生产未运行/签名/上传，不扩Crash/Firebase采集。82核心/UI、17官方SDK受控检查（含重试ID/时间、字段边界与撤回）通过；最新仅诊断metadata差额另2定向检查通过，提交后CI再全量。Computer新目标隔离冒烟QA1GET/production0/POST0、错配全0且离线可玩，非原生/正式后台通过。

QA0.1.0(7)双端debug及Android实际R8 full/shrink/minified/debug证书包已编译核资源；DEX marker与mapping对应、两APK签名匹配，未做minified运行。最终web s4g-release-config-selftest-3/434文件22949373B/manifest9a708df3f32373f12f2cd5ad8b2a06f1cd3c02c887b7e3c0eee223e3dd48be8c；native普通indexb2175361e45fdd6857c5f2dd29061082096cd83f38a70d1639bdd501168ff398，minified indexd9f4246cf47485334c21470759cccdeebed8abd2f6d8f09c75765397650b39a9。完整hash、范围与剩余见native-s4/release-configuration/report.md。与S5仅product/services两web文件，432保持；GameMunchies私有源码/旧app/core不改。未来发布runbook在native/RELEASE.md，不自动执行签名或正式发布。

实际原生迁移/进程恢复/真实广告与路由/测试后台/压缩启动/Activity重建晚回调/性能仍待合法窗口，F9/Fruplop不动。不以本配置检查点冒充完整手机验收或TestFlight更新。此前精确9995201/CI42255647434、0bc3acd/CI42255027814均3job成功，本源码另跑。

## S4h取消与晚回调修复，另有统计边界阻断

RED复现并修正：取消后late failure重新弹页、durable prepare等待取消仍send过期show、旧奖励到账仍show第二条未展示load。现代际/阶段/前台/权益/远配在save后再核，过期terminal仅观察不拉回UI，旧奖原子兑一次并取消同局未show的冗余load；已presenting仍等真实close。86核心/UI及17固定SDK受控检查通过，407源核符；Computer late failure/Settings及模拟旧奖/第二load路径过（模拟181s不算实际冷却）。最终s4h-cancelled-ad-selftest-2及-minified、QA7，hash/差额/原始红绿见native-s4/cancelled-ad/report.md，较S4g只ads.mjs变、433文件不变。

新独立统计反例仍RED：Off观察到的Native回执，SDK import延迟后Allow可能使旧事件入队。真实SDK＋Product/GameServices实际onCommit顺序/全部HTTP拦截复现，父独立确认；非真实服务数据，不验证reward。父协调官方逐观察policy-only能力，host继续前await许可/撤回epoch及native回放保守边界；不私改固定包、不建第二owner、不用临时globalOff清合法队列，也不跳过interstitial冷却。该项和真实原生/后台/性能均是发布阻断，不能用86绿冒充完整通过。当前不上传TF，F9不动。


# S4i host permission and native replay checkpoint — release blocked

7 November 2026. A native callback now captures the saved permission and document/choice epoch synchronously at receive, before queued game work, SDK import or persistence awaits. Every choice closes the native gate immediately; only a successful durable Allow reopens it. A withdrawal/reallow cannot revive a previously captured observation. Synthetic funnel observations allocate their original UUID/time before awaiting the owner.

Native first callbacks persist before forwarding. Only successful first live forwarding is replayed:false; drain, duplicate forwarding, restored/unknown receipts or failed persistence are replayed:true. Each receipt retains its first UUID/time and the native document/epoch/allowed stamp. Replayed raw callbacks do not create new optional metrics. Legitimate rewards still commit against the original saved attempt and duplicate receipts do not stack. Already queued valid SDK events retain their normal SDK retries; this change does not clear that queue.

GameServices serializes host observations with consent application. With fixed JS0.3.0, a denied ordinary/rewarded outcome is acknowledged without a new metric. A denied interstitial impression can update SDK policy while global statistics is Off. If global statistics is already On, the fixed SDK cannot apply policy-only safely: the native receipt remains unacknowledged, further interstitials are gated, and gameplay/true close still continue. An optional injected recorder is a tested adapter boundary only; no official new API is bound or claimed. No private SDK source/state, temporary global Off, second SDK owner or queue deletion is used. The separate SDK capability remains a release blocker. A conservative raw receipt that never entered the SDK before restart can be missed; zero-loss delivery is not claimed.

The previous actual Product/RewardedAds/GameServices/SDK delayed-import reproduction now reports offNativeObservationQueuedAfterAllow:false, using explicit first-live native metadata and isolated fake IndexedDB/intercepted HTTP. This impression-only reproduction does not prove a reward or server acceptance. New tests preserve valid queued ID/time retries while holding the denied interstitial policy receipt. The actual allowed-controller remote-block path now validates config_disabled against the fixed SDK, correcting the unsupported remote_disabled reason.

94 core/UI tests and19 actual fixed-SDK controlled tests pass. Original407 inputs,6 core files and100 levels are verified during the freeze. Native iOS Debug, Android Debug and R8 Release QA compile successfully, with no signing/profile changes or launch. QA0.1.0(8), bridge5. Frozen web s4i-native-consent-selftest-1:435 files22954283B, manifest a787332e8160930fba70b41dd531d6cc8657c40850915379c9c7d0f1b25ce349. Ordinary native index e881bebaef90c9e29666b6bb38c5e548bb481167516a39968184ca317302bcb6/APK c3ed0cd59000b0686cba078ab5afdf2af5a75d2fa05a51123a6a025564a1b382. Minified same-name-minified index6fc614ee115d4924552538b1719a6f54eaff851c3896f45a294a388fada0fbee/APK35aa6d6a7b9cbffb73329af6aec2eb09af063d25e9be33fa67ad297022d830b2. All old frozen candidates remain intact.

Actual browser consent/late-reward exercise is delegated to the existing Computer chat against qa/ad-consent.html. It uses real frozen UI/SDK with a local SDK-import fault and simulated native callbacks, isolated storage and intercepted HTTP; it is not native or backend acceptance. The fault server only holds this exact frozen tag SDK entry, with explicit release in test cleanup. Await the actual report before claiming a browser pass.

A further static finding remains: Android still instantiates one GardenAds per Activity, allowing an old callback/receipt owner to outlive a reconstructed Activity. First native callbacks arriving after a document replacement also need an explicit uncertain-origin fence. These are not represented as fixed by this checkpoint. Computer has been told not to install S4i; source-level lifecycle repair follows in a separate checkpoint. Actual native launch/upgrade/Worker/background/renderer Retry/audio/GMA/routing/backend/minified Activity recreation/performance remain pending, as does the official SDK capability. No device started/installed (UDID/serial used:not applicable), production data, signing, upload or TestFlight update. F9, Fruplop and original library untouched.


# S4j native callback owner and source fence — not native runtime acceptance

7 November 2026. The previous Android GardenAds was instantiated per Activity. Actual production Java source5ff5af0 reproduces the failure under controlled JVM platform ports: after another Activity takes over, a late reward from the originally shown ad reaches the old receiver rather than the current document. Independent stale receipt arrays could also overwrite each other when acknowledging another callback. Baseline RED is retained; no device or Google SDK executed in that reproduction.

Android now retains one process-owned GardenAds, attaches the current Activity/receiver, rejects commands/lifecycle updates from a stale Activity, and detaches without discarding presented ads or original receipts. Old Activity destruction cannot detach a newer receiver. Initialization and load use the application Context; a main-thread Handler dispatches SDK initialization completion, without calling a destroyed Activity. Detached delivery remains in the same durable queue; a newly attached receiver drains it. Only a live current Activity can request show. Cached unshown loads are cancelled conservatively, with their callbacks retained until their actual result.

Both native implementations remember the document session in which an attempt first loaded. A first callback from an original attempt arriving after document replacement is marked replayed:true even if the new document has already allowed statistics. Unknown origins and persistence failures are conservative as well. This flag affects optional statistics, not the original game reward or mandatory fullscreen policy. The first callback in the current document with successful durable persistence remains replayed:false. Epoch changes within the same document still use the current choice at actual observation.

qa/android-ad-owner-check.py compiles the actual unmodified GardenAds.java under test, using controlled Android/GMA/UMP ports and an existing cached Gson2.11 for real JSON serialization. It verifies late reward delivery to the current document, old-destroy/new-attach ordering, state ACK preserving the original reward, stable original ID/time on drain/duplicates, stale-owner command rejection, one presentation until true close, same-Activity new-document provenance, fresh durable callbacks and failed-persist replay marking. All pass. The script also accepts --source to reproduce the exact old source RED without checking out or modifying the working copy. Temporary class/source directories are automatically removed. This is a source-level callback/state test, not GMA, Android lifecycle, process recovery or minified-device proof; actual Activity/renderer tests remain on the native batch sheet.

94 core/UI and19 actual fixed-SDK controlled tests remain green; their web payload is unchanged from accepted S4i. iOS generic Simulator Debug, Android Debug and R8 Release QA compile successfully. Existing debug certificate only; no Apple signing/profile change or upload. Final QA0.1.0(9), bridge5. Reuse immutable s4i-native-consent-selftest-1 web435 files/22954283B/manifest a787332e8160930fba70b41dd531d6cc8657c40850915379c9c7d0f1b25ce349. Final native s4j-native-owner-selftest-2 index0807dfffe1c2c8498aba754015535f4636392fd045c27cbe141b4136c407dc2a/APK8c889b06ada3853b4cd195a47b8c68b85fde0838fedf73be1bcb0c44ce920646. Minified same-name-minified index9e2af71f361aa86926cc2c7ea4f15d99c87a584787ad312c117b92612fb0e023/APK5e317c5602aa8daefabfb483563b92e649cb15a8bbf032991e771ea4bb4ac38a. Earlier selftest1 is retained but superseded: final2 also makes the unchecked internal command overload private; only the Activity-checked bridge entry is callable by MainActivity. The iOS app is unchanged between these two native checkpoints.

Computer S4i browser evidence is now complete in browser-s4i/report.md. Root inspected consent-counts.jpg: old Off impression0, new permitted reward1, six bottles and0 moves after pour/Undo. Total-controller independently accepted only S4i host consent/replay scope (canonical review/new-cocos-s4i-independent.md). Neither report establishes native/backend success.

The latest natural device check still finds Fruplop74DA booted and no adb devices; no owned device launched/installed (test UDID/serial used:not applicable). F9/original app/library/save and other task devices untouched. Host test/build processes completed. The actual batch in native-batch-plan.md remains queued for a legitimate single-device window; no need to retest unchanged old web suites. Fixed JS0.3 policy-only capability is still independently release-blocking and parent owns the already-asked SDK coordination question. No private8-file SDK edits, global statistics toggles, valid-queue deletion, network/TLS changes, production data or TestFlight completion.
