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

Save failure retains the pending complete snapshot, blocks dependent navigation/input and offers Retry/Stay. Corruption is not treated as a new player. Old site/prototype localStorage and Flutter SQLite are neither adopted nor modified. This is **not an implemented migration from the old 60-level app**; a future same-store update requires a separately accepted mapping and nonempty-data migration.

## Scope and honest limitations

This local product has no analytics/ad/GameMunchies SDK or outbound collection/queue. The choice is saved but does not enable collection; the notice explicitly requires a fresh disclosure/choice before connecting services. CSP limits network connections to the local origin. SDK callback tests or real ads are not claimed. No rewards, extra bottle, gameId, store registration, signing or upload is introduced.

Sound effects and reduced motion are functional. Music/haptics are unavailable controls, matching the accepted prototype's capability state. Their placeholder values do not constitute an approved production default or migration policy; existing stored booleans are preserved. Mobile shells and native lifecycle/storage/Worker validation follow representative acceptance and are not yet implemented or passed. No performance optimization or measured performance claim is made.

## Isolated failure harness

Use `python3 qa/serve.py` and open `http://127.0.0.1:4199/qa/` (the earlier static4198 harness supports transaction abort only). It uses a separate origin and forcibly separate QA IndexedDB. The clearly labelled QA control aborts the next real IndexedDB write after a put request succeeds, before the transaction completes. Use it to check failed-save gating, retained pending board, Retry and reopen. It never generates a solved board or fabricated SDK callback and is never copied into a player candidate. Preserve its failure evidence separately from ordinary player acceptance.

The local QA server can arm one genuine HTTP503 for the next engine request and then resumes normal serving. It does not alter player assets or network/proxy configuration. The load Retry path can therefore be exercised without browser request interception.
