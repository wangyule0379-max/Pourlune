# BR01 store preflight — local review, not submission approval

Skills: app-store-preflight-skills(all_apps/games, relevantmetadata/privacy/design/entitlements) and app-store-compliance(game + relevantplatform/privacy rules). Native final-product checks are recorded separately from this cheap source scan. The guard completed with application-summary critical0/high4/medium4; its generic jurisdiction deadline preamble is not an app finding or approval block.

|ID / severity|Platform / rule|Actual finding and disposition|Evidence / concrete next action|
|---|---|---|---|
|BR-B03 Critical submission gate|Both / Apple5.1.1(i),1.5; Play User Data|No approved public privacy/support URL or feedback mailbox. In-app accurately says unavailable. Local drafts exist, not published or legally approved.|service_config.dart defaults; docs/support/beta/; owner supplies owned destinations/controller/request contact, then configure/rebuild/verify HTTP+in-app links.|
|BR-B04 Critical submission gate|Both / content rights, Apple5.2|Candidate visual manifests retain UNCONFIRMED. Runtime acceptance is not a commercial license.|runtime/manifest.json and runtime/ui/manifest.json, original design pack; owner verifies original/derivative commercial rights. Nunito OFL and procedural audio provenance are present.|
|BR-B05 High submission gate|Both / accurate age/audience/privacy/export declarations|No store app records/forms submitted; final age, audience, countries, export/legal and data answers unconfirmed.|beta-copy-en.md facts, service matrix and actual SDK/permission inventory; owner approves corresponding actual forms, no guessing.|
|BR-B01 High account gate|Both / app record setup|AppleAppID+Pourlune profile created; ASC record absent and SKU unknown. Existing ASC Schedule2 update banner needs owner assessment; not assumed a universal free-Beta block. Playpackage available, but create form requires policy/export declarations.|accounts.json / pourlune-profile.json. No terms accepted; do not change FishPilot.|
|BR-B02 High Android signing gate|Play / release signing|No authorized Pourlune upload key selected. Existing debug or other-app profile is not a release signer.|Unsigned AAB can be inspected; owner selects existing local upload key or handles key creation outside this authorization. No passwords/keystores in chat.|
|BR-B06 Device/evidence gate|Both / actual runtime/screenshots|Formal candidate clean install/upgrade, physical/minimumOS, screen readers, audio/haptics and store screenshots still require appropriate conditions.|BR02-BR03-checklist.md; no capture permission workaround or fabricated QA screenshots.|

## Source-scanner triage

- BOTH-PLACEHOLDER high: false positive in service_config.dart's explicit example-domain rejection list; no example URL is configured. Keep validation. Public destinations are genuinely missing under BR-B03.
- APPLE-EXPORT-COMPLIANCE-MISSING high: factual key absent. Owner must establish applicable encryption/export answer; do not silence by inventing an exemption. No encryption implementation was added.
- ANDROID-R8-OPTIMIZATION-MISSING high: source-pattern false positive; pinned FlutterPlugin.kt sets release minify/shrinkResources. Final release logs/mapping prove effective R8. No redundant Gradle setting or SDK upgrade added.
- GOOGLE-DATASAFETY-MISMATCH high: SDK presence triggers a review reminder, not an observed submitted-form mismatch (there is no form yet). Treat accurate form completion as BR-B05; no zero-collection declaration.
- VoiceOver/haptics medium: native Swift symbol scan cannot assess Flutter semantic/feedback implementation. Existing UI tests/semantics and motion tests are inherited, actual physical VoiceOver/TalkBack/hearing/haptics remain BR-B06.
- Age-rating medium: owner questionnaire remains BR-B05; no rating number guessed.
-12-tester medium: current official policy is for production access on applicable new personal accounts, not a condition for starting this closed test.

No account, IAP, UGC, backend or runtime AI features were introduced. No actual submission/rejection/legal compliance conclusion is claimed. Optional Firebase receipt/ads inventory gaps remain separately scoped; disabled ads do not require a real ad reward to play this beta's free core.
