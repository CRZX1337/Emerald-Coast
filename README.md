# CANNABIZ

A California cannabis brand tycoon game for iOS – SwiftUI, Liquid Glass, bundle id `com.cannabiz.game`.

Grow Humboldt strains in real time, license real California brands and harvest buds that sell with a brand bonus.

## Brands and genetics

The brand catalog follows publicly documented information from the companies and the trade press:
license prices and level gates are game design, but names, cities, strain lists, lineages and
approximate THC ranges are researched.

| Brand | City | Signature genetics |
| --- | --- | --- |
| Breezy | Los Angeles | retail/delivery brand – shelf cuts only, no in-house breeding |
| Wizard Trees | Los Angeles | RS-11 (OZK × Pink Guava × Black Sherb Bx), Zoza (Zoap × Zangria), Limelight (Gelonade × Zangria) |
| The Ten Co | Los Angeles | Blue Zushi (Zkittlez × Kush Mints #18), Yellow Zushi, Pink Zushi, Nozu |
| Doja Pak | Sacramento | Permanent Marker ((Biscotti S1 × Sherb Bx1) × Jealousy F2), Neon Wormz (Sour SFV #10 × Z Bx2) |
| Jungle Boys | Los Angeles | Jungle Cake (White Fire #43 × Wedding Cake), LA Kush Cake (Kush Mints × Wedding Cake) |
| Backpack Boyz | Los Angeles | Lemon Cherry Gelato (Sunset Sherbet × GSC), Guava Gelato, Blue Guava Gelato |
| Connected | Sacramento | Gelonade (Lemon Tree × Gelato #41), Biscotti (South Florida OG × Gelato #25), Lemonatti |
| Cookies | San Francisco | Gary Payton (Y Life × Snowman #20), Cereal Milk (#18), Georgia Pie |
| Seed Junky | San Fernando Valley | Wedding Cake (Triangle Mints #23), Kush Mints, Jealousy (Sherb Bx1 × Gelato 41) |
| Alien Labs | Redding | Area 41 (Lemon Fuel OG × Gelato #41), Biskanté (Melonade × Biscotti #6), Atomic Apple |
| Team Elite | Orange County | Styrofoam Cup, Pearadise, Orange Soda, Goat Cheese (Grandma's Cookies × UK Cheese) |
| Sherbinskis | San Francisco | Bacio Gelato 41 (Sunset Sherbet × Thin Mint Cookies), Sunset Sherbet, Mochi Gelato |
| Fig Farms | Humboldt County | Blue Face (Face Off OG × Animal Mints), Strawberry Guava, Fabulosa |

Brand logos are trademarks of their owners and are not bundled with this repository. The game draws its
own monogram tiles in each brand's colour instead.

## Versioning

Every commit bumps the version: `CFBundleShortVersionString` for features (1.1, 1.2, …) and
`CFBundleVersion` as the build number that goes up with every commit. Both live in
`Emerald Coast/Info.plist`, and the current value is shown at the bottom of the in-app settings.

## Unsigned IPA

`.github/workflows/build-ipa.yml` builds the app on every push to `main` and packages an **unsigned** `.ipa`.
Signing happens on your device, not in CI.

Two downloads are published:

- **Latest build** – release `latest-build`, always the newest commit on `main`
- **Tagged releases** – pushed for tags like `v1.0`

Both are also attached to each workflow run as the artifact `CANNABIZ-unsigned-ipa`.

### Install with Feather

1. Open [Feather](https://github.com/khcrysalis/Feather) and go to the **Files** tab.
2. Import `CANNABIZ-unsigned.ipa` from the release page.
3. Tap the IPA, choose **Sign** (or use a saved certificate) – Feather signs it with your certificate and
   provisioning profile.
4. Tap **Install**. You need a valid signing certificate (free Apple ID or a paid developer account) and, on
   a free account, a registered device.

Because the app targets iOS 26, the build machine and the SDK have to be new enough; the workflow selects the
newest installed Xcode automatically.
