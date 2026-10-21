const sharp=require('/Users/wangyule/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path=require('path'); const fs=require('fs');
const root=path.resolve(__dirname,'..'), src=path.resolve(root,'../original/Pourlune_Design_Pack/boards');
const crops={
'cream':['02_Tutorial_Play_Pause.png',1080,360,60,35],
'green':['04_Win_and_Collection.png',570,840,25,20],
'background':['01_Entry_and_Chapters.png',500,38,475,1000],
'room':['04_Win_and_Collection.png',532,190,420,370],
'calendar':['05_Scene_and_Daily.png',613,140,258,239],
'check':['04_Win_and_Collection.png',160,172,165,140],
'logo':['01_Entry_and_Chapters.png',586,50,296,120],
'back':['02_Tutorial_Play_Pause.png',512,58,77,74],
'bulb':['03_Hint_and_Recovery.png',150,147,42,48],
'empty':['02_Tutorial_Play_Pause.png',666,535,143,274],
'patch':['05_Scene_and_Daily.png',54,642,64,57],
'garden':['01_Entry_and_Chapters.png',1016,606,168,139],
'seaside':['01_Entry_and_Chapters.png',1016,762,168,129]
};
(async()=>{for(const [name,[file,left,top,width,height]] of Object.entries(crops)) await sharp(path.join(src,file)).extract({left,top,width,height}).png().toFile(path.join(root,'assets',name+'.png'));
// Prototype uses the installed rounded font via CSS local(); do not redistribute system font files.
fs.writeFileSync(path.join(root,'assets','source-crops.json'),JSON.stringify(crops,null,2));})();
