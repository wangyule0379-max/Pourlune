# Firebase 收件有界定位补充

2026-10-22，Asia/Taipei。基线为已由架构接受的44353c9及后续文档提交；本补充**没有修改客户端源码、SDK、构建选择、TLS、代理、证书、权限或生产环境**。结论是两端各自的原生日志已定位到具体失败环节，不能继续用“可能忘开调试/同意”解释；也不能越过证据推断是哪一个VPN/代理/运营商/远端策略造成。

## 结论

|平台/服务|已证实前置链路|实际失败环节|
|---|---|---|
|iOS Analytics|真实dev App；-FIRDebugEnabled在进程参数；SDK原生确认debug/real-time；analytics_storage=granted；measurement enabled；pl_hint_result原生记录成功|app-analytics-services.com/config/app/... 请求在TLS阶段失败，NSURLErrorDomain -1200、底层-9816，日志为server closed session with no notification；未取得HTTP结果|
|Android Analytics|真实dev App；debug.firebase.analytics.app为精确包名；FA确认faster debug mode；native/API及GMS侧analytics_storage=granted、measurement=true；具名事件进入FA-SVC并安排upload|同一有界窗口内，明确属于dev包的GMS CONFIG请求报Cronet ERR_CONNECTION_CLOSED，ErrorCode5/InternalErrorCode-100；该行未给出URL，不能虚构其具体主机或声称是Crashlytics同一请求|
|iOS Crashlytics|持久化crash=true后先冷启动；原生自动采集仍disabled；native crash后同安装新PID；Sending unsent reports→packaged report→Submitting report async|firebase-settings.crashlytics.com 的settings及crashlyticsreports-pa.googleapis.com/v1/firelog/legacy/batchlog均出现原生TLS -1200/-9816；“Completed report submission”只代表本地交给传输队列，随后batchlog失败，不是服务端收件|
|Android Crashlytics|持久化crash=true后先冷启动；native crash后同安装新PID；Waiting for send/delete→Sending cached crash reports|向firebase-settings.crashlytics.com的Android dev App设置请求报SSLHandshakeException: connection closed，底层EOFException；尚不能进入成功的settings/收件链路|

此外，不携带App ID、配置或凭据的**主机curl根路径TLS基线**对上述三个iOS明确主机均exit35、HTTP000。这是同一主机现有路由上的独立旁证，不替代原生SDK日志，也不证明Android Analytics那条未暴露URL的请求使用这些主机。未禁用校验、未绕过代理或切换网络。iOS原生日志将当前路径标为satisfied、interface utun1024；只能说明观察到的传输路径，不能据此认定某个软件/持有人配置错误。

## 实验与可重复定位

使用原专用Simulator 7C054CE1-CCA7-405E-A884-886A859D6968及AVD emulator-5582。安装中的dev QA保持不变，**没有使用app/build的none产物重装**，没有删存档；前后iOS同实例修订2、Android同实例修订3均clean且与落盘一致，保留了架构手动操作结果。

时间窗约12:15:10–12:18:10，一次180秒有界原生日志录制。读取原生偏好仅保留consent/enabled白名单；请求URL去query，客户端key在内存过滤，运行/安装/session标识脱敏后落盘。iOS起初包含的无关CFBundle/计时器条目已从交付精简；Android同一已录制时间窗的logcat补读仅补足捕获过滤器遗漏的debug/CONFIG错误行，不是新增实验或轮询。

1. 首次取样双采集off/off、原存档状态。开启原生debug日志；正常main/Bootstrap仍由现有隔离QA委托。
2. 显式调用现有privacy选择为true/true，观察原生consent和measurement生效。iOS实例ID未导出；Android storage编码G101与原生日志的analytics_storage=granted、ad_storage=denied对应，日志是主要判断依据。
3. 各平台仅一个新具名hint实验：`rxd-ios-event-20261022t1225`、`rxd-android-event-20261022t1225`（名称是唯一实验标签，实际时刻以utc字段为准，均约12:15:28）。现有QA每个identity调用两次，SQLite仅一个claim，原生pl_hint_result记录对应此次操作。未新增事件类型或自由文本。
4. 保存共享选择后同安装重新启动，确保新进程初次report action是send，避免用首次off状态已经选择delete的同一进程解释发送结果。fresh-shared证据PID iOS19546/Android4913。
5. 各做一次受控service nonfatal与一次native crash，随后脱离调试器同安装启动：iOS19546→19718；Android4913→5097。未中途重装、清缓存或变更SDK设置；SDK日志分别展示实际send路径及对应TLS失败。命令曾在异步诊断尚未完成时提前发出一次launch（返回同一旧PID/Activity未重启），没有把它计作恢复；收到crash完成回执后才执行上述真实新PID启动。
6. 保存日志后撤回为off/off，关闭Android debug/verbose属性，以-FIRDebugDisabled重启iOS；最终快照iOS20400、Android5097仍为SDK ready、off/off、安全RC策略及原修订。没有继续触发事件或崩溃。

## App / 属性与采集检查

- 安装中的iOS plist回读project pourlune-dev、App1:309263048936:ios:176391f479157c675ca95d、bundle dev.pourlune.pourluneDev；Info.plist的两项默认采集false。原生持久化analytics_storage=granted、ad_storage=denied、measurement_enabled_state=1，且SDK明确记录事件带_dbg=1/_r=1。
- 从**已安装**Android包复制base.apk到本机临时目录，仅用aapt2读出白名单：google_app_id为1:309263048936:android:46b23c29ec2729e25ca95d、project pourlune-dev，Crashlytics build ID存在。未读取app/build的none产物冒充dev。见android-installed-binding.json。
- 两端真实Firebase.app返回与上述原生App相符；公共registration.json登记dev属性560151748、iOS流16177185477、Android流16178472667，已有架构独立报告回读dev属性。此补充核对这些当前登记与安装身份，不把历史截图写成新的浏览器现场读取。三个主机TLS在HTTP前失败，现有证据不指向由错误App/属性ID造成的服务端拒绝。
- `deferred_analytics_collection`内部持久化值仍可见true；没有强行改写。不能凭这个内部字段判当前许可关闭：同一窗口明确出现原生measurement enabled、granted consent、event logged以及原生传输尝试。这里依据可观察链路，不对未知内部字段语义编造解释。

## send/delete时序与代码结论

已查当前[DebugView官方说明](https://firebase.google.com/docs/analytics/debugview)、[Apple手动报告API](https://firebase.google.com/docs/reference/swift/firebasecrashlytics/api/reference/Classes/Crashlytics)、[Android手动报告API](https://firebase.google.com/docs/reference/kotlin/com/google/firebase/crashlytics/FirebaseCrashlytics)及本地固定版本源码。

官方sendUnsentReports是排队，不提供服务端回执；未开启automatic collection时仍可手动send。iOS Firebase13.0.0 FIRCLSReportManager的_reportActionProvided是每次执行的promise，send/delete fulfill该选择；checkForUnsentReports也限定每次执行一次。FlutterFire6.0.0 Android桥send/delete调用原生后即回调，不等待HTTP。既有gateway始终保持automatic=false，以已保存的选择分流send/delete；本次在共享true的新进程中确实走send，因此没有凭空修改该生产路径。

iOS还记录GADRegisterExceptionHandler警告，但实际测试崩溃已收集、打包并送入传输队列；这个警告不能解释已经观察到的settings/batchlog TLS失败。本次不扩展为AdMob改造。

**未发现本次能够证实并需修复的客户端收件代码缺陷。** 因为没有源码修改，不重复跑B05、全量平台构建或不相关测试。原生实际初始化/许可/事件/发送失败证据比新增mock测试更直接。没有用send返回、pending=false或本地“submission completed”提升控制台收件状态；本补充不宣称Analytics或Crashlytics已收件，也不做无效刷新轮询。

## 交付与下一步

证据目录 `docs/development/evidence/firebase-receipt-diagnosis/`：

- ios/android-native-sanitized.ndjson：精简、脱敏原生日志，保留带时刻的完整链路；line number可用于独立定位。
- native-choice-and-binding.json、ios-launch-debug-arguments.json、android-installed-binding.json：实际native设置、标志及安装身份。
- rxd-*-before / enable / event / fresh-shared / nonfatal / crash / after-crash / restored-off / cleanup-checked.json：唯一命令ID和PID/修订/选择证据。
- host-tls-baseline.json：不带配置/凭据的主机TLS基线。

外部阻塞已缩小为**当前实际访问路径上的Google测量配置、Crashlytics设置/报告端点TLS或连接失败**；尚不能细分到VPN/代理/出口/远端兼容问题，不推定全部是用户网络。最小后续动作是由管理该访问路径的人核对上述明确端点的正常TLS可达性，或在已有获准的可用网络上由执行方复验同一个dev流程；不用重新下载配置、重新开户、换项目或放宽TLS/权限。Apple登录保持此前等待，不重复提出。

本补充结论已足以停止本轮收件实验，保留外部收件未通过，继续已获用户确认的M01–M08加载/过渡优化。仅新增本交付/证据，不修改tracking、plans或review；等待架构独立验收后由架构决定提交推送。

最后设备盘点时adb已无emulator-5582；原因未查明，不归因于App。此前恢复debug/verbose的命令均exit0，随后live Android5097明确off/off、原修订3；最终无法再次读取属性，以cleanup-and-binding-checkpoint.json如实标记，未为补读而反复重启Firebase设备。其AVD安装/数据未清理。原普通审查库摘要再次一致。
