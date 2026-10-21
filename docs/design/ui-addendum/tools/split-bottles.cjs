// Re-extract each existing bottle from the original generated sheet. No paint or regeneration.
// The old equal fifths crossed bottle silhouettes and included pixels of neighbours.
const sharp=require('/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const fs=require('fs'),path=require('path');const root=path.resolve(__dirname,'..');
const bounds=[[38,413],[424,796],[807,1178],[1188,1558],[1572,1945]];
(async()=>{for(let i=0;i<bounds.length;i++){const [left,right]=bounds[i],width=right-left,margin=396-width;await sharp(path.join(root,'assets/bottles-edited.png')).extract({left,top:51,width,height:705}).extend({left:Math.floor(margin/2),right:Math.ceil(margin/2),top:51,bottom:37,background:{r:0,g:0,b:0,alpha:0}}).png().toFile(path.join(root,`assets/bottle-${i}.png`));}fs.writeFileSync(path.join(root,'assets/bottle-crops.json'),JSON.stringify({source:'bottles-edited.png',canvas:[396,793],sourceVerticalCrop:[51,705],bounds,method:'Non-overlapping silhouette extraction; preserve source RGBA pixels and original canvas height. No bottle redraw.'},null,2));})();
