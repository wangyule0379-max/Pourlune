importScripts('campaign.js','rules.js');
// Retain a proven route across repeated hints. Re-solving each step independently
// can suggest a reversible detour on a large board even though each route is valid.
const cacheKey=s=>JSON.stringify([s.bottles,s.fog,s.opened,s.collector,s.capacity,s.target,s.locks,s.collectedStart]);
let route=[];
self.onmessage=function(e){
  const {id,state}=e.data;
  try{
    const key=cacheKey(state),cached=route.find(step=>step.key===key);
    if(cached){self.postMessage({id,status:'solved',path:state.fog?cached.path.slice(0,1):cached.path,visited:0});return;}
    const result=PourRules.solve(state,150000);route=[];
    if(result.status==='solved'){
      let current=state;
      for(let i=0;i<result.path.length;i++){
        route.push({key:cacheKey(current),path:result.path.slice(i)});
        current=PourRules.move(current,...result.path[i]).state;
      }
    }
    self.postMessage({id,...result,path:state.fog?result.path.slice(0,1):result.path});
  }catch(error){self.postMessage({id,status:'error',message:String(error)});}
};
