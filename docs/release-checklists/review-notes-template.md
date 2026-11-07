# Review Notes Template

Use with the six-part New App section in [Pre Submission Checklist](new-app-review-checklist.md). Prepare all six sections for each first formal submission. This is our preparation standard; do not present a video as a universal Apple requirement. Follow the app's actual review message. Refresh only affected evidence on updates.

Before pasting: replace all brackets; use the exact intended build, verified navigation and current services. Mark inapplicable capabilities explicitly. Never claim a simulator is a physical device or a TestFlight-only build is an App Store candidate. Keep internal evidence/status outside the reviewer-facing text. Provide reviewer credentials in the dedicated secure fields, not this repository.

Adapted from the open source app-store-preflight-skills project (MIT), credited in the upstream app-store-compliance `docs/CREDITS.md`.

```text
App: [name], [version/build]

1. PHYSICAL-DEVICE DEMONSTRATION
Recording: [reviewer-accessible URL or attachment name]
Recorded on [physical device model], [OS version], [date], using [build].
Shows launch, [typical main flow], and [applicable account/deletion, UGC safety,
or paid access flows]. [Explicitly identify inapplicable flows.]

2. PURPOSE, AUDIENCE AND BUSINESS MODEL
[Purpose, intended audience, practical value, and how the app is funded.]

3. ACCESS TO MAIN FEATURES
[Numbered launch/setup/navigation steps; offline/network requirements.]
[No login is required OR dedicated review account supplied in review fields.]
[Sample file / restricted feature instructions if required.]

4. EXTERNAL SERVICES
[Actual service — purpose and applicable behavior.]
[Identify bundled core functionality and any runtime AI, rather than confusing
asset creation with a service used by the player.]
Support: [URL]
Privacy policy: [URL]

5. REGIONAL BEHAVIOR
[Selected storefronts and any relevant functional, content, consent or ad
availability differences; accurately scope any consistency statement.]

6. REGULATORY AND THIRD-PARTY RIGHTS
[Regulated activity and credentials, OR explicit non-applicability.]
[Relevant protected material, licenses/authorizations and attachment names.]
```

## Internal handoff (do not paste)

- Exact candidate/source/package hash and store-selected build agree.
- Video link opens without an access request; no placeholder URL remains.
- Supported physical-device QA and known defects have truthful status.
- Screenshots, description, age rating and privacy declarations match the candidate.
- Licenses include required attribution and changes; no private SDK source or credentials are attached.
- Review contacts and any required accounts are usable.
- A specific Guideline 2.1 message is answered item by item before resubmission.
- Preparing this pack does not authorize submission or public release.
