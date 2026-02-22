# budsBags - Projektübersicht & Spezifikation

## Allgemeines
**Projektname:** budsBags
**Spiel:** World of Warcraft (Privatserver)
**Patch-Version:** 3.3.5 / 3.3.5a

**Ziel-Server & Ressourcen:**
- **Privat Server:** [Ascension.gg](https://ascension.gg/)
- **Bespielter Server:** [Bronzebeard](https://project-ascension.fandom.com/wiki/Bronzebeard)
- **Server DB:** [Ascension DB](https://db.ascension.gg/)
- **Server Wiki:** [Project Ascension Wiki](https://project-ascension.fandom.com/wiki/Project_Ascension_Wiki)

## Bezugnahme auf budsUI
Das Addon ordnet sich in das "Budtender Universum" ein.
- **Design:** Nutzung von WoW Standard UI Elementen und stark orientiert an einem "Bagnon-Style" Interface (eine zusammenhängende, große Tasche).
- Es soll **unabhängig** (standalone) funktionieren können, auch wenn budsUI nicht installiert ist.

## Kernfunktionen (MVP)
budsBags ist ein umfassendes Taschen- und Inventar-Addon, das Geschwindigkeit, Übersichtlichkeit und Auto-Sortierung vereint.

1. **Interface & Design:**
   - **Bagnon-Style Interface:** Alle Taschen (Rucksack und ausgerüstete Taschen) werden als ein einziges, großes und zusammenhängendes Fenster dargestellt. Oben Standard-Buttons (Schließen, Suchen).
   - **Item Level Anzeige:** Direkte Anzeige des Item-Levels (Gegenstandsstufe) gut lesbar direkt auf dem Item-Icon in der Taschenansicht.

2. **Sortierung & Performance:**
   - **ElvUI-Style Sortiergeschwindigkeit:** Sehr schnelle und performante Sortieralgorithmen, um Lade-Ruckler (Lags) beim Sortieren großer Inventare zu vermeiden.

3. **Auto-Sortierung & Kategorisierung (ArkInventory-Style):**
   - **Regelbasierte Gruppen:** Items werden automatisch in visuell abgetrennte Gruppen oder Kategorien aufgeteilt (z.B. "Materialien", "Ausrüstung/Gear", "Verbrauchsgüter", "Quest-Items", "Müll/Trash").
   - **Visuelle Trennung:** Diese Kategorien sind innerhalb des großen Taschenfensters durch Überschriften oder separate Boxen klar voneinander abgegrenzt.

## Technische Anforderungen & Entwicklungsrichtlinien (WoW 3.3.5a)

- **WoW API:** Frame-Definitionen, Backpack/Container APIs (z.B. `GetContainerNumSlots`, `GetContainerItemInfo`) und Event-Namen auf dem Stand von WotLK (3.3.5a). Das Item Level muss eventuell über Tooltip-Scanning oder Server-Daten (falls DB-abhängig) ausgelesen werden.
- **Dateistruktur:**
  - `budsBags.toc`: Metadaten (Version, Autor), `SavedVariables` für Profileinteilungen und Lade-Reihenfolge.
  - `Core.lua`: Event-Listener (z.B. `BAG_UPDATE`), Initialisierung und grundlegendes Setup.
  - `UI.lua`: Aufbau des Interfaces (Das große Hauptfenster, Container-Logik, Item-Buttons).
  - `Sorting.lua`: Die performanten Sortier-Mechaniken.
  - `Categories.lua`: Definition, Erkennung und Zuweisung der Item-Gruppen.
- **Versionierung:** Semantic Versioning ab `0.1.0-alpha`.
