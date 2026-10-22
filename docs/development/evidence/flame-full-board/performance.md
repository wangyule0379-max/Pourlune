# Full-board diagnostic timing

Debug Simulator/AVD diagnostics, not physical/profile performance or a60fps claim. Same dedicated devices/settings,27 native pours per phase without PNG,3 cold launches, hot N=1 each. Before is the old renderer/current accepted UI; after is the final repaired source. Before QA source is preserved; after adds diagnostic elapsed JSON, initial lifecycle log and early-flow recovery guard. Gesture/route/timed/startup endpoint policy unchanged.

Cold endpoint: Dart-main→first PourluneApp host frame after normal Bootstrap. Native pre-Dart time and completion of all intro effects are excluded. Frame series includes framework/setup frames throughout the complete timed command; total also includes frame scheduling latency. Nearest-rank p95. N=1 hot samples cannot establish a stable regression or improvement.

|Platform / phase|Pours / frames|Build p50 / p95 ms|Raster p50 / p95 ms|Cold median ms(N=3)|First board / Next ms(N=1 each)|
|---|---:|---:|---:|---:|---:|
|ios / before|27 / 2240|5.27 / 10.87|0.68 / 1.05|843.2|261.0 / 277.9|
|ios / after|27 / 2151|6.79 / 14.79|0.72 / 1.06|786.5|276.5 / 276.2|
|android / before|27 / 1412|11.80 / 31.89|5.12 / 17.75|3494.7|885.7 / 587.5|
|android / after|27 / 1907|9.97 / 26.23|1.81 / 10.52|1361.4|354.1 / 325.7|

Idle snapshots: after Flame engine paused, two owned art layers, one canvas, no active token. Normal Flutter/QA still generates framework frames during the approx3-second host wait plus protocol overhead: ios=79, android=193. This is not zero whole-app redraw or a leak bound. RSS is a debug process observation.

Pre-review Android Next587.5→955.9ms and first-board885.7→1137.3ms single-sample increases remain in pre-review/performance.md. The current repaired run has different observed values above; neither run proves shipping performance. Decode parallelization and static-tick caching were reviewer Minor findings and remain deferred.

No physical/profile/release runtime, stable start regression threshold, GPU thermal/power or60fps pass is assigned. Native QA does not replace hardware profiling.
