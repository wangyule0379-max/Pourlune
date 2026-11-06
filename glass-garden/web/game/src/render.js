/* Cocos Canvas render-command nodes. Bottle contents are live geometry, not screenshots. */
(function(global){
  'use strict';
  const COLOR={mystery:'#75638b',pink:'#ff3597',turquoise:'#10c9bf',yellow:'#ffcf05',purple:'#9c48ed',blue:'#4383f0',orange:'#ff9700',green:'#8fd000',coral:'#ee514e'};
  const art={};
  function loadAssets(){return Promise.all(['collector-socket','bottle-reflection'].map(name=>new Promise((resolve,reject)=>{
    const img=new Image();img.onload=()=>{
      if(name==='bottle-reflection'){
        // Reflection map is authored on black; convert its luminance to smooth alpha once.
        // This preserves a completely clear center without automatic cutout speckles.
        const layer=document.createElement('canvas');layer.width=img.width;layer.height=img.height;
        const c=layer.getContext('2d');c.drawImage(img,0,0);const pixels=c.getImageData(0,0,img.width,img.height),d=pixels.data;
        for(let i=0;i<d.length;i+=4){const a=Math.max(d[i],d[i+1],d[i+2]);d[i+3]=a<4?0:a;if(a){d[i]=Math.round(d[i]*255/a);d[i+1]=Math.round(d[i+1]*255/a);d[i+2]=Math.round(d[i+2]*255/a);}}
        c.putImageData(pixels,0,0);art[name]=layer;
      }else art[name]=img;resolve();
    };img.onerror=()=>reject(new Error('Could not load '+name));img.src='assets/art/'+(name==='collector-socket'?'collector-porcelain':name)+'.png';
  })));}
  const NAME={mystery:'Hidden',pink:'Pink',turquoise:'Turquoise',yellow:'Yellow',purple:'Purple',blue:'Blue',orange:'Orange',green:'Green',coral:'Coral'};
  function rgba(hex,a){if(hex.startsWith('rgb('))return hex.replace('rgb(','rgba(').replace(')',','+a+')');const n=parseInt(hex.slice(1),16);return `rgba(${n>>16},${n>>8&255},${n&255},${a})`;}
  function shade(hex,amount){const n=parseInt(hex.slice(1),16),target=amount>0?255:0,f=Math.abs(amount);return 'rgb('+[n>>16,n>>8&255,n&255].map(v=>Math.round(v+(target-v)*f)).join(',')+')';}
  function span(poly,y){const xs=[];for(let i=0;i<poly.length;i++){const a=poly[i],b=poly[(i+1)%poly.length];if((a.y<=y&&b.y>y)||(b.y<=y&&a.y>y))xs.push(a.x+(b.x-a.x)*(y-a.y)/(b.y-a.y));}return xs.length>1?[Math.min(...xs),Math.max(...xs)]:[-24,24];}
  function round(ctx,x,y,w,h,r){ctx.beginPath();ctx.roundRect(x,y,w,h,r);}
  function text(ctx,t,x,y,size=12,color='#56818b',weight=500){ctx.font=`${weight} ${size}px "Nunito",ui-rounded,system-ui,sans-serif`;ctx.fillStyle=color;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(t,x,y);}
  function star(ctx,x,y,r,color,rotation=0){ctx.save();ctx.translate(x,y);ctx.rotate(rotation);ctx.fillStyle=color;ctx.beginPath();for(let i=0;i<8;i++){const a=i*Math.PI/4,v=i%2?r*.28:r;i?ctx.lineTo(Math.cos(a)*v,Math.sin(a)*v):ctx.moveTo(v,0);}ctx.closePath();ctx.fill();ctx.restore();}
  // A true crescent silhouette, with transparent negative space over the liquid.
  function crescent(ctx,x,y,r,color){
    const d=r*.45,inner=r*.92,ix=(r*r-inner*inner+d*d)/(2*d),iy=Math.sqrt(r*r-ix*ix);
    ctx.save();ctx.translate(x,y);ctx.rotate(-.32);ctx.fillStyle=color;
    ctx.beginPath();ctx.arc(0,0,r,Math.atan2(iy,ix),Math.atan2(-iy,ix),false);
    ctx.arc(d,0,inner,Math.atan2(-iy,ix-d),Math.atan2(iy,ix-d),true);ctx.closePath();ctx.fill();ctx.restore();
  }
  function droplet(ctx,x,y,size,color){ctx.save();ctx.translate(x,y);ctx.fillStyle=color;ctx.beginPath();ctx.moveTo(0,-size);ctx.bezierCurveTo(size*.4,-size*.45,size*.72,0,size*.63,size*.4);ctx.bezierCurveTo(size*.55,size*1.1,-size*.55,size*1.1,-size*.63,size*.4);ctx.bezierCurveTo(-size*.72,0,-size*.4,-size*.45,0,-size);ctx.fill();ctx.restore();}
  const PaintNode=cc.Node.extend({
    ctor:function(paint){this._super();this.paint=paint;this.setContentSize(480,1040);},
    _createRenderCmd:function(){const cmd=new cc.Node.CanvasRenderCmd(this);cmd._needDraw=true;cmd.rendering=function(wrapper,sx,sy){wrapper=wrapper||cc._renderContext;wrapper.setTransform(this._worldTransform,sx,sy);wrapper.setGlobalAlpha(1);const ctx=wrapper.getContext();ctx.save();ctx.globalAlpha=1;this._node.paint(ctx,this._node);ctx.restore();};return cmd;},
    updateTweenAction:function(value,key){this[key]=value;}
  });
  function path(ctx,w,h,lip=4){
    const a=w/2,n=w*.29;
    ctx.beginPath();ctx.moveTo(-n,lip);ctx.lineTo(-n,14);ctx.bezierCurveTo(-n,20,-a,19,-a,33);ctx.lineTo(-a,h-12);ctx.bezierCurveTo(-a,h-3,-a*.55,h+2,0,h+2);ctx.bezierCurveTo(a*.55,h+2,a,h-3,a,h-12);ctx.lineTo(a,33);ctx.bezierCurveTo(a,19,n,20,n,14);ctx.lineTo(n,lip);ctx.closePath();
  }
  function rot(p,a){return {x:p.x*Math.cos(a)-p.y*Math.sin(a),y:p.x*Math.sin(a)+p.y*Math.cos(a)};}
  function outletOffset(width,angle){return rot({x:Math.sign(angle)*width*.245,y:-.8},angle);}
  // Place the actual lower lip, not the bottle pivot. Keep the stream clear at every tilt.
  function pourPose(target,width,direction,angle){const lip=outletOffset(width,angle);return {x:target.x-lip.x,y:target.y+2-32-lip.y};}
  function area(poly){let s=0;for(let i=0,j=poly.length-1;i<poly.length;j=i++)s+=poly[j].x*poly[i].y-poly[i].x*poly[j].y;return Math.abs(s/2);}
  function below(poly,y){const out=[];for(let i=0;i<poly.length;i++){const p=poly[i],q=poly[(i+1)%poly.length],a=p.y>=y,b=q.y>=y;if(a)out.push(p);if(a!==b){const t=(y-p.y)/(q.y-p.y);out.push({x:p.x+(q.x-p.x)*t,y});}}return out;}
  function surface(poly,volume){let lo=Math.min(...poly.map(p=>p.y))-1,hi=Math.max(...poly.map(p=>p.y))+1;for(let i=0;i<22;i++){const mid=(lo+hi)/2;if(area(below(poly,mid))>volume)lo=mid;else hi=mid;}return (lo+hi)/2;}
  function liquidPolygon(w,h,angle){return [{x:-w/2+3,y:h-4},{x:w/2-3,y:h-4},{x:w/2-3,y:29},{x:w*.26,y:16},{x:w*.245,y:-.8},{x:-w*.245,y:-.8},{x:-w*.26,y:16},{x:-w/2+3,y:29}].map(p=>rot(p,angle));}
  function pourAngle(w,h,unit,remaining){
    // Find the gravity angle at which the remaining volume meets the lower lip.
    // Below a sub-pixel film, the last visible liquid is represented by tail drops.
    const volume=Math.max(.03,remaining)*(w-6)*unit;let lo=0,hi=Math.PI;
    for(let i=0;i<24;i++){const a=(lo+hi)/2,held=area(below(liquidPolygon(w,h,a),outletOffset(w,a).y));if(held>volume)lo=a;else hi=a;}
    return (lo+hi)/2;
  }
  function runs(units){const out=[];for(const u of units){if(u.amount<=.001)continue;const p=out[out.length-1];if(p&&p.color===u.color&&u.color!=='mystery')p.amount+=u.amount;else out.push({color:u.color,amount:u.amount});}return out;}
  function drawGlass(ctx,w,h,front){
    const img=art['bottle-reflection'];if(!img||!front)return;
    const sw=img.width,sh=img.height;
    ctx.save();
    // Keep the subtle body reflection, with one clean, code-native collar above it.
    ctx.globalAlpha=.48;
    ctx.drawImage(img,sw*20/737,sh*470/2134,sw*680/737,sh*1450/2134,-w/2,33,w,h-46);
    ctx.globalAlpha=1;
    // A tapered window reflection follows the shoulder instead of a full-height white stripe.
    const sheen=ctx.createLinearGradient(0,17,0,h-14);
    sheen.addColorStop(0,'rgba(255,255,255,.82)');sheen.addColorStop(.22,'rgba(255,255,255,.53)');sheen.addColorStop(.68,'rgba(255,255,255,.10)');sheen.addColorStop(1,'rgba(255,255,255,0)');
    ctx.fillStyle=sheen;ctx.beginPath();ctx.moveTo(-w*.25,17);
    ctx.bezierCurveTo(-w*.42,22,-w*.43,28,-w*.43,40);ctx.lineTo(-w*.43,h-19);
    ctx.bezierCurveTo(-w*.40,h-22,-w*.35,h*.61,-w*.32,40);
    ctx.bezierCurveTo(-w*.31,28,-w*.25,23,-w*.20,21);ctx.closePath();ctx.fill();
    const shoulder=ctx.createLinearGradient(-w*.4,18,-w*.1,35);shoulder.addColorStop(0,'rgba(255,255,255,.7)');shoulder.addColorStop(1,'rgba(255,255,255,0)');ctx.fillStyle=shoulder;ctx.beginPath();ctx.moveTo(-w*.26,20);ctx.bezierCurveTo(-w*.4,23,-w*.43,29,-w*.41,34);ctx.bezierCurveTo(-w*.33,31,-w*.22,25,-w*.15,23);ctx.closePath();ctx.fill();
    ctx.strokeStyle='rgba(255,255,255,.88)';ctx.lineWidth=1.1;ctx.lineCap='round';
    ctx.beginPath();ctx.moveTo(-w*.27,19);ctx.bezierCurveTo(-w*.38,24,-w*.42,28,-w*.42,36);ctx.stroke();
    // A single refracted foot and a quiet far-side rim establish glass thickness.
    const foot=ctx.createLinearGradient(0,h-9,0,h+1);foot.addColorStop(0,'rgba(133,178,164,.05)');foot.addColorStop(.55,'rgba(100,150,137,.22)');foot.addColorStop(1,'rgba(255,255,255,.74)');
    ctx.fillStyle=foot;ctx.beginPath();ctx.ellipse(0,h-4,w*.43,4,0,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle='rgba(255,255,255,.86)';ctx.lineWidth=1.35;ctx.beginPath();ctx.ellipse(0,h-4,w*.40,3.4,0,.08,Math.PI-.08);ctx.stroke();
    const edge=ctx.createLinearGradient(0,30,0,h-12);edge.addColorStop(0,'rgba(255,255,255,.12)');edge.addColorStop(.75,'rgba(255,255,255,.42)');edge.addColorStop(1,'rgba(255,255,255,.16)');
    ctx.strokeStyle=edge;ctx.lineWidth=.8;ctx.beginPath();ctx.moveTo(w*.455,34);ctx.lineTo(w*.455,h-16);ctx.stroke();
    ctx.restore();
  }
  function paintCover(ctx,b,seal){
    if(!seal)return;const w=b.w+8,h=b.h+2,p=b.cover?0:1-b.unveil,color=COLOR[seal.color]||COLOR.pink;
    ctx.save();ctx.translate(0,-p*28);ctx.globalAlpha=1-p;ctx.shadowColor='rgba(116,64,81,.16)';ctx.shadowBlur=9;ctx.shadowOffsetY=5;
    ctx.beginPath();ctx.moveTo(-w*.3,-5);ctx.quadraticCurveTo(0,-12,w*.3,-5);ctx.bezierCurveTo(w*.31,10,w*.53,22,w*.52,45);ctx.lineTo(w*.52,h-7);ctx.quadraticCurveTo(w*.3,h+7,0,h-1);ctx.quadraticCurveTo(-w*.3,h+7,-w*.52,h-7);ctx.lineTo(-w*.52,45);ctx.bezierCurveTo(-w*.53,22,-w*.31,10,-w*.3,-5);ctx.closePath();
    const cloth=ctx.createLinearGradient(-w*.55,0,w*.55,0);cloth.addColorStop(0,'#e8b2bb');cloth.addColorStop(.14,'#f7d7d8');cloth.addColorStop(.32,'#fff1e7');cloth.addColorStop(.48,'#f3ced1');cloth.addColorStop(.68,'#fff2e8');cloth.addColorStop(.86,'#f3c8ce');cloth.addColorStop(1,'#dca7b5');ctx.fillStyle=cloth;ctx.fill();ctx.shadowBlur=0;ctx.shadowOffsetY=0;ctx.lineWidth=1;ctx.strokeStyle='#fff3e8';ctx.stroke();
    ctx.save();ctx.clip();for(const x of [-.30,-.08,.16,.36]){ctx.beginPath();ctx.moveTo(x*w*.55,0);ctx.bezierCurveTo(x*w,35,x*w-3,h*.6,x*w,h+2);ctx.strokeStyle='rgba(255,255,255,.27)';ctx.lineWidth=2;ctx.stroke();}ctx.restore();
    const cy=Math.max(67,h*.48);ctx.save();ctx.shadowColor='rgba(116,64,81,.15)';ctx.shadowBlur=5;ctx.shadowOffsetY=2;ctx.fillStyle='#fff9e9';ctx.beginPath();ctx.ellipse(0,cy,24,31,0,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;ctx.shadowOffsetY=0;ctx.strokeStyle='#dec59d';ctx.lineWidth=1;ctx.stroke();
    if(seal.color){ctx.save();ctx.translate(0,cy-21);ctx.scale(.30,.30);path(ctx,60,105);ctx.fillStyle=color;ctx.fill();ctx.strokeStyle=shade(color,-.25);ctx.lineWidth=4;ctx.stroke();ctx.fillStyle='#e2c589';round(ctx,-19,-5,38,14,5);ctx.fill();ctx.restore();text(ctx,NAME[seal.color].toUpperCase(),0,cy+20,8.5,'#755d65',850);}
    else{droplet(ctx,0,cy-7,11,COLOR.pink);text(ctx,String(b.reserveRemaining??seal.collect)+' more',0,cy+17,10,'#885e71',850);}
    ctx.restore();ctx.fillStyle='#fff6e7';ctx.beginPath();ctx.arc(0,h-20,9,0,Math.PI*2);ctx.fill();ctx.strokeStyle='#9b7b87';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(0,h-22,3.3,Math.PI,0);ctx.stroke();round(ctx,-4.5,h-22,9,7,2);ctx.fillStyle='#9b7b87';ctx.fill();ctx.restore();
  }
  const Bottle=PaintNode.extend({
    ctor:function(index,capacity,x,y,scene){this.index=index;this.capacity=capacity;this.w=scene.layout.width;this.unit=scene.layout.unit;this.h=capacity*this.unit+33;if(index===scene.session.state.collector&&scene.layout.span){this.h=4*this.unit+33+(scene.layout.span-1)*this.unit*6;this.unit=(this.h-33)/capacity;}this.liquidUnit=this.unit-5/capacity;this.angle=0;this.glow=0;this.hint=0;this.wave=0;this.done=false;this.completion=0;this.units=[];this.scene=scene;this.home={x,y};this._super((ctx,node)=>node.drawBottle(ctx));this.setPosition(x,1040-y);this.setContentSize(80,this.h+30);},
    sync:function(colors){this.units=colors.map(color=>({color,amount:1}));this.done=this.capacity===4&&colors.length===4&&colors.every(c=>c===colors[0])&&(colors[0]!=='pink'||this.scene?.session.state.collector<0)&&colors[0]!=='mystery';},
    screen:function(){return {x:this.getPositionX(),y:1040-this.getPositionY()};},
    mouth:function(){const p=rot({x:0,y:2},this.angle);const s=this.screen();return {x:s.x+p.x,y:s.y+p.y};},
    outlet:function(){const edge=outletOffset(this.w,this.angle),s=this.screen();return {x:s.x+edge.x,y:s.y+edge.y};},
    drawBottle:function(ctx){
      const moving=this.unveil>0||Math.abs(this.angle)>.0001||this.wave>0||this.completion>0||this.reveal>0||(this.index===this.scene.session.state.collector&&this.scene.fullBloom>0);
      if(moving){this.paintBottle(ctx);return;}
      const key=JSON.stringify([this.units,this.glow,this.hint,this.accepts,this.pending,this.done,this.scene.reduced,this.cover,this.reserveRemaining]);
      if(!this.cache||this.cache.key!==key){
        const scale=Math.min(2,global.devicePixelRatio||1),left=-this.w/2-30,top=-40,width=this.w+60,height=this.h+70;
        const canvas=document.createElement('canvas');canvas.width=Math.ceil(width*scale);canvas.height=Math.ceil(height*scale);
        const c=canvas.getContext('2d');c.scale(scale,scale);c.translate(-left,-top);this.paintBottle(c);this.cache={key,canvas,left,top,width,height};
      }
      const c=this.cache;ctx.drawImage(c.canvas,c.left,c.top,c.width,c.height);
    },
    paintBottle:function(ctx){
      const w=this.w,h=this.h,t=this.scene.time,tilt=this.angle;
      const celebration=this.scene.reduced?0:this.completion,phase=1-celebration;
      if(this.hint>0||this.glow>0){ctx.save();ctx.rotate(tilt);const strong=this.hint>0?1:this.glow;ctx.shadowBlur=10;ctx.shadowColor=rgba('#df709f',strong*.65);path(ctx,w+6,h+2);ctx.strokeStyle=rgba('#fff9ef',strong*.95);ctx.lineWidth=5;ctx.stroke();ctx.shadowBlur=0;ctx.strokeStyle=rgba('#bd4a81',strong*.9);ctx.lineWidth=2;ctx.stroke();ctx.restore();}
      ctx.save();ctx.rotate(tilt);path(ctx,w,h);const glass=ctx.createLinearGradient(-w/2,0,w/2,0);glass.addColorStop(0,'rgba(68,129,121,.18)');glass.addColorStop(.15,'rgba(255,255,255,.38)');glass.addColorStop(.4,'rgba(255,255,255,.03)');glass.addColorStop(.8,'rgba(255,255,255,.2)');glass.addColorStop(1,'rgba(59,116,115,.22)');ctx.fillStyle=glass;ctx.fill();ctx.restore();
      ctx.save();ctx.rotate(tilt);drawGlass(ctx,w,h,false);ctx.restore();
      // Clip with bottle geometry, then paint horizontal liquid in world orientation.
      ctx.save();ctx.rotate(tilt);path(ctx,w-4,h-3,-1);ctx.clip();ctx.rotate(-tilt);
      const poly=liquidPolygon(w,h,tilt);
      const bottom=Math.max(...poly.map(p=>p.y));let cumulative=0;const bands=runs(this.units),questions=[];let prev=bottom+2;
      const innerW=w-6,liquidUnit=this.liquidUnit,unitArea=innerW*liquidUnit;
      for(let k=0;k<bands.length;k++){
        const band=bands[k];cumulative+=band.amount;const y=Math.abs(tilt)<.001?h-4-cumulative*liquidUnit:surface(poly,cumulative*unitArea);
        const base=COLOR[band.color],edges=span(poly,(y+prev)*.5),topEdges=span(poly,y+.1);
        const grad=ctx.createLinearGradient(edges[0],0,edges[1],0);
        grad.addColorStop(0,shade(base,-.34));grad.addColorStop(.08,shade(base,-.08));grad.addColorStop(.25,shade(base,.2));grad.addColorStop(.43,shade(base,.08));grad.addColorStop(.60,shade(base,-.01));grad.addColorStop(.78,shade(base,-.15));grad.addColorStop(.94,shade(base,-.32));grad.addColorStop(1,shade(base,-.45));
        // A shallow convex boundary makes adjacent colors read as stacked liquid cylinders.
        const depth=Math.max(0,prev-y),curve=Math.min(Math.abs(Math.cos(tilt))*7,depth*.3);
        ctx.fillStyle=grad;ctx.beginPath();ctx.moveTo(-500,y);ctx.lineTo(500,y);ctx.lineTo(500,prev);ctx.lineTo(edges[1],prev);ctx.bezierCurveTo(edges[1]*.5,prev+curve*1.35,edges[0]*.5,prev+curve*1.35,edges[0],prev);ctx.lineTo(-500,prev);ctx.closePath();ctx.fill();
        // Quiet vertical depth within each color, separate from the specular surface.
        const depthShade=ctx.createLinearGradient(0,y,0,prev+curve);depthShade.addColorStop(0,rgba(shade(base,.12),.06));depthShade.addColorStop(.45,rgba(base,0));depthShade.addColorStop(1,rgba(shade(base,-.25),.10));ctx.fillStyle=depthShade;ctx.fillRect(-500,y,1000,depth+curve);
        // Each color has a convex front edge and a narrow bright meniscus.
        if(k>0){
          ctx.strokeStyle=rgba(base,.48);ctx.lineWidth=.8;
          ctx.beginPath();ctx.moveTo(edges[0],prev);ctx.bezierCurveTo(edges[0]*.5,prev+curve*1.35,edges[1]*.5,prev+curve*1.35,edges[1],prev);ctx.stroke();
        }
        if(k===bands.length-1){
          // A thin remainder keeps its pigment: shrink the specular cap, not its opacity.
          const cap=Math.min(7,depth*.3,band.amount*liquidUnit*.4),light=Math.min(1,depth/16,band.amount/.5);
          const wave=this.scene.reduced?0:(Math.sin(t*11+this.index*.8)+.25*Math.sin(t*17))*Math.min(this.wave,2.4,cap*.25),cx=(topEdges[0]+topEdges[1])/2,rx=(topEdges[1]-topEdges[0])/2;
          const top=ctx.createLinearGradient(0,y-cap,0,y+cap);top.addColorStop(0,shade(base,-.08));top.addColorStop(.40,shade(base,.06));top.addColorStop(.8,shade(base,.15));top.addColorStop(1,shade(base,.22));ctx.fillStyle=top;
          ctx.beginPath();ctx.moveTo(cx-rx,y);ctx.bezierCurveTo(cx-rx*.65,y-cap+wave,cx+rx*.65,y-cap-wave,cx+rx,y);ctx.bezierCurveTo(cx+rx*.65,y+cap-wave,cx-rx*.65,y+cap+wave,cx-rx,y);ctx.fill();
          ctx.strokeStyle=rgba(shade(base,-.12),.40*light);ctx.lineWidth=.8;ctx.beginPath();ctx.moveTo(cx-rx*.94,y);ctx.bezierCurveTo(cx-rx*.55,y-cap*.8+wave,cx+rx*.55,y-cap*.8-wave,cx+rx*.94,y);ctx.stroke();
          ctx.strokeStyle=rgba('#ffffff',.55*light);ctx.lineWidth=.95*light;ctx.beginPath();ctx.moveTo(cx-rx*.94,y);ctx.bezierCurveTo(cx-rx*.72,y+cap*.64,cx-rx*.35,y+cap*.83,cx+rx*.12,y+cap*.73);ctx.stroke();
          // Tiny curved menisci meet the walls; scale down with the last film.
          ctx.strokeStyle=rgba(shade(base,.28),.7*light);ctx.lineWidth=.75*light;
          for(const side of [-1,1]){const wall=cx+side*rx;ctx.beginPath();ctx.moveTo(wall-side*.7,y-Math.min(1.7,cap*.3));ctx.quadraticCurveTo(wall-side*1.3,y+cap*.3,wall-side*3,y+cap*.4);ctx.stroke();}
          if(this.wave>.3&&!this.scene.reduced){ctx.strokeStyle=rgba('#ffffff',Math.min(.35,this.wave*.12)*light);ctx.lineWidth=.7*light;ctx.beginPath();ctx.ellipse(cx,y,rx*(.35+.25*(1+Math.sin(t*10))),Math.min(2,cap*.4),0,0,Math.PI*2);ctx.stroke();}
        }
        if(band.color==='mystery'){const mid=(y+prev)/2,range=span(poly,mid);questions.push({x:(range[0]+range[1])/2,y:mid+3,size:Math.min(25,Math.max(13,(prev-y)*.75))});}
        prev=y;
      }
      for(const q of questions)text(ctx,'?',q.x,q.y,q.size,'#fff3ea',900);
      ctx.restore();
      ctx.save();ctx.rotate(tilt);
      if(bands.length){
        ctx.save();path(ctx,w-3,h-2);ctx.clip();
        const tint=COLOR[bands[bands.length-1].color],bounce=ctx.createLinearGradient(0,8,0,38);
        bounce.addColorStop(0,rgba(tint,.05));bounce.addColorStop(.6,rgba(tint,.10));bounce.addColorStop(1,rgba(tint,0));
        ctx.fillStyle=bounce;ctx.fillRect(-w/2,7,w,31);ctx.restore();
      }
      if(this.reveal>0){ctx.save();path(ctx,w-4,h-3);ctx.clip();const bottom=h-4-this.revealLayer*this.liquidUnit,top=bottom-this.liquidUnit;ctx.globalAlpha=this.reveal;const veil=ctx.createLinearGradient(-w/2,0,w/2,0);veil.addColorStop(0,'#58456e');veil.addColorStop(.4,'#9483a7');veil.addColorStop(1,'#58456e');ctx.fillStyle=veil;ctx.fillRect(-w/2,top,w,this.liquidUnit+4);text(ctx,'?',0,(top+bottom)/2,25,'#fff3ea',900);ctx.globalAlpha=Math.sin(this.reveal*Math.PI)*.8;ctx.strokeStyle='#fff9f4';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(0,top+3,w*.44,4,0,0,Math.PI*2);ctx.stroke();ctx.restore();}
      path(ctx,w+1,h);ctx.strokeStyle='rgba(64,110,106,.64)';ctx.lineWidth=1.45;ctx.stroke();
      path(ctx,w-2,h-1);ctx.strokeStyle='rgba(255,250,244,.92)';ctx.lineWidth=.85;ctx.stroke();
      // Two readable lip contours replace the overlapping raster rings.
      const lip=ctx.createLinearGradient(0,-4,0,8);
      lip.addColorStop(0,'rgba(255,253,245,.94)');lip.addColorStop(.35,'rgba(210,227,217,.45)');lip.addColorStop(.6,'rgba(251,251,239,.85)');lip.addColorStop(.85,'rgba(174,200,186,.52)');lip.addColorStop(1,'rgba(248,247,236,.80)');
      ctx.fillStyle=lip;ctx.beginPath();ctx.moveTo(-w*.33,2);ctx.lineTo(-w*.33,6);ctx.bezierCurveTo(-w*.25,11,w*.25,11,w*.33,6);ctx.lineTo(w*.33,2);ctx.closePath();ctx.fill();
      ctx.strokeStyle='rgba(81,128,114,.5)';ctx.lineWidth=.85;ctx.beginPath();ctx.moveTo(-w*.33,4);ctx.lineTo(-w*.33,6.5);ctx.bezierCurveTo(-w*.25,11,w*.25,11,w*.33,6.5);ctx.lineTo(w*.33,4);ctx.stroke();
      ctx.fillStyle=lip;ctx.beginPath();ctx.ellipse(0,2,w*.33,5,0,0,Math.PI*2);ctx.fill();
      ctx.strokeStyle='rgba(77,114,103,.62)';ctx.lineWidth=.85;ctx.stroke();
      const mouth=ctx.createLinearGradient(0,-3,0,3);
      mouth.addColorStop(0,'rgba(64,106,97,.52)');mouth.addColorStop(1,'rgba(242,247,229,.24)');
      ctx.fillStyle=mouth;ctx.beginPath();ctx.ellipse(0,.1,w*.245,2.5,0,0,Math.PI*2);ctx.fill();
      ctx.strokeStyle='rgba(73,120,106,.67)';ctx.lineWidth=.7;ctx.stroke();
      ctx.strokeStyle='rgba(255,255,255,.96)';ctx.lineWidth=1.2;ctx.beginPath();ctx.ellipse(0,1.5,w*.31,4.3,0,Math.PI,Math.PI*1.89);ctx.stroke();
      drawGlass(ctx,w,h,true);
      if(this.accepts){
        ctx.save();ctx.shadowColor='rgba(71,178,155,.55)';ctx.shadowBlur=9;ctx.strokeStyle='#309f8a';ctx.lineWidth=5;ctx.beginPath();ctx.ellipse(0,-1,w*.39,7,0,0,Math.PI*2);ctx.strokeStyle='#fffdf2';ctx.stroke();ctx.lineWidth=2.4;ctx.strokeStyle='#238c78';ctx.stroke();ctx.shadowBlur=0;
        ctx.beginPath();ctx.moveTo(-6,-20);ctx.lineTo(0,-14);ctx.lineTo(6,-20);ctx.stroke();ctx.restore();
      }
      if(this.pending){ctx.save();ctx.fillStyle='#ffffffec';round(ctx,-23,-30,46,18,8);ctx.fill();text(ctx,'Next',0,-21,10,'#aa5685',650);ctx.restore();}
      if(celebration>0){
        ctx.save();path(ctx,w-3,h-2);ctx.clip();
        const sweepY=h+35-phase*(h+90)*1.7,shine=ctx.createLinearGradient(0,sweepY-35,0,sweepY+35);
        shine.addColorStop(0,'rgba(255,255,255,0)');shine.addColorStop(.5,'rgba(255,255,255,.62)');shine.addColorStop(1,'rgba(255,255,255,0)');ctx.fillStyle=shine;ctx.fillRect(-w/2,sweepY-35,w,70);ctx.restore();
      }
      if(this.index===this.scene.session.state.collector&&this.scene.fullBloom>0&&!this.scene.reduced){
        const p=1-this.scene.fullBloom,envelope=Math.sin(p*Math.PI);
        ctx.save();path(ctx,w-3,h-2);ctx.clip();
        // Last drop wakes the surface; a caustic travels down to the fixed socket.
        const y=29+Math.max(0,Math.min(1,(p-.1)/.55))*(h+55),light=ctx.createLinearGradient(0,y-55,0,y+55);
        light.addColorStop(0,'rgba(248,238,255,0)');light.addColorStop(.5,'rgba(255,250,255,.72)');light.addColorStop(1,'rgba(231,232,255,0)');
        ctx.fillStyle=light;ctx.fillRect(-w/2,y-55,w,110);
        for(let ribbon=0;ribbon<2;ribbon++){
          ctx.beginPath();for(let j=0;j<=35;j++){const v=j/35,yy=29+v*(h-33),xx=Math.sin(v*Math.PI*5-p*9+ribbon*Math.PI)*(w*.29);j?ctx.lineTo(xx,yy):ctx.moveTo(xx,yy);}
          ctx.strokeStyle=rgba('#fff8ff',envelope*.42);ctx.lineWidth=2.5-ribbon;ctx.stroke();
        }
        for(let i=0;i<12;i++){const travel=(p*1.25+i/12)%1,xx=Math.sin(i*2.7+p*3)*w*.31,yy=h-10-travel*(h-48);ctx.globalAlpha=envelope*(.35+.65*Math.sin(travel*Math.PI));star(ctx,xx,yy,1.2+i%3*.5,'#fffaff',p);}
        ctx.restore();ctx.strokeStyle=rgba('#d897dc',envelope*.8);ctx.lineWidth=2.4;path(ctx,w+2,h+1);ctx.stroke();
      }
      if(this.done){ctx.fillStyle='#78baa6';ctx.beginPath();ctx.arc(w/2-1,h-4,10,0,Math.PI*2);ctx.fill();ctx.strokeStyle='#fff';ctx.lineWidth=1.7;ctx.beginPath();ctx.moveTo(w/2-5,h-4);ctx.lineTo(w/2-2,h-1);ctx.lineTo(w/2+3,h-7);ctx.stroke();}
      ctx.restore();
      if(this.cover||this.unveil>0)paintCover(ctx,this,this.cover||this.lastCover);
    }
  });
  function background(ctx,scene){
    for(const b of scene.bottles){
      const position=b.screen(),distance=Math.hypot(position.x-b.home.x,position.y-b.home.y),contact=Math.max(0,1-distance/45),x=b.home.x,y=b.home.y+b.h+3;
      if(contact<=0)continue;
      ctx.save();ctx.globalAlpha=contact;ctx.translate(x,y);ctx.scale(1,.18);
      const shadow=ctx.createRadialGradient(2,0,2,4,1,34);shadow.addColorStop(0,'rgba(68,91,77,.24)');shadow.addColorStop(.45,'rgba(83,107,86,.10)');shadow.addColorStop(1,'rgba(83,107,86,0)');
      ctx.fillStyle=shadow;ctx.beginPath();ctx.ellipse(3,1,35,35,0,0,Math.PI*2);ctx.fill();ctx.restore();
      const base=b.units[0];
      if(base&&base.color!=='mystery'){
        ctx.save();ctx.globalAlpha=contact;ctx.translate(x+4,y+1);ctx.scale(1,.16);
        const bounce=ctx.createRadialGradient(0,0,1,0,0,28);bounce.addColorStop(0,rgba(COLOR[base.color],.11));bounce.addColorStop(1,rgba(COLOR[base.color],0));ctx.fillStyle=bounce;ctx.beginPath();ctx.arc(0,0,28,0,Math.PI*2);ctx.fill();ctx.restore();
      }
    }
    if(scene.selected>=0){const selected=scene.bottles[scene.selected],x=selected.home.x,y=selected.home.y+selected.h+10;ctx.fillStyle='#f7c2dcaa';ctx.beginPath();ctx.ellipse(x,y,selected.w*.56,7,0,0,Math.PI*2);ctx.fill();ctx.strokeStyle='#bd4a81';ctx.lineWidth=1.8;ctx.stroke();}
    // A fixed socket visually separates the receiver from moveable bottles.
    const b=scene.bottles[scene.session.state.collector];if(!b)return;const p=b.home,y=p.y+b.h-16;
    const pulse=scene.reduced?0:(scene.collectorPulse||0),amount=b.units.reduce((n,u)=>n+u.amount,0),bloom=scene.reduced?0:(scene.fullBloom||0),moon=scene.moonFill||0;
    if(bloom>0){const light=ctx.createLinearGradient(0,p.y+22,0,y+20);light.addColorStop(0,rgba('#f8dfff',0));light.addColorStop(.8,rgba('#edcbfa',bloom*.28));light.addColorStop(1,rgba('#e6bcf5',bloom*.4));ctx.fillStyle=light;ctx.beginPath();ctx.moveTo(p.x-62,p.y+20);ctx.lineTo(p.x+62,p.y+20);ctx.lineTo(p.x+35,y+25);ctx.lineTo(p.x-35,y+25);ctx.closePath();ctx.fill();}
    if(pulse>0){const halo=ctx.createRadialGradient(p.x,y+12,8,p.x,y+12,80);halo.addColorStop(0,rgba('#ffb1d5',pulse*.4));halo.addColorStop(1,rgba('#ffb1d5',0));ctx.fillStyle=halo;ctx.fillRect(p.x-90,y-80,180,180);}
    const cx=p.x,cy=y+20;
    if(bloom>0){const u=Math.max(0,Math.min(1,(1-bloom-.43)/.57));ctx.save();ctx.globalAlpha=Math.sin(u*Math.PI)*.85;ctx.strokeStyle='#fff8eb';ctx.lineWidth=4;ctx.beginPath();ctx.ellipse(cx,cy,43+u*30,15+u*12,0,0,Math.PI*2);ctx.stroke();ctx.strokeStyle='#cf719d';ctx.lineWidth=1.5;ctx.stroke();ctx.restore();}

    if(art['collector-socket'])ctx.drawImage(art['collector-socket'],cx-55,y-1,110,44);
    if(pulse>0){ctx.strokeStyle=rgba('#eaa5c5',pulse*.5);ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(cx,cy,44+(1-pulse)*24,17+(1-pulse)*10,0,0,Math.PI*2);ctx.stroke();}
    ctx.save();round(ctx,cx-45,y+43,90,27,13);ctx.fillStyle='#fff9ed';ctx.shadowColor='#688d7929';ctx.shadowBlur=3;ctx.shadowOffsetY=1;ctx.fill();ctx.shadowColor='transparent';ctx.strokeStyle='#fff9e8';ctx.lineWidth=1;ctx.stroke();text(ctx,Math.floor(amount+.001)+' / '+b.capacity,cx,y+57,22,'#365f54',800);ctx.restore();
  }
  function effects(ctx,scene){
    const flow=scene.flow;
    if(flow&&flow.active){
      const src=scene.bottles[flow.from].outlet(),dst=scene.bottles[flow.to].mouth(),color=COLOR[flow.color];
      const ramp=Math.max(.08,Math.min(1,flow.progress*12,(1-flow.progress)*14)),sway=scene.reduced?0:Math.sin(scene.time*24)*1.4;
      ctx.save();ctx.lineCap='round';ctx.strokeStyle=shade(color,-.08);ctx.lineWidth=(4.4+sway*.25)*ramp;
      ctx.beginPath();ctx.moveTo(src.x,src.y);ctx.lineTo(src.x,dst.y+8);ctx.stroke();ctx.strokeStyle=shade(color,.16);ctx.lineWidth=1.1*ramp;ctx.stroke();
      const target=scene.bottles[flow.to],units=target.units.reduce((a,u)=>a+u.amount,0),surfaceY=target.screen().y+target.h-4-units*target.liquidUnit;
      const stream=ctx.createLinearGradient(0,dst.y+6,0,surfaceY);stream.addColorStop(0,shade(color,-.04));stream.addColorStop(1,shade(color,-.10));ctx.strokeStyle=stream;ctx.lineWidth=2.8*ramp;ctx.beginPath();ctx.moveTo(dst.x,dst.y+6);ctx.lineTo(dst.x,surfaceY);ctx.stroke();ctx.strokeStyle=shade(color,.16);ctx.lineWidth=.7*ramp;ctx.stroke();
      for(let i=0;i<2;i++){const phase=(scene.time*3+i*.5)%1;ctx.strokeStyle=rgba('#ffffff',(1-phase)*.65*ramp);ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(dst.x,surfaceY,3+phase*18,1+phase*3,0,0,Math.PI*2);ctx.stroke();}
      ctx.restore();
    }
    for(const drop of scene.drips){
      if(drop.age<0)continue;const u=Math.min(1,drop.age/drop.duration),v=1-u;
      const x=v*v*drop.from.x+2*v*u*drop.mouth.x+u*u*drop.impact.x,y=v*v*drop.from.y+2*v*u*drop.mouth.y+u*u*drop.impact.y;
      ctx.save();ctx.globalAlpha=1;droplet(ctx,x,y,drop.size*(1-u*.25),drop.color);ctx.restore();
    }
    // Completion feedback is drawn independently of input and bottle movement actions.
    for(const bottle of scene.bottles){
      if(!bottle.completion||scene.reduced||!bottle.done)continue;
      const p=1-bottle.completion,color=COLOR[bottle.units[0].color],x=bottle.home.x,bottom=bottle.home.y+bottle.h;
      ctx.save();ctx.globalAlpha=(1-p)*.8;ctx.strokeStyle=color;ctx.lineWidth=2.2;
      ctx.beginPath();ctx.ellipse(x,bottom+5,29+p*37,8+p*13,0,0,Math.PI*2);ctx.stroke();
      if(p>.13){ctx.globalAlpha=(1-p)*.45;ctx.beginPath();ctx.ellipse(x,bottom+5,24+(p-.13)*32,6+(p-.13)*12,0,0,Math.PI*2);ctx.stroke();}ctx.restore();
      const fade=Math.min(1,p*9)*Math.min(1,(1-p)*3),size=16+Math.sin(Math.min(1,p*3)*Math.PI)*3,cy=bottle.home.y+68-p*16;
      ctx.save();ctx.globalAlpha=fade;ctx.shadowBlur=12;ctx.shadowColor=rgba(color,.6);ctx.fillStyle='#fffdf8';ctx.beginPath();ctx.arc(x,cy,size,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;ctx.strokeStyle=shade(color,-.23);ctx.lineWidth=3;ctx.lineCap='round';ctx.lineJoin='round';ctx.beginPath();ctx.moveTo(x-7,cy);ctx.lineTo(x-2,cy+5);ctx.lineTo(x+8,cy-6);ctx.stroke();ctx.restore();
    }
    const receiver=scene.bottles[scene.session.state.collector];
    if(receiver&&(scene.fullBloom>0||scene.moonFill>.95)){
      const bloom=scene.reduced?0:scene.fullBloom,p=1-bloom,x=receiver.home.x;
      const rise=1-Math.pow(1-Math.min(1,p/.65),3),y=receiver.home.y+62+(bloom>0?(1-rise)*(receiver.h-105):0);
      const radius=14+(bloom>0?Math.sin(p*Math.PI)*8:0);
      ctx.save();ctx.globalAlpha=bloom>0?Math.min(1,p*12):1;
      ctx.shadowColor='#dfa7e5';ctx.shadowBlur=10+(bloom>0?Math.sin(p*Math.PI)*12:0);
      crescent(ctx,x,y,radius,'#fff8ff');ctx.shadowBlur=0;
      star(ctx,x+radius*.55,y-radius*.7,3,'#fff8ff',.15);ctx.restore();
      if(bloom>0){
        // A few water rings open at the mouth, while droplets turn into glints.
        for(let i=0;i<3;i++){const u=(p-i*.14)/.58;if(u<0||u>1)continue;ctx.save();ctx.globalAlpha=Math.sin(u*Math.PI)*(1-u)*.8;ctx.strokeStyle='#c391ce';ctx.lineWidth=1.6;ctx.beginPath();ctx.ellipse(x,receiver.home.y+28-u*16,16+u*35,4+u*9,0,0,Math.PI*2);ctx.stroke();ctx.restore();}
        for(let i=0;i<9;i++){const u=(p-i*.035)/.66;if(u<0||u>1)continue;const xx=x+Math.sin(i*2.3)*(10+u*39),yy=receiver.home.y+30-u*(38+i%3*12);ctx.save();ctx.globalAlpha=Math.sin(u*Math.PI)*.9;star(ctx,xx,yy,1.8+i%3,'#b67bbf',u*.4);ctx.restore();}
      }
    }
    if(scene.hintPair){const a=scene.bottles[scene.hintPair[0]].screen(),b=scene.bottles[scene.hintPair[1]].screen();const x1=a.x,y1=a.y-21,x2=b.x,y2=b.y-20,cx=(x1+x2)/2,cy=Math.min(y1,y2)-32;ctx.save();ctx.lineCap='round';ctx.lineJoin='round';ctx.beginPath();ctx.moveTo(x1,y1);ctx.quadraticCurveTo(cx,cy,x2,y2);ctx.strokeStyle='#fff9ed';ctx.lineWidth=7;ctx.stroke();ctx.strokeStyle='#258d7b';ctx.lineWidth=3;ctx.stroke();const angle=Math.atan2(y2-cy,x2-cx);ctx.translate(x2,y2);ctx.rotate(angle);ctx.beginPath();ctx.moveTo(-10,-6);ctx.lineTo(0,0);ctx.lineTo(-10,6);ctx.strokeStyle='#fff9ed';ctx.lineWidth=7;ctx.stroke();ctx.strokeStyle='#258d7b';ctx.lineWidth=3;ctx.stroke();ctx.restore();}
    for(const p of scene.particles){const a=p.life/p.max;ctx.save();ctx.globalAlpha=a;if(p.kind==='star')star(ctx,p.x,p.y,p.size,p.color===COLOR.pink?'#e2b5e4':'#f2c364',p.angle);else{ctx.fillStyle=p.color;ctx.beginPath();ctx.ellipse(p.x,p.y,p.size,p.size*.7,p.angle,0,Math.PI*2);ctx.fill();}ctx.restore();}
    if(scene.floating){for(const f of scene.floating){ctx.save();ctx.globalAlpha=Math.max(0,f.life/f.max);text(ctx,f.text,f.x,f.y,14,'#d95b9c',750);ctx.restore();}}
  }
  global.PourRender={pourAngle,pourPose,COLOR,NAME,PaintNode,Bottle,background,effects,loadAssets};
})(window);
