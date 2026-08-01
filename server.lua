local vehicleStates = {}
local recentDrivers = {}

local function sanitizeState(state)
    if type(state) ~= 'table' then return nil end

    local tone = tonumber(state.tone) or 1
    local maxTone = tonumber(Config.NormalSirenToneCount) or 3
    local available = #(Config.SirenTones or {})

    if maxTone < 1 then maxTone = 1 end
    if maxTone > available then maxTone = available end

    if tone < 1 then tone = 1 end
    if tone > maxTone then tone = 1 end

    return {
        lights = state.lights == true,
        siren = state.siren == true,
        tone = tone,
        powercall = state.powercall == true
    }
end

local function playerIsDriver(sourceId, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    local ped = GetPlayerPed(sourceId)
    if ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    return GetPedInVehicleSeat(vehicle, -1) == ped
end

RegisterNetEvent('lg_emergencycontrols:updateState', function(netId, state)
    local sourceId = source
    netId = tonumber(netId)

    if not netId or not playerIsDriver(sourceId, netId) then
        return
    end

    local cleanState = sanitizeState(state)
    if not cleanState then
        return
    end

    -- Sirene und Powercall duerfen ohne Licht nicht aktiv bleiben.
    if not cleanState.lights then
        cleanState.siren = false
        cleanState.powercall = false
    end

    if not cleanState.siren then
        cleanState.powercall = false
    end

    vehicleStates[netId] = cleanState

    -- Merkt sich kurz den letzten bestaetigten Fahrer. Das ist nur fuer den
    -- Exit-Fallback gedacht, wenn der Spieler beim Event bereits aus dem Sitz ist.
    recentDrivers[netId] = {
        source = sourceId,
        expiresAt = os.time() + 10
    }

    TriggerClientEvent('lg_emergencycontrols:syncState', -1, netId, cleanState)
end)

-- Fallback fuer erzwungenes Aussteigen, Tod, Teleport usw. Hier darf der zuletzt
-- bestaetigte Fahrer nur Sirene/Powercall ausschalten. Das Blaulicht bleibt erhalten.
RegisterNetEvent('lg_emergencycontrols:driverExited', function(netId)
    local sourceId = source
    netId = tonumber(netId)
    if not netId then return end

    local driver = recentDrivers[netId]
    if not driver then return end
    if driver.source ~= sourceId then return end
    if driver.expiresAt < os.time() then
        recentDrivers[netId] = nil
        return
    end

    local state = vehicleStates[netId]
    if not state then
        recentDrivers[netId] = nil
        return
    end

    state.siren = false
    state.powercall = false
    vehicleStates[netId] = state
    recentDrivers[netId] = nil

    TriggerClientEvent('lg_emergencycontrols:syncState', -1, netId, state)
end)

RegisterNetEvent('lg_emergencycontrols:requestSync', function()
    TriggerClientEvent('lg_emergencycontrols:syncAll', source, vehicleStates)
end)

CreateThread(function()
    while true do
        Wait(30000)

        local now = os.time()

        for netId in pairs(vehicleStates) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if vehicle == 0 or not DoesEntityExist(vehicle) then
                vehicleStates[netId] = nil
                recentDrivers[netId] = nil
            end
        end

        for netId, driver in pairs(recentDrivers) do
            if driver.expiresAt < now then
                recentDrivers[netId] = nil
            end
        end
    end
end)
