(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.GardenAudioBridge=factory();})(typeof self!=='undefined'?self:globalThis,function(){
 'use strict';
 function attach(audio){
  const unlock=audio.unlock,voices=new Set();let instrumented;
  audio.unlock=function(){
   unlock.call(this);if(!this.ctx||this.ctx===instrumented)return;instrumented=this.ctx;
   const create=this.ctx.createOscillator.bind(this.ctx);
   this.ctx.createOscillator=function(){const node=create();voices.add(node);node.addEventListener('ended',()=>voices.delete(node),{once:true});return node;};
  };
  audio.stopTransient=function(){this.stopWater();for(const node of voices){try{node.stop();}catch{}try{node.disconnect();}catch{}}voices.clear();};
 }
 return {attach};
});
