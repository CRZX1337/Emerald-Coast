# CANNABIZ — Implementierungsbericht

Stand: 15. November 2026 · Version 1.4 (24)

## 1. Ausgangslage

- SwiftUI-App, iOS-26-Deployment-Target, Xcode 26.x, Swift 5/6-Sprachmodus.
- Pflanze vollständig prozedural in `Design/PlantArtView.swift` (SwiftUI `Canvas`, keine Bilddateien).
- Fünf Tabs: Grow, Brands, Shop, Fleet, Crew.
- Persistenz über `UserDefaults` (`emerald-coast-save-v1`), `GameStore` ist `@Observable`.

## 2. Fleet-/Seed-Bug

### Ursache

`selectedStrainID` war eine **einzige globale Auswahl** für alle Grow Rooms. `plant(in:)` und
`silentPlant(in:)` haben immer diese globale Sorte verwendet, unabhängig davon, welcher Raum
ausgewählt war. `selectStrain` hatte keinen Raumbezug. Dadurch überschrieben sich Raumwechsel und
Sortenwechsel gegenseitig; nach dem Wechsel blieb effektiv Emerald Coast OG als fallback übrig.
Fleet-Aufträge besitzen zwar eine eigene `strainID`, wurden aber aus dem Regal gespeist, das
wiederum über den globalen Zustand neu befüllt wurde – daher wirkten Aufträge „festgefahren“.

### Lösung

- `GrowRoom.selectionID: String?` – persistierte, **pro Raum** unabhängige Sortenauswahl.
- `GameStore.strain(for room:)` löst die Sorte eines Raums stabil über die ID auf.
- `GameStore.isStrainSelected(_:)` prüft die Auswahl des aktuell gewählten Raums.
- `plant(in:)` und `silentPlant(in:)` verwenden und bepreisen die Sorte des jeweiligen Raums.
- `selectStrain` schreibt in den ausgewählten Raum; die globale ID bleibt nur als Fallback.
- Migration beim Laden: fehlende/ungültige Raum-Auswahlen werden auf eine freigeschaltete Sorte
  gesetzt; `reset` und Erststart initialisieren jede Raum-Auswahl.
- Grow-Room-Karten zeigen die jeweilige Sorte; die Sortenliste markiert die Auswahl des Raums.

### Regressionstests

`Emerald CoastTests/Emerald_CoastTests.swift`:

1. Zwei Räume mit unterschiedlichen Sorten bepflanzen; beide behalten ihre Sorte.
2. Zur Alternativsorte wechseln und wieder zurück; Emerald Coast OG ist erneut pflanzbar.
3. Fleet-Auftrag erzeugen, Sortenauswahl mehrfach wechseln; die `strainID` des Auftrags bleibt
   unverändert.

## 3. Tagesbilanz-Chart

### Ursache

Die Label-Zeile verwendete `frame(width: barWidth + spacing)` **innerhalb** eines
`HStack(spacing: spacing)`. Dadurch wurde der Abstand pro Label doppelt eingerechnet:
Gesamtbreite ≈ Kartenbreite + `(Anzahl Labels × spacing)`. Die letzten Labels liefen rechts aus
der Karte heraus.

### Lösung

Label-Breite auf exakt `barWidth` gesetzt; die `HStack`-Abstände entsprechen jetzt denen der
Balken. Keine Skalierung der Daten, keine horizontale Scroll-Lösung.

## 4. Blütenrendering

Die Blätter blieben unverändert. `drawCola` wurde ersetzt:

- 46 überlappende, unregelmäßige Kelch-Silhouetten statt gleichmäßiger Ellipsen.
- Drei Tiefenlagen aus tropfenförmigen Kelchen (dunkle Basis, mittlere Schicht, wenige helle
  Spitzen) mit Gradient, dünner Kontur und dunklen Kerben am Kelchansatz.
- Keine goldenen Spiralpunkte, keine neonfarbenen Glanzpunkte, keine gleichmäßigen Kugeln.
- 14 feine, gebogene Pistillen; 54 zurückhaltende Trichome nur an den oberen Rändern.
- Die Cola skaliert mit dem Reifegrad, ohne doppelte Verkleinerung; die obere Cola wurde etwas
  nach unten und schmaler gesetzt, damit sie nicht an der Zeichenfläche abgeschnitten wird.

## 5. Samen-Auswahl im Grow

- Neuer Button im Hero-Card: „Sorte wählen“ (leerer Raum) bzw. „Nächster Batch“ (wachsende
  Pflanze).
- `SeedPickerView` listet alle **freigeschalteten** Sorten, gruppiert nach Marke, mit Suche,
  Typ, THC, Samenpreis und aktueller Auswahl.
- Die Auswahl wird über `GrowRoom.selectionID` nur für den geöffneten Raum gespeichert; andere
  Räume behalten ihre Sorte.
- Emerald Coast OG ist damit jederzeit wieder wählbar, auch wenn zuvor Pink Zushi ausgewählt war.
- 4 Samen pro Batch; der Preis pro Samen wird in der Liste angezeigt.

## 6. Verstecktes Dev-Menü

- **Zugang:** Einstellungen → 7× auf die Versionszeile tippen. Kein sichtbarer Hinweis.
- Guthaben: +10.000 $, +100.000 $, auf 1.000.000 $ setzen.
- Fortschritt: Level +5, alle Marken und Grow Rooms freischalten, Upgrades maximieren.
- Testdaten: Regal mit allen Sorten füllen, alle Pflanzen erntereif setzen, Fahrer anheuern,
  Fleet-Auftrag erzeugen.
- Gefahrenzone: Spielstand zurücksetzen (mit Bestätigung).
- Alle Aktionen speichern sofort; das Menü ist nur über die versteckte Geste erreichbar.

## 7. UI/UX

- Untere Navigation von einem `ZStack`-Overlay auf `.safeAreaBar(edge: .bottom)` umgestellt;
  Inhalte haben 104 pt unteren Scroll-Abstand, damit Karten oberhalb der Leiste erreichbar sind.
- Tap-Animationen: `.spring(dampingFraction: 0.72)` → kritisch gedämpftes `Theme.tap`
  (`.smooth(0.28)`); Press-Feedback 0.965 statt 0.955 und kürzer.
- Reduce Motion: Tab-Wechsel und Pflanzen-Sway werden bei aktivierter Einstellung abgeschaltet.
- Bestehende Karten, Farben, Typografie und Glasflächen bleiben erhalten; keine Umstellung auf
  ein generisches iOS-Template.

## 8. Verifikation

- Build `build-ipa.yml`: grün, IPA `1.4 (24)`, 5,47 MB.
- Simulator-Screenshots: grün (`simulator-screenshots`), inklusive `seed-picker.png`.
- Unit-Tests: Swift Testing, zwei Tests (Raum-Isolation inkl. Rückwechsel, Fleet-Auftrag bleibt
  stabil) – Run `43761451725` grün.
- Chart-Sichtprüfung: Tagesbilanz bleibt innerhalb der Karte.

## 9. Verbleibende Einschränkungen

- Keine Verifikation auf einem echten Gerät; CI nutzt ausschließlich den iOS-Simulator.
- Dynamic Type ist noch nicht vollständig auf semantische Schriftstile umgestellt; viele
  Oberflächen verwenden feste Punktgrößen.
- Samen werden beim Pflanzen als 4er-Pack berechnet; ein separates Samen-Inventar mit
  Pack-Käufen gibt es noch nicht.
- Breezy besitzt weiterhin kein Markenlogo und fällt auf die Monogramm-Kachel zurück.
- Der Fleet-Test prüft die Zustandsisolation, nicht die komplette Fahrtsimulation über mehrere
  Tage.
