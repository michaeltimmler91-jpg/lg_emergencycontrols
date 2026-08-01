Config = {}

-- Standard-Tasten. Spieler koennen diese spaeter in den FiveM-Keybindings aendern.
Config.Keys = {
    Lights = 'LMENU', -- Linkes ALT
    Siren = 'Q',
    Tone = 'R',
    Tone1 = '1',
    Tone2 = '2',
    Tone3 = '3',
    Tone4 = '4'
}

-- R kurz: normalen Martinshorn-Ton wechseln.
-- R lange halten: temporaer Powercall, beim Loslassen zurueck zum laufenden normalen Ton.
Config.PowercallHoldMs = 450
Config.NormalSirenToneCount = 4
Config.PowercallToneIndex = 5

-- Der normale Ton wird waehrend Powercall NICHT gestoppt, sondern nur stumm geschaltet.
-- Dadurch laeuft seine Abspielposition weiter und setzt danach nahtlos fort.
Config.SirenMuteVariable = 'Loudness'
Config.SirenMutedValue = 0.0
Config.SirenNormalValue = 1.0

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
-- Die ersten vier Toene sind die normalen Favoriten-Toene.
-- Ton 4 ist aktuell eine GTA-basierte Q-Siren-Naeherrung und kann spaeter 1:1
-- gegen ein eigenes Audio-Pack getauscht werden, ohne die Bedienlogik anzufassen.
-- Ton 5 ist nur der temporaere Powercall bei langem Druck auf R.
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
        label = 'Q-Siren',
        sound = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01',
        soundSet = 0
    },
    {
        label = 'Powercall',
        sound = 'VEHICLES_HORNS_AMBULANCE_WARNING',
        soundSet = 0
    }
}
