# Lies of P Trainer für macOS

<img src="Resources/AppIcon.png" alt="Lies of P Trainer" width="128">

[Aktuelle App herunterladen](https://github.com/darkuser89/Lies-of-P-Mac-Trainer/releases/latest) · [Automatischer Build](https://github.com/darkuser89/Lies-of-P-Mac-Trainer/actions/workflows/release.yml)

Eigenständiges Spielprojekt aus der lokalen GPL-3.0-Vorlage. Die ursprüngliche Vorlage wird nicht verändert. Native Anbindung ausschließlich für Lies of P Steam 1.14.0, arm64, UUID `0F3CE7C1-0CBC-371B-99D6-28656270D8D7`, Bundle-ID `com.neowiz.game.lop.steam`.

## Start und Bedienung

Steam öffnen. Eine bereits laufende Spielinstanz regulär beenden. Den Trainer öffnen, die Spiele-App auswählen und „Lies of P mit Trainer starten“ verwenden. Die bestätigte Steam-App-ID wird nur an den gestarteten Prozess übergeben. Das Spiel wird weder gepatcht noch neu signiert.

Im geladenen Einzelspieler den gewünschten Cheat direkt einschalten. Die Spielanbindung aktiviert sich dabei automatisch; ein separater Klick auf „Trainer aktivieren“ ist nicht erforderlich. Grün bedeutet erfolgreiche Rückleseprüfung des angewendeten Werts oder nativen Zustands. Orange bedeutet ausgewählt, aber noch nicht bestätigt. Fehlende Spieler/NPCs lassen Funktionen warten; eine tatsächliche Netzwerksitzung sperrt sie.

Die gewählten Dauerschalter einschließlich „Trainer aktivieren“ und ihrer eingestellten Multiplikatoren werden automatisch pro Spielprofil gespeichert. Die Launcher-Option „Mit zuletzt benutzten Cheats starten“ ist standardmäßig ausgeschaltet. Nur mit gesetztem Häkchen werden sie beim nächsten Start vorgemerkt und nach dem Laden eines gültigen Einzelspieler-Kontexts erneut angewendet. Einmalaktionen, einmalige Editoren und gespeicherte Teleportziele werden nicht automatisch ausgeführt. „Alles aus“ bleibt auch nach einem Neustart ausgeschaltet; eine bestätigte Netzwerksitzung löscht ebenfalls die gespeicherte Auswahl.

- Das Overlay startet verborgen, auch wenn es zuletzt sichtbar war. Position und Größe bleiben erhalten.
- `⌘^`: Overlay öffnen/schließen. Trainer und Maus werden gemeinsam geöffnet; beim Schließen geht die Eingabe zurück ans Spiel. Es gibt keine separate Maus-Tastenkombination.
- `⌃⇧Rücktaste`: eigene Dauereffekte lösen, auch im Zahleneditor und während Ladepausen.
- Zahlenwert anklicken, eingeben und mit Enter übernehmen. Einmalige Editoren anschließend mit LOS ausführen. Negative Koordinaten sind zulässig.
- Der native Zeiger wird gemeinsam mit dem Overlay eingeblendet. Dafür werden zusätzlich zum Eingabemodus die Cursorform und Sichtbarkeit von Lies of P gesetzt und beim Schließen bedingt zurückgenommen. Die Zeigeranzeige benötigt keinen geladenen Spieler. Klicks innerhalb des sichtbaren Trainers werden sofort angenommen und nicht an das Spiel weitergereicht. Cheat-Aktionen benötigen weiterhin einen gültigen Einzelspieler-Kontext.

Nach einem Trainer-Update muss Lies of P regulär beendet und über den aktualisierten Trainer neu gestartet werden. Nur den Launcher neu zu öffnen ersetzt keine Bibliothek im bereits laufenden Spielprozess.

Alle Funktionskürzel verwenden ausschließlich Strg + Umschalt + die in der Zeile angegebene Ziffer, den Buchstaben oder Minus. ⌘^ bleibt auf ausdrücklichen Wunsch zum Öffnen/Schließen erhalten. Andere Command-/Option-Kombinationen und F-Tasten lösen keine Traineraktion aus. Beim Aktivieren des Spielfensters werden die aktivierten macOS-Systemkurzbefehle gelesen; erkannte Überschneidungen werden gesperrt. Scheitert diese Prüfung, bleiben Hotkeys aus. Die Bedienung der sichtbaren Oberfläche per Maus bleibt verfügbar. Eigene Kurzbefehle anderer Apps werden von dieser macOS-Schnittstelle nicht vollständig erfasst.

## Umfang und Bedeutung

„Gewählter Gegenstand“ bezeichnet das vom Spiel gewählte Schnellzugriffs-Item. Seine Inventarzugehörigkeit und maximale Stapelgröße werden geprüft. Es handelt sich nicht um einen beliebigen hervorgehobenen Inventar-Bildschirmeintrag.

Super-Schalter und zugehöriger Multiplikator steuern jeweils denselben Effekt. Der Multiplikator kann auch allein aktiviert werden; beide zusammen multiplizieren sich nicht ein zweites Mal. Spieler-Tempo verändert die persönliche Zeitrate, Bewegung verändert die Geh-/Lauf- und Sprint-Statistik. KI-Tempo gilt nur für vom Spiel ermittelte feindliche Charaktere; ohne solche Objekte bleibt es wartend.

Pulszellen werden über die native Auffüllfunktion ergänzt. „Unbegrenztes Ergo“ hält 999999999 Ergo. Diese Ergänzungen sowie Mengen-, Zeit-, Level-, Menschlichkeits- und Ergo-Editoren können vom Spiel gespeichert werden. ⌃⇧Rücktaste stoppt Dauereffekte; bereits gespeicherte Ergänzungen und bewusst ausgeführte einmalige Editoren sind keine rücknehmbaren Schalter.

Stat-Editoren verwenden die nativen Ganzzahlwerte des Spiels. Maximalwerte werden über die vorhandene Statberechnung angepasst. Level verändert das gespeicherte Level-Feld und vergibt keine zusätzlichen Attributpunkte; Menschlichkeits-Level verändert das Level-Feld und vergibt keine historischen Entscheidungen oder Menschlichkeits-Records.

Koordinaten gehören zum validierten Welt-/Spieler-Kontext. Nach einem Kontextwechsel ist die gespeicherte Position ungültig. Teleport nutzt die native, kollisionsgeprüfte Spielfunktion und bestätigt anschließend die erreichte Position.

| Nr. | Funktion | Tastenkürzel |
| --- | --- | --- |
| 1 | Trainer aktivieren | ⌃⇧1 |
| 2 | Unbegrenzte Gesundheit | ⌃⇧2 |
| 3 | Unbegrenzte Ausdauer | ⌃⇧3 |
| 4 | Unbegrenzte Legion | ⌃⇧4 |
| 5 | Ein Treffer tötet | ⌃⇧5 |
| 6 | Unbegrenzte Pulszellen | ⌃⇧6 |
| 7 | Spielzeit einfrieren | ⌃⇧7 |
| 8 | Erhöhtes Spielertempo | ⌃⇧8 |
| 9 | KI verlangsamen | ⌃⇧9 |
| 10 | Erhöhtes Bewegungstempo | ⌃⇧0 |
| 11 | Koordinaten speichern | ⌃⇧A |
| 12 | Zur gespeicherten Position teleportieren | ⌃⇧B |
| 13 | Unbegrenzte Gegenstandsnutzung | ⌃⇧C |
| 14 | Unbegrenztes Ergo | ⌃⇧D |
| 15 | Schleichmodus | ⌃⇧E |
| 16 | Menge des gewählten Gegenstands | ⌃⇧F |
| 17 | Ergo-Faktor | ⌃⇧G |
| 18 | Spielertempo-Faktor | ⌃⇧H |
| 19 | KI-Tempo-Faktor | ⌃⇧I |
| 20 | Bewegungstempo-Faktor | ⌃⇧J |
| 21 | Aktuelle Gesundheit setzen | ⌃⇧K |
| 22 | Max. Gesundheit setzen | ⌃⇧L |
| 23 | Aktuelle Ausdauer setzen | ⌃⇧M |
| 24 | Max. Ausdauer setzen | ⌃⇧N |
| 25 | Aktuelle Legion setzen | ⌃⇧O |
| 26 | Max. Legion setzen | ⌃⇧P |
| 27 | Max. Traglast setzen | ⌃⇧Q |
| 28 | Feuerresistenz setzen | ⌃⇧R |
| 29 | Elektroblitzresistenz setzen | ⌃⇧S |
| 30 | Säureresistenz setzen | ⌃⇧T |
| 31 | Spielzeit setzen | ⌃⇧U |
| 32 | Stufe setzen | ⌃⇧V |
| 33 | Ergo setzen | ⌃⇧W |
| 34 | Menschlichkeit setzen | ⌃⇧X |
| 35 | X-Koordinate setzen | ⌃⇧Y |
| 36 | Y-Koordinate setzen | ⌃⇧Z |
| 37 | Z-Koordinate setzen | ⌃⇧- |

## Entwicklung

`bash script/build_and_run.sh --build-only` baut und prüft die App. Der Standard ist ein einziger stabiler Buildbaum unter `~/Documents/Codex/Builds/LiesOfPTrainer`, außerhalb des Quellprojekts. Nur die aktuell geprüfte App wird behalten; der Austauschbestand wird entfernt. Lokale Pfade und Spielstände gehören nicht in Git.

Xcode 26+ mit macOS-26-SDK wird benötigt. Die App zielt auf macOS 14+. Glas- und Kontrast-Fallbacks werden durch UI-Fixtures geprüft; daraus folgt keine ausgeführte Prüfung auf älteren Betriebssystemen.

`Sources/LiesOfPBuild.h` enthält ausschließlich zum benannten Build gehörende Symboladressen und Funktionsbytes. Die Runtime sucht ausdrücklich das Haupt-Executable in der Modulliste, berücksichtigt ASLR und prüft UUID und Funktionsbytes vor nativen Aufrufen. Objektbesitzer werden mit Engine-Weak-Handles geschützt. Es werden ausschließlich bereits schreibbare Daten verändert.

Die Tests unter `Tests/` prüfen unter anderem alle 37 Einträge, eindeutige Hotkeys, Zahleneditor/⌃⇧Rücktaste, Material-Fallbacks, Darstellungscache, Lade-/Kontextwechsel, veraltete Aktionen, Netzwerksperre, Ablehnung fremder Prozesse und die Rücknahme eigener Schreibdatensätze. Synthetische Tests sind von echten Spielbeobachtungen zu unterscheiden. Permanente Editor- und Gameplay-Tests benötigen die entsprechende Nutzerfreigabe.

## Automatische Veröffentlichung

Jeder Push auf `main` baut die App auf einem Apple-Silicon-Runner mit macOS 26, führt die bestehenden Tests aus und erzeugt das App-Icon. Anschließend wird das ZIP nach dem Entpacken erneut auf seine Signatur geprüft und mit SHA-256-Prüfsumme unter dem Release `latest` veröffentlicht. Dieses Release wird beim nächsten erfolgreichen Build aktualisiert. Über „Run workflow“ kann derselbe Ablauf manuell gestartet werden. Ein fehlgeschlagener Build veröffentlicht keine App.

Das Icon liegt versioniert unter `Resources/AppIcon.png`. App-Bundles und ZIPs gehören nicht in den Git-Quellstand. Für das Paket ist lokal `bash script/package_release.sh` nach einem erfolgreichen Build verfügbar. Die App ist ad-hoc-signiert und nicht notarisiert. Die CI startet kein Spiel; sie ersetzt keine Ingame-Prüfung.

GPL-3.0-only. Herkunft und Lizenz der Vorlage bleiben enthalten.
