// Port of the existing game's first-clear qualification and shared fullscreen
// clock. Remote policy may restrict it further, never loosen this local floor.
export function adLedger(state){return state.fullscreen||{qualifyingTotal:Math.max(0,state.completedLevels.length-10),consumedTotal:0,lastShownAt:null,attempts:{}};}
export function validateFullscreen(state){
 const f=state.fullscreen;if(f==null)return;
 const object=x=>x&&typeof x==='object'&&!Array.isArray(x),integer=x=>Number.isSafeInteger(x)&&x>=0;
 if(!object(f)||f.qualifyingTotal!==Math.max(0,state.completedLevels.length-10)||!integer(f.consumedTotal)||f.consumedTotal>f.qualifyingTotal||(f.lastShownAt!==null&&!integer(f.lastShownAt))||(f.uncertainAt!=null&&!integer(f.uncertainAt))||!object(f.attempts))throw Error('Unreadable fullscreen ledger');
 for(const [id,a] of Object.entries(f.attempts))if(!id||!object(a)||!['rewarded','interstitial'].includes(a.kind)||!Number.isInteger(a.level)||a.level<1||a.level>100||typeof a.roundId!=='string'||!a.roundId||!integer(a.boundary)||a.boundary>f.qualifyingTotal||!['prepared','shown','closed'].includes(a.status)||!Number.isFinite(Date.parse(a.createdAt))||(a.shownAt!=null&&!integer(a.shownAt)))throw Error('Unreadable fullscreen attempt');
}
export class FullscreenClock {
 constructor(ledger,{wall=()=>Date.now(),monotonic=()=>performance.now()}={}){Object.assign(this,{wall,monotonic});this.restore(ledger.lastShownAt,Object.values(ledger.attempts||{}).some(a=>a.status==='prepared'));if(ledger.uncertainAt!=null){const prior=this.duration;this.restore(ledger.uncertainAt);this.duration=Math.max(prior,this.duration);}}
 restore(last,uncertain=false){const delta=last==null?null:this.wall()-last;this.duration=uncertain||delta!==null&&(delta<0||delta>7*86400000)?180000:delta===null?0:Math.max(0,180000-delta);this.anchor=this.monotonic();}
 remaining(){return Math.max(0,this.duration-Math.max(0,this.monotonic()-this.anchor));}
 shown(at){this.restore(at);}
}
