# Concrete support/privacy delta for the Glass Garden candidate

Prepared7November2026; not published and not an availability announcement. The existing support repository main/index.html was read through GitHub and still documents the older60-level campaign. The current source privacy.html covers legacy0.5.0/Firebase/SDK0.2 configurations. Root has not verified the deployed Pages response in this step. Existing source files in docs/support/pages-site/ and the live site remain unchanged.

Before the accepted TestFlight update, keep the legacy60 help/privacy instructions and add a clearly separate Glass Garden guide. Select the guide by the campaign shown in the installed app, not by guessing a free store version/build. Read the actual accepted store version/build first. The new guide must never say old60 progress becomes100 progress or that an ad timeout grants a bottle. Final wording and in-app notice must match the accepted SDK/runtime. The official policy-only SDK fix and actual native tests are still pending.

## New help section text

### Pourlune · Glass Garden

Glass Garden has100 built-in levels and a floral Home, Levels and Settings. The earlier campaign has60 main puzzles, daily puzzles and collections; use the earlier guide below for that version. Test availability depends on the build you have actually received.

Tap a bottle, then an empty bottle or a bottle with the same top color. Small bottles hold four layers. Sort the colors into full bottles. In collector levels, gather all pink water into the fixed tall collector, which accepts pink only, then sort the remaining colors. Covered bottles cannot pour or receive. Finishing a full bottle in the color on a seal lifts the corresponding covers automatically.

Undo, Hint and Restart are free. A hint points to a move without pouring it. A timeout means the search did not finish in time; it does not prove the puzzle is impossible. You can cancel a search, Undo, Restart or keep looking. There is no timer.

Home and Continue reopen the saved board and move history. Completed levels remain available to replay; Next preserves a different unfinished level's saved board. At the end of level100, use Levels or Home. There is no level101.

In an ad-enabled build, Extra bottle requires a genuine earned-reward confirmation and a successful local save. Closing an advertisement alone does not earn a bottle. One ordinary empty bottle can be earned per puzzle. Undo and Restart keep an already earned bottle for that puzzle; replaying a completed level starts a new puzzle. A network failure or unavailable advertisement does not block normal puzzles or the free tools.

Progress and settings are stored on this device. Keep the app open if a save error appears and use Retry save before leaving. There is no player account or cloud sync. Removing the app or clearing app data may remove progress. During the change from the older campaign, its original local records are retained; its level numbers and completed records are not mapped into Glass Garden. The new campaign starts at level1. This does not make the old campaign playable inside the new campaign.

Use Settings for Sound, Music, Haptics where supported, Reduced motion and Analytics. Ad privacy options appear when required by Google's consent system. Report a problem through TestFlight feedback or wangyule0379@gmail.com. Include the actual app version/build, device/OS, level, steps and any save error. The app does not automatically send a board or email. Do not send passwords or verification codes.

## New version-specific privacy section text

### Glass Garden test builds

This section applies only to the Glass Garden build identified in the supplied test release notes. It does not change the description of the earlier60-level builds below. Pourlune is operated by changjiang li; privacy/support contact: wangyule0379@gmail.com.

Glass Garden stores puzzle boards, move history, completion records, settings, statistics choices and pending reward/fullscreen receipts locally. Core puzzles and the free Hint, Undo and Restart work offline. There is no player account, cloud sync, payment or subscription. Earlier local campaign records are retained during an update and are not converted into the new campaign. Uninstalling or clearing app data can remove local records.

Optional GameMunchies statistics start off. If you allow the current notice, the service can receive a random installation identifier, event identifiers and first-occurrence times, active-use/new-round events and ad opportunity, load, failure, impression and earned-reward outcomes. Ad event context includes the placement, provider, app version and attempt identifiers. These events do not include your name, email, puzzle board or an advertising ID from this app. Event processing uses the registered game, platform and environment. The new campaign's reporting installation identifier is independent of the older campaign's reporting identity.

GameMunchies configuration requests are independent of optional statistics and can occur while statistics is off. They communicate the game, platform and ordinary network information, including the IP address, to the service and its infrastructure. Remote settings can disable eligible placements or tighten the local rules; they do not revoke a saved reward or replace Google's advertising-consent checks.

The new campaign uses a separate local statistics store. The older campaign's installation identifier and pending statistics are not imported or replayed into that store; the original storage remains on the device. This can interrupt reporting identity/continuity across the campaign change. It is not a promise that every old or interrupted observation will be delivered.

The current JavaScript SDK bounds its local pending queue to1000 events/512KiB and discards entries older than30 days during subsequent queue processing. Storage eviction, interruption or failures can lose pending telemetry. Turning Analytics off stops new optional statistics, attempts to cancel event requests and clears the current service scope's pending queue. The local installation identifier can remain. It cannot recall data already received by the server. Later allowing does not backfill raw observations captured while sharing was off; valid events already queued under permission can retry with the same identifiers while sharing remains allowed. Support requests and server/infrastructure retention still follow the applicable sections below; local deletion does not recall already received data.

This candidate does not newly enable Firebase Analytics, Crashlytics or Firebase Remote Config in the Glass Garden runtime. An earlier saved crash-sharing preference is retained with the older local records but does not turn on a new crash-reporting service here.

The candidate uses official Google test advertisements with Google Mobile Ads and UMP. Test advertisements still involve network requests and Google processing of IP-derived approximate location, app/device information, ad interactions, diagnostics and consent choices for delivery, measurement, consent and fraud prevention. Requests use non-personalized mode. The app does not request ATT authorization or Android advertising-ID permission; other SDK identifiers and processing can still exist. A test/non-personalized advertisement is not a promise of no data collection.

Google consent eligibility gates ad loading separately from the Analytics choice. Use Ad privacy options in Settings when Google requires them. Turning Analytics off does not itself turn off UMP or eligible Google test-ad requests. No optional play-statistics permission is inferred from advertising eligibility. An extra bottle requires the actual rewarded-ad confirmation and a successful game save; closing an ad alone does not earn it.

The operator/contact, voluntary feedback, service-provider/international processing, children and website-hosting sections below continue to apply. These pages do not add forms or scripts. A public support page cannot guarantee service delivery or erase provider records. The accepted release's actual service configuration must be compared with this section before publication.

## Final application checks

- Replace the candidate reference with the live verified accepted version/build only after total-controller approval and upload processing. Do not claim a new build is installable from an upload receipt alone.
- Preserve the older guide and clearly label its fixed-tag, daily, collection, direct-extra and Firebase behavior as earlier-version behavior.
- Compare the final signed App/SDK/network/permissions/queue behavior and store privacy declarations with the new section. The per-observation policy-only gap must be fixed first.
- Publish only the reviewed source through the existing support repository; read back the deployed Help and Privacy pages. Do not create a new website/repository, change operator facts or send email.
