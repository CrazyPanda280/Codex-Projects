# Password Finder Testprojekt (Windows)

Dieses kleine Testprojekt liefert eine **direkt startbare Windows-App** als `.hta` (HTML Application), inklusive Launcher-Batch-Datei.

## Starten auf Windows 11 (64 Bit)

1. `PasswordFinder.hta` und `run_password_finder.bat` im gleichen Ordner lassen.
2. Doppelklick auf `run_password_finder.bat` (oder direkt auf `PasswordFinder.hta`).
3. Es öffnet sich die App mit GUI.

## Funktionen

- Passwort-Eingabe (maskiert)
- Checkbox „Sichtbar“, um Passwortzeichen anzuzeigen
- Dropdown für Zeichensystem:
  - Buchstaben + Zahlen
  - ASCII inkl. Sonderzeichen
  - Erweitert inkl. häufiger Akzentzeichen (z. B. ä, ö, ü, ß, à, á, â, î, ó, ò …)
- Start-Button: systematisches Durchprobieren aller Kombinationen
- Live-Anzeige des aktuell getesteten Strings
- Laufende Zeitmessung
- Anzeige der Anzahl an Versuchen
- Abbrechen-Button während der Ausführung
- Während der Ausführung sind Passwortfeld, Sichtbarkeits-Checkbox und Zeichensatz-Auswahl gesperrt

## Hinweise

- Die Suche läuft bis zur **Länge des eingegebenen Passworts**.
- Große Zeichensätze und längere Passwörter führen zu sehr langen Laufzeiten (exponentielles Wachstum).
- Die App ist in sich geschlossen und verändert keine anderen Programme.
