// Product integration. Original rules/game/render/main files remain unchanged.
(function(){
 'use strict';
 const host=()=>parent.GardenHost,load=PourProgress.load,S=PourluneScene.prototype;
 PourProgress.load=function(){return load(JSON.stringify(host().gameProgress()),null,{levels:PourRules.LEVELS,catalog:PourRules.CATALOG_ID});};
 const bind=S.bindUI,refresh=S.refresh,finish=S.finishPour,select=S.select,undo=S.undo,handle=S.handleHint,clear=S.clearHint,wake=S.wake,pour=S.pour,loadLevel=S.loadLevel;
 S.routeSelection=function(_hash,current){return {index:current,obsolete:false};};
 S.routeChanged=function(){};
 S.loadLevel=function(index,restore){this.stopAllActions?.();for(const b of this.bottles||[])b.stopAllActions();this._roundId=host().roundId(index+1);this._actionRound=null;loadLevel.call(this,index,restore,host().activeLevel(index+1));};
 S.bindUI=function(){bind.call(this);const scene=this;
  document.getElementById('levels').setAttribute('aria-label','Pause game');document.getElementById('levels').onclick=()=>host().pause();
  document.getElementById('settings').onclick=()=>host().settings();document.getElementById('help').onclick=()=>host().help();document.getElementById('restart').onclick=()=>host().restart();
  const win=this.audio.win.bind(this.audio);this.audio.win=()=>{this._winSound=win;};
  setTimeout(()=>host().ready(scene),0);
 };
 S.save=function(){if(this._finishing)return Promise.resolve(true);return host().capture(this);};
 S.levels=function(){return host().levels();};S.settings=function(){host().settings();};S.help=function(){host().help();};S.confirmRestart=function(){host().restart();};S.closeModal=function(){host().closeSheet();};
 S.showWin=function(){if(PourRules.isSolved(this.session.state))host().win(this);};
 S.refresh=function(){refresh.call(this);if(!host()?.blocked())return;for(const el of document.querySelectorAll('#screen-header button,#screen-footer button'))el.disabled=true;if(!(this.returning&&host().canRender()))for(const el of document.querySelectorAll('#bottle-targets button'))el.disabled=true;};
 S.select=function(i){if(this._finishing){this._queuedSelections.push(i);return;}if(!host()?.blocked()||(this.returning&&host().canRender()))select.call(this,i);};
 S.pour=function(from,to){const before=this.session.moves;pour.call(this,from,to);if(this.session.moves===before)return;this._actionRound=this._roundId;this._actionCommit=host().capture(this);};
 S.undo=function(){if(!host().blocked())undo.call(this);};
 S.wake=function(){if(!host()?.canRender()){cc.game.pause();return;}wake.call(this);};
 S.clearHint=function(){clear.call(this);host()?.hintStatus('clear');};
 S.cancelHint=function(){clearTimeout(this.hintTimer);this.hintRequest++;this.searching=false;this.worker?.terminate();this.worker=null;this.refresh();};
 S.hint=function(){
  if(this.busy||this.modal||this.searching||host().blocked()||PourRules.isSolved(this.session.state))return;
  this.audio.unlock();this.deselect();this.searching=true;const id=++this.hintRequest;
  try{if(!this.worker){this.worker=new Worker('src/solver-worker.js');this.worker.onmessage=e=>this.handleHint(e.data);this.worker.onerror=()=>{this.cancelHint();host().hintStatus('unavailable');};}
   this.refresh();host().hintStatus('searching');this.worker.postMessage({id,state:this.session.state});
   clearTimeout(this.hintTimer);this.hintTimer=setTimeout(()=>{if(this.searching&&id===this.hintRequest){this.cancelHint();host().hintStatus('timeout');}},5000);
  }catch{this.cancelHint();host().hintStatus('unavailable');}
 };
 S.handleHint=function(data){if(data.id!==this.hintRequest)return;clearTimeout(this.hintTimer);handle.call(this,data);host().hintStatus(data.status==='solved'&&data.path.length?'result':data.status==='dead'?'dead':data.status==='limit'?'timeout':'unavailable');};
 S.finishPour=function(m){
  const scene=this,round=this._actionRound,session=this.session,state=this.session.state;
  if(!this.flow||this.flow.state!==m.state||!round||round!==host().roundId(this.levelIndex+1))return;
  this._queuedSelections=[];this._finishing=true;
  try{finish.call(this,m);}finally{this._finishing=false;}
  const queued=this._queuedSelections;this._queuedSelections=[];
  this.save().then(ok=>{
   if(!ok||scene.session!==session||session.state!==state||round!==host().roundId(scene.levelIndex+1))return;
   if(this._winSound){if(host().canRender())this._winSound();this._winSound=null;}
   if(host().canRender())for(const i of queued)select.call(this,i);
   if(!scene.busy&&session.state===state&&!PourRules.isSolved(scene.session.state)&&!scene.hasMoves()&&host().canRender())host().noMoves(scene);
  }).catch(()=>{});
 };
})();
