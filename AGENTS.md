# Arbeiten mit dieser Trainer-Vorlage

- Lies `SKILL.md` und `docs/ADAPTER.md`, bevor du einen Spieladapter implementierst.
- Für UI-Anpassungen zusätzlich `docs/UI.md` lesen. Native Glasfläche, Legacy-/
  Kontrast-Fallback und Darstellungscache übernehmen; GameThread-/Cheat-Taktung
  sowie Maus-/Sichtbarkeitsregeln dadurch nicht verändern.
- Dieses konkrete Spielprojekt enthält keinen Demo-Modus. Die Demo gehört nur
  zur ursprünglichen Vorlage und darf hier nicht erneut eingebaut werden.
  Synthetische Test-Fixtures bleiben ausschließlich unter Tests und werden
  nicht in App oder Spielbibliothek eingebunden.
- Für ein anderes Spiel `script/create_project.py` in einen neuen Codeordner
  verwenden, sofern der Nutzer nicht ausdrücklich diese Vorlage ändern will.
- Spielprofile bleiben deaktiviert, bis tatsächliche Bundle-ID, Executable,
  Architektur, UUID und die dazugehörige Adapter-Anbindung geprüft sind.
- Original-Spiele-Apps und Saves bleiben unverändert, sofern der Nutzer keine
  konkrete abweichende Aktion autorisiert. Diese Vorlage erlaubt keine
  automatischen Spielstarts, Multiplayer-Cheats oder Änderungen an Schutzfunktionen.
- Eine Engine braucht ihre eigene GameThread-Zustellung. AppKit läuft auf dem
  Hauptthread; ein beliebiger Hintergrundthread ersetzt den GameThread nicht.
- Beim Laden Auswahl behalten, alte eigene Effekte lösen und neue lokale Besitzer
  validieren. Bei bestätigtem Netzwerkmodus Auswahl löschen und Wirkungen lösen.
  UI-Steuerung und ⌃⇧Rücktaste müssen auch während Ladepausen funktionieren.
- Einmalaktionen nach einem Kontextwechsel verwerfen. Effekte nur nach bestätigter
  Rückleseprüfung grün anzeigen. Native Besitzer über passende Weak-Handles schützen.
- Keine festen Adressen oder vermeintlichen Signaturen aus einem anderen Spiel
  übernehmen. Neue Profile ohne echte Belege nicht als unterstützt bezeichnen.
- Code, Builds und Audit-Unterlagen getrennt halten. Ein stabiler Buildordner
  außerhalb des Codes; nur die aktuelle App behalten. Keine neuen Archive,
  Backup-Repositories oder Quellkopien als automatische Sicherung anlegen.
- Keine Builds, Apps, Logs, Saves, Schlüssel oder lokalen Konto-/Installationspfade
  einchecken. Ein konkreter neuer Projektcode ist die Ausgabe der Vorlage und
  keine Sicherungskopie.
- Nach Änderungen das Buildskript verwenden; es führt die passenden Tests aus.
  Keine Spiele beenden oder für Tests starten, wenn dies nicht beauftragt wurde.
- Externe Veröffentlichung, Commit und Push nur im Umfang des Nutzerauftrags.

- Nutzerbedienung: Nur ⌘^ schaltet Traineranzeige und Mausanforderung gemeinsam.
  Keine zusätzliche Maus-Tastenkombination, Maus-Menüumschaltung oder einen
  separaten Anzeige-ohne-Maus-Modus einführen. Die ursprüngliche Vorlage bleibt
  unverändert; abweichende Vorlagenregeln hierzu nicht erneut übernehmen.
- Keinen Trainer-Eintrag in der macOS-Menüleiste anlegen.
- Auf Nutzerauftrag die gewählten Dauerschalter samt Multiplikatorwerten pro
  Spielprofil über vollständige Spielneustarts speichern und erst nach gültigem
  Einzelspieler-Kontext anwenden. GO-Aktionen niemals wiederholen. „Alles aus“
  und Netzwerk-Sperre löschen die gespeicherte Aktivierung. Wiederaktivierung nur
  bei gesetzter Launcher-Option „Mit zuletzt benutzten Cheats starten“;
  standardmäßig ausgeschaltet. Keine weiteren Extras.

- Cheats und Einmalaktionen aktivieren die native Trainer-Anbindung bei Bedarf
  automatisch. Keine manuelle Voraktivierung verlangen. Lade-/Netzwerk-/Besitzer-
  Prüfungen bleiben verbindlich; „Alles aus“ bleibt wirksam.
