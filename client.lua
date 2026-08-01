local vehicleStates = {}
local activeSounds = {}
local activeSoundTones = {}
local activePowercallSounds = {}

local noControlModels = {}
local noSirenModels = {}
local extraAllowedModels = {}

local tonePressToken = 0
local tonePressVehicle = 0
local tonePressPowercallActive = false
local trackedDriverVehicle = 0
local preferredTone = 1

local PREFERRED_TONE_KVP = 'lg_emergencycontrols_preferred_tone'

local function buildModelSet(list)
    local set = {}
    for _, modelName in ipairs(list or {}) do
        set[joaat(modelName)] = true
    end
    return set
end

local function notify(message)
    if not Config.ShowNotifications then return end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function getNormalToneCount()
    local configured = tonumber(Config.NormalSirenToneCount) or 4
    local available = #(Config.SirenTones or {})

    if configured < 1 then configured = 1 end
    if configured > available then configured = available end

    return configured
end

local function normalizeNormalTone(tone)
    local normalToneCount = getNormalToneCount()
    tone = tonumber(tone) or 1

    if tone < 1 or tone > normalToneCount then
        return 1
    end

    return tone
end

local function loadPreferredTone()
    local stored = GetResourceKvpInt(PREFERRED_TONE_KVP)

    if stored and stored > 0 then
        preferredTone = normalizeNormalTone(stored)
    else
        preferredTone = 1
    end
end

local function savePreferredTone(tone)
    preferredTone = normalizeNormalTone(tone)
    SetResourceKvpInt(PREFERRED_TONE_KVP, preferredTone)
    return preferredTone
end

CreateThread(function()
    noControlModels = buildModelSet(Config.NoEmergencyControls)
    noSirenModels = buildModelSet(Config.NoSirenVehicles)
    extraAllowedModels = buildModelSet(Config.ExtraAllowedVehicles)
    loadPreferredTone()
end)

local function isNoSirenVehicle(vehicle)
    return noSirenModels[GetEntityModel(vehicle)] == true
end

local function isControlledVehicle(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local model = GetEntityModel(vehicle)

    if noControlModels[model] then
        return false
    end

    -- Fahrzeuge aus der NoSiren-Liste duerfen das Licht trotzdem benutzen.
    if noSirenModels[model] then
        return true
    end

    if extraAllowedModels[model] then
        return true
    end

    if not Config.RequireEmergencyClass then
        return true
    end

    return GetVehicleClass(vehicle) == Config.EmergencyClass
end

local function getDriverVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return 0
    end

    if not isControlledVehicle(vehicle) then
        return 0
    end

    return vehicle
end

local function setBaseSirenMuted(netId, muted)
    local soundId = activeSounds[netId]
    if not soundId then return end

    local variableName = Config.SirenMuteVariable or 'Loudness'
    local value = muted and (Config.SirenMutedValue or 0.0) or (Config.SirenNormalValue or 1.0)
    SetVariableOnSound(soundId, variableName, value)
end

local function stopSirenSound(netId)
    local soundId = activeSounds[netId]
    if not soundId then return end

    StopSound(soundId)
    ReleaseSoundId(soundId)
    activeSounds[netId] = nil
    activeSoundTones[netId] = nil
end

local function startSirenSound(netId, vehicle, toneIndex)
    toneIndex = normalizeNormalTone(toneIndex)
    local tone = Config.SirenTones[toneIndex]
    if not tone then return end

    -- Derselbe laufende normale Ton wird nie neu gestartet.
    -- Dadurch bleibt seine Abspielposition auch waehrend Powercall erhalten.
    if activeSounds[netId] and activeSoundTones[netId] == toneIndex then
        return
    end

    stopSirenSound(netId)

    local soundId = GetSoundId()
    activeSounds[netId] = soundId
    activeSoundTones[netId] = toneIndex

    PlaySoundFromEntity(
        soundId,
        tone.sound,
        vehicle,
        tone.soundSet or 0,
        false,
        0
    )
end

local function stopPowercallSound(netId)
    local soundId = activePowercallSounds[netId]
    if not soundId then return end

    StopSound(soundId)
    ReleaseSoundId(soundId)
    activePowercallSounds[netId] = nil
end

local function startPowercallSound(netId, vehicle)
    if activePowercallSounds[netId] then
        return
    end

    local powercallToneIndex = tonumber(Config.PowercallToneIndex) or 5
    local tone = Config.SirenTones[powercallToneIndex]
    if not tone then return end

    local soundId = GetSoundId()
    activePowercallSounds[netId] = soundId

    PlaySoundFromEntity(
        soundId,
        tone.sound,
        vehicle,
        tone.soundSet or 0,
        false,
        0
    )
end

local function applyState(netId, state)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        stopPowercallSound(netId)
        stopSirenSound(netId)
        return
    end

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, state.lights == true)

    if state.lights and state.siren and not isNoSirenVehicle(vehicle) then
        local normalTone = normalizeNormalTone(state.tone)
        startSirenSound(netId, vehicle, normalTone)

        if state.powercall == true then
            -- Der normale Ton laeuft im Hintergrund zeitlich weiter und wird nur stumm.
            setBaseSirenMuted(netId, true)
            startPowercallSound(netId, vehicle)
        else
            stopPowercallSound(netId)
            setBaseSirenMuted(netId, false)
        end
    else
        stopPowercallSound(netId)
        stopSirenSound(netId)
    end
end

local function sendState(vehicle, state)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return end

    state.tone = normalizeNormalTone(state.tone)
    state.powercall = state.powercall == true

    vehicleStates[netId] = state
    applyState(netId, state)
    TriggerServerEvent('lg_emergencycontrols:updateState', netId, state)
end

local function currentState(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local state = vehicleStates[netId]

    if not state then
        state = {
            lights = false,
            siren = false,
            tone = preferredTone,
            powercall = false
        }
        vehicleStates[netId] = state
    end

    state.tone = normalizeNormalTone(state.tone)
    state.powercall = state.powercall == true

    return netId, state
end

local function cancelTonePress()
    tonePressToken = tonePressToken + 1
    tonePressVehicle = 0
    tonePressPowercallActive = false
end

local function setPreferredToneForVehicle(vehicle, tone, showNotification)
    if vehicle == 0 or not DoesEntityExist(vehicle) or isNoSirenVehicle(vehicle) then
        return
    end

    tone = savePreferredTone(tone)
    cancelTonePress()

    local _, state = currentState(vehicle)

    sendState(vehicle, {
        lights = state.lights == true,
        siren = state.siren == true,
        tone = tone,
        powercall = false
    })

    if showNotification then
        local toneConfig = Config.SirenTones[tone]
        notify(('~r~Martinshorn:~s~ %s'):format(toneConfig and toneConfig.label or tone))
    end
end

local function applyPreferredToneOnEntry(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) or isNoSirenVehicle(vehicle) then
        return
    end

    local _, state = currentState(vehicle)

    if state.tone == preferredTone and not state.powercall then
        return
    end

    sendState(vehicle, {
        lights = state.lights == true,
        siren = state.siren == true,
        tone = preferredTone,
        powercall = false
    })
end

local function stopSirenForExit(vehicle, useExitFallback)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return end

    local state = vehicleStates[netId]
    if type(state) ~= 'table' then return end

    if not state.siren and not state.powercall then return end

    local exitState = {
        lights = state.lights == true,
        siren = false,
        tone = normalizeNormalTone(state.tone),
        powercall = false
    }

    vehicleStates[netId] = exitState
    applyState(netId, exitState)
    cancelTonePress()

    if useExitFallback then
        TriggerServerEvent('lg_emergencycontrols:driverExited', netId)
    else
        TriggerServerEvent('lg_emergencycontrols:updateState', netId, exitState)
    end
end

RegisterNetEvent('lg_emergencycontrols:syncState', function(netId, state)
    netId = tonumber(netId)
    if not netId or type(state) ~= 'table' then return end

    state.tone = normalizeNormalTone(state.tone)
    state.powercall = state.powercall == true
    vehicleStates[netId] = state
    applyState(netId, state)
end)

RegisterNetEvent('lg_emergencycontrols:syncAll', function(states)
    if type(states) ~= 'table' then return end

    vehicleStates = states

    for netId, state in pairs(vehicleStates) do
        if type(state) == 'table' then
            state.tone = normalizeNormalTone(state.tone)
            state.powercall = state.powercall == true
            applyState(tonumber(netId), state)
        end
    end
end)

RegisterCommand('+lg_emergency_lights', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 then return end

    local _, state = currentState(vehicle)
    local newLights = not state.lights

    sendState(vehicle, {
        lights = newLights,
        siren = newLights and state.siren or false,
        tone = preferredTone,
        powercall = false
    })

    notify(newLights and '~b~Blaulicht AN' or '~s~Blaulicht AUS')
end, false)

RegisterCommand('-lg_emergency_lights', function() end, false)

RegisterCommand('+lg_emergency_siren', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 then return end

    if isNoSirenVehicle(vehicle) then
        notify('~y~Dieses Fahrzeug hat kein Martinshorn.')
        return
    end

    local _, state = currentState(vehicle)

    if not state.lights then
        notify('~y~Blaulicht muss zuerst eingeschaltet sein.')
        return
    end

    local newSiren = not state.siren

    sendState(vehicle, {
        lights = true,
        siren = newSiren,
        tone = preferredTone,
        powercall = false
    })

    notify(newSiren and '~r~Martinshorn AN' or '~s~Martinshorn AUS')
end, false)

RegisterCommand('-lg_emergency_siren', function() end, false)

RegisterCommand('+lg_emergency_tone', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 or isNoSirenVehicle(vehicle) then return end

    local _, state = currentState(vehicle)
    if not state.lights or not state.siren then return end

    tonePressToken = tonePressToken + 1
    local thisPressToken = tonePressToken

    tonePressVehicle = vehicle
    tonePressPowercallActive = false

    CreateThread(function()
        Wait(tonumber(Config.PowercallHoldMs) or 450)

        if tonePressToken ~= thisPressToken then return end
        if tonePressVehicle ~= vehicle then return end
        if getDriverVehicle() ~= vehicle then return end

        local _, current = currentState(vehicle)
        if not current.lights or not current.siren then return end

        tonePressPowercallActive = true

        sendState(vehicle, {
            lights = true,
            siren = true,
            tone = preferredTone,
            powercall = true
        })

        notify('~r~Powercall')
    end)
end, false)

RegisterCommand('-lg_emergency_tone', function()
    local vehicle = tonePressVehicle
    local wasPowercallActive = tonePressPowercallActive

    cancelTonePress()

    if vehicle == 0 or getDriverVehicle() ~= vehicle then return end

    local _, state = currentState(vehicle)
    if not state.lights or not state.siren then return end

    if wasPowercallActive then
        sendState(vehicle, {
            lights = true,
            siren = true,
            tone = preferredTone,
            powercall = false
        })
        return
    end

    local normalToneCount = getNormalToneCount()
    if normalToneCount < 2 then return end

    local nextTone = preferredTone + 1
    if nextTone > normalToneCount then
        nextTone = 1
    end

    savePreferredTone(nextTone)

    sendState(vehicle, {
        lights = true,
        siren = true,
        tone = preferredTone,
        powercall = false
    })

    local tone = Config.SirenTones[preferredTone]
    notify(('~r~Martinshorn:~s~ %s'):format(tone.label or preferredTone))
end, false)

RegisterCommand('+lg_emergency_tone1', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 then return end
    setPreferredToneForVehicle(vehicle, 1, true)
end, false)
RegisterCommand('-lg_emergency_tone1', function() end, false)

RegisterCommand('+lg_emergency_tone2', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 then return end
    setPreferredToneForVehicle(vehicle, 2, true)
end, false)
RegisterCommand('-lg_emergency_tone2', function() end, false)

RegisterCommand('+lg_emergency_tone3', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 then return end
    setPreferredToneForVehicle(vehicle, 3, true)
end, false)
RegisterCommand('-lg_emergency_tone3', function() end, false)

RegisterCommand('+lg_emergency_tone4', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 then return end
    setPreferredToneForVehicle(vehicle, 4, true)
end, false)
RegisterCommand('-lg_emergency_tone4', function() end, false)

RegisterKeyMapping('+lg_emergency_lights', 'Blaulicht AN / AUS', 'keyboard', Config.Keys.Lights)
RegisterKeyMapping('+lg_emergency_siren', 'Martinshorn AN / AUS', 'keyboard', Config.Keys.Siren)
RegisterKeyMapping('+lg_emergency_tone', 'Martinshorn wechseln / Powercall halten', 'keyboard', Config.Keys.Tone)
RegisterKeyMapping('+lg_emergency_tone1', 'Martinshorn direkt: Wail', 'keyboard', Config.Keys.Tone1)
RegisterKeyMapping('+lg_emergency_tone2', 'Martinshorn direkt: Yelp', 'keyboard', Config.Keys.Tone2)
RegisterKeyMapping('+lg_emergency_tone3', 'Martinshorn direkt: Hi-Lo', 'keyboard', Config.Keys.Tone3)
RegisterKeyMapping('+lg_emergency_tone4', 'Martinshorn direkt: Q-Siren', 'keyboard', Config.Keys.Tone4)

-- Beim normalen Aussteigen wird das Martinshorn ausgeschaltet, das Blaulicht bleibt an.
CreateThread(function()
    while true do
        local vehicle = getDriverVehicle()

        if vehicle ~= 0 then
            if IsControlJustPressed(0, 75) or IsDisabledControlJustPressed(0, 75) then
                stopSirenForExit(vehicle, false)
            end
            Wait(0)
        else
            Wait(150)
        end
    end
end)

-- Erkennt Fahrerwechsel. Beim Verlassen Sirene aus; beim Einsteigen persoenlichen
-- Lieblingssound auf das neue Fahrzeug uebernehmen.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local currentDriverVehicle = 0

        if vehicle ~= 0
            and DoesEntityExist(vehicle)
            and GetPedInVehicleSeat(vehicle, -1) == ped
            and isControlledVehicle(vehicle) then
            currentDriverVehicle = vehicle
        end

        if trackedDriverVehicle ~= 0 and trackedDriverVehicle ~= currentDriverVehicle then
            stopSirenForExit(trackedDriverVehicle, true)
        end

        if currentDriverVehicle ~= 0 and trackedDriverVehicle ~= currentDriverVehicle then
            applyPreferredToneOnEntry(currentDriverVehicle)
        end

        trackedDriverVehicle = currentDriverVehicle
        Wait(currentDriverVehicle ~= 0 and 50 or 100)
    end
end)

-- Verhindert parallele GTA-Funktionen auf unseren Sirenen-Tasten.
-- Die normale Fahrzeughupe (Control 86 / E) bleibt bewusst frei.
CreateThread(function()
    while true do
        local sleep = 500
        local vehicle = getDriverVehicle()

        if vehicle ~= 0 then
            sleep = 0
            DisableControlAction(0, 19, true)  -- Linkes ALT / Character Wheel
            DisableControlAction(0, 85, true)  -- Q / Radio-Wheel
            DisableControlAction(0, 80, true)  -- R / Cinematic Camera
            DisableControlAction(0, 157, true) -- 1 / Weapon Unarmed
            DisableControlAction(0, 158, true) -- 2 / Weapon Melee
            DisableControlAction(0, 160, true) -- 3 / Weapon Shotgun
            DisableControlAction(0, 164, true) -- 4 / Weapon Heavy
        end

        Wait(sleep)
    end
end)

-- GTA erzeugt sonst bei entfernten Polizeifahrzeugen teilweise kuenstliche Sirenen.
CreateThread(function()
    if not Config.DisableDistantCopCarSirens then return end

    while true do
        DistantCopCarSirens(false)
        Wait(Config.DistantSirenRefreshMs or 5000)
    end
end)

-- Gespeicherte Zustaende erneut anwenden, wenn Fahrzeuge in den Streaming-Bereich kommen.
CreateThread(function()
    while true do
        Wait(1000)

        for netId, state in pairs(vehicleStates) do
            local numericNetId = tonumber(netId)
            local vehicle = NetworkGetEntityFromNetworkId(numericNetId)

            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                applyState(numericNetId, state)
            else
                stopPowercallSound(numericNetId)
                stopSirenSound(numericNetId)
            end
        end
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('lg_emergencycontrols:requestSync')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for netId in pairs(activePowercallSounds) do
        stopPowercallSound(netId)
    end

    for netId in pairs(activeSounds) do
        stopSirenSound(netId)
    end

    for netId in pairs(vehicleStates) do
        local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId))
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            SetVehicleHasMutedSirens(vehicle, false)
        end
    end
end)