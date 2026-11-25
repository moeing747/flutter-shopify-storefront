# Release process

How this app ships to the stores. The steps assume fastlane later; today they
are runnable by hand.

## Versioning

`pubspec.yaml` `version: X.Y.Z+N` — semver for humans, monotonically
increasing build number `N` for the stores. One tag per release (`vX.Y.Z`).

## Android (Play Store)

1. Release signing: `key.properties` + upload keystore (never in git; CI gets
   them as secrets). Play App Signing holds the app signing key.
2. Build:
   ```bash
   flutter build appbundle --release \
     --obfuscate --split-debug-info=build/symbols \
     --dart-define=BRAND=basics \
     --dart-define=STOREFRONT_ENDPOINT=... --dart-define=STOREFRONT_TOKEN=...
   ```
3. Upload the `.aab` to the **internal track**, QA on real devices, then
   promote to production with a **staged rollout** (10% → 50% → 100%),
   watching crash-free rate between stages.
4. Upload `build/symbols` to the crash reporter so obfuscated traces resolve.

## iOS (App Store)

1. Certificates/profiles via App Store Connect (later: fastlane `match`).
2. Build & upload:
   ```bash
   flutter build ipa --release \
     --obfuscate --split-debug-info=build/symbols \
     --dart-define=... # same defines as Android
   xcrun altool --upload-app -f build/ios/ipa/*.ipa ...
   ```
3. TestFlight internal → external testers → submit for review with phased
   release enabled.

## App size policy

Target: **≤ 20 MB per-device download**. Guardrails:

- Product imagery comes from the Shopify CDN, never bundled.
- Release builds tree-shake icons and Dart code by default;
  `--obfuscate --split-debug-info` keeps symbol tables out of the binary.
- Ship `.aab` so Play serves per-ABI/per-density splits; on iOS rely on app
  thinning.
- CI builds the release bundle on every push and prints its size in the job
  summary, so a size regression is visible in the PR that causes it.

## Rollback

Play: halt the staged rollout, promote the previous bundle. App Store: phased
release can be paused; a fixed build goes through expedited review. Server
side, the Storefront API version is pinned in the endpoint URL, so API
migrations are explicit app releases, never silent breakage.
