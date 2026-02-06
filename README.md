# Password Finder Testprojekt (Windows / WPF)

Dieses Projekt wurde neu aufgebaut und nutzt jetzt **PowerShell + WPF** für eine Windows-geeignete Desktop-Oberfläche.

## Starten auf Windows 11 (64 Bit)

1. `PasswordFinder.ps1` und `run_password_finder.bat` im gleichen Ordner belassen.
2. `run_password_finder.bat` per Doppelklick starten.
3. Die WPF-App öffnet sich direkt.

## UI und Funktionen

- Maskiertes Passwortfeld (ohne Sichtbarkeits-Haken).
- 4 auswählbare Kategorien (Checkboxen):
  - **Buchstaben**
  - **Zahlen**
  - **Sonderzeichen**
  - **Sonderbuchstaben**
- Während der Suche sind Passwortfeld und Kategorien gesperrt.
- Buttons:
  - **Start**: Beginnt den systematischen Suchlauf.
  - **Abbrechen**: Stoppt den laufenden Prozess jederzeit.
- Laufende Anzeige von:
  - Status
  - vergangener Zeit
  - Anzahl der Versuche
  - aktuell geprüftem String

## Suchlogik

- Der Algorithmus prüft systematisch alle Kombinationen.
- Es wird bis zur Länge des eingegebenen Passworts gesucht.
- Vor dem Start wird geprüft, ob alle Zeichen des Passworts in den aktivierten Kategorien enthalten sind.

## Hinweis

Große Zeichensätze und längere Passwörter führen zu sehr langen Laufzeiten (exponentielles Wachstum).
