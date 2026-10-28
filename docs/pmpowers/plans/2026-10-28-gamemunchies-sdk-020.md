# GameMunchies 0.2.0 integration

Scope: implement and validate only; TestFlight19 is paused. Preserve source-only pour fix from 1f077ce, existing identities, consent, AdMob policy and rewards.

1. Verify fixed private Dart package archive and all seven files before installation. Keep path dependency and previous package backup.
2. Transport reports actual load/show/impression/reward callbacks. Coordinator/user action boundaries report opportunities and blocked reasons, never widget rebuilds. Each correlation/stage retains first ID/time; SDK alone owns persistence and retries.
3. Test withdrawal, nonblocking behavior, cooldown restart, real callback dedupe and game reward idempotence. API only; no administrator credentials or revenue fabrication.
4. Build explicit test environment for existing independent game registration on iOS and Android. Computer chat owns device/backend interaction, protects F9 and existing saves. Inspect real test ads, native recovery and backend environment/dimension/funnel records. Report unverified cases honestly.
5. No UI/gameplay/consent-policy changes; no store upload or submission.

SDK0.2.0 SHA256: 70effde1c9150b416b34f4dd4b6d95912ef836b5f429c98ea5a8cbf98fd0c167.

## Later user authorization: iOS release

The user now authorizes iOS TestFlight first, then formal App Store review if verified. This supersedes the no-publishing scope above. Use Computer exclusively owns GUI/ASC/Organizer. Parent prepares the precise source, exact-head CI and signed package, checks privacy and package deltas, and supplies the approved candidate. Preserve existing Self group (2 people), no new invitations, manual release after review. Android device interaction remains unverified and is not an iOS blocker. No new UI or consent policy changes. Existing build19 is unoccupied; align the unsent App Store version with 0.5.0. Obtain the actual missing distribution/contact/ad-mode choices, not generic upload permission.
