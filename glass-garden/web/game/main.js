(function(){
  function fit(){
    const style=getComputedStyle(document.body),top=parseFloat(style.paddingTop)||0,bottom=parseFloat(style.paddingBottom)||0,left=parseFloat(style.paddingLeft)||0,right=parseFloat(style.paddingRight)||0;
    // HUD and dialogs use physical CSS pixels; only the puzzle scales.
    const header=104,footer=88,bounds=window.PourBoardBounds||{top:65,bottom:866},boardTop=bounds.top,boardBottom=bounds.bottom;
    const framed=Number.isFinite(bounds.left)&&Number.isFinite(bounds.right),boardLeft=framed?bounds.left:0,boardRight=framed?bounds.right:480,gutter=framed?8:0;
    const availableWidth=innerWidth-left-right,availableHeight=Math.max(200,innerHeight-top-bottom-header-footer),s=Math.min((availableWidth-gutter*2)/(boardRight-boardLeft),availableHeight/(boardBottom-boardTop),1.08),stage=document.getElementById('stage-wrap');
    document.documentElement.style.setProperty('--game-scale',s);
    const y=top+header+(availableHeight-(boardBottom-boardTop)*s)*(framed?.16:.25)-boardTop*s;
    stage.style.left=(left+availableWidth/2+(240-(boardLeft+boardRight)/2)*s)+'px';
    stage.style.top=y+'px';stage.style.transform='translateX(-50%) scale('+s+')';
    const blocked=innerWidth>innerHeight&&innerHeight<520;
    window.PourViewportBlocked=blocked;document.getElementById('orientation').hidden=!blocked;
    for(const id of ['stage-wrap','screen-header','screen-footer','modal'])document.getElementById(id).inert=blocked||(id!=='modal'&&!document.getElementById('modal').hidden);
    window.dispatchEvent(new Event('pour-viewport-change'));
  }
  fit();window.addEventListener('pour-layout-change',fit);window.addEventListener('resize',fit);if(window.visualViewport)window.visualViewport.addEventListener('resize',fit);
  cc.game.onStart=function(){
    cc.view.enableRetina(true);cc.view.adjustViewPort(false);cc.view.setDesignResolutionSize(480,1040,cc.ResolutionPolicy.SHOW_ALL);cc.view.resizeWithBrowserSize(false);
    cc.director.setClearColor(cc.color(255,255,255,0));
    window.PourBoot.stage('Preparing your colors…');
    const background=new Promise((resolve,reject)=>{const image=new Image();image.onload=resolve;image.onerror=reject;image.src='assets/art/garden-daylight.webp';});
    Promise.all([PourRender.loadAssets(),document.fonts.load('900 33px Nunito'),background]).then(()=>{
      const firstFrame=cc.eventManager.addCustomListener(cc.Director.EVENT_AFTER_DRAW,function(){
        cc.eventManager.removeListener(firstFrame);
        window.PourBoot.ready();
      });
      cc.director.runScene(new PourluneScene());
    }).catch(()=>window.PourBoot.fail());
  };
  cc.game.run();
})();
