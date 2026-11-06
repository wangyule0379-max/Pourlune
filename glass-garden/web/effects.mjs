// Native transports own media decoding, platform interruptions and tactile output.
// These optional effects never save or advance a game action.
export class NativeEffects {
 constructor(send){this.send=send;this.desired=null;this.prefs={};this.active=false;}
 update(prefs,active){this.prefs=prefs;this.active=active;const desired=active&&prefs.music;if(this.desired===desired)return;this.desired=desired;try{this.send({command:'music',enabled:desired});}catch{}}
 haptic(){if(this.active&&this.prefs.haptics)try{this.send({command:'haptic'});}catch{}}
}
