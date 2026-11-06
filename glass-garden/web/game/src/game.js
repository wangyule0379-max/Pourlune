(function(){
  'use strict';
  const R=PourRules,P=PourProgress,V=PourRender,$=id=>document.getElementById(id),PREVIEW=!!window.location?.hash.startsWith('#preview'),LEVELS=PREVIEW?PourSamples:R.LEVELS,SAVE=PREVIEW?'pourlune.samples.v4':'pourlune.gentle100.v4',IDLE_TEXT='Select a bottle, then a glowing opening';
  const reasonText={fixed:'This bottle stays here. Pink only.',empty:'Select a bottle with water first.',full:'This bottle is full.',mismatch:'Pour into an empty bottle or the same color.','pink-only':'The tall bottle only collects pink.',invalid:'Choose another bottle.',locked:'Complete the color on this seal to open it.'};
  const Sounds=PourWaterAudio.Sounds;
  window.PourluneScene=cc.Scene.extend({
    ctor:function(){
      this._super();this.time=0;this.collectorPulse=0;this.fullBloom=0;this.moonFill=0;this.selected=-1;this.busy=false;this.returning=false;this.queuedTarget=-1;this.particles=[];this.drips=[];this.floating=[];this.bottles=[];this.flow=null;this.hintPair=null;this.modal=false;this.hintRequest=0;this.completed=[];this.levelIndex=0;this.audio=new Sounds();this.reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
      try{this.progress=P.load(localStorage.getItem(SAVE),localStorage.getItem('pourlune.garden100.v1')||localStorage.getItem('pourlune.v2')||localStorage.getItem('pourlune.v1'),{levels:LEVELS,catalog:PREVIEW?'samples-v4':R.CATALOG_ID});}catch(e){this.progress=P.load(null,null,{levels:LEVELS,catalog:PREVIEW?'samples-v4':R.CATALOG_ID});}
      this.levelIndex=this.progress.current;this.audio.enabled=this.progress.sound!==false;this.reduced=this.progress.reduced===true||this.reduced;this.completed=this.progress.completed;
      const route=this.routeSelection(window.location.hash,this.levelIndex);this.levelIndex=route.index;
      this.background=new V.PaintNode(ctx=>V.background(ctx,this));this.background.setPosition(0,1040);this.addChild(this.background,-10);
      this.effects=new V.PaintNode(ctx=>V.effects(ctx,this));this.effects.setPosition(0,1040);this.addChild(this.effects,30);
      this.loadLevel(this.levelIndex,true);this.bindUI();this.scheduleUpdate();if(route.obsolete)this.sampleLevels('All',true);
      try{this.worker=new Worker('src/solver-worker.js');this.worker.onmessage=e=>this.handleHint(e.data);this.worker.onerror=()=>{this.searching=false;$('hint').disabled=this.busy;this.say('Hint unavailable. Try Undo.',true);};}catch(e){this.worker=null;}
      window.addEventListener('hashchange',()=>this.routeChanged());
      const scene=this;
      cc.eventManager.addListener({event:cc.EventListener.TOUCH_ONE_BY_ONE,swallowTouches:true,onTouchBegan:function(t){const p=t.getLocation();scene.clickAt(p.x,1040-p.y);return true;}},this);
      window.addEventListener('keydown',e=>{if(e.key==='Escape'){if(scene.modal)scene.closeModal();else scene.deselect();}if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){e.preventDefault();scene.undo();}});
      for(const type of ['pointerdown','click','touchstart'])document.addEventListener(type,()=>this.wake(),{capture:true,passive:true});document.addEventListener('keydown',()=>this.wake(),true);window.addEventListener('resize',()=>this.wake());window.addEventListener('pour-viewport-change',()=>this.viewportChanged());
      document.addEventListener('visibilitychange',()=>{if(document.hidden){this.audio.stopWater();this.rest('background');}else this.viewportChanged();});
    },
    loadLevel:function(index,restore=false){
      this.wake?.();this.pendingWin=false;this.hintRequest++;this.searching=false;this.levelIndex=index;this.session=P.restore(LEVELS[index],restore?this.progress?.slots[LEVELS[index].id]:null);
      this.collectorPulse=0;this.fullBloom=0;this.moonFill=0;this.selected=-1;this.busy=false;this.returning=false;this.queuedTarget=-1;this.hintPair=null;this.flow=null;this.unveiling=null;this.particles=[];this.drips=[];this.floating=[];
      for(const b of this.bottles)b.removeFromParent();this.bottles=[];
      this.layout=R.layoutFor(LEVELS[index]);const state=this.session.state;
      for(let i=0;i<state.bottles.length;i++){const [x,y]=this.layout.slots[i],b=new V.Bottle(i,i===state.collector?state.capacity:4,x,y,this);b.sync(R.visibleColors(state,i));this.bottles.push(b);this.addChild(b,2);}
      const collector=this.bottles[state.collector];
      $('collector-tag').hidden=!collector;if(collector){$('collector-tag').style.left=(collector.home.x-70)+'px';$('collector-tag').style.top=(collector.home.y+collector.h+57)+'px';$('collector-tag').style.width='140px';}
      $('game-shell').dataset.layout=this.layout.complex?'garden':'classic';
      window.history.replaceState(null,'',(PREVIEW?'#preview-':'#level-')+LEVELS[index].id);
      window.PourBoardBounds={left:Math.min(...this.bottles.map((b,i)=>b.home.x-(i===state.collector?70:42))),right:Math.max(...this.bottles.map((b,i)=>b.home.x+(i===state.collector?70:42))),top:Math.min(...this.bottles.map(b=>b.home.y))-132,bottom:Math.max(...this.bottles.map((b,i)=>b.home.y+b.h+(i===state.collector?93:20)))};window.dispatchEvent?.(new Event('pour-layout-change'));
      this.moonFill=state.collector>=0&&state.bottles[state.collector].length===state.capacity?1:0;this.buildTargets();this.refresh();this.say(restore&&this.session.moves?'Welcome back. Your progress is saved.':IDLE_TEXT,false,false,3);
      if(R.isSolved(this.session.state)){this.pendingWin=true;this.scheduleOnce(()=>{this.pendingWin=false;this.showWin(false);},.3);}
    },
    buildTargets:function(){
      $('bottle-targets').replaceChildren();
      this.bottles.forEach((b,i)=>{const el=document.createElement('button');el.className='bottle-target';// Expand short-screen touch areas without crossing a neighboring bottle's lane.
        let half=Math.min(b.home.x,480-b.home.x);
        for(const other of this.bottles){if(other===b||other.home.y-10>=b.home.y+b.h+10||b.home.y-10>=other.home.y+other.h+10)continue;half=Math.min(half,Math.abs(other.home.x-b.home.x)/2-1);}
        el.style.setProperty('--hit-width',`min(max(${this.layout.hitWidth}px,calc(44px / var(--game-scale,1))),${half*2}px)`);el.style.left=`calc(${b.home.x}px - var(--hit-width) / 2)`;el.style.top=(b.home.y-10)+'px';el.style.width='var(--hit-width)';el.style.height=(b.h+20)+'px';el.dataset.index=i;el.addEventListener('click',()=>this.select(i));$('bottle-targets').appendChild(el);});
    },
    bindUI:function(){
      document.addEventListener('click',e=>{if((e.target===document.body||e.target===document.documentElement)&&!this.modal&&(!this.busy||this.canQueueReturn()))this.deselect();});
      $('board-dismiss').onclick=()=>{if((!this.busy||this.returning)&&!this.modal){this.deselect();this.say(IDLE_TEXT,false,false,0);}};
      $('undo').onclick=()=>this.undo();$('hint').onclick=()=>this.hint();$('restart').onclick=()=>this.confirmRestart();$('settings').onclick=()=>this.settings();$('help').onclick=()=>this.help();$('levels').onclick=()=>this.levels();$('modal-close').onclick=()=>this.closeModal();$('sound').onclick=()=>this.toggleSound();
      $('modal').addEventListener('click',e=>{if(e.target===$('modal')&&!R.isSolved(this.session.state))this.closeModal();});
      $('modal').addEventListener('keydown',e=>{if(e.key!=='Tab')return;const els=Array.from($('modal').querySelectorAll('button:not([disabled])'));const first=els[0],last=els.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}});
    },
    refresh:function(){
      this.updateGuides();
      const s=this.session.state,count=s.collector>=0?s.bottles[s.collector].length:0;
      $('level-title').textContent=(PREVIEW?'SAMPLE '+(this.levelIndex+1)+' / '+LEVELS.length:'LEVEL '+LEVELS[this.levelIndex].id);$('level-difficulty').textContent=(LEVELS[this.levelIndex].mystery||LEVELS[this.levelIndex].difficulty==='A little challenge')?LEVELS[this.levelIndex].difficulty:'';$('level-difficulty').hidden=!(LEVELS[this.levelIndex].mystery||LEVELS[this.levelIndex].difficulty==='A little challenge');$('level-name').textContent=LEVELS[this.levelIndex].name;$('collected').textContent=count;$('progress-bar').style.width=(s.capacity?count/s.capacity*100:0)+'%';$('moves').textContent=this.session.moves+(this.session.moves===1?' move':' moves');
      {$('objective-text').textContent=LEVELS[this.levelIndex].objective;$('objective-icon').hidden=s.collector<0;}
      $('level-dots').innerHTML=LEVELS.map((_,i)=>'<i class="'+(i===this.levelIndex?'active':this.completed.includes(i)?'done':'')+'"></i>').join('');
      $('undo').disabled=this.busy||!this.session.history.length;$('hint').disabled=this.busy||this.searching||R.isSolved(s);$('restart').disabled=this.busy;for(const id of ['settings','help','levels'])$(id).disabled=this.busy;
      $('board-dismiss').disabled=this.busy&&!this.returning;$('screen-footer').dataset.busy=String(this.busy);$('screen-header').dataset.busy=String(this.busy);
      $('sound').setAttribute('aria-label',this.audio.enabled?'Mute sound':'Enable sound');$('sound').style.opacity=this.audio.enabled?'1':'.4';
      Array.from($('bottle-targets').children).forEach((el,i)=>{const shown=this.unveiling?.before||((s.fog||s.locks)&&this.flow?this.flow.before:s),b=R.visibleColors(shown,i);this.bottles[i].cover=R.lockFor(this.unveiling?s:shown,i);this.bottles[i].reserveRemaining=shown.collector<0?0:Math.max(0,4-(shown.bottles[shown.collector].length-(shown.collectedStart||0)));const label=R.isLocked(shown,i)?'Covered bottle '+(i+1)+'. '+this.lockMessage(i,shown):i===s.collector?`Fixed collector, pink ${b.length} of ${s.capacity}, receives only`:`Bottle ${i+1}, ${b.length?b.length+(b.length===1?' layer, top to bottom: ':' layers, top to bottom: ')+b.slice().reverse().map(c=>V.NAME[c]).join(', '):'empty'}`;el.setAttribute('aria-label',label+(this.returning&&i===this.selected?', queued':''));el.setAttribute('aria-disabled',String(R.isLocked(shown,i)));el.setAttribute('aria-pressed',i===this.selected?'true':'false');el.setAttribute('aria-description',this.bottles[i].accepts?'Can receive water from the selected bottle':'');el.dataset.canReceive=String(this.bottles[i].accepts);el.dataset.pending=String(this.bottles[i].pending);el.disabled=(this.busy&&(!this.canQueueReturn()))||R.isSolved(s);});
    },
    updateGuides:function(){
      const active=this.selected>=0&&(!this.busy||this.returning);
      this.bottles.forEach((b,i)=>{b.accepts=!!(active&&R.move(this.session.state,this.selected,i).ok);b.pending=!!(this.returning&&i===this.selected);});
    },
    clickAt:function(x,y){if(this.modal||(this.busy&&!this.returning))return;for(let i=0;i<this.bottles.length;i++){const b=this.bottles[i];if(Math.abs(x-b.home.x)<(this.layout?.hitWidth||84)/2&&y>=b.home.y-10&&y<b.home.y+b.h+10){this.select(i);return;}}this.deselect();},
    clearHint:function(){this.hintPair=null;this.bottles.forEach(b=>b.hint=0);this.hintRequest++;this.searching=false;},
    deselect:function(){if(this.busy&&!this.returning)return;this.clearHint();this.selected=-1;this.queuedTarget=-1;if(this.returning){this.refresh();this.say(IDLE_TEXT,false,false,0);return;}for(const b of this.bottles){b.stopAllActions();b.glow=0;b.angle=0;b.runAction(cc.moveTo(this.reduced?.01:.1,b.home.x,1040-b.home.y).easing(cc.easeSineOut()));}this.refresh();this.say(IDLE_TEXT,false,false,0);},
    canQueueReturn:function(){return this.returning&&!this.flow?.revealed?.length&&!this.flow?.unlocked?.length;},
    selectPending:function(i){
      const s=this.session.state;
      if(R.isLocked(s,i)){this.invalid(i,'locked');return;}
      if(i===this.selected){this.deselect();this.say(IDLE_TEXT,false,false,0);return;}
      if(this.selected>=0&&R.move(s,this.selected,i).ok){this.queuedTarget=i;this.say('Next pour queued: '+(i===s.collector?'pink collector':'bottle '+(i+1)));this.refresh();return;}
      if(i===s.collector||!s.bottles[i].length){this.say(i===s.collector?reasonText.fixed:reasonText.empty);return;}
      this.clearHint();this.selected=i;this.queuedTarget=-1;this.audio.select();this.selectionFeedback();this.refresh();
    },
    select:function(i){
      if(this.modal||R.isSolved(this.session.state))return;
      if(this.busy){if(this.canQueueReturn())this.selectPending(i);return;}this.audio.unlock();this.clearHint();
      if(R.isLocked(this.session.state,i)){this.invalid(i,'locked');return;}
      if(i===this.selected){this.deselect();this.say(IDLE_TEXT,false,false,0);return;}
      if(this.selected>=0){const m=R.move(this.session.state,this.selected,i);if(m.ok){this.pour(this.selected,i);return;}
        if(i!==this.session.state.collector&&this.session.state.bottles[i].length){this.deselect();}
        else{this.invalid(i,m.reason);return;}}
      if(i===this.session.state.collector){this.invalid(i,'fixed');return;}
      if(!this.session.state.bottles[i].length){this.invalid(i,'empty');return;}
      this.selected=i;const b=this.bottles[i];b.stopAllActions();b.completion=0;b.reveal=0;b.glow=1;b.wave=1.6;b.runAction(cc.moveTo(this.reduced?.01:.12,b.home.x,1040-b.home.y+13).easing(cc.easeBackOut()));this.audio.select();this.selectionFeedback();this.refresh();
    },
    selectionFeedback:function(){
      const s=this.session.state,canReceive=s.bottles.some((_,i)=>R.move(s,this.selected,i).ok);
      this.say(canReceive?'Choose a glowing opening.':'No matching opening. Try another bottle.',false,false,0);
    },
    lockMessage:function(i,state=this.session.state){const l=R.lockFor(state,i);return !l?'':l.color?'Finish a '+V.NAME[l.color].toLowerCase()+' bottle to lift this cover.':'Collect '+Math.max(0,l.collect-((state.bottles[state.collector]?.length||0)-state.collectedStart))+' more pink layers to open this bottle.';},
    invalid:function(i,reason){
      const b=this.bottles[i];if(!this.reduced){b.stopAllActions();const p=b.screen();b.runAction(cc.sequence(cc.moveBy(.045,4,0),cc.moveBy(.06,-8,0),cc.moveBy(.06,6,0),cc.moveTo(.06,p.x,1040-p.y)));}this.audio.error();this.say(reason==='locked'?this.lockMessage(i):reasonText[reason]||'You cannot pour here yet.',true);this.refresh();
    },
    pour:function(from,to){
      const before=R.clone(this.session.state),m=this.session.pour(from,to);if(!m.ok)return;
      this.clearHint();this.selected=-1;this.queuedTarget=-1;this.returning=false;this.busy=true;this.flow={...m,before,active:false,progress:0};this.refresh();if(to===before.collector){$('collected').textContent=before.bottles[to].length;$('progress-bar').style.width=before.bottles[to].length/before.capacity*100+'%';}
      const src=this.bottles[from],dst=this.bottles[to],direction=dst.home.x>=240?1:-1;
      src.setLocalZOrder(15);src.stopAllActions();src.glow=.5;dst.glow=.35;
      const distance=Math.hypot(src.home.x-dst.home.x,src.home.y-dst.home.y),duration=this.reduced?.01:.20+Math.min(.16,distance/2000);
      const angle=direction*V.pourAngle(src.w,src.h,src.liquidUnit,before.bottles[from].length),{x,y}=V.pourPose(dst.home,src.w,direction,angle),start=src.screen();
      const arc=[cc.p(start.x,1040-Math.max(152,start.y-48)),cc.p(x-direction*34,1040-Math.max(152,y-24)),cc.p(x,1040-y)];
      const travel=this.reduced?cc.moveTo(duration,x,1040-y):cc.bezierTo(duration,arc).easing(cc.easeSineInOut());
      src.runAction(cc.sequence(cc.spawn(travel,cc.sequence(cc.delayTime(this.reduced?0:.12),cc.actionTween(this.reduced?duration:duration-.12,'angle',0,angle).easing(cc.easeSineInOut()))),cc.callFunc(()=>{
        this.flow.active=true;this.flow.direction=direction;this.audio.startWater();
        this.runAction(cc.sequence(cc.actionTween(this.reduced?.05:.26+m.amount*.12,'pourProgress',0,1).easing(cc.easeSineInOut()),cc.callFunc(()=>{
          this.releaseTailDrops();this.flow.active=false;this.audio.stopWater();this.settleWater(m);this.returning=true;this.refresh();
          const returnTime=this.reduced?.01:.14+Math.min(.06,distance/4000),home=cc.p(src.home.x,1040-src.home.y);
          const returnArc=[cc.p(x,1040-Math.max(152,y-24)),cc.p(home.x,Math.min(860,home.y+45)),cc.p(home.x,home.y+3)];
          const returnMove=this.reduced?cc.moveTo(returnTime,home):cc.bezierTo(returnTime,returnArc).easing(cc.easeSineInOut());
          src.runAction(cc.sequence(cc.spawn(returnMove,cc.actionTween(returnTime,'angle',src.angle,-direction*.025).easing(cc.easeSineInOut())),cc.spawn(cc.moveTo(this.reduced?.01:.045,home).easing(cc.easeSineOut()),cc.actionTween(this.reduced?.01:.045,'angle',-direction*.025,0)),cc.callFunc(()=>this.finishPour(m))));
        })));
      })));
      this.say(IDLE_TEXT,false,false,0);
    },
    releaseTailDrops:function(){
      if(this.reduced||!this.flow)return;
      const f=this.flow,src=this.bottles[f.from].outlet(),target=this.bottles[f.to],mouth=target.mouth(),amount=target.units.reduce((n,u)=>n+u.amount,0);
      const impact={x:mouth.x,y:target.screen().y+target.h-4-amount*(target.liquidUnit||target.unit)};
      for(let i=0;i<2;i++)this.drips.push({from:src,mouth,impact,color:V.COLOR[f.color],age:-i*.025,duration:.16+i*.035,size:1.7-i*.35});
    },
    updateTweenAction:function(value,key){
      if(key!=='pourProgress'||!this.flow)return;const f=this.flow;f.progress=value;{const bottle=this.bottles[f.from];bottle.angle=f.direction*V.pourAngle(bottle.w,bottle.h,bottle.liquidUnit,f.before.bottles[f.from].length-f.amount*value);bottle.wave=0;const p=V.pourPose(this.bottles[f.to].home,bottle.w,f.direction,bottle.angle);bottle.setPosition(p.x,1040-p.y);}
      const src=R.visibleColors(f.before,f.from).map(color=>({color,amount:1})),dst=R.visibleColors(f.before,f.to).map(color=>({color,amount:1}));let remove=f.amount*value;
      for(let i=src.length-1;i>=0&&remove>0;i--){const n=Math.min(remove,src[i].amount);src[i].amount-=n;remove-=n;}
      dst.push({color:f.color,amount:f.amount*value});this.bottles[f.from].units=src;this.bottles[f.to].units=dst;this.bottles[f.to].wave=2.5;
      if(f.to===f.before.collector){const amount=f.before.bottles[f.to].length+f.amount*value;this.collectorPulse=.5+value*.5;$('progress-bar').style.width=amount/f.before.capacity*100+'%';$('collected').textContent=Math.floor(amount+.001);}
    },
    settleWater:function(m){
      if(!this.flow||this.flow.arrived)return;this.flow.arrived=true;const before=this.flow.before;this.bottles[m.to].sync(R.visibleColors(this.session.state,m.to));
      const dst=this.bottles[m.to];dst.wave=3;
      if(m.to===this.session.state.collector){this.collectorPulse=1;if(this.session.state.bottles[m.to].length===this.session.state.capacity&&before.bottles[m.to].length<before.capacity){this.fullBloom=1;this.audio.complete();}this.burst(dst.home.x,dst.home.y+dst.h-4-this.session.state.bottles[m.to].length*(dst.liquidUnit||dst.unit),14,V.COLOR.pink);this.floating.push({x:dst.home.x,y:dst.home.y+dst.h-40,text:'+'+m.amount,life:1.2,max:1.2});this.say(this.session.state.bottles[m.to].length===this.session.state.capacity?'Pink collected! Sort the remaining colors.':IDLE_TEXT,false,false,4);}
      else if(R.newlyCompleted(before,this.session.state,m.to)){dst.completion=this.reduced?0:1;this.burst(dst.home.x,dst.home.y+45,16,V.COLOR[m.color]);this.audio.complete();this.say(V.NAME[m.color]+' sorted!',false,true);}
      else this.say(IDLE_TEXT,false,false,0);
    },
    finishPour:function(m){
      if(!this.flow)return;this.settleWater(m);const nextSource=this.selected,nextTarget=this.queuedTarget;this.selected=-1;this.queuedTarget=-1;this.returning=false;this.unveiling=m.unlocked?.length&&!this.reduced?{before:this.flow.before,remaining:.65}:null;this.flow=null;this.busy=!!this.unveiling;
      this.bottles.forEach((b,i)=>{b.sync(R.visibleColors(this.session.state,i));b.glow=0;b.angle=0;b.setLocalZOrder(2);});
      for(const i of m.unlocked||[]){const b=this.bottles[i];b.lastCover=b.cover;b.unveil=this.reduced?0:1;b.wave=2;}
      for(const reveal of m.revealed||[]){const b=this.bottles[reveal.bottle];b.revealLayer=reveal.layer;b.reveal=this.reduced?0:1;b.wave=2;}
      this.refresh();this.save();if(R.isSolved(this.session.state)){this.completed=Array.from(new Set([...this.completed,this.levelIndex]));this.save();this.audio.win();for(let k=0;k<3;k++)this.burst(95+k*120,305,10,[V.COLOR.pink,V.COLOR.turquoise,V.COLOR.yellow,V.COLOR.purple][k%4]);const completedSession=this.session;this.pendingWin=true;this.say('Beautifully sorted. Level complete!',false,true,0);this.scheduleOnce(()=>{if(this.session===completedSession){this.pendingWin=false;if(!this.modal&&R.isSolved(this.session.state))this.showWin(true);}},this.reduced?.15:this.fullBloom>0?this.fullBloom*1.8+.15:1.05);}
      else if(!this.hasMoves())this.say('No moves left. Try Undo or Hint.',true);
      if(m.unlocked?.length&&!R.isSolved(this.session.state))this.say(m.unlocked.length===1?'A new bottle is ready.':'The covers are open. A little more room!',false,true,4);
      if(nextSource>=0&&!R.isSolved(this.session.state)){this.select(nextSource);if(nextTarget>=0)this.select(nextTarget);}
    },
    hasMoves:function(){const s=this.session.state;for(let i=0;i<s.bottles.length;i++)for(let j=0;j<s.bottles.length;j++)if(R.move(s,i,j).ok)return true;return false;},
    burst:function(x,y,n,color){if(this.reduced)return;for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,v=25+Math.random()*75;this.particles.push({x,y,vx:Math.cos(a)*v,vy:Math.sin(a)*v-25,size:1.6+Math.random()*2.8,life:.6+Math.random()*.6,max:1.2,color,angle:Math.random()*6,kind:i%4===0?'star':'dot'});}},
    update:function(dt){
      dt=Math.min(dt,.05);this.time+=dt;this.collectorPulse=Math.max(0,this.collectorPulse-dt*.75);this.fullBloom=Math.max(0,this.fullBloom-dt/1.8);const targetMoon=this.session.state.collector>=0&&this.bottles[this.session.state.collector].units.reduce((n,u)=>n+u.amount,0)>=this.session.state.capacity-.001?1:0;this.moonFill+= (targetMoon-this.moonFill)*Math.min(1,dt*5);if(Math.abs(targetMoon-this.moonFill)<.001)this.moonFill=targetMoon;for(const b of this.bottles){b.unveil=Math.max(0,(b.unveil||0)-dt/.65);b.wave*=Math.exp(-dt*3.4);if(b.wave<.025)b.wave=0;b.completion=Math.max(0,(b.completion||0)-dt/.9);b.reveal=Math.max(0,(b.reveal||0)-dt/.42);}
      if(this.unveiling){this.unveiling.remaining-=dt;if(this.unveiling.remaining<=0){this.unveiling=null;this.busy=false;this.refresh();}}
      for(const drop of this.drips)drop.age+=dt;this.drips=this.drips.filter(drop=>drop.age<drop.duration);
      for(const p of this.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=70*dt;p.angle+=dt;}
      this.particles=this.particles.filter(p=>p.life>0).slice(-80);for(const f of this.floating){f.life-=dt;f.y-=dt*23;}this.floating=this.floating.filter(f=>f.life>0);
      if(this.flow&&this.flow.active&&!this.reduced&&Math.random()<.35){const dst=this.bottles[this.flow.to],n=dst.units.reduce((sum,u)=>sum+u.amount,0);this.particles.push({x:dst.home.x,y:dst.home.y+dst.h-4-n*(dst.liquidUnit||dst.unit),vx:(Math.random()-.5)*45,vy:-20-Math.random()*25,size:1.4,life:.3,max:.3,color:V.COLOR[this.flow.color],angle:0,kind:'dot'});}
      const active=this.busy||this.pendingWin||this.particles.length||this.drips.length||this.floating.length||this.fullBloom>0||this.collectorPulse>0||this.moonFill!==targetMoon||this.getNumberOfRunningActions()>0||this.bottles.some(b=>b.unveil>0||b.wave>0||b.completion>0||b.reveal>0||b.getNumberOfRunningActions()>0);
      this.idleTime=active?0:(this.idleTime||0)+dt;if(this.idleTime>.2&&!this.restTimer)this.restTimer=setTimeout(()=>{this.restTimer=null;this.rest('resting');},0);
    },
    say:function(message,error=false,success=false,seconds=4){$('message').textContent=message===IDLE_TEXT?'':message;$('message').className='message'+(error?' error':success?' success':'');clearTimeout(this.messageTimer);if(seconds)this.messageTimer=setTimeout(()=>this.say(IDLE_TEXT,false,false,0),seconds*1000);},
    undo:function(){if(this.busy||this.modal)return;this.audio.unlock();if(!this.session.undo()){this.say('Nothing to undo yet.');return;}this.fullBloom=0;this.clearHint();this.deselect();this.bottles.forEach((b,i)=>{b.sync(R.visibleColors(this.session.state,i));b.completion=0;b.reveal=0;b.unveil=0;b.wave=1;});this.audio.select();this.refresh();this.save();this.say('Last move undone.');},
    confirmRestart:function(){if(this.busy)return;this.openModal('<span class="badge">A FRESH START</span><h2 id="modal-title">A fresh start?</h2><p>'+(this.session.state.fog?'Reset colors and cover the mystery layers again.':'Reset this puzzle to its original colors.')+'<br>Your completed levels stay saved.</p><button class="primary" id="do-restart">Restart level</button><button class="secondary" id="keep-playing">Keep playing</button>');$('do-restart').onclick=()=>{this.closeModal();this.loadLevel(this.levelIndex);this.save();};$('keep-playing').onclick=()=>this.closeModal();},
    hint:function(){if(this.busy||this.searching||this.modal||R.isSolved(this.session.state))return;this.audio.unlock();this.deselect();this.searching=true;const id=++this.hintRequest;this.refresh();this.say('Finding a way through…',false,false,0);if(this.worker)this.worker.postMessage({id,state:this.session.state});else{this.searching=false;this.refresh();this.say('Hint unavailable. Try Undo or Restart.',true);}},
    handleHint:function(data){if(data.id!==this.hintRequest)return;this.wake();this.searching=false;if(data.status==='solved'&&data.path.length){this.hintPair=data.path[0];for(const i of this.hintPair)this.bottles[i].hint=1;this.session.hints++;const [a,b]=this.hintPair;this.say('Follow the arrow to pour.',false,true,0);this.audio.select();this.save();}else if(data.status==='dead'){this.say('No solution from here. Undo and try again.',true, false,8);}else if(data.status==='limit'){this.say('Try Undo, then ask for another hint.',true);}else if(data.status!=='solved'){this.say('Hint unavailable. Please try again.',true);}this.refresh();},
    wake:function(){clearTimeout(this.restTimer);this.restTimer=null;this.idleTime=0;if(this.modal||document.hidden||window.PourViewportBlocked)return;cc.director.setNextDeltaTimeZero(true);cc.game.resume();$('game-shell').dataset.renderState='active';},
    viewportChanged:function(){if(window.PourViewportBlocked||document.hidden){this.audio.stopWater();this.rest(window.PourViewportBlocked?'orientation':'background');}else{this.wake();if(!this.modal&&this.flow?.active)this.audio.startWater();}},
    rest:function(reason){clearTimeout(this.restTimer);this.restTimer=null;cc.game.pause();$('game-shell').dataset.renderState=reason;},
    save:function(){P.capture(this.progress,this.levelIndex,this.session,{sound:this.audio.enabled,reduced:this.reduced,completed:this.completed},LEVELS);try{localStorage.setItem(SAVE,JSON.stringify(this.progress));}catch(e){}},
    routeSelection:function(hash,current){const requested=PREVIEW?LEVELS.findIndex(l=>l.id===Number((hash.match(/^#preview-(\d+)$/)||[])[1])):hash==='#challenge'?5:Number((hash.match(/^#level-(\d+)$/)||[])[1])-1;const valid=Number.isInteger(requested)&&requested>=0&&requested<LEVELS.length;return {index:valid?requested:PREVIEW?0:current,obsolete:PREVIEW&&!valid};},
    routeChanged:function(){this.save();this.audio.stopWater();window.location.reload();},
    switchLevel:function(index){this.save();this.closeModal();this.loadLevel(index,P.resumable(this.progress,index,LEVELS));this.save();},
    toggleSound:function(){this.audio.unlock();this.audio.enabled=!this.audio.enabled;if(!this.audio.enabled)this.audio.stopWater();else this.audio.select();this.refresh();this.save();},
    openModal:function(html){if(this.busy)return;if(!this.modal)this.lastFocus=document.activeElement;this.modal=true;this.rest('modal');$('modal-content').innerHTML=html;$('modal').hidden=false;for(const id of ['stage-wrap','screen-header','screen-footer'])$(id).inert=true;$('modal-close').focus();},
    closeModal:function(){this.modal=false;$('modal').hidden=true;for(const id of ['stage-wrap','screen-header','screen-footer'])$(id).inert=!!window.PourViewportBlocked;this.wake();if(this.lastFocus&&this.lastFocus.isConnected)this.lastFocus.focus();},
    help:function(){if(this.busy)return;const s=this.session.state;this.openModal('<span class="badge">A LITTLE HELP</span><h2 id="modal-title">One gentle pour at a time</h2><ol class="rules-list"><li>Select a bottle, then an empty bottle or a matching top color. Small bottles hold four layers.</li><li>You start with two empty bottles. Use them to make room.</li>'+(s.collector>=0?'<li>The tall bottle stays in place. Collect all the pink, then sort the remaining colors.</li>':'')+(s.locks?.length?'<li>Finish a full bottle in the color shown on a seal to lift its covers. Covered bottles cannot pour or receive water.</li>':'')+(Object.entries(R.counts(s)).some(([c,n])=>c!==s.target&&n>4)?'<li>Some colors fill two separate bottles.</li>':'')+'<li>No timer. Undo is always available after a pour.</li></ol><button class="primary" id="help-play">Let’s play</button>');$('help-play').onclick=()=>this.closeModal();},
    settings:function(){if(this.busy)return;this.openModal('<span class="badge">MAKE YOURSELF AT HOME</span><h2 id="modal-title">Settings</h2><div class="setting-row"><div>Sound effects<small>Gentle water and playful feedback</small></div><button id="toggle-sound" class="toggle" role="switch" aria-label="Sound effects" aria-checked="'+this.audio.enabled+'"></button></div><div class="setting-row"><div>Reduced motion<small>Shorter pours with fewer effects</small></div><button id="toggle-motion" class="toggle" role="switch" aria-label="Reduced motion" aria-checked="'+this.reduced+'"></button></div><button class="secondary" id="settings-help">How to play</button>');$('toggle-sound').onclick=()=>{this.toggleSound();$('toggle-sound').setAttribute('aria-checked',String(this.audio.enabled));};$('toggle-motion').onclick=()=>{this.reduced=!this.reduced;$('toggle-motion').setAttribute('aria-checked',String(this.reduced));this.save();};$('settings-help').onclick=()=>this.help();},
    levels:function(filter='All',chapter=Math.floor(this.levelIndex/10)){
      if(this.busy)return;if(PREVIEW){this.sampleLevels(filter);return;}this.save();chapter=Math.max(0,Math.min(9,chapter));
      const rows=LEVELS.map((l,i)=>({l,i})).filter(({l,i})=>filter==='Continue'?P.resumable(this.progress,i,LEVELS):filter==='Covers'?!!l.locks:Math.floor(i/10)===chapter);
      const chapters=['Morning Light','Gentle Currents','Pink Terraces','First Petals','Petal Pairs','Room to Bloom','Garden Gifts','Three Petals','Twilight Gardens','Four Petals Open'];
      this.openModal('<span class="badge">100 LITTLE MOMENTS</span><h2 id="modal-title">Choose a level</h2><div class="level-tabs" role="group" aria-label="Level category">'+['All','Covers','Continue'].map(f=>'<button data-filter="'+f+'" aria-pressed="'+(filter===f)+'">'+f+'</button>').join('')+'</div>'+(filter==='All'?'<div class="chapter-nav"><button id="chapter-prev" aria-label="Previous chapter" '+(chapter===0?'disabled':'')+'>‹</button><span><b>Chapter '+(chapter+1)+' / 10</b><small>'+chapters[chapter]+'</small></span><button id="chapter-next" aria-label="Next chapter" '+(chapter===9?'disabled':'')+'>›</button></div>':'')+(rows.length?rows.map(({l,i})=>'<button class="level-choice" data-level="'+i+'"><strong>'+String(i+1).padStart(2,'0')+'</strong><span>'+l.name+'<small>'+(P.resumable(this.progress,i,LEVELS)?'Resume · '+this.progress.slots[l.id].moves+' moves':l.kind)+'</small></span><i>'+(this.completed.includes(i)?'✓':'→')+'</i></button>').join(''):'<p>Your unfinished levels will appear here.</p>'));
      $('modal-content').querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>this.levels(b.dataset.filter,chapter));$('modal-content').querySelectorAll('[data-level]').forEach(b=>b.onclick=()=>this.switchLevel(Number(b.dataset.level)));
      if(filter==='All'){ $('chapter-prev').onclick=()=>this.levels('All',chapter-1);$('chapter-next').onclick=()=>this.levels('All',chapter+1); }
    },
    sampleLevels:function(filter='All',obsolete=false){
      this.save();const rows=LEVELS.map((l,i)=>({l,i})).filter(({l,i})=>filter==='Continue'?P.resumable(this.progress,i,LEVELS):filter==='All'||(filter==='Early'?l.id<=30:filter==='Middle'?l.id<=60&&l.id>30:l.id>60));
      this.openModal('<span class="badge">'+LEVELS.length+' SAMPLE'+(LEVELS.length===1?'':'S')+' · A GENTLER FLOW</span><h2 id="modal-title">Choose a sample</h2>'+(obsolete?'<p>This preview has been updated. Choose a new sample below.</p>':'')+'<p>Early 1–30: open bottles<br>Middle 31–60: 1–2 covers<br>Late 61–100: 2–4 covers</p><div class="level-tabs">'+['All','Early','Middle','Late','Continue'].map(f=>'<button data-filter="'+f+'" aria-pressed="'+(filter===f)+'">'+f+'</button>').join('')+'</div>'+rows.map(({l,i})=>{const covers=(l.locks||[]).reduce((n,x)=>n+x.bottles.length,0);return '<button class="level-choice" data-level="'+i+'"><strong>'+String(i+1).padStart(2,'0')+'</strong><span>'+l.name+'<small>'+(l.id<=30?'Early':l.id<=60?'Middle':'Late')+' · '+covers+' cover'+(covers===1?'':'s')+(l.collector?' · Tall bottle':'')+'</small><small>Campaign '+l.id+' · '+l.minimum+' minimum pours</small></span><i>'+(this.completed.includes(i)?'✓':'→')+'</i></button>';}).join(''));
      $('modal-content').querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>this.sampleLevels(b.dataset.filter));$('modal-content').querySelectorAll('[data-level]').forEach(b=>b.onclick=()=>this.switchLevel(Number(b.dataset.level)));
    },
    showWin:function(celebrate){if(PREVIEW){this.openModal('<img class="win-moon" src="assets/icons/moon.svg" alt=""><span class="badge">BEAUTIFULLY SORTED</span><h2 id="modal-title">Lovely work!</h2><p>Every color in its happy place.</p><div class="win-stat"><div><b>'+this.session.moves+'</b><span>moves</span></div></div><button class="primary" id="next-level">'+(this.levelIndex<LEVELS.length-1?'Next sample':'Explore the samples')+'</button><button class="secondary" id="replay-level">Play again</button>');$('next-level').onclick=()=>this.levelIndex<LEVELS.length-1?this.switchLevel(this.levelIndex+1):this.levels();$('replay-level').onclick=()=>{this.closeModal();this.loadLevel(this.levelIndex);this.save();};return;}if(!R.isSolved(this.session.state))return;this.openModal('<img class="win-moon" src="assets/icons/moon.svg" alt=""><span class="badge">BEAUTIFULLY SORTED</span><h2 id="modal-title">'+(this.levelIndex===99?'A garden of color!':'Lovely work!')+'</h2><p>'+(this.levelIndex===99?'You reached level 100.<br>Enjoy a little well-earned calm.':(this.session.state.collector>=0?'Pink collected.<br>':'')+'Every color in its happy place.')+'</p><div class="win-stat"><div><b>'+this.session.moves+'</b><span>moves</span></div>'+(this.session.state.collector>=0?'<div><b>'+this.session.state.capacity+' / '+this.session.state.capacity+'</b><span>pink collected</span></div>':'')+'</div><button class="primary" id="next-level">'+(this.levelIndex<LEVELS.length-1?'Next level':(this.completed.length===LEVELS.length?'All 100 complete!':'Explore the garden'))+'</button><button class="secondary" id="replay-level">Play this level again</button>');$('next-level').onclick=()=>{if(this.levelIndex===99)this.levels('All',9);else this.switchLevel(this.levelIndex+1);};$('replay-level').onclick=()=>{this.closeModal();this.loadLevel(this.levelIndex);this.save();};}
  });
})();
