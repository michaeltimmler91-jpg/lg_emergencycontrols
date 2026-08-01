Config = {}

-- Standard-Tasten. Spieler koennen diese spaeter in den FiveM-Keybindings aendern.
Config.Keys = {
    Lights = 'RMENU', -- Rechts ALT
    Siren = 'Q',
    Tone = 'R'
}

-- Standardmaessig werden Fahrzeuge der GTA-Klasse 18 (Emergency) unterstuetzt.
Config.RequireEmergencyClass = true
Config.EmergencyClass = 18

-- Zusaetzliche Fahrzeuge, die die Steuerung benutzen duerfen.
-- Spawnnamen immer klein schreiben.
Config.ExtraAllowedVehicles = {
    -- 'mein_sonderfahrzeug'
}

-- Bei diesen Fahrzeugen funktioniert weder Blaulicht noch Martinshorn ueber diese Resource.
Config.NoEmergencyControls = {
    -- 'fahrzeug_ohne_steuerung'
}

-- Bei diesen Fahrzeugen funktioniert das Warn-/Blaulicht, aber KEIN Martinshorn.
-- Fahrzeuge in dieser Liste gelten automatisch als erlaubt, auch wenn sie nicht Klasse 18 sind.
Config.NoSirenVehicles = {
    'flatbed',
    'towtruck',
    'towtruck2',
    'wrecker'
}

-- Entfernt die kuenstlichen Sirenen, die GTA bei weit entfernten Einsatzfahrzeugen abspielt.
Config.DisableDistantCopCarSirens = true
Config.DistantSirenRefreshMs = 5000

Config.ShowNotifications = true

-- Eingebaute GTA-Sirenen. Keine zusaetzliche Sirenen-Resource erforderlich.
-- Mit R wird zyklisch durch diese Liste geschaltet.
Config.SirenTones = {
    {
        label = 'Wail',
        sound = 'RESIDENT_VEHICLES_SIREN_WAIL_01',
        soundSet = 0
    },
    {
        label = 'Yelp',
        sound = 'RESIDENT_VEHICLES_SIREN_QUICK_01',
        soundSet = 0
    },
    {
        label = 'Hi-Lo',
        sound = 'RESIDENT_VEHICLES_SIREN_QUICK_02',
        soundSet = 0
    },
    {
        label = 'Powercall',
        sound = 'VEHICLES_HORNS_AMBULANCE_WARNING',
        soundSet = 0
    }
}
