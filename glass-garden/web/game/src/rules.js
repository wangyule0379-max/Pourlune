(function(root,factory){const api=factory(typeof module==='object'?require('./campaign.js'):root.PourCampaign);if(typeof module==='object'&&module.exports)module.exports=api;else root.PourRules=api;})(typeof self!=='undefined'?self:globalThis,function(campaign){
  'use strict';
  const C={P:'purple',Y:'yellow',T:'turquoise',R:'pink',B:'blue',O:'orange',G:'green',C:'coral'};
  const expand=s=>Array.from(s,c=>C[c]);
  // Bottom-to-top arrays. Collector capacity and prefill belong to each level.
  const LEVELS=campaign,CATALOG_ID='gentle-100-v4';

  const clone=s=>({...s,bottles:s.bottles.map(b=>b.slice()),...(s.fog?{fog:s.fog.slice()}:{}),...(s.locks?{locks:s.locks.map(l=>({...l,bottles:l.bottles.slice()})),opened:s.opened.slice()}:{})});
  function initialState(level){
    const bottles=level.stacks.map(expand).concat(Array.from({length:level.emptyCount??1},()=>[]));
    const collector=level.collector===false?-1:bottles.length;
    if(collector>=0)bottles.push(Array(level.prefill??6).fill('pink'));
    return {bottles,collector,target:collector<0?null:'pink',capacity:collector<0?0:(level.capacity||10),
      ...(level.mystery?{fog:bottles.map((_,i)=>level.mystery.covered[i]||0)}:{}),
      ...(level.locks?{locks:level.locks.map(l=>({...l,bottles:l.bottles.slice()})),opened:level.locks.map(()=>false),collectedStart:collector<0?0:bottles[collector].length}:{})};
  }
  function lockFor(s,index){return s.locks?.find((l,k)=>!s.opened[k]&&l.bottles.includes(index))||null;}
  function isLocked(s,index){return !!lockFor(s,index);}
  // Stable slots and shared liquid-unit height; bottle positions never change during play.
  function layoutFor(level){
    const complex=level.stacks.length>4,width=60,unit=35.5,hitWidth=84;
    if(level.layout)return {width,unit:level.layout.unit,hitWidth,slots:level.layout.slots.map(p=>p.slice()),complex,span:level.layout.span};
    const ordinary=complex?[[63,197],[180,197],[298,197],[415,197],[102,402],[384,402],[102,615],[384,615]]:[[72,280],[181,280],[290,280],[126,493],[245,493]];
    return {width,unit,hitWidth,slots:ordinary.concat([complex?[240,402]:[396,280]]),complex,span:2};
  }
  // Preserve saves from the original 8-unit collector when upgrading the two-row layout.
  function upgradeSave(saved){
    if(!saved||saved.level>=5||saved.state?.capacity!==8)return saved;
    const upgrade=s=>s&&s.capacity===8?{...s,capacity:10,bottles:s.bottles.map((b,i)=>i===s.collector?['pink','pink',...b]:b.slice())}:s;
    return {...saved,state:upgrade(saved.state),history:Array.isArray(saved.history)?saved.history.map(upgrade):saved.history};
  }
  function counts(s){const result={};for(const b of s.bottles)for(const c of b)result[c]=(result[c]||0)+1;return Object.fromEntries(Object.entries(result).sort());}
  function isSolved(s){return (!s.fog||s.fog.every(mask=>mask===0)) && (!s.opened||s.opened.every(Boolean)) && (s.collector<0||(s.bottles[s.collector].length===s.capacity && s.bottles[s.collector].every(c=>c===s.target))) && s.bottles.every((b,i)=>i===s.collector||!b.length||(b.length===4&&b.every(c=>c===b[0])&&b[0]!==s.target));}
  function newlyCompleted(before,after,index){const b=after.bottles[index];return !after.fog?.[index]&&index!==after.collector&&before.bottles[index].length<4&&b.length===4&&b[0]!==after.target&&b.every(c=>c===b[0]);}
  function move(s,from,to){
    const fail=reason=>({ok:false,reason});
    if(!Number.isInteger(from)||!Number.isInteger(to)||from<0||to<0||from>=s.bottles.length||to>=s.bottles.length)return fail('invalid');
    if(from===to)return fail('same');
    if(from===s.collector)return fail('fixed');
    if(isLocked(s,from)||isLocked(s,to))return fail('locked');
    const a=s.bottles[from],b=s.bottles[to];
    if(!a.length)return fail('empty');
    const color=a[a.length-1],cap=to===s.collector?s.capacity:4;
    if(to===s.collector&&color!==s.target)return fail('pink-only');
    if(b.length>=cap)return fail('full');
    if(b.length&&b[b.length-1]!==color)return fail('mismatch');
    let amount=1;while(amount<a.length&&!(s.fog?.[from]&(1<<(a.length-amount-1)))&&a[a.length-amount-1]===color)amount++;
    amount=Math.min(amount,cap-b.length);
    const next=clone(s);next.bottles[from].splice(a.length-amount,amount);next.bottles[to].push(...Array(amount).fill(color));
    const revealed=[];if(next.fog){const depth=next.bottles[from].length-1;if(depth>=0&&(next.fog[from]&(1<<depth))){next.fog[from]&=~(1<<depth);revealed.push({bottle:from,layer:depth,color:next.bottles[from][depth]});}}
    const unlocked=[];
    if(next.locks)next.locks.forEach((l,k)=>{
      if(next.opened[k])return;
      const triggered=l.color?newlyCompleted(s,next,to)&&next.bottles[to][0]===l.color:
        next.collector>=0&&next.bottles[next.collector].length-next.collectedStart>=l.collect;
      if(triggered){next.opened[k]=true;unlocked.push(...l.bottles);}
    });
    return {ok:true,state:next,from,to,color,amount,...(s.fog?{revealed}:{}),...(s.locks?{unlocked}:{})};
  }
  function key(s){
    const ordinary=[],locked=[];
    s.bottles.forEach((b,i)=>{if(i===s.collector)return;const v=b.join(',')+':'+(s.fog?.[i]||0);if(isLocked(s,i))locked.push(i+'='+v);else ordinary.push(v);});
    return ordinary.sort().join('|')+'#'+(s.collector<0?'-':s.bottles[s.collector].length)+'#'+locked.join('|')+'#'+(s.opened||[]).map(Number).join('');
  }
  function solve(start,limit=100000){
    if(start.bottles.length>6)return solveLarge(start,limit);
    if(isSolved(start))return {status:'solved',path:[],visited:1};
    const queue=[{s:start,parent:-1,edge:null}],seen=new Set([key(start)]);
    for(let head=0;head<queue.length;head++){
      if(queue.length>limit)return {status:'limit',path:[],visited:queue.length};
      const s=queue[head].s;
      const destinations=[...(s.collector<0?[]:[s.collector]),...s.bottles.map((_,i)=>i).filter(i=>i!==s.collector)];
      for(let i=0;i<s.bottles.length;i++){
        if(i===s.collector||!s.bottles[i].length)continue;
        const source=s.bottles[i];
        for(const j of destinations){
          if(!s.bottles[j].length&&source.every(c=>c===source[0])&&!s.fog?.[i]&&j!==s.collector)continue; // equivalent empty swap
          const m=move(s,i,j);if(!m.ok)continue;
          const k=key(m.state);if(seen.has(k))continue;
          seen.add(k);const id=queue.length;queue.push({s:m.state,parent:head,edge:[i,j]});
          if(isSolved(m.state)){const path=[];let at=id;while(queue[at].parent>=0){path.push(queue[at].edge);at=queue[at].parent;}return {status:'solved',path:path.reverse(),visited:seen.size};}
        }
      }
    }
    return {status:'dead',path:[],visited:seen.size};
  }
  // Larger boards use ordered depth-first search with canonical-state pruning.
  // It finds a valid continuation, not necessarily the shortest one; the UI claims no par score.
  function solveLarge(start,limit=150000){
    const seen=new Set([key(start)]),path=[];
    function candidates(s){
      const choices=[];
      for(let i=0;i<s.bottles.length;i++){
        const a=s.bottles[i];if(i===s.collector||!a.length)continue;
        const uniform=a.every(c=>c===a[0]);
        if(uniform&&!s.fog?.[i]&&a.length===4&&a[0]!==s.target)continue;
        let usedEmpty=false;
        for(let j=0;j<s.bottles.length;j++){
          const b=s.bottles[j];
          if(j!==s.collector&&!b.length&&!isLocked(s,j)){if((uniform&&!s.fog?.[i])||usedEmpty)continue;usedEmpty=true;}
          const m=move(s,i,j);if(!m.ok)continue;
          const score=(j===s.collector?100:0)+(b.length?20:0)+m.amount*3+(b.length+m.amount===4?10:0)+(a.length===m.amount?8:0);
          choices.push({m,score});
        }
      }
      return choices.sort((a,b)=>b.score-a.score);
    }
    if(isSolved(start))return {status:'solved',path:[],visited:1};
    const stack=[{choices:candidates(start),next:0}];
    while(stack.length){
      const frame=stack[stack.length-1];
      if(frame.next===frame.choices.length){stack.pop();path.pop();continue;}
      const {m}=frame.choices[frame.next++],k=key(m.state);
      if(seen.has(k))continue;
      if(seen.size>=limit)return {status:'limit',path:[],visited:seen.size};
      seen.add(k);path.push([m.from,m.to]);
      if(isSolved(m.state))return {status:'solved',path,visited:seen.size};
      stack.push({choices:candidates(m.state),next:0});
    }
    return {status:'dead',path:[],visited:seen.size};
  }
  function validState(s,level){
    try{
      const base=initialState(level);
      if(!s||s.collector!==base.collector||s.capacity!==base.capacity||s.target!==base.target||!Array.isArray(s.bottles)||s.bottles.length!==base.bottles.length)return false;
      if(level.mystery){if(!Array.isArray(s.fog)||s.fog.length!==base.bottles.length)return false;for(let i=0;i<s.fog.length;i++){const mask=s.fog[i],b=s.bottles[i];if(!Number.isInteger(mask)||mask<0||(mask&~base.fog[i])||(mask&~((1<<b.length)-1))||(mask&(1<<(b.length-1))))return false;for(let j=0;j<b.length;j++)if((mask&(1<<j))&&b[j]!==base.bottles[i][j])return false;}}else if(s.fog)return false;
      if(base.locks){
        if(JSON.stringify(s.locks)!==JSON.stringify(base.locks)||s.collectedStart!==base.collectedStart||!Array.isArray(s.opened)||s.opened.length!==base.opened.length||s.opened.some(v=>typeof v!=='boolean'))return false;
        for(let k=0;k<s.locks.length;k++)if(!s.opened[k])for(const i of s.locks[k].bottles)if(JSON.stringify(s.bottles[i])!==JSON.stringify(base.bottles[i]))return false;
      }else if(s.locks||s.opened)return false;
      const colors=new Set(Object.keys(counts(base)));
      if(!s.bottles.every((b,i)=>Array.isArray(b)&&b.length<=(i===s.collector?s.capacity:4)&&b.every(c=>colors.has(c))))return false;
      if(s.collector>=0&&(s.bottles[s.collector].length<base.bottles[base.collector].length||!s.bottles[s.collector].every(c=>c==='pink')))return false;
      return JSON.stringify(counts(s))===JSON.stringify(counts(base));
    }catch(e){return false;}
  }
  class Session{
    constructor(level){this.level=level;this.restart();}
    restart(){this.state=initialState(this.level);this.history=[];this.moves=0;this.hints=0;this.known=this.state.fog?.map(()=>0);}
    remember(saved=this.known){if(!this.state.fog)return;const base=initialState(this.level).fog;this.known=base.map((mask,i)=>(mask&~this.state.fog[i])|(mask&(Number.isInteger(saved?.[i])?saved[i]:0)));this.state.fog=this.state.fog.map((mask,i)=>mask&~this.known[i]);}
    pour(i,j){const result=move(this.state,i,j);if(result.ok){this.history.push(clone(this.state));this.state=result.state;this.remember();this.moves++;}return result;}
    undo(){if(!this.history.length)return false;this.state=clone(this.history.pop());this.remember();this.moves=Math.max(0,this.moves-1);return true;}
  }
  // The only representation passed to visible water and accessible labels.
  function visibleColors(s,index){if(isLocked(s,index))return [];return s.bottles[index].map((color,layer)=>(s.fog?.[index]&(1<<layer))?'mystery':color);}
  function sameBoard(a,b){return JSON.stringify(a.bottles)===JSON.stringify(b.bottles)&&JSON.stringify(a.opened)===JSON.stringify(b.opened);}
  return {CATALOG_ID,isLocked,lockFor,stateKey:key,visibleColors,sameBoard,LEVELS,layoutFor,upgradeSave,initialState,clone,counts,isSolved,newlyCompleted,move,solve,validState,Session};
});
