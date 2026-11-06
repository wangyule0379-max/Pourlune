# S4i 同意边界受控自测 · 2026-11-07

4199/qa/ad-consent.html，冻结 s4i-native-consent-selftest-1。所有HTTP拦截、原生广告回调模拟；不代表真实服务或原生验证。

首页Continue Level1（页面初始已显示Continue，未重新弹首次选择；Settings确认Not allowed）→Deliver old Off impression，old sent0、observer held、gate false。Settings→Analytics→Allow后gate true→Release held SDK→重放旧展示，old sent仍0。New permitted reward及Replay后回原关卡六瓶；倒一手再Undo回0仍六瓶。等待约30秒后old sent0/new sent1、observer released、gate true（consent-counts.jpg）；HTTP503可重试，发送数不是去重证明。浏览器error/warning为空。

按夹具要求结束POST /qa/release-s4i-sdk返回204。未读取或记录安装ID/HTTP正文。未测真实SDK广告、后台或设备；Android Activity重建与iOS/Web Retry回调来源另有开发待修事项。
