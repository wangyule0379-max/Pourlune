# Progression v7 verification — 2026-11-05

Levels11–100 replaced; exact v6 opening1–10 preserved. Existing changed later-board saves are invalidated by level UID; unchanged opening progress and preferences persist.

## Evidence

- `node --test --test-concurrency=1 app/tests/*.test.cjs`: **122 passed,0 failed**,45.15 seconds.
- Complete-search shortest proofs freshly recomputed for all100. Maximum search87,425 expanded states within100,000 budget. No budget limit is treated as proof.
- Independent legal replay:2,338 shortest-path pours. Visible-only two-step policy:2,576 pours, zero Undo, no hidden-color lookup. These are algorithmic checks, not human difficulty ratings.
- All100 hint-worker playthroughs finish; cache identity includes collector and seal rules. Save/reload/Undo validated at every proof step.
- All reference pours checked at six fill fractions, including tiny remainders: source/receiver conservation, vertical stream alignment and32-unit mouth separation.
- Responsive geometry checked at320×568,360×800,390×844 and430×932 including safe-area insets. Browser DOM audit of all100 at320×568: no target overlap/clipping or objective/move-counter collision; minimum bottle target44.733 CSS pixels. Final14-bottle targets49.89px.
- Browser click-through wins:11,16,31,36,61,71,86,100. Level36 checks Undo and reload after unlocking;71 and100 completed at320×568. Level100 completes in42 visible-policy pours (proven minimum36) and returns to Chapter10 correctly. Browser console: no warnings/errors in inspected session.
- Fresh external code review of generator, rules, proofs1–98 and UI geometry. Found a missing checkpoint directory in fresh checkouts; reproduced ENOENT, fixed, regression test passed. Last99–100 use existing ordinary5-column layout with14 bottles and are covered by final full suite and browser audit.
- Production build: `node build.mjs`, successful. No native emulator/simulator was started; this round validates the browser build, not a packaged iOS/Android binary.

## Design decisions

- Water-sort permits interchangeable final bottle arrangements; validity and solvability matter, not unique bottle positions.
- Ordinary/collector family changes can change ordinary starting water by4 units because a fixed collector occupies one slot. Bottle count, distinct colors and proven minimum never decrease.
- Visible-policy v2 preserves completed full non-target bottles. Historical sample traces keep v1; player rules are unchanged.
- Collector positions70/410 leave room for pedestal labels while retaining touch spacing. Collector combinations cap at13 bottles; final two ordinary boards use14 in5+5+4 rows without narrower bottles.
- Collection workload rises4→8→12 while prefill stays4. No growth claimed solely from a larger prefilled collector.
- First seal unlock2–5 moves in introduction,3–8 later. Final independent unlock<=14 except95–100<=18; longer second objective remains fully visible and must pass the bounded no-Undo route.
- Eight colors are the palette ceiling here. Later growth also uses genuine water rearrangement, minimum-step increases, different seal keys and layout families. No new fog, reserve or chained locks.

See [the complete100-level catalog](gentle-100-catalog.md) for individual bottle/color counts, proven minima, visible-route lengths and unlock timings.
