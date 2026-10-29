# Google Play 最新 Alpha 封测更新（进行中）

2026-10-29，Asia/Taipei。原Alpha19现已真正送审：正常UI提交的XHR200及Play“正在审核中的更改”双重回执已取得，尚未获Google批准或19可安装回执。Android实际测试广告、同实例奖励持久化、统计撤回/冷却重启及正常main已通过总控独立证据验收。原13/候选19-2的R8启动构造器缺失已在新19-3修复：新签名生产包及精确CI通过，且专用设备实际minified首次启动、普通操作及仅App重启恢复已成功，当前会话无原Fatal。总控已最终接受并放行原Alpha19更新，广告及数据安全声明一并送审；本人已明确允许当前美国/巴基斯坦和原两测试列表，原自动发布已恢复，Google获批后生效，不再重复提交或重传19。iOS19既有Self测试与正式提交不改，不重复上传。

实际13在专用QA中首次安装，启动报`InitializationProvider`无法创建`WorkDatabase`，没有生成非空玩法存档。两版DEX都保留`WorkDatabase_Impl`和两个`InputMerger`类，却缺少反射所需public无参构造器；debug包有这些构造器。应用本地keep规则仅补这三个反射入口，Flutter3.47.2原生插件会自动读取该规则，不改SDK/锁/R8模式。CI新增真实minified release AAB及DEX构造器门槛。旧13/19-2红、debug对照绿、本地新release三项绿均留在`release-startup/`，包检查仍不等于实际运行通过。

总控同意保留原13不修补、不将重制13冒充原发行升级。替代兼容验证明确使用原13精确源236cea04的原GameStore/core生成纯合成非空SQLite：已过1–3、main004两步/原定义v2/已领直接加瓶/音乐和统计Off。446项旧源码与原冻结清单匹配，生成器1项、当前真实SQLite的撤销/重开/动作/再打开1项通过；该夹具不含设备或SDK数据、不列为生产asset，后续独立命名QA入口仅在库不存在时种入再调用正常main。它属于存档契约兼容验证，原13非空现场升级仍未完成，不合并两者状态。

## 新包与来源

生产代码基线eb48e7d，最新Android修复源`9eab3b62940146dbc8cb9fb1a80a9e5b37cc8906`。沿用SDK0.2.0固定私有源6dac3537及7文件指纹，不降级SDK、不重登记gameId。主线题库/5色、R03源瓶运动、原静态布局/接水瓶、音频、奖励/存档事务及统计默认off保持。原Android正式AppID和两个既有正式单元经控制台再次确认后填入公开登记；QA继续使用独立test游戏和官方sample单元。

AAB1保留为未上传候选。最终manifest审计发现它只去掉GMS广告ID权限，却仍有平台`ACCESS_ADSERVICES_AD_ID`能力。Android官方文档确认这是另一条广告ID访问通路；没有据此声称本轮实际读取或发送过该ID。最小修复同时移除两条权限，最终manifest guard覆盖两者；NPA、PG上限、其它权限、游戏ID和同意默认不变。新生产权限反例先红后绿，7项聚焦检查通过。

历史候选2（已阻断，不得上传）：`build/beta-candidates/0.5.0-19/android-alpha-gm020-2/Pourlune-0.5.0-19-upload-signed.aab`，136231956字节，SHA256 `fbe5f16b7bf7a3d5432e2b58a22143d38cac393da6a64a742b71fa8d3518167f`。只读同字节9文件镜像为`build/package-review/0.5.0-19/android-alpha-gm020-2`。复用原BR05上传key及公开pin，不创建/重置key，秘密不进入仓库或日志。

修复候选3源`de5a5950b6e86c50c24e681add0b43e079bc4145`：`build/beta-candidates/0.5.0-19/android-alpha-gm020-3/Pourlune-0.5.0-19-upload-signed.aab`，136310168字节，SHA256 `bcfa0483c086c71161653829067d12e42ee30f275dcc4699bd7c2ca0ee19c06d`，9文件冻结镜像`build/package-review/0.5.0-19/android-alpha-gm020-3`。570输入对精确提交与固定SDK指纹吻合，147资源/90题、12ELF的16KB段、正式身份/默认Off/双广告ID权限排除/无integration_test原生入口及签名均已作者包核。实际三ABI Dart AOT与候选2逐字节相同，非签名载荷仅classes.dex、映射、R8元数据及两项baseline profile改变；夹具和QA入口不在生产AOT。三个反射构造器在最终签名AAB中全存在，不能据此提前写实际启动通过。新精确CI40837181164两job终态成功：工具87/核心47/应用492通过、1已有opt-in夹具跳过，格式/analyze、Android debug APK、新增minified release AAB及3构造器门槛、iOS simulator编译通过；固定SDK V2恢复7文件。旧CI不重跑，真实release设备门槛仍等解锁。

候选3派生同上传key universal APK137457919字节，SHA256 `3859b4f2e27786e380bcd0acf4033c4c4267b01da31006085a3e6f0f98bdf12a`；168项DEX/native/assets与冻结AAB逐字节相同，APK签名pin及16KB zipalign通过。仅用于专用QA更新原空状态13、观察真实minified正式启动/正常动作/仅App重启；它不等于Google Play Signing证书或物理手机升级证明。独立合成旧库debug QA和此正式release验证队列已准备并交Computer，Mac再次锁屏且正常自动解锁失败；Computer已一次请求本人解锁，总控与开发不重复问，不绕过锁屏、不改安全设置，未Run这两条新入口。

作者离线核563源输入、147包内资源及90题、三ABI生产AOT的正式API/GMID/Android单元、12个ELF的16KB载入对齐、bundletool校验与16KB打包配置、无原生integration_test类/通道、strict签名和pin。包为com.pourlune.app/0.5.0(19)，min24/target36，debuggable=false；实际无GMS或平台Advertising-ID权限，Analytics广告ID采集及原生采集默认false。AAB1到AAB2的非签名ZIP载荷仅`base/manifest/AndroidManifest.xml`变化，其余Dart AOT、dex、原生库、资源均逐字节相同。静态16KB检查不是16KB物理设备运行证明。

新精确CI `40808115652`，head同9eab3b6，两job成功；工具87/核心47/应用491通过、1个已有opt-in夹具跳过，格式与分析通过，APK和iOS simulator编译成功。固定SDK V2真实恢复7文件。未重跑已完成的40715422974/40718567516。CI与实际包是独立证据，未用编译替代Android设备验收。详同名evidence目录的`no-id-ci-final.json`和`repair-r2/`。

## Android 实际状态与限制

设备操作全由既有Use Computer执行。专用AVD`Pourlune GM QA 20261028`/Android16，实际运行时回读emulator-5554；不根据旧编号猜设备，自动目标跳到FishPilot时没有Run。原QA数据先经Device Explorer导出40文件，0700目录/0600文件私密保存，未用allowBackup=false作清库理由。

APK分析项目缺SDK的原因是模块没有SDK引用且项目只指Java21。只在新ignored标准APK项目中显式引用既有Android36 SDK，零编译脚本、clearStorage=false，未改全局SDK或App生产代码。GUI实际安装成功。旧权限变体APK1显示官方测试激励、Reward granted、extraBottle=true/pending0及冷却阻止；这些仅是该次界面回执。

随后专用AVD失联、启动超时。仅精确核对PID/qemu/该AVD路径后通过活动监视器普通Quit，再启动该AVD；F9及其他设备不动。恢复后extraBottle=false、队列状态变化，与之前奖励截图不一致。导出的前后gm_020库均schema5、integrity ok、相同原实例/棋盘，均无奖励回执；before本来是在激励前导出，不能以恢复它修补后发奖励。快照页显示Quickboot自动快照，但尚不足以证明回退原因；没有加载、删除快照或恢复库。该次奖励跨重启持久化未通过，不把它写成App故障已确认或SDK持久化成功。

r2 APK使用同身份/同debug签名、官方测试广告、无两种广告ID权限及独立`gm_020_recovery_20261028.sqlite`，保留旧库。待补受控离线/丢ACK/正常App重开去重、真实无ID广告、SQLite奖励即时回执、冷却/撤回、正常main及后台test/android回读。普通main使用独立gm_020_normal_20261028.sqlite，保持默认统计off；不得用iOS的成功补这些Android缺口。

## 商店与隐私差额

旧13的“不包含广告”须更新，不能沿用。新版实际阻断两条Advertising-ID权限后可按最终包处理AAID声明，但其它SDK标识符仍需披露。既有四类数据中的位置、互动、崩溃/诊断和设备或其它ID逐项核，广告SDK处理不因Analytics关闭而全部可选。拟定字段与官方来源在`data-safety-plan.json`，尚未保存为商店终态。

Play Policy Insights完成7目标/2批critic静态审计；报告仅2项建议。其Flutter动态包名识别为pourlune_dev并抓到404，不能据此认定应用未发布或无声明，也不采用其绿色标题代替实际manifest和真实控制台核对。原报告留在隔离scratch，范围说明在`policy-audit-scope.json`。

支持站隐私HTML已发布最小版本说明及两条广告ID权限的准确文案：支持仓库提交e3d03704、Pages40812749349成功，HTTPS200字节与源一致，SHA912721d14190cd8bf03bd4ce6f3ffe07d44bb790266777ec6ac64c4ff9466e46。未改iOS商店提交。真实13升级准备从原已发行13 AAB派生同上传证书APK，旧AAB SHA3383d698…匹配；这不等于Play App Signing交付签名的手机升级，实际安装及存档回读尚待。

后续须完成真实Android门槛、总控独立核新包、声明和站点一致，再由Use Computer复核19占用并上传/提交现有Alpha封测，回读处理/审核/安装入口。不另开internal或公开production，不新增测试员或重复邀请。物理手机升级、硬件音触觉、真人首玩和正式广告填充保持未验；AdMob应用待审/投放受限不冒称商业readiness通过。

## 锁屏中断及恢复记录

Computer导出r2数据时远端Mac锁屏，正常自动解锁失败。已有本人解锁请求，不再重复问，不绕过登录。锁屏前已留42项r2私密原件：真实首批3/3，加入4条新加载记录后的重传4/7，原3不重复、原ID/首次时间检查true、最终队列0；不能写成纯0/7。实际无ID测试广告完成加载与曝光，但误入外部Play登录后未收到奖励确认；SQLite只有open/confirmed0尝试、1次rewarded shown、无entitlement/extra。证据是中断状态，不冒称完成奖励或跨重启持久通过。已准备只启动已有QA的NoDeploy配置、正常main及真实13/最终19同上传证书APK标准GUI项目，均未借锁屏进行设备操作。解锁后继续剩余实际门槛，再提交Alpha。

本人随后在总控确认已解锁。Computer回读专用AVD身份后仅停止QA App的PID6350，并选NoDeploy启动；控制台只显示Launching，未观察到启动完成，进程列表曾为空，画面仍停在旧Play页。首轮新的Sync/导出未成功，0项不能当作新的停机快照。AX树与实际窗口位置不符、点击报windowNotFoundAtPosition，先核宿主窗口映射，不据此认定游戏或guest冻结。

总控已确认在既有授权内的恢复路径：确认QA App停止，完整导出其databases（含存在的wal/shm）、files和shared_prefs并核同实例/integrity后，Computer可GUI普通停止精确该AVD、单次Cold Boot；不Wipe、不删除或加载快照、不恢复库、不再次Host Quit qemu。启动后先重新导出核原持久状态再NoDeploy。无需再次要求本人操作模拟器。官方单次Cold Boot操作见[Android Emulator snapshots](https://developer.android.com/studio/run/emulator-snapshots#cold-boot-once)。

随后普通键盘Find Action可用，经键盘定位与实际路径匹配行恢复导出。Computer给出三次成功回执：数据库38文件/844134B、files4文件/1096B、shared_prefs7文件/9417B，合计49文件/854647B，存于新的受限`private-r2-app-stopped/`；最后Processes刷新为空且其后未再Run，Sync没有单独完成回执，不虚构该回执。作者核新r2库integrity=ok/schema5，同原实例、完整活动payload和奖励聚合与中断副本一致；已存SDK偏好原字节相同，test/android配置v1、同安装标识、队列0。保全门槛通过后才通知Computer执行上述GUI普通Stop/单次Cold Boot，尚不视作恢复或奖励验收通过。公开核对见`native-r2/stopped-export-database.json`、`stopped-export-preservation.json`，不公开原始标识或数据文件。

旧窗口的Device Manager红色普通Stop不在AX中、坐标仍失败。总控确认只试一次独立新主窗口；新ignored APK分析项目仅引用原冻结APK/现有SDK，不提供Run配置或构建脚本，不关旧窗/AVD。Computer在新窗口safe mode恢复正常点击，随后对精确QA普通Stop、单次Cold Boot成功到Android主屏，仍5554；没有安装/Run、Wipe、旧快照加载或其它设备操作。冷启动后的同库和SDK偏好回读仍待完成，不把主屏出现直接视为存档或完整流程通过。

冷启动后、启动App前另导出同包49文件/854647B。作者逐文件比较全部49项原字节一致，r2库integrity=ok/schema5、原实例payload、完整SDK偏好/安装标识/configv1/queue0保留，奖励确认与权益仍0；详`native-r2/coldboot-preservation.json`。这一保全门槛通过后，才为当前新窗口项目加入明确的`Pourlune_R2_LaunchOnly_NoDeploy`配置（不部署/清库，零BeforeRun任务）继续既有App启动，不再回到坏窗口。此前原队列已完成ACK，后续进程的`restored_original_events=false`本身不能解释成丢队列；原第二进程离线恢复/重传去重证据继续保留。完整激励完成和跨App重开仍待实际回执。

该新项目的模块下拉为空，NoDeploy被IDE以Module not specified拦住，没有实际启动。Computer改为直接使用专用QA的既有Android桌面图标启动，该无效配置随后删除；没有重装/部署或清库。实际Level4显示中断提示，End interrupted request后旧请求关闭且没有补奖。通过实际游戏Extra bottle/Try again/Watch路径，官方Test Ad约20秒后可见，出现Reward granted、真实关闭后Bottle added及五瓶。曾先观察到旧No ad available画面，随后广告出现，不能把前一幅画面直接判成加载或展示失败；界面刷新和SDK展示延迟尚不能精确区分，也未猜测修改App。

立即只停止QA App PID5188后，新副本实际SQLite已核：integrity=ok，同原实例、extra=true、五瓶/revision1；旧中断attempt为closed/confirmed0，新attempt为done/confirmed1，唯一entitlement匹配原实例与该新attempt，pending0，rewarded展示2。SDK偏好确实已变更、同安装标识/config1、队列0，rewarded后的sdkCooldownSaved=false本身不是插屏持久化故障。详`native-r2/reward-committed.json`。目录缓存仍只带出旧2个process文件夹，已要求单独刷新当前证据子目录，不把该49文件副本称为最新进程诊断完整通过。原Reward granted和五瓶截图保留在Computer工具记录，无法文件化的历史图没有重造。跨App重开、真实插屏/撤回冷却、正常main及真实13升级仍继续。

单独Sync该证据子目录后已导出12文件，取到PID5188的当前status/http/ACK：same instance、extra=true/pending0/queue0，最后可见冷却8秒；16条新事件真实ACK16/16，含本次一次曝光、一次earned回调，没有新round start。旧2事件早已收件，当前进程的“首批含原事件/原事件重试”布尔值false不当作去重失败。之后正常桌面重开实际仍Level4/五瓶/Bottle added，没有中断提示；只停止PID6633后同步导出57文件/857591B，作者核原实例及完整活动payload、所有attempt/entitlement记录均与获奖后相同，confirmed/done1、权益1、pending0，SDK同安装/config1/queue0。该进程仅新增active1并ACK1/1，没有重复开局；其它5个已有命名SQLite文件原字节未改。真实激励原实例落盘及正常App重开持久化通过，详`reward-current-process.json`和`reward-restart.json`；不以此代替尚未完成的真实插屏/撤回冷却、正常main、升级与商店门槛。

真实官方测试插屏随后展示、关闭，Flush真实队列后撤回统计并重开。首轮快照63文件/859938B核得插屏1、激励2、唯一奖励仍1；隐私analytics/crash均false，SDK lastShownAt保留，重开PID7885只有配置GET、没有POST。但两进程启动相隔313秒，重开时cooldown0、adConsent=false/库存idle，未见新广告不能归因于冷却；这一不足明记于`interstitial-withdrawal-first.json`。

仅补一组有新目标的统计关闭广告/快速重启观察，没有调时钟：statsfalse仍真实展示另一条官方测试插屏。关闭后只停止App、图标重开，观察冷却123秒；Prepare后许可true/库存ready/冷却103，按一次Show未出现新广告、冷却93且库存仍ready。最终PID9089诊断保存冷却73、sdkCooldownSaved=true。完整66文件/860683B独立核验：两次off进程均无SDK POST、也无任何发送前批文件；SDK lastShownAt相对首轮确实为该off展示更新且跨重开保留，同安装/config1/queue0。SQLite插屏2/激励2、原奖励与原实例完整payload不变、旧5命名库原字节保留。该次排除了未许可、库存未就绪和已过期的混淆，真实统计关闭广告可用及冷却跨重开/拒绝通过；详`off-ad-cooldown-restart.json`。仍只完成专用Android原生广告/SDK部分，正常main、真实13升级、声明/上传和总控整体验收继续，尚未上传Alpha。

正常`lib/main.dart`另用同dev身份的NoAdID测试APK及新`gm_020_normal_20261028.sqlite`运行，Firebase none/GM test。IDE误报SDK36缺失来自生成项目残留SETUP_ISSUES；只去掉该旧缓存并保留原SDK及符号警告，实际android36平台已存在，随后无Build任务安装成功，没有下载/改SDK。初始系统Home后Studio再Run仅作为同APK重新部署保留存档记录；之后专门以系统Home→既有图标验证真正前后台恢复，没有将重新部署冒充恢复。

正常UI两项采集初始Off；Main1完成引导、真实动作、Undo/Hint、Home/Continue，开启统计后首个10/29 Daily执行1→5。测试Android今日开局从1增2，Daily Resume及真正前后台后仍2，最后正常隐私UI回到两项Off并停App。独立核12文件/157997B，其中新库147456B、schema5/integrity=ok：Main1两步/revision4，Hint1/Undo1、引导completed，棋盘等于原定义前两条有效参考动作；Daily002一步/revision1/单条undo，逐格等于初盘的合法1→5动作。最终privacy两false、SDK同安装/config1/queue0、没有奖励attempt或权益。详`normal-main-runtime.json`。单文件SaveAs曾把完整目标路径编码为normal分析项目中的冒号文件名；作者按确切测试文件名找到原件，收紧0600、保留原件并同字节复制至目标私密目录，没有重新操作设备或重造数据。此后继续真实13→19升级及商店门槛，尚未上传。

后台同日test/android/版本19漏斗浏览器实际回读为机会2、加载6/成功6/失败0、尝试展示2/曝光2/奖励1、乱序0；generatedAt为10/29 12:42:26台北，最后上报仍11:19:06。这一范围包含同日既有轮次，不能仅凭奖励总数1声称r2到账；继续要求当前实例的真实回调、SQLite去重权益及重启持久回执。today totals的1活跃/1开局/2展示/0失败不受版本筛选，不能替代该漏斗过滤或归因。原始浏览器回执归档尚待，先按观察范围记于`native-r2/backend-before-r2-completion.json`。

后续15:27台北的浏览器完整响应已由Computer原文转交并归档`backend-test-20261029.json`：test/Android/版本19今日总览1活跃、2开局、4曝光、0加载失败，版本漏斗机会5、privacy阻断1、加载16/成功16/失败0、展示尝试4/曝光4/奖励2、乱序0。包含早先同日QA，不能全部归因于本轮R2，也不把总览当成受版本过滤。`backend-production-20261029.json`同过滤范围hasData=false/updatedAt=null、总览null/漏斗0；仅说明这次正式Android过滤无数据，收入unsupported_filter不是收入0。没有向正式游戏伪造测试统计。

Play只读原声明10/25为无广告/无广告ID；五类数据均收集不分享，互动/崩溃/诊断可选、位置/ID必需，用途没有广告。逐字段差额在`play-current-declarations-readonly.json`及`data-safety-plan.json`：新包需含广告true；AAID依最终双权限缺失保持false，其它标识仍披露；Google广告位置/互动/诊断/ID共享及广告/安全用途不能被统计Off掩盖，Remote Config位置的应用功能用途保留。没有保存或提交声明，最终须按实际标签逐项回读；持有人法律承诺和未知账号事实不猜。

## R3 真实 minified 运行结果

本人解锁后，Computer在原专用QA/emulator-5554安装现成R3正式APK，首次正常渲染Main1，引导、Undo、Hint、有效动作和Home/Continue均可操作。仅Android应用信息中对Pourlune执行Force stop，再从原图标重开成功；Continue恢复此前四瓶容量2/4、4/4、2/4、0/4，之后真实2→1变为4/4、2/4、2/4、0/4。没有重装来冒充重启，没有AVD重启或清库，没有手点正式广告。隐私页Analytics/Crash仍Off。

当前Logcat `package:com.pourlune.app`、重开PID13997可见FirebaseInitProvider初始化成功、cold app start和analytics collection disabled；本次可见过滤会话没有FATAL EXCEPTION，不扩大为全历史无错误。实际正式minified启动和操作已越过旧13/R2在Flutter前的WorkDatabase崩溃，不以构造器静态检查替代这个结果。来源是Computer实际GUI观察及直接交接，开发没有绕过GUI操作设备，也未读取不可调试正式包的私有库；详`release-startup/actual-r3-runtime.json`。

新会话同时出现UMP publisher misconfiguration（该AppID没有配置表单）及两次Ad failed to load:3，设备标记为test。按[Google Android AdRequest官方定义](https://developers.google.com/admob/android/reference/com/google/android/gms/ads/AdRequest#ERROR_CODE_NO_FILL)，3为no fill，不能写成网络超时或真实广告展示成功。后台UMP表单与商业填充仍有明确未完成/异常边界，继续保留；没有通过绕过同意、换单元、反复重请求或伪造数据掩盖。该运行证明核心流程不被这些警告阻塞，商业readiness仍未通过。

合成旧库debug APK已安装，首页Continue Level4可见；其后游戏UI/仅App重启及库导出因CUA窗口映射未完成。总控明确收敛门槛：原13精确源生成与当前真实SQLite动作/undo/restart/save/reopen验证已通过，额外替代夹具GUI如因工具失败，明确未验即可，不再单独阻断本次更新。仍不称原发行13非空现场升级。没有为此新建包、设备或重复旧SDK测试/终态CI；F9未动。

总控已依据独立签名包、此前原生/正常main证据及本次Computer实际R3结果放行原Alpha19，机器终态为`release-startup/r3-runtime-acceptance.json`；没有扩大为公开production、iOS19变更、邀请或默认隐私改变。

UMP新警告的代码门控已只读复核：`UmpConsentGateway`在成功/失败回调都读取真实SDK `canRequestAds()`，读取失败则false；ServiceHub更新前先关闭广告资格，SDK结果不允许时返回并维持false，只有SDK明确允许才初始化/预加载，失败标记仍保留。没有将后台无表单或统计Off解释为擅自许可，也没有因为警告强制true。[Google Flutter UMP指南](https://developers.google.com/admob/flutter/privacy)明确允许在更新失败后咨询SDK已有同意状态。两个采集默认false保持；本轮没有新增运行采样去推断PID13997的具体资格布尔值，没有重跑已验测试。

Computer另只读看到Android AppID与实际包/日志一致，商店关联为“—/添加”，隐私总览的欧洲/美国州级项均为“创建”、无管理消息入口；欧洲消息页仍加载，故不能扩大断言所有表单为空。具体Android消息/商店关联与商业填充作为待办留真，不为它重复造包或改iOS。详`release-startup/ump-current-gate-review.json`。

既有ASC隐私只读页显示11小时前由持有人发布，七类为其他诊断/广告/设备ID/产品互动/崩溃/大致位置/性能，均显示身份关联；当前无待发布按钮，本轮没有修改或重复发布。本人“同意并发布”仅对应此前隐私准确性承诺，不推断另一份草稿或新iOS提交授权；见`asc-privacy-existing-readback.json`。

## Play 上传与送审请求（等待平台实际回执）

Computer在上传前回读版本/bundle目录只有13、12，19未占用、原Alpha没有重复草稿。已保存Contains ads=是与Data safety，并在预览逐项核准：位置/互动/诊断/设备或其它ID的分享用途均为分析、广告营销、防欺诈安全合规；位置/ID的收集另外含应用功能，互动/诊断收集为三项，Crash收集仅分析、可选且不分享；传输加密。原来单一用途草案已按实际两页拆成collection_purposes/sharing_purposes，不把RemoteConfig的应用功能直接扩到广告第三方分享。

唯一候选3审核副本已上传，Play识别19(0.5.0)、min24/target36，ReTrace与原生符号附带。原Alpha100%预览已保存，发布概览恰为Alpha19、广告、数据安全三项。Computer已点击并确认送审，此后页面仍显示“尚未提交送审的更改”及最长14分钟快速检查，提交活动没有新条目；因此本轮此刻只能记录请求已发/检查中，尚无实际送审、审核通过或19可安装回执。保留当前页面等待，不重复上传已占用的19或反复点提交，不改公开production、测试员或iOS。机器记录为`play-upload-and-review-request.json`，后续实际回执另补。

## 实际送审受理回执（覆盖上节检查中状态）

快速检查完成后，Play明确三项可送审；此前检查中及就绪后的语义/前台原生确认合计三次没有受理证据，重载仍未送审、活动仅旧1/2，具体原因未知，不能把按过按钮当成成功。随后总控授权一次改变诊断条件的正常UI提交：先开启Chrome Network并由普通重载验证可捕获，再清列表、只按同三项的正常提交确认。实际可见`publishing:sendChangesToRe…` XHR状态200，页面随即明确“正在审核中的更改”“您的更改目前正在接受审核”，列封闭式Alpha0.5.0(19)及应用内容。未展开认证头或导出HAR，没有猜API/脚本代发、改权限或范围。

本次已有真实受理证据；前面未受理的原因仍未知，不反向推断。原包/19占用/签名源不变，无需再次提交、重传、构建或CI。Google审核通过、轨道实际生效及19安装仍待平台后续结果；加入测试链接如存在也不能代替这些状态。请求与UI回执已合并到`play-upload-and-review-request.json`，Computer正在作最后只读原轨道/范围/既有入口核对。

提交活动随后新增ID3，页面时间2026-10-29 17:32，范围封闭式Alpha/应用内容，状态审核中；发布概览逐项显示Alpha19、广告声明、数据安全均在审。总控已在`parent-formal-submission-acceptance.json`接受正式送审终态。未把受理写成批准，也没有重提iOS19。

## 最后只读范围与入口核对

Alpha19审核中、13已向所选测试人员发布。实际国家/地区是美国及巴基斯坦；测试页选择Pourlune Beta（列表1人）及“10月29test”（列表51人），FishPilot/test未选。列表人数不等于去重人数或实际加入/安装人数。Save/Discard均disabled，Computer本轮没有改名单、地区或邀请；本次观察不能推断是谁何时配置，不能写成仅本人/仅美国已核或范围一定未变。已交总控按最近人类授权核定这一实际既有范围，不自动删名单/国家、不重传19或重提审核。

实际现有[加入测试入口](https://play.google.com/apps/testing/com.pourlune.app)及[商店入口](https://play.google.com/store/apps/details?id=com.pourlune.app)可见，但没有加入/安装操作，入口不代表19已审核批准或可安装。回读时自管发布关闭，故当前范围的最终授权核定需与后续发布区分；详`play-final-scope-and-entry-readback.json`。正式送审ID3事实仍有效，iOS19/F9不动。

总控随后让Computer开启自管式发布并实际回读“已开启自管式发布模式”；正在审核的19/广告/数据安全必须在获批后另行决定发布，目前ready区无项目。未点发布、撤回、改名单/地区或停止旧13；ID3仍审核中。该可逆hold保留原既有设置，由总控核最新本人分发授权后处理，不将无近期授权记录推断为他人擅改。

总控已就当前两地区和两列表明确询问本人，得到直接答复“是，19版按当前国家和名单开放”。因此当前范围已获授权，不能恢复为早期仅US/本人，也不归因为误配置。总控已让Computer核仅本次三项后恢复原自动发布；如已获批则仅发布这三项，不撤ID3、不改名单/地区、不邀请或改iOS/公开production。恢复的实际UI回读尚待，范围本身不再阻断或重复询问。

最终恢复已实际回读：在确认仅Alpha19/广告/数据安全三项审核中、ready区为空后关闭自管发布，页面显示“已关闭自管式发布模式”及审核批准后自动发布；三项及ID3仍审核中。未变更名单/地区、邀请、撤回、重传、重提或iOS。当前已无需本人再操作；等待Google外部审核，19可安装状态尚未确认。商业UMP/商店关联/填充、物理手机及硬件音触觉/真人首玩等未验边界继续保留。
