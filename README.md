# lg_emergencycontrols

Eigenstaendige FiveM-Resource fuer getrennte Steuerung von Blaulicht und Martinshorn.

## Bedienung

- **Linkes ALT**: Blaulicht AN / AUS
- **Q**: Martinshorn AN / AUS (nur wenn Blaulicht an ist)
- **R kurz druecken**: normalen Martinshorn-Ton wechseln
- **R gedrueckt halten**: Powercall temporaer abspielen
- **R loslassen**: der normale Martinshorn-Ton wird genau an seiner inzwischen erreichten Abspielposition wieder hoerbar

Die normalen, mit kurzem R wechselbaren Toene sind:

1. Wail
2. Yelp
3. Hi-Lo

Powercall ist kein vierter dauerhaft ausgewaehlter Ton mehr. Er wird nur aktiviert, solange R lange gehalten wird. Standardmaessig gilt ein Druck ab 450 ms als Langdruck. Das kann in `config.lua` ueber `Config.PowercallHoldMs` angepasst werden.

Der Powercall nutzt den bereits in GTA V vorhandenen Sound `VEHICLES_HORNS_AMBULANCE_WARNING`. Es ist dafuer keine zusaetzliche Audio-Datei erforderlich.

### Nahtloser Wechsel nach Powercall

Der normale Martinshorn-Ton wird beim Start des Powercalls nicht gestoppt oder neu gestartet. Er laeuft intern weiter und wird waehrend des Powercalls nur stummgeschaltet. Beim Loslassen von R wird derselbe laufende Sound wieder eingeblendet. Dadurch beginnt Wail/Yelp/Hi-Lo nicht wieder von vorne.

### Verhalten beim Aussteigen

Beim Verlassen des Fahrersitzes werden **Martinshorn und Powercall immer ausgeschaltet**. Der Zustand des Blaulichts wird dabei nicht veraendert.

Beispiel:

```text
Blaulicht AN + Martinshorn AN
-> Fahrer steigt aus
-> Blaulicht bleibt AN
-> Martinshorn AUS
```

Die Resource erkennt sowohl normales Aussteigen als auch Situationen, in denen ein anderes Script den Spieler aus dem Fahrersitz entfernt, z. B. durch Tod, Teleport oder `TaskLeaveVehicle`.

Die Tasten werden mit `RegisterKeyMapping` registriert und koennen von Spielern in den FiveM-Tastatureinstellungen geaendert werden.

## Besonderheiten

- Blaulicht und Martinshorn sind voneinander getrennt.
- Beim Ausschalten des Blaulichts wird das Martinshorn automatisch ausgeschaltet.
- Beim Aussteigen wird das Martinshorn immer ausgeschaltet; Blaulicht darf an bleiben.
- Der ausgewaehlte normale Martinshorn-Ton bleibt beim Powercall erhalten und laeuft zeitlich weiter.
- Fahrzeuge koennen komplett von der Steuerung ausgeschlossen werden.
- Fahrzeuge wie Abschlepper koennen Licht benutzen, waehrend Q und R gesperrt sind.
- GTA-`DistantCopCarSirens` werden deaktiviert, damit keine kuenstlichen Sirenen aus grosser Entfernung zu hoeren sind.
- Sirenenzustand, Sirenenton und Powercall werden zwischen Spielern synchronisiert.
- Keine ESX-/QBCore-Abhaengigkeit.

## Installation

1. Resource als `lg_emergencycontrols` in den `resources`-Ordner legen.
2. In der `server.cfg` eintragen:

```cfg
ensure lg_emergencycontrols
```

3. Server/Resource neu starten.

## Fahrzeuge konfigurieren

In `config.lua`:

```lua
Config.NoSirenVehicles = {
    'flatbed',
    'towtruck',
    'towtruck2',
    'wrecker'
}
```

Diese Fahrzeuge duerfen das Licht mit linkem ALT schalten, haben aber kein Martinshorn ueber Q und keine R-Funktion.

Komplett ausschliessen:

```lua
Config.NoEmergencyControls = {
    'mein_fahrzeug'
}
```

Weitere Fahrzeuge erlauben, die nicht GTA-Fahrzeugklasse 18 sind:

```lua
Config.ExtraAllowedVehicles = {
    'mein_sonderfahrzeug'
}
```

## Powercall-Langdruck anpassen

```lua
Config.PowercallHoldMs = 450
```

Kleinerer Wert = Powercall startet schneller. Groesserer Wert = R muss laenger gehalten werden.

## Hinweis

Wenn bereits eine andere Resource die Sirenen-/ELS-Steuerung uebernimmt, koennen sich beide Resources gegenseitig beeinflussen. In diesem Fall sollte die bisherige Steuerung fuer dieselben Fahrzeuge deaktiviert werden.
