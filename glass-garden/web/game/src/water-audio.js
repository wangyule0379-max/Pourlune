(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.PourWaterAudio=factory();})(typeof self!=='undefined'?self:globalThis,function(){
'use strict';
  class Sounds{
    constructor(){this.ctx=null;this.enabled=true;this.flowNodes=null;this.waterBuffer=null;this.waterBytes=fetch('assets/audio/water-pour.wav').then(r=>{if(!r.ok)throw new Error('Water recording unavailable');return r.arrayBuffer();}).catch(()=>null);}
    unlock(){if(!this.ctx){try{this.ctx=new (window.AudioContext||window.webkitAudioContext)();}catch(e){return;}}if(!this.waterDecode)this.waterDecode=this.waterBytes.then(bytes=>bytes?this.ctx.decodeAudioData(bytes):null).then(buffer=>{this.waterBuffer=buffer;}).catch(()=>{});if(this.ctx.state==='suspended')this.ctx.resume().catch(()=>{});}
    tone(freq,duration=.12,gain=.04,type='sine',delay=0){if(!this.enabled||!this.ctx)return;const t=this.ctx.currentTime+delay,o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type=type;o.frequency.setValueAtTime(freq,t);g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(gain,t+.012);g.gain.exponentialRampToValueAtTime(.001,t+duration);o.connect(g);g.connect(this.ctx.destination);o.start(t);o.stop(t+duration+.02);}
    select(){this.tone(660,.07,.007);}
    error(){this.tone(220,.1,.018,'triangle');}
    complete(){this.tone(784,.2,.012);}
    win(){[523,659,784,1047].forEach((f,i)=>this.tone(f,.4,.018,'sine',i*.12));}
    startWater(){
      if(!this.enabled||!this.ctx||!this.waterBuffer)return;
      this.stopWater();const c=this.ctx,n=c.createBufferSource(),g=c.createGain();
      n.buffer=this.waterBuffer;n.loop=false;g.gain.setValueAtTime(0,c.currentTime);g.gain.linearRampToValueAtTime(.65,c.currentTime+.045);
      n.connect(g);g.connect(c.destination);n.onended=()=>{n.disconnect();g.disconnect();};n.start();this.flowNodes={n,g};
    }
    stopWater(){if(!this.flowNodes)return;const {n,g}=this.flowNodes;this.flowNodes=null;try{g.gain.cancelScheduledValues(this.ctx.currentTime);g.gain.setValueAtTime(g.gain.value,this.ctx.currentTime);g.gain.linearRampToValueAtTime(0,this.ctx.currentTime+.08);n.stop(this.ctx.currentTime+.09);}catch(e){}}
  }
return {Sounds};
});
