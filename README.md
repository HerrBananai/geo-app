# Geo-App – Geographie-Fachbegriffe lernen (Android + iOS)

Eine Codebasis (Flutter) für **Android und iOS** mit interaktiven Lernmodi.
Mit **525 echten Fachbegriffen** (326× Q12 physische Geographie, 199× Q13 Humangeographie),
sortiert nach **Stufe (Q12/Q13)** und **thematischen Rubriken** (z. B. Klima & Wetter,
Böden, Stadt & Urbanisierung, Migration).

## Lernmodi
1. **Karteikarten** – tippen zum Umdrehen, „Gewusst / Nochmal", Mischen, Filter „Nur ungelernte"
2. **Quiz** – 10 Fragen pro Runde, 4 Auswahlmöglichkeiten, Bestleistung wird gespeichert
3. **Zuordnen** – 4 Begriffe + 4 Definitionen per Tippen paaren
4. **Liste** – suchen, nach Kategorie filtern, aufklappen, „kann ich" abhaken

Fortschritt wird **lokal auf dem Gerät** gespeichert (SharedPreferences), funktioniert offline.

## Web-Version für Safari (Apple-Look, PWA)

Ordner **`web/`** – kein Build nötig, läuft sofort in Safari:

- **Lokal testen:** Doppelklick auf `web/index.html` oder besser per Server:
  `python -m http.server` in `web/` → `http://localhost:8000`
- **Online via GitHub Pages:** Workflow `.github/workflows/pages.yml` deployt `web/`
  automatisch. Auf GitHub unter **Settings → Pages → Source: GitHub Actions**
  aktivieren, dann ist die App unter `https://DEINNAME.github.io/geo-app/` erreichbar.
- **Aufs iPhone:** Seite in Safari öffnen → Teilen-Symbol → **„Zum Home-Bildschirm"**.
  Danach Vollbild, eigenes Icon, **offline** nutzbar (Service Worker).
- Design: System-Font, Frosted-Glass-Header/Tabbar, Dark Mode automatisch,
  Fortschritt in `localStorage`. Begriffe aus `web/data/terms.json`
  (Kopie von `assets/data/terms.json`).

## Duolingo-Theme, Retro-Theme (Web + App) + Gamification

- **Web:** Einstellungen → **Design** → Apple, Duolingo oder Retro (bleibt gespeichert).
  Duolingo-Look: Nunito-Schrift, knalliges Grün, dicke 3D-Buttons.
  Retro-Look: Windows-XP-Stil mit Tahoma, blauer Titelleiste und Taskleisten-Tabbar.
  Darstellung (Hell/Dunkel/System) funktioniert in allen Designs.
- **Flutter-App** (`lib/theme/duo.dart`): komplett im Duolingo-Stil
  (grünes Theme, 3D-Buttons, Nachtmodus).
- **Gamification in beiden:** XP (Quiz +10, Karte +5, Paar +5), Tages-Streak
  mit Flamme, Level (alle 100 XP, z. B. Entdecker → Legende), **3 Herzen pro
  Quiz-Runde** (falsche Antwort kostet ein Herz, bei 0 ist die Runde vorbei).
  Alles lokal gespeichert (Web: `localStorage`, App: `SharedPreferences`).
- **Nur Web:** **Edelsteine** als Währung (Quiz +5, Paare +3, neue Karte +1)
  und **Begleiter „Krümel"** auf der Heute-Seite – vom Ei zum Freund
  hochfüttern (10 Edelsteine pro Mahlzeit), antippen und umbenennen.

## Echte Begriffe nachliefern / aktualisieren
Die Begriffe liegen in `assets/data/terms.json` (App) und `web/data/terms.json` (Web,
plus eingebetteter Offline-Fallback in `web/app.js`). Format pro Begriff:
```json
[{ "id": "eindeutig", "begriff": "...", "definition": "...", "beispiel": "...", "kategorie": "...", "stufe": "Q12" }]
```
Neue Begriffe einfach als `Begriff,Definition` pro Zeile schicken (Stufe dazu sagen) –
Kategorien vergebe ich automatisch, IDs auch.

## Weg zur APK (Android) und IPA (iOS) über GitHub
Lokal ist kein Flutter installiert nötig – GitHub baut beides automatisch:

1. Auf github.com neues **leeres Repo** anlegen (z. B. `geo-app`), **ohne** README.
2. Dann lokal in PowerShell:
```powershell
cd "D:\claude_code_everything\geo-app"
git init
git add .
git commit -m "Geo-App Grundgerüst mit Platzhaltern"
git branch -M main
git remote add origin https://github.com/DEINNAME/geo-app.git
git push -u origin main
```
3. Auf GitHub: Reiter **Actions** → Workflow **„Build APK + IPA"** → warten (~5–10 Min).
4. Danach unter **Actions → letzter Run → Artifacts** herunterladen:
   - `geo-app-apk` → `app-release.apk` (direkt auf Android installierbar)
   - `geo-app-ipa-unsigniert` → `*.ipa`

## iPhone-Hinweis (wichtig)
Die IPA aus dem Workflow ist **unsigniert** (`--no-codesign`), Apple lässt unsignierte IPAs
nicht einfach so installieren. Optionen:

- **Einfach (ohne Entwicklerkonto):** IPA per **AltStore** oder **Sideloadly** mit deiner
  Apple-ID selbst signieren und per USB/Kabel aufs iPhone sideloaden.
  Muss alle **7 Tage** neu signiert werden (Apple-Limit für kostenlose Konten).
- **Komfortabel (mit Apple Developer Account, ca. 99 $/Jahr):** In Xcode Signing aktivieren
  und per **TestFlight** verteilen – dann ohne 7-Tage-Limit und ohne Kabel.
- **Alternative ganz ohne Store:** Ich kann dir zusätzlich eine **Web-Version (PWA)**
  bauen – läuft sofort im Safari, kein Sideloading nötig.

## Lokal testen (optional)
1. Flutter SDK installieren: https://docs.flutter.dev/get-started/install/windows
2. Dann:
```powershell
cd "D:\claude_code_everything\geo-app"
flutter create --project-name geo_app --org com.example.geoapp .
flutter pub get
flutter run
```

## Projektstruktur
```
lib/main.dart                  Einstieg + Tab-Navigation + Fortschritt
lib/models/term.dart            Datenmodell Fachbegriff
lib/data/terms_repository.dart  Lädt assets/data/terms.json
lib/storage/progress_storage.dart Lokaler Fortschritt
lib/screens/flashcards_screen.dart
lib/screens/quiz_screen.dart
lib/screens/matching_screen.dart
lib/screens/terms_list_screen.dart
assets/data/terms.json          <-- hier kommen später deine echten Begriffe rein
.github/workflows/build.yml    Baut APK (Ubuntu) + IPA (macOS) automatisch
```
