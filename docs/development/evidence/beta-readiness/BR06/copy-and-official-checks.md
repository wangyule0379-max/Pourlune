# 英文粘贴字段和官方核对

六个同目录.txt只含目标字段正文（Play release notes含en-US标签），不含主体/邮箱占位符；提交前按最终精确候选再核对版本适用性。用户批准的name=Pourlune、语言English(U.S.)、SKU=POURLUNE-IOS-001仍复用BR04，不重复造字段。

- Apple：apple-beta-description.txt、apple-what-to-test.txt、apple-review-notes.txt。审核不需登录信息已并入notes。Beta说明和反馈联系见[官方测试信息](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)。该页未公开这些字段的字符上限；本批三字段均压在2000字符以内，2000仅为本地保守预算，**不冒充官方上限验证**，实际填写时以控制台字段校验为准。不借用IAP Review Notes的4000限制证明Beta字段。
- Play：play-short-description.txt复用既有34字符短句；play-full-description.txt独立全文；[官方限制](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)：name30、short80、full4000。play-release-notes.txt按[官方release格式](https://support.google.com/googleplay/android-developer/answer/9859348?hl=en-EN)在单独行使用语言标签，正文≤500 Unicode字符，无促销或催下载。
- 文案数量依据：内置60 main与30 rotating daily candidates、3scenes；不是每日30新关。默认analytics/crash off不写零数据，adsdisabled仅当前beta；不承诺真机表现、网络送达、云存档或永久商业策略。
- TestFlight内部使用既有合格ASC账号资格；外部需要Beta App Review测试资料/真实审核联系人/反馈邮箱/出口信息等。正式App Store全部宣传截屏不自动提升为TestFlight内部/外部一律必填；[Apple测试说明](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/)明确其测试资料可与以后上市资料不同。
- Play closed使用真实listing和App content/签名/隐私/目标地区/测试者配置；internal不是closed替代。[官方测试轨道](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en)。个人账号后续生产访问测试规则不冒充本批启动closed前必须已完成的条件。

访问日期2026-10-23。字段字符实测见delivery-checks.json；未登录提交表单，不声称平台已接受。
