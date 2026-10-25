# Pourlune支持/隐私网站

2026-10-23。用户已明确授权复用FishPilot实际主体与支持邮箱，并发布独立GitHub Pages。唯一源码根为`pages-site/`；只含`index.html`、`privacy.html`、空`.nojekyll`。旧`beta/`和BR04 ZIP是历史本地草稿，不是发布根。

- 帮助：https://wangyule0379-max.github.io/pourlune-support/
- 隐私：https://wangyule0379-max.github.io/pourlune-support/privacy.html
- 邮箱：wangyule0379@gmail.com（用户批准公开复用；未发送测试信，真实收件/处理仍待实际请求验证）。
- 独立公共仓库：[pourlune-support](https://github.com/wangyule0379-max/pourlune-support)，提交`24ff80c6fc0cc2f0b513b49c5c236a029334cc2b`，Pages[39906073868](https://github.com/wangyule0379-max/pourlune-support/actions/runs/39906073868)终态success，main根目录/默认域名/强制HTTPS，无CNAME或购买。

主体`changjiang li`从ASC商务协议实体记录只读核对，未从证书CN/用户名猜测；证据仅保留必要姓名与依据，不复制私人电话/地址/银行资料。FishPilot旧支持页提供邮箱来源，但Pourlune内容按本项目离线/无账号/无付费/默认可选采集/RC实际功能另写，不照搬其账号/位置/订阅条款。

网站无JavaScript、表单、嵌入媒体、外链字体或主动analytics。GitHub会记录Pages访问IP用于安全，外链及用户主动邮件由对应供应商处理；正文明确说明，不承诺零收集或删除供应商日志。请求和保留说明不虚构固定响应天数或自动SDK删除能力。

本轮部署与HTTP正文hash、导航和有限布局检查在`docs/development/evidence/beta-readiness/BR06/`。公开App源码仓库可见性未改；没有发布app/config/build/测试名单/私密文件。站点上线不代表商店法律/受众/数据标签最终通过。

## 后续有限更新与打包

编辑此唯一根的已知段落：`index.html#operator-contact`和`privacy.html#operator-contact`为主体/邮箱；`privacy.html#requests-retention`为可履行请求/保留流程；`#providers-transfers`为服务方/处理；`#children`不代替目标年龄问卷。更新这些事实时同步商店声明，必要时新候选目录重建；不要只改历史ZIP或另造模板站。

先核对这3份文件和正文无占位/密钥，再按文件名逐个打包（不能递归docs或仓库根）：

```python
from pathlib import Path
from zipfile import ZipFile
root = Path('docs/support/pages-site')
names = ['.nojekyll', 'index.html', 'privacy.html']
assert sorted(p.name for p in root.iterdir()) == names
output = Path('build/beta-owner-assisted/BR06/support-site.zip')
output.parent.mkdir(parents=True, exist_ok=True)
assert not output.exists()  # 冻结包不覆盖
with ZipFile(output, 'x') as package:
    for name in names:
        package.write(root / name, name)
```

发布后只读检查该commit的远端tree白名单、Pages终态及两个HTTPS正文与本地逐字节一致；浏览器检查相对两页导航和mailto，不自动发邮件。移动CSS含device-width viewport、流式max-width/16px窄屏边距、44px导航、长链接换行。当前实际浏览器1440宽无溢出；320/375/430是静态结构检查，真实手机浏览保留未验。没有采集系统屏幕/设备图或绕过既有限制。
