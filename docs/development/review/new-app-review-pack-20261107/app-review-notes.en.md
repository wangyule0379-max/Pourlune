# Pourlune — App Review Notes draft

INTERNAL STATUS: prepared against Cocos build 22 source 094727b7. Do not paste the header or submit the draft until the exact App Store candidate, physical-device video and final advertising/privacy configuration have been verified. Build 22 is internal-TestFlight-only. Replace the two bracketed fields below; do not invent evidence.

---

App: Pourlune, [FINAL VERSION AND BUILD]

1. PHYSICAL-DEVICE DEMONSTRATION
Video: [ACCESSIBLE VIDEO LINK; DEVICE MODEL, OS VERSION AND RECORDING DATE]
The recording must show launching this build and its typical gameplay flow. No account registration, login, account deletion, user-generated content or in-app purchases are offered. We will identify the device and build used in the final recording rather than present simulator footage as physical-device testing.

2. PURPOSE AND AUDIENCE
Pourlune is a single-player color-sorting puzzle game for people who enjoy relaxed logic puzzles. Players plan pours to sort colored liquid and meet each level's stated goal. It offers 100 bundled levels, free hints, undo and restart, and locally saved progress. Core puzzles work offline. The business model is a free game with advertising; there are no subscriptions or paid digital items.

3. ACCESS TO MAIN FEATURES
No login, review account or sample file is required.
Launch the app, review the welcome/privacy information and choose Continue. Use Play on Home to begin or resume, or Levels to choose an unlocked level. Tap a bottle, then a valid destination to pour. Hint suggests a move; Undo reverses a move. Restart is available from Pause.
Extra bottle offers one optional empty buffer bottle per round after the advertising SDK confirms a rewarded-ad reward. Closing an ad without that confirmation does not grant the bottle. An earned bottle remains on restart or app relaunch. Interstitial advertising may occur between levels when eligible, not during an active pour. Ads need a network connection and availability; offline core gameplay remains usable.
Settings provides audio, haptics, reduced motion and privacy controls. Statistics can be disabled; existing explicit choices are retained.

4. EXTERNAL SERVICES
GameMunchies (api.gamemunchies.com): advertising configuration/cooldown and optional gameplay/advertising statistics. Statistics are controlled by the player's choice; configuration and reward handling are separate.
Google AdMob / User Messaging Platform: ad loading, display, reward callbacks and applicable advertising privacy choices.
GitHub Pages: external support and privacy information.
The game engine, puzzles and assets are bundled locally. There is no account server, payment processor, cloud-save service or runtime generative-AI service. Artwork authoring tools do not receive player data.
Support: https://wangyule0379-max.github.io/pourlune-support/
Privacy: https://wangyule0379-max.github.io/pourlune-support/privacy.html

5. REGIONAL BEHAVIOR
The selected storefronts are the United States and Canada. The bundled puzzles and core English-language gameplay are the same. Advertising availability and applicable advertising privacy messages may differ by region, network and eligibility. There is no region-exclusive paid content.

6. REGULATORY AND THIRD-PARTY MATERIAL
This is an entertainment puzzle game, not a regulated financial, medical or gambling service. It has no cash prizes or wagering.
Bundled notices document Cocos2d-JS, Nunito (SIL OFL) and Phosphor icons (MIT). Music is “Dream Culture” by Kevin MacLeod, credited under CC BY 4.0. The pouring sound is “Water, pouring into glass” by giddster, CC0, with excerpt/fade modifications disclosed. Garden artwork was created for Pourlune using OpenAI ImageGen. Supporting license and attribution notices are supplied in third-party-notices.zip and retained in the app's credits.
