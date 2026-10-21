const fs=require('fs'),path=require('path');const root=path.resolve(__dirname,'..'),base=path.join(root,'revision-r1');const rows=[
['R01 · 4/5首页进入收藏','before/R01-progress-4.png','after/R01-collection-4.png'],
['R02 · 待奖励→Stay here→Undo','before/R02-reward-pending-undo.png','after/R02-reward-pending-undo.png'],
['R02 · 未保存→Undo','before/R02-pause-stay-undo.png','after/R02-pause-stay-undo.png'],
['R02 · 旧每日→Undo','before/R02-daily-old-board-undo.png','after/R02-daily-old-board-undo.png'],
['R02 · 重玩身份','before/R02-replay-board-undo.png','after/R02-replay-board-undo.png'],
['R03 · 六瓶超时→重开→取消','before/R03-six-cancel.png','after/R03-six-cancel.png'],
['R03 · 七瓶→Undo→重开确认','before/R03-seven-confirm.png','after/R03-seven-confirm.png'],
['R04 · 首关Skip','before/R04-tutorial-skip.png','after/R04-tutorial-skip.png'],
['R05 · 橙瓶裁切','before/assets/bottle-0.png','../assets/bottle-0.png'],
['R05 · 蓝瓶裁切','before/assets/bottle-3.png','../assets/bottle-3.png']
];let html='<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pourlune · R01–R05修复证据</title><style>body{font:16px/1.6 system-ui;background:#eef6f9;color:#123d70;margin:28px}section{margin:40px 0}.pair{display:flex;gap:20px;overflow:auto}figure{margin:0;flex:0 0 300px}img{width:300px;display:block;background:#82dff1;border-radius:12px}figcaption{margin:6px 0}a{color:#075895}</style><h1>R01–R05 修复前后</h1><p>执行方实际DOM路径检查的截图。左：修复前首次断言失败时；右：修复后完成该用例时。R01专门取同一收藏页面检查点；其他用例完成后可能包含额外的辅助往返。不是独立复验结论。</p><p><a href="../REVISION-R1.md">修复说明</a> · <a href="after/results.json">41项结果</a> · <a href="../index.html">原型</a> · <a href="../evidence.html">全状态截图</a></p>';
for(const [title,before,after] of rows)html+=`<section><h2>${title}</h2><div class="pair"><figure><figcaption>Before</figcaption><a href="${before}"><img src="${before}" alt="${title} before"></a></figure><figure><figcaption>After</figcaption><a href="${after}"><img src="${after}" alt="${title} after"></a></figure></div></section>`;html+='<h2>待奖励Undo后的底部入口</h2><p>与顶部截图配套：免费Undo／Hint仍可用，Reward pending禁用，不提供第二次领取。</p><img src="after/R02-reward-pending-undo-bottom.png" alt="Pending reward remains disabled after Undo"></html>';fs.writeFileSync(path.join(base,'index.html'),html);console.log('Revision gallery:',rows.length,'comparisons');
