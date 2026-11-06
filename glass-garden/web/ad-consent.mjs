// A permission stamp belongs to this document and this exact choice window.
// Native receipts carry the gate at first observation; draining a receipt cannot
// create optional statistics. Game rewards and fullscreen policy are independent.
export class AdObservationConsent {
 constructor({allowed=()=>false,session=crypto.randomUUID()}={}){this.allowed=allowed;this.session=session;this.epoch=0;}
 snapshot(){return {session:this.session,epoch:this.epoch,allowed:this.allowed()===true};}
 attach(send){this.send=send;this.sync();}
 sync(){const gate=this.snapshot(),key=JSON.stringify(gate);if(this.send&&key!==this.sent){this.send({command:'statistics-gate',...gate});this.sent=key;}}
 changed(){this.epoch++;this.sync();}
 capture(event){const stamp=this.snapshot();if(event!==undefined){const native=event?.adConsent;stamp.allowed=stamp.allowed&&event?.replayed===false&&native?.allowed===true&&native.session===stamp.session&&native.epoch===stamp.epoch;}return stamp;}
 permits(stamp){return stamp?.allowed===true&&this.allowed()===true&&stamp.session===this.session&&stamp.epoch===this.epoch;}
}
export function modelAdConsent(model){return new AdObservationConsent({allowed:()=>model.state.analyticsChoice==='allowed'&&model.state.disclosureVersion>=(model.policyVersion||3)});}
export function observation(event){return event?{id:event.id,occurredAt:event.occurredAt}:{id:crypto.randomUUID(),occurredAt:new Date().toISOString()};}
