# Pourlune · Glass Garden

Independent implementation of the accepted R1-5732d17bf059 product prototype around the original Cocos2d-JS 3.17 / HTML campaign. The original 100 levels, rules, rendering, game source and movement durations remain unchanged. Product integration lives in `web/game-bridge.js`; source provenance is in `source-manifest.json` and `reference/`.

## Representative stage S2

Node 22.23.2; no runtime npm dependencies. `fake-indexeddb` 6.2.7 is a locked development test dependency.

```sh
npm ci --ignore-scripts
npm test
npm run verify -- --inputs
npm start
```

Run these in `glass-garden/`. Open `http://127.0.0.1:4197/`. All actual browser/device actions are coordinated with the existing Use Computer chat; F9 and unrelated devices/data remain protected. This phase does not start a simulator.

`npm run package -- s2-r1` creates a new ignored candidate under `build/s2-r1/`, refuses to overwrite it, verifies the original/prototype inputs, and records every shipped file hash. The player package contains only `web/`; source samples, QA harness, npm development dependencies and reference reports are excluded. No development query, fake reward route or debug rail is exposed.

## State and persistence

`product-model.mjs` owns rounds, sequential unlocks, per-level slots, settings and completion receipts. `storage.mjs` atomically writes full snapshots to IndexedDB `pourlune.glass-garden.product.v1`, object store `snapshots`. `current` and `previous` are updated in one transaction; explicit corrupt-save replacement keeps `quarantine:<revision>`. Only transaction completion confirms a save. A revision comparison rejects competing-window overwrite. Requested strict durability uses the browser implementation; this is not a hardware power-loss guarantee.

`gameProgress.slots` is the sole canonical per-level board/history, with stable original level uid. There is no second divergent resume board. A new/restart/replay round is committed before loading it; resume preserves the round. A legal pour commits the real Session after-state and any completion receipt immediately, independently of animation completion. The bridge preserves the original return-stage input queue and original animation. Duplicate checkpoints join the same write. Old-round finish callbacks are ignored.

Save failure retains the pending complete snapshot, blocks dependent navigation/input and offers Retry/Stay. Corruption is not a new player. Native legacy readers copy the fixed old SQLite family read-only, preserve old60 originals and settings/privacy refusal, and start new100 at1 exactly once. Existing new progress is authoritative. Old private Dart SDK state is not rewritten or replayed into the JS SDK. Host/browser checks do not establish a real device upgrade.

## Current mobile/service checkpoint

The independent mobile QA shells, licensed original music and native selection haptics are implemented. Fixed official GameMunchies JS0.3.0 is ignored outside source control and packaged only by explicit --sdk; --ads additionally includes official test ads and expanded disclosure. QA uses the existing Pourlune test scope; statistics default off. A persisted withdrawal token prevents old queue revival across delayed startup/restart. Native UMP eligibility is separate from optional statistics.

A true rewarded receipt grants one ordinary empty buffer per puzzle atomically; Restart/Undo retain it, replay after completion creates a new puzzle, duplicate/late callbacks cannot stack or reward another puzzle. Original100 definitions and rules remain unchanged; a strictly generated scene adapter accepts the per-instance expanded definition.

The existing interstitial first-clear/Next policy and shared180s fullscreen clock are implemented. No inventory/late inventory never blocks Next or automatically presents. Only true shown consumes its previously saved qualification boundary. Actual shown waits true close/failure, including background; Next advances only after foreground and matching original round. Details and frozen candidate hashes: native/README.md and docs/development/deliveries/new-cocos-product-implementation.md at repository root.

Current local checks:80 core/UI and15 actual-SDK tests pass with controlled HTTP/IndexedDB. Browser developer reports use simulated native ports, with no real ad/backend proof. Actual native upgrade, Worker/lifecycle/process recovery, real ads/routing/backend, audio/hardware and performance remain pending while another task owns the single device slot. No signed release, final acceptance or TestFlight update is claimed. F9 and old app data remain protected.

CI runs core/copied-source verification and services-disabled native compilation without exporting the private SDK. CI packaging uses --copied-inputs-only only for ci- tags without SDK/ads; ordinary frozen candidates still verify original inputs. Remote CI result must be read separately, not inferred from workflow presence.

## Isolated failure harness

Use `python3 qa/serve.py` and open `http://127.0.0.1:4199/qa/` (the earlier static4198 harness supports transaction abort only). It uses a separate origin and forcibly separate QA IndexedDB. The clearly labelled QA control aborts the next real IndexedDB write after a put request succeeds, before the transaction completes. Use it to check failed-save gating, retained pending board, Retry and reopen. It never generates a solved board or fabricated SDK callback and is never copied into a player candidate. Preserve its failure evidence separately from ordinary player acceptance.

The local QA server can arm one genuine HTTP503 for the next engine request and then resumes normal serving. It does not alter player assets or network/proxy configuration. The load Retry path can therefore be exercised without browser request interception.
