# Independent UI observations — 2026-10-22

On installed iOS candidate 3497E78D, CUA interaction: Home → Settings → Reduced motion off → How to play → repeated return → Settings; Reset confirmation opened and Keep progress cancelled; Home retained5/5 collection and replay. Continue replay entered real board with prior one move; Pause exposed only Close/Resume/Restart/Home semantics; Home returned correctly. Coordinate fallback used when AX Reset action did not activate. No reset confirmed. These are manual actions, separate from native automation.

Parent restarted both dedicated QA candidates and read fresh102-step reports with no errors. Runner uses actual Flutter gestures and sqflite with controlled progress/transaction failure; not natural60-level play, service success, or process-recovery proof. Dynamic dev instance IDs differ from author's prior reports; four explicit transitions-main2/4/20/60 fixture IDs are intentionally shared. Installed iOS35 critical hashes match manifest. Android installed hash checked separately.

Reviewed author iOS/Android navigation videos by AVFoundation extraction. iOS2.6–3.8s white native launch, blue Flutter startup at4s; Android3–4s white native splash with icon, blue startup after5s. Times are positions in videos, NOT benchmark launch measurements. Native storyboard and Android launch theme explicitly use white. T-R01 P2: native cold launch discontinuity; requires repair and new native/main-entry evidence.

Independent simctl recording failed once with Cocoa513/-12204 permission error. No workaround/retry; existing author recordings are labeled source evidence, while this run's route reports and manual interaction are independent. Screenshots alone do not establish temporal smoothness; no representative-device FPS claim.
