(function(root,factory){const api=factory(typeof module==='object'?require('./rules.js'):root.PourRules);if(typeof module==='object'&&module.exports)module.exports=api;else root.PourProgress=api;})(typeof self!=='undefined'?self:globalThis,function(R){
 'use strict';
 function parse(raw){try{return JSON.parse(raw||'null');}catch{return null;}}
 function load(current,legacy,options={}){
  const catalog=options.catalog||R.CATALOG_ID,levels=options.levels||R.LEVELS;
  const data=parse(current),old=parse(legacy);
  const valid=data?.version===3&&data.catalog===catalog&&data.slots&&typeof data.slots==='object'&&!Array.isArray(data.slots);
  const preferences=data||old;
  const progress=valid?data:{version:3,catalog,current:0,slots:{},completed:[],sound:preferences?.sound!==false,reduced:preferences?.reduced===true,legacyRetained:!!old};
  progress.current=Number.isInteger(progress.current)?Math.max(0,Math.min(levels.length-1,progress.current)):0;
  progress.completed=Array.isArray(progress.completed)?progress.completed.filter(i=>Number.isInteger(i)&&levels[i]&&progress.slots[levels[i].id]?.uid===levels[i].uid):[];
  return progress;
 }
 function restore(level,saved){
  const session=new R.Session(level);
  if(!saved||saved.uid!==level.uid||saved.level!==level.id-1||!R.validState(saved.state,level))return session;
  session.state=R.clone(saved.state);
  const history=saved.history;let valid=Array.isArray(history)&&history.length<10000;if(valid&&!history.length)valid=R.sameBoard(saved.state,R.initialState(level));
  if(valid&&history.length){const chain=[...history,saved.state];valid=R.sameBoard(chain[0],R.initialState(level));
   for(let k=0;valid&&k<chain.length-1;k++){
    if(!R.validState(chain[k],level)){valid=false;break;}
    let legal=false;for(let i=0;i<chain[k].bottles.length&&!legal;i++)for(let j=0;j<chain[k].bottles.length;j++){const m=R.move(chain[k],i,j);if(m.ok&&R.sameBoard(m.state,chain[k+1])){legal=true;break;}}
    valid=legal;
   }
  }
  if(!valid&&level.locks)return new R.Session(level);
  session.history=valid?history.map(R.clone):[];
  session.moves=valid?history.length:Math.max(0,Number.isInteger(saved.moves)?saved.moves:0);
  session.hints=Math.max(0,Number.isInteger(saved.hints)?saved.hints:0);session.remember(saved.known);return session;
 }
 function capture(progress,index,session,preferences,levels=R.LEVELS){
  progress.current=index;Object.assign(progress,preferences);
  progress.slots[levels[index].id]={uid:levels[index].uid,level:levels[index].id-1,state:R.clone(session.state),history:session.history.map(R.clone),moves:session.moves,hints:session.hints,known:session.known?.slice()};
  return progress;
 }
 function resumable(progress,index,levels=R.LEVELS){const saved=progress.slots[levels[index].id];return !!(saved&&saved.uid===levels[index].uid&&(saved.moves>0||saved.hints>0||saved.known?.some(n=>n>0))&&R.validState(saved.state,levels[index])&&!R.isSolved(saved.state));}
 return {load,restore,capture,resumable};
});
