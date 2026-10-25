# BR03 实际候选与符号索引

2026-10-23（Asia/Taipei）整理。来源精确JSON：[artifact-index.json](artifact-index.json)。本批没有重建或改动BR01候选；接受提交33433c76cd6c97338f0016815208999832050cfb与原构建时0727f9c的关系是：构建时工作区字节由sources.json锁定，之后精准提交。当前两份394项散列仍完全一致，不要求原metadata的git_head假装变成后来的提交。

|对象|真实位置（项目根下）|散列／用途|
|---|---|---|
|iOS唯一指定Store IPA|build/beta-candidates/0.5.0-5/ios-br01-3/Pourlune-0.5.0-5.ipa|0d98659a5c9c6f1253cd6e357d1f46954f71ed5a44b62f9453d100dccc82ebf5；59257617 bytes；0.5.0(5)，com.pourlune.app。签名通过，仍有最终配置/持有人/设备门槛，不是可直接侧载文件。|
|iOS归档|build/beta-candidates/0.5.0-5/ios-br01-3/ios-export/Runner.xcarchive|Info/原包/dSYMs保留；导出选项在ios-export/ipa/ExportOptions.plist，destination=export，不自动上传。|
|iOS符号|上归档dSYMs/|5份DWARF条目，4个不同模块（objective_c两份同UUID重复条目）；逐份UUID和实际导出Runner/App/Flutter/objective_c相符，hash见JSON，未上传。|
|Android原始AAB|build/beta-candidates/0.5.0-5/android-br01-3/app-release-unsigned.aab|ea71eb8815f07210627e67e7af84d8ca367ecf469e4e46b19ebffa6abc574a90；106155330 bytes；0.5.0/5，com.pourlune.app，target36/min24。unsigned，不能上传或直接adb install。|
|AndroidR8 mapping|build/beta-handoff/0.5.0-5-br03/android/mapping.txt|从该AAB内BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map精确提取；hash见JSON，并与当前生成mapping.txt核对相同。不靠可被下一次构建覆盖的路径保存唯一副本。|
|Android原生符号|上述AAB内BUNDLE-METADATA/com.android.tools.build.debugsymbols/|arm64-v8a/x86_64/armeabi-v7a各libflutter/libdartjni/libapp，共9项；逐项容器/成员路径/bytes/hash在JSON。没有另造Dart split-debug-info或声称32位运行通过。|
|两份源码清单|上述两个候选目录各sources.json|均SHA256 3348e6b5ee555cb5a9cdb57c7bd2461de6f788905ebf5c319b970d2a403c70f1，各394项；二进制、元数据和签名记录不因本批文档更新被覆写。|
|客户端公开配置指纹|JSON client_config_public_fingerprints|仅记录prod项目/AppID/nativeID及文件SHA；本批4份prod文件仍匹配。没有把真实配置内容、私钥、密码、profile文件或服务账号打进交接压缩包。|

精确候选JSON本地索引另存build/beta-handoff/0.5.0-5-br03/artifact-index.json；后续交接ZIP只收资料与公开指纹，不复制大型包或私密配置。IPA原导出同字节副本与失败/中间目录不另作为“候选版本”；唯一指定为上表final3文件。Android签名后会产生新hash，必须新命名并重新核对，不能把当前索引静默改成signed。

已有独立验证见[BR01独立报告](../../../review/beta-readiness-BR01-acceptance.md)。本批只新增来源/顶层hash/配置指纹及符号对应核对，不重复BR01完整签名/manifest/资源实验，也不把这些静态读取算作设备通过。后续必要变化见[重建与复验条件](rebuild-and-revalidation.md)。
