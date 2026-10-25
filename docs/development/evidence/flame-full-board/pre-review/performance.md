# Full-board diagnostic timing

Debug Simulator/AVD diagnostics, not physical/device-profile performance or a 60fps claim. Same hardware/settings, same 27 formal native pointer pours, no PNG in timing command. Before collected after implementation from unchanged Flutter-board source to retain latest UI baseline.

Three cold launches measure Dart-main → first actual PourluneApp host frame after Bootstrap. Native pre-Dart time and completion of intro effects are excluded. Hot entry N=1 for each endpoint/phase. Frame samples include complete timed command/setup framework frames; total includes frame scheduling latency. None of these are an FPS benchmark.

|Platform / phase|Native pours / frames|Build p50 / p95 ms|Raster p50 / p95 ms|Cold host-frame median ms (N=3)|First board / Next ms (N=1 each)|
|---|---:|---:|---:|---:|---:|
|ios / before|27 / 2240|5.27 / 10.87|0.68 / 1.05|843.2|261.0 / 277.9|
|ios / after|27 / 2079|7.14 / 17.20|0.67 / 1.01|824.4|287.2 / 280.3|
|android / before|27 / 1412|11.80 / 31.89|5.12 / 17.75|3494.7|885.7 / 587.5|
|android / after|27 / 1286|15.40 / 37.68|4.89 / 18.03|3547.3|1137.3 / 955.9|

After idle snapshots show the Flame engine paused with two owned art layers, one canvas, no active token. The normal Flutter app/instrumentation still generates framework frames (iOS101, Android159 over the approx3-second host wait plus protocol overhead); this does not prove zero whole-app idle redraw. RSS is a debug process diagnostic, not a leak bound.

No physical device, release/profile runtime, GPU thermal/power or statistically stable startup regression threshold was verified. The iOS first-board diagnostic increased from261 to287ms; Android first-board increased885.7→1137.3ms and Next587.5→955.9ms in these single debug samples; these costs need representative-device/profile investigation before a performance pass. Full raw series are in the JSON. No unmeasured performance pass is assigned.
