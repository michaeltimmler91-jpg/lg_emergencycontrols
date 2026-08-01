local vehicleStates = {}
local activeSounds = {}
local activeSoundTones = {}

local noControlModels = {}
local noSirenModels = {}
local extraAllowedModels = {}

local function buildModelSet(list)
    local set = {}
    for _, modelName in ipairs(list or {}) do
        set[joaat(modelName)] = true
    end
    return set
end

CreateThread(function()
    noControlModels = buildModelSet(Config.NoEmergencyControls)
    noSirenModels = buildModelSet(Config.NoSirenVehicles)
    extraAllowedModels = buildModelSet(Config.ExtraAllowedVehicles)
end)

local function notify(message)
    if not Config.ShowNotifications then return end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

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

local function stopSirenSound(netId)
    local soundId = activeSounds[netId]
    if not soundId then return end

    StopSound(soundId)
    ReleaseSoundId(soundId)
    activeSounds[netId] = nil
    activeSoundTones[netId] = nil
end

local function startSirenSound(netId, vehicle, toneIndex)
    local tone = Config.SirenTones[toneIndex]
    if not tone then return end

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

local function applyState(netId, state)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        stopSirenSound(netId)
        return
    end

    -- Die GTA-Standardsirene bleibt stumm. Den Ton spielen wir selbst,
    -- damit Licht und Martinshorn wirklich getrennt bleiben.
    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, state.lights == true)

    if state.lights and state.siren and not isNoSirenVehicle(vehicle) then
        startSirenSound(netId, vehicle, state.tone or 1)
    else
        stopSirenSound(netId)
    end
end

local function sendState(vehicle, state)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return end

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
            tone = 1
        }
        vehicleStates[netId] = state
    end

    return netId, state
end

RegisterNetEvent('lg_emergencycontrols:syncState', function(netId, state)
    netId = tonumber(netId)
    if not netId or type(state) ~= 'table' then return end

    vehicleStates[netId] = state
    applyState(netId, state)
end)

RegisterNetEvent('lg_emergencycontrols:syncAll', function(states)
    if type(states) ~= 'table' then return end

    vehicleStates = states

    for netId, state in pairs(vehicleStates) do
        applyState(tonumber(netId), state)
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
        tone = state.tone or 1
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
        tone = state.tone or 1
    })

    notify(newSiren and '~r~Martinshorn AN' or '~s~Martinshorn AUS')
end, false)

RegisterCommand('-lg_emergency_siren', function() end, false)

RegisterCommand('+lg_emergency_tone', function()
    local vehicle = getDriverVehicle()
    if vehicle == 0 or isNoSirenVehicle(vehicle) then return end

    local _, state = currentState(vehicle)

    if not state.lights or not state.siren then
        return
    end

    local toneCount = #(Config.SirenTones or {})
    if toneCount < 2 then return end

    local nextTone = (state.tone or 1) + 1
    if nextTone > toneCount then
        nextTone = 1
    end

    sendState(vehicle, {
        lights = true,
        siren = true,
        tone = nextTone
    })

    local tone = Config.SirenTones[nextTone]
    notify(('~r~Martinshorn:~s~ %s'):format(tone.label or nextTone))
end, false)

RegisterCommand('-lg_emergency_tone', function() end, false)

RegisterKeyMapping('+lg_emergency_lights', 'Blaulicht AN / AUS', 'keyboard', Config.Keys.Lights)
RegisterKeyMapping('+lg_emergency_siren', 'Martinshorn AN / AUS', 'keyboard', Config.Keys.Siren)
RegisterKeyMapping('+lg_emergency_tone', 'Martinshorn-Ton wechseln', 'keyboard', Config.Keys.Tone)

-- Verhindert, dass GTA parallel mit E/Q/R seine eigenen Fahrzeugfunktionen ausloest.
CreateThread(function()
    while true do
        local sleep = 500
        local vehicle = getDriverVehicle()

        if vehicle ~= 0 then
            sleep = 0
            DisableControlAction(0, 86, true) -- E / Fahrzeughupe bzw. Standard-Sirenenbedienung
            DisableControlAction(0, 85, true) -- Q / Radio-Wheel
            DisableControlAction(0, 80, true) -- R / Cinematic Camera
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

-- Wenn ein bereits synchronisiertes Fahrzeug erst spaeter in den Streaming-Bereich kommt,
-- wird der gespeicherte Zustand hier erneut angewendet.
CreateThread(function()
    while true do
        Wait(1000)

        for netId, state in pairs(vehicleStates) do
            local numericNetId = tonumber(netId)
            local vehicle = NetworkGetEntityFromNetworkId(numericNetId)

            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                applyState(numericNetId, state)
            else
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
