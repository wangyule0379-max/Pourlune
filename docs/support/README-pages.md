# Pourlune支持/隐私静态站预备方案（未公开）

2026-10-23。仅可部署根目录为pages-site/，其中只有index.html、privacy.html和空.nojekyll；不发布Pourlune App源码仓库。现有beta/本地草稿继续保留。本批未创建公共仓库、未改源码仓库可见性、未部署，也没有购买域名。

低成本建议：在用户明确批准后，建立独立仅网页公共仓库pourlune-support，以GitHub Pages发布。GitHub Free支持公共仓库Pages；默认project-site地址模式是https://<实际owner>.github.io/pourlune-support/。这只是方案，当前地址不存在/未批准，不编入App、不作为已可用政策URL。账号真实owner及命名冲突应在获准时核对，不把已有源码仓库直接变public。官方[Pages说明](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages)。

## 已准备与发布前差异

|项|当前交付|正式公开前必须补齐|
|---|---|---|
|纯网页包|pages-site/3文件，原始内容由现有beta帮助/隐私草稿复用；精确hash与ZIP在BR04证据|只复制这3个网页文件，不能递归发布docs/、app/、build/、仓库根目录或任何配置/日志/签名资产|
|状态标识|LOCAL REVIEW DRAFT、noindex/nofollow、无占位mailto/地址|经营/隐私主体、真实公共邮箱及处理人、可履行的保留/删除/请求流程、受众地区/批准日期及最终SDK披露确认后再更新标识。不能只去掉DRAFT就称法律通过|
|访问处理|网页无表单/JS/跟踪脚本/外链字体/嵌入媒体；供应商链接为真实anchor|GitHub Pages会记录访客IP用于安全；GitHub自己的处理/保留按其政策，不承诺网站“零收集”，不替GitHub承诺删日志或保留期限|
|App与网页区分|App本地保存及可选SDK说明、当前adsdisabled/默认采集off/RC风险如实保留|最终配置和实际批准运行范围核对；链接对浏览器/邮箱的处理与App内处理分开披露|
|发布与验证|仅本地ZIP和文件结构/链接检查|本人批准独立公共repo/公开内容及部署后，再按具体目标执行。随后检查HTTPS证书/正文/两页导航、无登录墙及手机浏览，并真实验证邮箱收件；最后批准URL/邮箱交给构建工具|

GitHub明确[记录Pages访问IP用于安全](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages#data-collection)，[隐私政策](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)另有服务处理说明。当前只是可审可部署结构，不是有效公开政策或网址。无第三方网页图像/字体，不扩大游戏视觉范围。

后续获准的Pages建议配置：独立repo根目录的main分支发布、Enforce HTTPS，使用项目子路径下相对导航；不设置自定义域名/CNAME，不购买服务。此说明不执行gh repo create、git push或Pages API。
