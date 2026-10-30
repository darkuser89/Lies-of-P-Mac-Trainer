# Wiederverwendbare Glas-Oberfläche und Darstellungscache

Diese Bausteine sind spielunabhängig und werden durch `script/create_project.py`
mit jedem neuen Projekt übernommen. Sie implementieren keine Cheats und geben
kein Spielprofil frei. Test-Fixtures, Adapter-Vertrag, Thread-Zustellung, Hotkeys sowie
Sichtbarkeits- und Mausregeln bleiben davon getrennt.

## Native Materialien

`Sources/TrainerMaterial.h/.m` stellt `MTTrainerMaterial` bereit:

- Unter macOS26+ wird das öffentliche `NSGlassEffectView` verwendet.
- Unter macOS14/15 bleibt native `NSVisualEffectView`-Vibrancy verfügbar.
- „Transparenz reduzieren“ oder erhöhter Kontrast wählen eine deckende Fläche.
  Änderungen während der Laufzeit werden über die Workspace-Mitteilung beachtet.
- Zum Bauen ist Xcode26+ mit macOS26+-SDK nötig. Die App behält macOS14 als
  Mindestversion. Neue APIs müssen versionsgeschützt und schwach verlinkt bleiben.

Den eigentlichen Inhalt mit `initWithContentView:cornerRadius:` übergeben. Nur
`contentView` enthält die interaktiven Controls. Materialinterne Unteransichten
nicht abfragen oder verändern; ihre Struktur ist keine öffentliche API.

`logicalContentSize` skaliert ausschließlich den Inhalt. Die native Glasfläche
behält normale Frame-/Bounds-Koordinaten. Die ganze Glashierarchie durch ein
abweichendes Frame-/Bounds-Verhältnis zu skalieren kann den Inhalt abschneiden.
Bei einer eigenen Panel-Anordnung `layout` nach Größenänderungen ausführen.

Der Material-Wrapper leitet Hit-Tests an die Content-Controls weiter. Eine
verborgene Fläche darf niemals Spielklicks abfangen. Das Overlay verwendet eine
einzige gemeinsame Fläche für seine Zeilen. Keine zusätzlichen Gläser pro Zeile,
keine deckenden Füllungen über die native Glasfläche und keine zweiten Handler
für denselben Klick hinzufügen. Die Overlay-Fläche verwendet Dark Aqua passend
zur hellen Zeichenschrift; bei eigener heller Darstellung Vordergrundfarben
entsprechend anpassen.

Der Launcher behält die normale macOS-Titelleiste mit sichtbarem Fenstertitel
und deckendem System-Fensterhintergrund. Die Materialfläche liegt im Inhalt;
die Fensterleiste wird nicht transparent oder ausgeblendet. Der Lies-of-P-Launcher
verwendet das App-Symbol im Kopfbereich, warme Messing-Akzente, eine dunkle
Verlaufsfläche und eine gemeinsame native Materialfläche für die vorhandenen
Profil-, Auswahl- und Startbedienelemente. Die Start-/Speicherlogik bleibt erhalten.

Beim Spielstart bleibt das Overlay unabhängig von der zuletzt gespeicherten
Sichtbarkeit verborgen; Position und Größe bleiben erhalten.
Beim Öffnen mit ⌘^ wird die Maus für das Overlay automatisch aktiviert,
auch wenn zuvor Anzeige ohne Maus gespeichert war. Beim Schließen geht die
Eingabe an das Spiel zurück. Eine separate Mausumschaltung gibt es nicht.
Ein altes gespeichertes `mouse: false` wird ignoriert; Sichtbarkeit und
Mausanforderung bilden denselben Zustand. Die Titelleiste bleibt auch ohne
gültige Spielfigur verschiebbar; Spielaktionen bleiben weiterhin gesperrt.
Ein konkreter Spieladapter muss die Mausübernahme über `setOverlayInteraction:`
tatsächlich implementieren und zurücklesen. Diese native Rückmeldung darf die
AppKit-Klickzustellung im sichtbaren Overlay nicht sperren. Trainer-Klickfolgen
werden vollständig konsumiert; Cheat-Aktionen benötigen weiterhin einen gültigen
Einzelspieler-Kontext.

## Darstellungscache

`MTOverlayRoot.updateState:` hält immer den neuesten Zustand, auch verborgen.
`refreshPresentation` baut sichtbare Zeilen nur bei einer tatsächlichen Änderung
neu auf: Verfügbarkeit, Auswahl, Anwendung, Zahlenwert, Notiz oder Bereitschaft.
Unveränderte Zeilen behalten ihre Darstellung und Accessibility-Texte.

Die Zeile besitzt dafür eine unabhängige Kopie der Darstellungswerte. Keine
Pointer-Gleichheit des eingehenden Gesamtzustands als Änderungsnachweis verwenden:
Ein Adapter oder Test kann denselben Zustand in-place verändern. Beim Öffnen des
Panels muss sofort der letzte Zustand erscheinen; Hotkeys verwenden weiterhin
den aktuellen Zustand. Status-/Maus-/Summenzeile und die aktuelle Hover-Notiz
werden bei relevanten Änderungen ebenfalls neu gezeichnet.

Die feste Zeilen-/Spaltengeometrie wird pro Overlay vorbereitet. Wird der Katalog
um mehrzeilige Titel oder andere Schriftgrößen erweitert, deren Höhen einmal
beim Erzeugen beziehungsweise beim echten Layoutwechsel bestimmen. Keine
wiederholten Textmessungen oder Tooltip-Erzeugung im unveränderten Poll-Pfad.

Dieser Cache betrifft nur AppKit-Darstellung. GameBridge-Polling, GameThread,
Effektanwendung, Besitzerprüfung, Einmalaktionen und Rücklesen nicht aus
UI-Performancegründen überspringen oder verlangsamen.

## Prüfungen bei Anpassungen

`Tests/PresentationTests.m` ergänzt die bestehenden Prüfungen um native und
simuliert gewählte ältere/kontrastreiche Materialpfade,1000 verborgene/sichtbare
Zustände, Einzeländerungen und in-place Änderungen, Einblenden des letzten
Zustands, verschiedene Größen/Positionen, vollständige Zeilensichtbarkeit nach
nativem Layout, Klickziele, Zahleneditor und Verschieben. Die Traineranzeige und Mausanforderung werden gemeinsam über ⌘^ geschaltet.
Keine separate Mausumschaltung und keinen Trainer-Eintrag in der Menüleiste anlegen.

`Tests/test_project_generation.py` prüft, dass ein neu erzeugtes Projekt diese
Bausteine, Anleitung und Tests enthält und sein Spielprofil deaktiviert bleibt.
Das Buildskript führt beide Prüfteile mit aus. Material-Fallback-Tests auf einem
neuen macOS sind keine tatsächlich ausgeführten Tests auf macOS14/15. Ebenso
sind UI-/Fixture-Tests kein Ingame-Nachweis und keine FPS-Messung.
