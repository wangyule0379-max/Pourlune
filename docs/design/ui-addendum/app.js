// A reviewable state prototype. Business services and persistence are deliberately simulated.
const $=s=>document.querySelector(s), A='assets/';
const states={};
// Only display context is retained. No puzzle engine, storage or SDK is simulated here.
const emptyPuzzle={mode:'main',level:12,day:null,layout:'regular',guided:false,added:false,pending:false,unsaved:false,cooldown:false,message:''};
let puzzle={...emptyPuzzle}, navigatingTo=null;
const puzzleEntries={
  board:{}, tutorial:{level:1,layout:'tutorial',guided:true}, seven:{added:true},
  'daily-old-board':{mode:'daily',day:'Oct 20'}, 'daily-today':{mode:'daily',day:'Oct 21'},
  'daily-replay':{mode:'daily-replay',day:'Oct 21'}, 'replay-board':{mode:'replay',level:3},
  ...Object.fromEntries([13,14,17,21,41].map(level=>['next'+level,{level}]))
};
const fixtureFlags={
  'pause-failed':{unsaved:true},'pause-stay':{unsaved:true},
  'reward-pending':{pending:true},'reward-stay':{pending:true},'reward-cooldown':{cooldown:true},
  'tutorial-free':{level:1,layout:'tutorial',guided:false},'reward-applied':{added:true},
  'restart-confirmed':{message:'Puzzle restarted · this instance is kept.'}
};
function resetFixture(id){puzzle={...emptyPuzzle,...puzzleEntries[id],...fixtureFlags[id]};}
function puzzleTitle(){return puzzle.mode==='daily'?'Daily · '+puzzle.day:puzzle.mode==='daily-replay'?'Replay · '+puzzle.day:(puzzle.mode==='replay'?'Replay · ':'')+'Level '+puzzle.level;}
function navigate(id){
  if(!states[id])return;
  if(Object.hasOwn(puzzleEntries,id))resetFixture(id);
  if(id==='pause-stay')puzzle.unsaved=true;
  if(id==='pause-saved')puzzle.unsaved=false; // Explicit save-success fixture only.
  if(id==='reward-pending')puzzle.pending=true;
  if(id==='reward-applied'){puzzle.pending=false;puzzle.added=true;}
  if(id==='tutorial-free')puzzle.guided=false;
  if(id==='restart-confirmed')puzzle.message='Puzzle restarted · this instance is kept.';
  if(id==='hint-undo')puzzle.message='Undo selected · free assistance remains available';
  if(id==='puzzle-board')puzzle.message='';
  navigatingTo=id;
  if(current()===id)render();else location.hash=id;
}
function add(id,group,name,render,note=''){states[id]={group,name,render,note};}
const img=(name,cls='',alt='')=>`<img class="art ${cls}" src="${A+name}.png" alt="${alt}">`;
const btn=(text,to,primary=false,disabled=false)=>`<button ${disabled?'disabled':''} class="${primary?'primary':''}" ${to?`data-go="${to}"`:''}>${text}</button>`;
const header=(title,back='home-replay')=>`<header>${back?`<button class="back" data-go="${back}" aria-label="Back">${img('back')}</button>`:'<span style="width:48px"></span>'}<h2>${title}</h2><span style="width:36px"></span></header>`;
const panel=(title,body,actions)=>`<section class="panel"><h2>${title}</h2>${body?`<p>${body}</p>`:''}<div class="actions">${actions||''}</div></section>`;
const modal=(title,body,actions)=>`<div class="modal-background" inert aria-hidden="true">${boardMarkup()}</div><div class="overlay" role="dialog" aria-modal="true" aria-label="${title}">${panel(title,body,actions)}</div>`;
const tags=['●','▲','◆','■'];
function boardMarkup({hint=false,status=''}={}){
const tutorial=puzzle.layout==='tutorial', seven=puzzle.added&&!tutorial;
const types=tutorial?[0,3,4,4]:(seven?[0,1,2,3,4,4,4]:[0,1,2,3,4,4]);
const target=tutorial?2:4;
let notices=[];
if(puzzle.day)notices.push(`<div class="status">${puzzle.day==='Oct 20'?'Tue':'Wed'}, ${puzzle.day}, 2026 · original puzzle date</div>`);
if(puzzle.unsaved)notices.push(`<div class="status"><div class="row"><span>Progress not saved</span>${btn(puzzle.pending?'Retry save':'Retry','pause-saved')}</div></div>`);
if(puzzle.pending)notices.push(`<div class="status"><div class="row"><span>Reward pending — retry</span>${btn(puzzle.unsaved?'Retry reward':'Retry','reward-applied')}</div></div>`);
if(puzzle.added)notices.push('<div class="status">Extra bottle added<small class="added-note">Your extra bottle will stay if you restart</small></div>');
if(status)notices.push(`<div class="status">${status}</div>`);
else if(puzzle.message)notices.push(`<div class="status">${puzzle.message}</div>`);
const showExtra=puzzle.mode.startsWith('daily')||puzzle.level>3;
const extraLabel=puzzle.pending?'Reward pending':puzzle.added?'Bottle added':puzzle.cooldown?'Available in 01:42':'Extra bottle';
return header(puzzleTitle(),'pause')+`<p class="center">${puzzle.guided?'Tap a bottle. Then tap an empty bottle.':'Match the color tags'}</p>`+notices.join('')+`<div class="board ${tutorial?'tutorial':seven?'seven':'six'}">${types.map((type,i)=>`<button class="bottle ${hint&&i===0?'selected':hint&&i===target?'suggested':''}" data-bottle="${i}" aria-label="Bottle ${i+1}, ${type===4?'empty buffer':`target ${['orange circle','green triangle','purple diamond','blue square'][type]}`}" ${hint&&i===target?'data-go="hint-executed"':''}>${img(tutorial&&i<2?'tutorial-'+i:'bottle-'+type,'',type===4?'Empty glass, no liquid or symbols':'Four-unit marked bottle')}<span class="tag" style="color:${['#b74e12','#16722b','#5e268c','#054b93'][type]||'#3e535a'}">${type===4?'—':tags[type]}</span></button>`).join('')}</div>`+`<div class="helper">${btn('Undo','hint-undo')}${btn('Hint','hint-search')}${showExtra?btn(extraLabel,puzzle.pending||puzzle.added||puzzle.cooldown?'':'reward-offer',false,puzzle.pending||puzzle.added||puzzle.cooldown):''}</div>`+(puzzle.guided?btn('Skip','tutorial-free'):'');
}
function pauseMarkup(){return modal('Take your time.',puzzle.unsaved?'Your latest moves are still here, but aren’t saved yet.':'Your puzzle is saved.'+(puzzle.pending?' Your reward is still pending.':''),btn('Resume','puzzle-board',true)+(puzzle.unsaved?btn('Retry save','pause-saved'):'')+btn('Restart','restart')+btn('Home','home-replay',false,puzzle.unsaved));}

const scene=(n,compact=true)=>`<div class="scene ${compact?'compact':''}" data-progress="${n}">${img('room','','Color Studio, original artwork')}${[1,2,3,4,5].filter(i=>i>n).map(i=>`<div class="veil r${i}">${['Window','Desk & paint','Stool','Plant','Table'][i-1]} · Locked</div>`).join('')}</div>`;
const progress=n=>`<div class="progress" aria-label="${n} of 5 patches">${[1,2,3,4,5].map(i=>`<span class="${i<=n?'earned':''}">${i<=n?'✓':i}</span>`).join('')}</div>`;
function collectionPage(kind,n=3){
const back=kind==='home'?null:kind==='collection'?'home-'+n:'collection-'+n;
return header(kind==='home'?'Pourlune':kind==='collection'?'Collection':'Color Studio',back)+scene(n)+`<div class="panel"><h3>Color Studio</h3>${progress(n)}<p>${n} / 5 patches</p><small>${n===5?'Scene complete':(20-n*4)+' levels to complete this scene'}</small></div>`+btn(kind==='home'?'Continue · Level '+(n*4+1):kind==='collection'?'View Color Studio':'Play Level '+(n*4+1),kind==='collection'?'scene-'+n:n===5?'next21':n===4?'next17':'next13',true)+btn(kind==='home'?'Collection':kind==='scene'?'Back to collection':'Back to home',kind==='home'?'collection-'+n:kind==='scene'?'collection-'+n:'home-'+n);
}
add('board','D06','P05 · four-unit readability',()=>boardMarkup(), 'Corrected trim matches target; neutral buffers; four ticks. Board is static, not a solver.');
add('tutorial','D06','P04 · two-unit segments',()=>boardMarkup(), 'Each color occupies two units; blue trim and square tag agree. Skip removes guidance.');
add('seven','D08','P18 · seven equal bottles',()=>boardMarkup(),'4+3, centered last row; all seven use one image box and scale.');
add('pause-saving','D01','P06 · saving',()=>modal('Saving your puzzle…','Keep this screen open while your progress is saved.',btn('Saving…','',true,true)+btn('Home','',false,true)),'Saving state is static; choose saved/failure in the reviewer selector.');
add('pause-failed','D01','P06 · save failed',()=>modal('Couldn’t save your progress.','Retry before leaving. Your latest moves are still here, but aren’t saved yet.',btn('Retry','pause-saved',true)+btn('Stay here','pause-stay')));
add('pause-stay','D01','P06 · stay in memory',()=>boardMarkup());
add('pause-saved','D01','P06 · saved / original retained',()=>pauseMarkup());
add('settlement-saving','D01','P10 · saving completion',()=>modal('Puzzle complete','Saving your progress and rewards…',btn('Next level','',true,true)+btn('Home','',false,true)));
add('settlement-failed','D01','P10 · completion save failed',()=>modal('Puzzle complete','Couldn’t save your progress. Retry before leaving. Your reward hasn’t been added yet.',btn('Retry','patch-complete',true)+btn('Stay here','settlement-stay')));
add('settlement-stay','D01','P10 · failed, remain locked',()=>modal('Progress not saved','Your completed board is locked. Retry to save your completion and reward.',btn('Retry','patch-complete',true)+btn('Next level','',false,true)+btn('Home','',false,true)));
add('restart','D02','P09 · original restart retained',()=>modal('Start this level again?','Your board will reset.'+(puzzle.added?' Your extra bottle stays.':''),btn('Keep playing','puzzle-board',true)+btn('Restart','restart-confirmed')));
add('hint-search','D02','P07 · searching / cancellable',()=>modal('Finding a hint…','You can cancel and keep playing.',btn('Cancel hint','puzzle-board',true)),'Search result is a review fixture. No solver or 2-second budget is implemented.');
add('hint-timeout','D02','P07 · timeout',()=>modal('No hint found yet.','You can keep playing.',btn('Keep playing','puzzle-board',true)+btn('Try again','hint-search')+btn('Undo','hint-undo')+btn('Restart','restart')));
add('hint-unsolvable','D02','P07 · confirmed no solution',()=>modal('No solution from here','Try undoing a move or restarting.',btn('Undo','hint-undo',true)+btn('Restart','restart')+btn('Back to puzzle','puzzle-board')));
add('hint-found','D02','P07 · suggested target, tap to act',()=>boardMarkup({hint:true,status:'Try this pour. Tap bottle '+(puzzle.layout==='tutorial'?3:5)+' to move the top orange layer.'})+btn('Cancel hint','puzzle-board'),'Source 1 selected; target 5 outlined. Only target click leads to execution feedback.');
add('hint-executed','D02','P07 · suggested action accepted',()=>boardMarkup({status:'Pour selected · 1 → '+(puzzle.layout==='tutorial'?3:5)})+`<p class="narrative">Transition preview only; liquid rendering remains a reference board.</p>`);
add('hint-undo','D02','P05 · free rescue',()=>boardMarkup({status:'Undo selected · free assistance remains available'})+btn('Restart','restart'));
const dailyBase=()=>header('Daily puzzle')+img('calendar','calendar','October 21 calendar')+`<h2 class="center">Today’s puzzle</h2><p class="center">Wed, Oct 21, 2026</p>`;
const dates=()=>`<div class="calendar-row">${[19,20,21,22,23,24,25].map(d=>btn(`${d}${d===19?' ✓':''}`,d<21?'daily-history':d===21?'daily-old':'',false,d>21).replace('<button ',`<button aria-label="October ${d}${d>21?', future, unavailable':''}" `)).join('')}</div><small class="center">October 2026 · Past dates are records only.</small>`;
add('daily-old','D03','P14 · old puzzle / today',()=>dailyBase()+panel('Unfinished puzzle','Tue, Oct 20, 2026',btn('Resume Oct 20','daily-old-board',true)+btn('Play Oct 21','daily-replace'))+dates()+`<small class="center">Your main game is saved.</small>`);
add('daily-old-board','D03','P05 · previous daily identity',()=>boardMarkup());
add('daily-replace','D03','P09 · replace daily confirmation',()=>dailyBase()+panel('Start today’s puzzle?','Starting today’s puzzle will replace your unfinished puzzle from Oct 20. Your main game is kept.',btn('Keep Oct 20','daily-old',true)+btn('Start Oct 21','daily-today')));
add('daily-replace-failed','D03','P09 · replacement not saved',()=>dailyBase()+panel('Couldn’t start today’s puzzle.','Your Oct 20 puzzle is kept. Retry before replacing it.',btn('Retry','daily-today',true)+btn('Keep Oct 20','daily-old')));
add('daily-today','D03','P05 · today started',()=>boardMarkup());
add('daily-old-complete','D03','P15 · old date stamped',()=>header('Daily complete')+img('check','check')+panel('A stamp for Oct 20','Your stamp is saved for Tue, Oct 20, 2026. Today’s puzzle is still available.',btn('Back to daily','daily-new',true)+btn('Home','home-replay')));
add('daily-new','D03','P14 · old completed, today available',()=>dailyBase()+panel('A fresh puzzle.','At your own pace.',btn('Play','daily-today',true))+dates());
add('daily-complete','D03','P15 · today complete / Replay',()=>dailyBase()+panel('Daily complete','Your stamp is saved.',btn('Back to daily','daily-completed-entry',true)+btn('Home','home-done')+btn('Replay','daily-replay')));
add('daily-completed-entry','D03','P14 · today stamped',()=>dailyBase()+panel('Completed','A stamp for Oct 21 is already saved.',btn('Replay','daily-replay',true))+dates());
add('daily-replay','D03','P05 · daily Replay',()=>boardMarkup());
add('daily-replay-complete','D03','P15 · replay / no second stamp',()=>dailyBase()+panel('Daily complete','Already stamped. No new stamp is awarded.',btn('Back to daily','daily-completed-entry',true)+btn('Replay','daily-replay')+btn('Home','home-done')));
add('daily-history','D03','P14 · history read only',()=>dailyBase()+panel('Oct 19 · Completed','This is a record only. Past dates can’t be started again.',btn('Back to daily','daily-old',true))+dates());
add('daily-unavailable','D03','P14 · missing daily content',()=>dailyBase()+panel('Today’s puzzle is unavailable','Your existing puzzles are kept. You can still play the main game.',btn('Resume Oct 20','daily-old-board',true)+btn('Main game','home-replay')));
add('home-replay','D04','P02 · continue Replay identity',()=>header('Pourlune')+img('logo','logo')+scene(3)+progress(3)+`<p class="center">Color Studio · 3 / 5 patches</p>`+btn('Replay · Level 3','replay-board',true)+btn('Chapters','ordinary-replace')+btn('Daily puzzle','daily-old')+btn('Collection','collection-3'));
add('ordinary-replace','D04','P03/P09 · ordinary slot replacement',()=>panel('Start Level 12?','Starting this level will replace your unfinished Replay · Level 3. Your daily puzzle is kept.',btn('Keep replay','home-replay',true)+btn('Start Level 12','board')));
add('replay-board','D04','P05 · replay',()=>boardMarkup());
add('replay-complete','D04','P10 · replay complete',()=>header('Replay · Level 3')+img('check','check')+panel('Puzzle complete','Your collection and story progress are unchanged.',btn('Replay again','replay-board',true)+btn('Choose level','ordinary-replace')+btn('Home','home-replay')));
add('normal-complete','D04','P10 · Level 11, no patch',()=>header('Level 11')+img('check','check')+panel('Beautifully sorted.','Color Studio · 11 / 20 levels',btn('Next level','board',true)+btn('Home','home-replay')),'Level 11: no interstitial eligibility.');
add('patch-complete','D04','P10 · Level 12, patch',()=>header('Level 12')+img('check','check')+panel('Beautifully sorted.','Color Studio · 12 / 20 levels. New patch unlocked.',btn('View patch','patch-reveal',true)+btn('Home','home-3')),'Persist ownership before showing reward.');
add('patch-reveal','D04','P11 · Level 12 reward',()=>header('Your collection')+`<h2 class="center">New patch unlocked</h2>`+scene(3)+progress(3)+`<p class="center">Color Studio · 3 / 5 patches</p><small class="center">8 levels to complete this scene</small>`+btn('Next level','next13',true)+btn('View collection','scene-3')+`<small class="center">Added to your collection</small>`);
add('patch16-complete','D04','P10 · Level 16, patch before ad',()=>header('Level 16')+img('check','check')+panel('Beautifully sorted.','Color Studio · 16 / 20 levels. New patch unlocked.',btn('View patch','patch16-reveal',true)+btn('Home','home-4')));
add('patch16-reveal','D04','P11 · Level 16, 4 / 5',()=>header('Your collection')+`<h2 class="center">New patch unlocked</h2>`+scene(4)+progress(4)+`<p class="center">Color Studio · 4 / 5 patches</p><small class="center">4 levels to complete this scene</small>`+btn('Next level','next17',true)+btn('View collection','scene-4')+`<small class="center">Added to your collection</small>`);
add('ad-check','D04','Review · eligible Next transition',()=>panel('Next transition','Review fixture: progress saved, reward shown. Select an SDK outcome.',btn('Ad closed','next17',true)+btn('Ad failed','next17')+btn('Unavailable / cooldown — skip','next17'))+`<p class="narrative">No advertisement is rendered. An actual successful interstitial resets cumulative first clears; a failed or skipped display keeps eligibility. Both outcomes navigate once.</p>`);
for(const level of [13,17,21,41]) add('next'+level,'D04',`P05 · entered Level ${level}`,()=>boardMarkup({status:'Next puzzle · transition completed once'}));
for(const [level,name,next] of [[20,'Color Studio',21],[40,'Garden Nook',41]])add('chapter'+level,'D04',`P11 · chapter ${level} complete`,()=>header('Your collection')+img(name==='Color Studio'?'room':'garden','room',name)+panel('Scene complete',`${name} · 5 / 5 patches. ${level===20?'Garden Nook':'Seaside Corner'} unlocked.`,btn('View collection',level===20?'scene-5':'garden-complete',true)+btn('Continue','next'+next)),'20/40 chapter protection: skip interstitial and keep cumulative eligibility. Original scene image reused.');
add('garden-complete','D04','P13 · Garden Nook complete',()=>header('Garden Nook')+img('garden','room')+panel('Scene complete','5 / 5 patches',btn('Continue','next41',true)+btn('Home','home-replay')));
add('all-complete','D04','P10 · Level 60, final',()=>header('Level 60')+img('seaside','room')+panel('All 60 levels complete','Seaside Corner · 5 / 5 patches',btn('Daily puzzle','daily-new',true)+btn('View collection','all-collection')+btn('Replay levels','ordinary-replace')),'No Next level and no interstitial.');
add('all-collection','D04','P12 · all collection complete',()=>header('Collection')+['room','garden','seaside'].map((s,i)=>`<section class="panel">${img(s,'room')}<h3>${['Color Studio','Garden Nook','Seaside Corner'][i]}</h3><p>5 / 5 patches · Complete</p></section>`).join('')+btn('Home','home-story'));
for(const [id,done,replay] of [['home-story',false,false],['home-done',true,false],['home-story-replay',true,true]])add(id,'D04',`P02 · story complete${done?', today done':''}${replay?', replay saved':''}`,()=>header('Pourlune')+img('logo','logo')+img('seaside','room')+`<h2 class="center">Story complete</h2><p class="center">${done?'Today’s puzzle complete':'A little color. A little calm.'}</p>`+btn(done?'Replay today':'Daily puzzle',done?'daily-replay':'daily-new',true)+(replay?btn('Continue replay · Level 3','replay-board'):'')+btn('Replay levels','ordinary-replace')+btn('Collection','all-collection'));
add('reward-offer','D05','P16 · two-step offer retained',()=>modal('A little more room','Watch an ad to add one empty bottle to this puzzle.<br><br>One extra bottle per puzzle.',btn('Watch ad for +1 bottle','reward-pending',true)+btn('Not now','puzzle-board')));
add('reward-outcome','D05','Review · reward SDK outcomes',()=>panel('Reward result preview','Choose a simulated SDK result.',btn('Confirmed, save failed','reward-pending',true)+btn('Closed without confirmation','reward-unconfirmed')+btn('No inventory / offline','reward-unavailable')));
add('reward-cooldown','D05','P16 · cooldown',()=>modal('A little more room','Available in 01:42<br><br>You can still undo, use hints or restart.',btn('Available in 01:42','',true,true)+btn('Not now','puzzle-board')+btn('Undo','hint-undo')+btn('Hint','hint-search')+btn('Restart','restart')),'Sample remaining time is based on actual last full-screen display; reaching zero does not auto-play an ad.');
add('reward-pending','D05','P17 · confirmed, write failed',()=>modal('Reward pending — retry','Your reward was confirmed for '+puzzleTitle()+', but couldn’t be saved. Retry to add it. No bottle has been added yet.',btn('Retry','reward-applied',true)+btn('Stay here','reward-stay')),'No second ad request allowed while this slot has a pending claim.');
add('reward-stay','D05','P05 · pending claim banner',()=>boardMarkup());
add('reward-unconfirmed','D05','P17 · close without reward',()=>modal('Ad closed. No bottle added.','Your puzzle is unchanged. You can keep playing.',btn('Back to puzzle','puzzle-board',true)+btn('Try again','reward-offer')+btn('Send feedback','feedback')));
add('reward-unavailable','D05','P17 · original unavailable',()=>modal('No ad available','You can still undo or restart.',btn('Back to puzzle','puzzle-board',true)+btn('Undo','hint-undo')+btn('Restart','restart')));
add('reward-late','D05','P17 · late reward, replaced instance',()=>panel('Reward ready for Level 12','This reward belongs to your unfinished Level 12 puzzle. Resuming it will replace Replay · Level 3 in your main slot. Your daily puzzle is kept.',btn('Keep replay','home-replay',true)+btn('Resume rewarded puzzle','reward-resume-confirm')));
add('reward-resume-confirm','D05','P09 · restore original confirmation',()=>panel('Resume rewarded puzzle?','Replace Replay · Level 3 with the saved Level 12 board and its extra bottle?',btn('Keep replay','home-replay',true)+btn('Resume Level 12','seven')));
add('reward-late-complete','D05','P17 · late reward, completed origin',()=>panel('Reward recorded','Level 12 is already complete. Its reward is recorded; no puzzle is reopened.',btn('Home','home-replay',true)));
for(const kind of ['home','collection','scene'])for(const n of [3,4,5])add(`${kind}-${n}`,'D07',`P${kind==='home'?'02':kind==='collection'?'12':'13'} · ${n} / 5 consistent`,()=>collectionPage(kind,n),'Shared progress renderer and same crop masks at identical earned count; region mapping is an addendum composition, not final layered art.');
add('scene-stages','D07','P13 · 0–5 reveal map',()=>header('Color Studio')+[0,1,2,3,4,5].map(n=>`<section class="panel"><h3>${n} / 5 patches</h3>${scene(n,false)}${progress(n)}</section>`).join(''));
add('settings','D09','P19 · responsive text study',()=>header('Settings')+`<div class="panel settings">${['Sound','Music','Haptics','Reduced motion','Color symbols','Stronger contrast'].map((s,i)=>`<label>${s}<input aria-label="${s}" type="checkbox" ${[0,1,2,4].includes(i)?'checked':''} data-setting="${s}"></label>`).join('')}</div><div class="actions">${btn('How to play','tutorial')}${btn('Privacy choices','privacy-original')}${btn('Send feedback','feedback')}${btn('Reset progress','reset-original')}</div><small class="center">Pourlune · 1.0</small>`);
add('feedback','D09','P19 · feedback composition',()=>header('Send feedback','settings')+panel('How can we help?','Describe what happened. Please don’t include personal information.',`<label class="center">Message<textarea id="feedback-text" rows="5" style="width:100%;font:inherit;margin-top:10px"></textarea></label>`+btn('Prepare feedback','feedback-ready',true)+btn('Back','settings')),'Feedback destination is not supplied. Prepare only; no message is sent and no URL or recipient is invented.');
add('feedback-ready','D09','P19 · feedback ready / destination pending',()=>header('Send feedback','settings')+panel('Feedback prepared','Sending is not available in this design prototype. A support destination is required before release.',btn('Back','feedback',true)));
add('privacy-original','D09','P20 · existing original retained',()=>header('Privacy choices','settings')+`<p class="status">Original P20 preserved. SDK form and policy destination are outside this increment.</p><img class="art" src="assets/original-settings-board.png" alt="Original P19–P21 board">`+btn('Back','settings'));
add('reset-original','D09','P21 · keep progress primary retained',()=>panel('Reset all progress?','This removes your levels, collection and daily stamps from this device.<br><br>Saved puzzles will also be removed.<br><br>Sound and privacy choices stay.',btn('Keep progress','settings',true)+btn('Reset progress','settings')),'Reset is a visual demonstration only and does not modify any data.');

add('reward-complete13','D05','P10 · rewarded Level 13 complete',()=>header('Level 13')+img('check','check')+panel('Beautifully sorted.','Color Studio · 13 / 20 levels',btn('Next level','next14',true)+btn('Home','home-3')),'Recent rewarded full-screen display means shared 180-second cooldown skips interstitial; eligibility stays.');
add('next14','D05','P05 · Level 14 after cooldown skip',()=>boardMarkup());

add('settings-reuse','D09','P19 · original settings plus feedback',()=>`<img class="settings-source" src="assets/original-settings-body.png" alt="Original P19: Sound, Music, Haptics, Reduced motion, Color symbols, Stronger contrast, How to play, Privacy choices, Reset progress">`+btn('Send feedback','feedback')+`<small class="center">Pourlune · 1.0</small>`,'Existing settings are retained as visual evidence; only the new feedback entry is interactive here. Use settings state for text-reflow study.');

add('tutorial-fidelity','D06','P04 · minimal original-frame addendum',()=>`<div class="native-frame tutorial-frame"><img class="frame-background" src="assets/tutorial-frame-edited.png" alt="Original P04 retained: blue target trim, neutral buffers, two color segments of two units each."><div class="capacity-overlay first" aria-label="Four capacity marks">${[0,1,2,3].map(i=>`<i style="top:${i*33.333}%"></i>`).join('')}</div><div class="capacity-overlay second" aria-label="Four capacity marks">${[0,1,2,3].map(i=>`<i style="top:${i*33.333}%"></i>`).join('')}</div></div>`,'Static original-frame edit. Upper-bottle marks are native annotation layers to avoid the hand; adaptive component evidence is tutorial.');
add('seven-fidelity','D08','P18 · original backdrop, seven shared components',()=>`<div class="native-frame seven-frame"><img class="frame-background" src="assets/seven-background-edited.png" alt="Original P18 backdrop and controls retained"><div class="native-bottles">${[0,1,2,3,4,4,4].map((type,i)=>`<div class="native-bottle" style="left:${i<4?3+i*24:15+(i-4)*24}%;top:${i<4?21:48}%">${img('bottle-'+type,'',type===4?'Neutral empty buffer':'Target bottle')}<span class="native-tag" style="color:${['#c45d18','#16722b','#5e268c','#054b93'][type]||'transparent'}">${type===4?'':tags[type]}</span></div>`).join('')}</div></div>`,'Static original-frame composition; all seven use one exact 84 × 177 image box. Use seven for clickable/adaptive layout.');
add('puzzle-board','D02','P05 · retained current puzzle',()=>boardMarkup(),'Returns from helpers preserve identity, bottles and pending flags.');
add('pause','D01','P06 · pause current puzzle',()=>pauseMarkup());
add('restart-confirmed','D02','P05 · restart same instance',()=>boardMarkup(),'Only display feedback is simulated; identity and existing bottle entitlement are retained.');
add('tutorial-free','D06','P04 · Skip, same Level 1 board',()=>boardMarkup(),'Guidance removed; Level 1 and the four-bottle board stay, with no extra-bottle entry.');
add('reward-applied','D05','P18 · reward saved for current puzzle',()=>boardMarkup(),'Explicit reward-save success applies one bottle to the current prototype instance.');
function current(){return location.hash.slice(1)||'pause-failed'}
function render(){const id=states[current()]?current():'pause-failed'; if(navigatingTo!==id)resetFixture(id);navigatingTo=null;const s=states[id];$('#phone').innerHTML=s.render();$('#phone').scrollTop=0;$('#states').value=id;$('#note').textContent=`${s.group} · ${s.name}. ${s.note}`;document.title=`${s.group} · ${s.name} · Pourlune`;document.querySelectorAll('.back').forEach(b=>b.classList.add('back'));}
$('#states').innerHTML=Object.entries(states).map(([id,s])=>`<option value="${id}">${s.group} · ${s.name}</option>`).join('');$('#states').onchange=e=>{navigatingTo=null;if(current()===e.target.value)render();else location.hash=e.target.value};
$('#size').onchange=e=>{const scale=e.target.value;$('#phone').style.setProperty('--scale',scale);$('#phone').classList.toggle('large',scale!=='1')};$('#contrast').onchange=e=>$('#phone').classList.toggle('contrast',e.target.checked);
document.addEventListener('click',e=>{const b=e.target.closest('[data-go]');if(b&&!b.disabled){const next=b.dataset.go.trim();navigate(next);}});
document.addEventListener('change',e=>{if(e.target.dataset.setting==='Stronger contrast'){$('#contrast').checked=e.target.checked;$('#phone').classList.toggle('contrast',e.target.checked)}});window.addEventListener('hashchange',render);window.Pourlune={states,render};render();
