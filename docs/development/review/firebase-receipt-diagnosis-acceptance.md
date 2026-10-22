# Firebase 收件定位：独立审阅

2026-10-22，架构方。结论：**诊断交付通过；Analytics／Crashlytics 控制台收件仍未通过**。没有将本地入队、SDK ready、配置存在或CI成功当成服务端收件。本次未更改应用代码，无需重跑已有整批构建或重复制造测试崩溃。

## 独立执行与证据

读取全部26份JSON/NDJSON并验证可解析，生成逐文件SHA-256及敏感模式检查，见 `firebase-receipt-diagnosis-evidence/independent-checks.json`。核对具体原生日志、平台绑定、实验快照与现有 `app/lib/services/firebase_gateway.dart` 的选择/发送路径。检查现场设备：Firebase专用设备当前未运行，现有运行设备用于动效；未启动或重新安装Firebase App干扰并行任务。simctl当前容器查询不可用，改为只读已知设备目录：普通库摘要仍为 dc94bbfd1e8b10cda675f139a822c39e83dcc38bdf830c3a245d2221da9978c6；iOS测量偏好原始值为2。该读取不充当新的SDK操作或控制台收件证明。

|审阅项|独立检查依据|结论|
|---|---|---|
|开发环境与采集许可|安装绑定与native-choice-and-binding；双端fresh-shared为dev项目、true/true、automatic crash=false；iOS日志105–106、Android38/42/51|原生记录事件并确认debug/consent，不能再只用“没有开启调试”解释该窗口|
|iOS Analytics失败|ios-native-sanitized.ndjson 101–104、105–106及436–439|配置请求app-analytics-services.com在HTTP前-1200/-9816；事件本地记录不等于上传成功|
|Android Analytics失败|android-native-sanitized.ndjson 51、58–59|dev包GMS CONFIG出现ERR_CONNECTION_CLOSED；URL未给出，不补写推断主机|
|iOS Crashlytics失败|iOS350、379–381、465/491|发送/打包/本地submission后batchlog TLS失败；不接受“Completed report submission”为服务端收件|
|Android Crashlytics失败|Android151、153–156、181|发送缓存报告后settings请求SSLHandshakeException/EOFException；未观察成功响应|
|重启与清理|fresh-shared→after-crash PID iOS19546→19718、Android4913→5097；cleanup-checked双端off/off、rev2/3、clean|证据支持本轮重启及选择撤回；不是架构本轮重新操作。Androiddebug清理命令成功来自执行证据，最终设备消失，属性最终读回未验证|
|存档与安全边界|前后instance/revision及落盘一致；普通库独立摘要一致；无新源码差异归属本诊断，文件敏感模式扫描0命中|可归档；没有更改TLS/代理/生产采集配置的实现要求|

主机根路径curl返回exit35只作为原生日志旁证，不单独证明SDK请求或精确网络根因。日志中的utun接口也不能证明某个代理软件、运营商或远端配置有错。

## 官方语义核对与局限

独立打开[Apple Crashlytics API](https://firebase.google.com/docs/reference/swift/firebasecrashlytics/api/reference/Classes/Crashlytics)，确认sendUnsentReports是将报告排队上传，仅自动采集关闭时适用。独立打开[DebugView说明](https://firebase.google.com/docs/analytics/debugview)，确认iOS启停参数及Android包名/.none.调试属性。没有将SDK返回当成HTTP或控制台回执。

本次接受的是有界实验的证据与失败阶段定位，不是对客户端实现“绝无其他缺陷”的证明。没有重新打开控制台宣称最新零事件；没有重跑作者全部实验；尚未验证TLS通畅后两端事件/崩溃入库和可读栈。Crashlytics符号完整性最终仍需真实报告确认。模拟器/模拟设备结论不能代替真机。

## 未关闭事项与后续

- FI-E01（外部依赖，阻止服务验收）：当前访问路径的TLS/连接失败。需管理该路径的人核查 app-analytics-services.com、firebase-settings.crashlytics.com、crashlyticsreports-pa.googleapis.com 的正常TLS可达性；Android Analytics主机仍未从现有日志获知。不要关闭证书校验或宽放权限。网络恢复或提供已有获准可用网络后，原执行聊天按dev配置复验一次，本聊天核对控制台实际收件。
- FI-E02：Apple既有账号登录依赖仍保留，不重复要求开户或下载Firebase配置。
- M01–M08已开始，使用独立动效设备；本项外部依赖不阻塞动效实现与验收。

精确实现44353c95599f4fb236bda7002d9ca65c129c42e0的GitHub Actions run39720915730已独立读取为completed/success，见 `firebase-integration-evidence/remote-ci-final.json`。此CI以后不再轮询，诊断/跟踪文档提交无需新平台CI。
