// Per-puzzle entitlement adapter. The fixed campaign and original rules stay unchanged.
export function withExtraBottle(level,R){
 const next=structuredClone(level),base=R.initialState(level),at=base.collector<0?base.bottles.length:base.collector;
 next.emptyCount=(level.emptyCount??1)+1;
 if(next.mystery)next.mystery.covered.splice(at,0,0);
 const layout=R.layoutFor(level),slots=layout.slots.map(p=>p.slice()),height=4*layout.unit+33;
 const collectorHeight=height+Math.max(0,layout.span-1)*layout.unit*6;
 const separate=(x,y,bx,top,bottom,half)=>x+42<=bx-half||x-42>=bx+half||y+height+10<=top||y-10>=bottom;
 const free=(x,y)=>x>=42&&x<=438&&slots.every(([bx,by],i)=>{
  const tall=i===base.collector,h=tall?collectorHeight:height;
  return separate(x,y,bx,by-10,by+h+10,42)&&(!tall||separate(x,y,bx,by+h+57,by+h+93,70));
 });
 let position;
 const rows=[...new Set(slots.map(p=>p[1]))].sort((a,b)=>b-a),xs=[...new Set([...slots.map(p=>p[0]),52,146,240,334,428])].sort((a,b)=>Math.abs(a-240)-Math.abs(b-240)||a-b);
 for(const y of rows){position=xs.map(x=>[x,y]).find(([x,py])=>free(x,py));if(position)break;}
 // A full ordinary row can become five columns without reducing bottle size.
 if(!position&&base.collector<0)for(const y of rows){
  const indices=slots.map((p,i)=>p[1]===y?i:-1).filter(i=>i>=0).sort((a,b)=>slots[a][0]-slots[b][0]);
  if(indices.length!==4)continue;
  const grid=[52,146,240,334,428];let best;
  for(let gap=0;gap<5;gap++){const occupied=grid.filter((_,i)=>i!==gap),cost=occupied.reduce((n,x,i)=>n+Math.abs(x-slots[indices[i]][0]),0);if(!best||cost<best.cost)best={gap,occupied,cost};}
  indices.forEach((i,k)=>slots[i][0]=best.occupied[k]);position=[grid[best.gap],y];break;
 }
 // Dense tall-collector boards need one additional ordinary position below a side
 // column. Preserve every existing bottle/collector coordinate and liquid unit.
 if(!position){let y=Math.max(...rows)+height+23;position=xs.map(x=>[x,y]).find(([x,py])=>free(x,py));}
 if(!position)throw Error('No safe extra-bottle position');
 slots.splice(at,0,position);next.layout={unit:layout.unit,span:layout.span,slots};return next;
}
export function expandSlot(slot){
 const next=structuredClone(slot),at=next.state.collector<0?next.state.bottles.length:next.state.collector;
 const expand=s=>{s.bottles.splice(at,0,[]);if(s.collector>=0)s.collector++;if(s.fog)s.fog.splice(at,0,0);if(s.locks)for(const lock of s.locks)lock.bottles=lock.bottles.map(i=>i>=at?i+1:i);};
 expand(next.state);next.history.forEach(expand);if(next.known)next.known.splice(at,0,0);return next;
}
