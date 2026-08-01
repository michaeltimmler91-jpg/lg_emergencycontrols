# lg_emergencycontrols

Eigenstaendige FiveM-Resource fuer getrennte Steuerung von Blaulicht und Martinshorn.

## Bedienung

- **Rechts ALT**: Blaulicht AN / AUS
- **Q**: Martinshorn AN / AUS (nur wenn Blaulicht an ist)
- **R**: Martinshorn-Ton wechseln

Mit **R** wird aktuell durch folgende vier Toene geschaltet:

1. Wail
2. Yelp
3. Hi-Lo
4. Powercall

Der Powercall nutzt den bereits in GTA V vorhandenen Sound `VEHICLES_HORNS_AMBULANCE_WARNING`. Es ist dafuer keine zusaetzliche Audio-Datei erforderlich.

Die Tasten werden mit `RegisterKeyMapping` registriert und koennen von Spielern in den FiveM-Tastatureinstellungen geaendert werden.

## Besonderheiten

- Blaulicht und Martinshorn sind voneinander getrennt.
- Beim Ausschalten des Blaulichts wird das Martinshorn automatisch ausgeschaltet.
- Fahrzeuge koennen komplett von der Steuerung ausgeschlossen werden.
- Fahrzeuge wie Abschlepper koennen Licht benutzen, waehrend Q und R gesperrt sind.
- GTA-`DistantCopCarSirens` werden deaktiviert, damit keine kuenstlichen Sirenen aus grosser Entfernung zu hoeren sind.
- Sirenenzustand und Sirenenton werden zwischen Spielern synchronisiert.
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

Diese Fahrzeuge duerfen das Licht mit Rechts ALT schalten, haben aber kein Martinshorn ueber Q und keinen Tonwechsel ueber R.

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

## Hinweis

Wenn bereits eine andere Resource die Sirenen-/ELS-Steuerung uebernimmt, koennen sich beide Resources gegenseitig beeinflussen. In diesem Fall sollte die bisherige Steuerung fuer dieselben Fahrzeuge deaktiviert werden.
