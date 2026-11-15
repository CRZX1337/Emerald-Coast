# Emerald Coast

A California cannabis brand tycoon game for iOS – built with SwiftUI and Liquid Glass.

Grow Humboldt strains in real time, license California brands (Wizard Trees, The Ten, Breezy, Doja and more),
harvest buds and sell them with a brand bonus.

## Unsigned IPA

`.github/workflows/build-ipa.yml` builds the app on every push to `main` and packages an **unsigned** `.ipa`.
Signing happens on your device, not in CI.

Two downloads are published:

- **Latest build** – release `latest-build`, always the newest commit on `main`
- **Tagged releases** – pushed for tags like `v1.0`

Both are also attached to each workflow run as the artifact `EmeraldCoast-unsigned-ipa`.

### Install with Feather

1. Open [Feather](https://github.com/khcrysalis/Feather) and go to the **Files** tab.
2. Import the `EmeraldCoast-unsigned.ipa` from the release page.
3. Tap the IPA, choose **Sign** (or use a saved certificate) – Feather signs it with your certificate and
   provisioning profile.
4. Tap **Install**. You need a valid signing certificate (free Apple ID or a paid developer account) and, on
   a free account, a registered device.

Because the app targets iOS 26, the build machine and the SDK have to be new enough; the workflow selects the
newest installed Xcode automatically.
