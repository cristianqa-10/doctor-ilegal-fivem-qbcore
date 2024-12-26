local DOCTOR_PED = {}
local storedPoints = {}
Config = {}

local function resetDoctor(k)
    if DoesEntityExist(DOCTOR_PED[k]) then
        ClearPedTasksImmediately(DOCTOR_PED[k])
        -- Aquí no agregamos ninguna animación de sentarse, solo lo dejamos estático
        FreezeEntityPosition(DOCTOR_PED[k], true) -- El ped no se moverá después de realizar la acción
    end
end

function deleteDoctor()
    for i = 1, #storedPoints do
        if storedPoints[i] then
            storedPoints[i]:remove()
        end
    end
    for ped, _ in pairs(DOCTOR_PED) do
        if DoesEntityExist(DOCTOR_PED[ped]) then
            if GetResourceState('ox_target') == 'started' then
                exports.ox_target:removeLocalEntity(DOCTOR_PED[ped], 'Recibe tratamiento')
            else
                exports['qb-target']:RemoveTargetEntity(DOCTOR_PED[ped], 'Recibe tratamiento')
            end
            DeleteEntity(DOCTOR_PED[ped])
        end
    end
    table.wipe(DOCTOR_PED)
    table.wipe(storedPoints)
    table.wipe(Config)
end

local function spawnDoctor(data)
    if not DoesEntityExist(DOCTOR_PED[data.index]) then
        local v = data.pedData
        local model = joaat(v.model)
        lib.requestModel(model, 5000)
        DOCTOR_PED[data.index] = CreatePed(0, model, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, false, false)

        SetEntityAsMissionEntity(DOCTOR_PED[data.index], true, true)
        SetPedFleeAttributes(DOCTOR_PED[data.index], 0, 0)
        SetBlockingOfNonTemporaryEvents(DOCTOR_PED[data.index], true)
        SetEntityInvincible(DOCTOR_PED[data.index], true)
        FreezeEntityPosition(DOCTOR_PED[data.index], true) -- El ped no se moverá
        SetModelAsNoLongerNeeded(model)

        -- Eliminamos la animación de sentarse
        -- No pedimos ni ejecutamos ninguna animación de sentarse

        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:addLocalEntity(DOCTOR_PED[data.index], {
                {
                    icon = 'fa-solid fa-house-medical',
                    label = 'Get Treated',
                    onSelect = function()
                        local success = lib.callback.await('randol_doctor:server:useDoctor', false, data.index)
                        if success then
                            DoNotification('Estás siendo ayudado.', 'success')
                        end
                    end,
                    canInteract = function() return isPlyDead() end,
                    distance = 2.5
                }
            })
        else
            exports['qb-target']:AddTargetEntity(DOCTOR_PED[data.index], {
                options = {
                    { 
                        icon = 'fa-solid fa-house-medical',
                        label = 'Get Treated',
                        action = function()
                            local success = lib.callback.await('randol_doctor:server:useDoctor', false, data.index)
                            if success then
                                DoNotification('Estás siendo ayudado.', 'success')
                            end
                        end,
                        canInteract = function() return isPlyDead() end,
                    },
                },
                distance = 2.5 
            })
        end
    end
end

local function yeetDoctor(data)
    if DoesEntityExist(DOCTOR_PED[data.index]) then
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:removeLocalEntity(DOCTOR_PED[data.index], 'Recibe tratamiento')
        else
            exports['qb-target']:RemoveTargetEntity(DOCTOR_PED[data.index], 'Recibe tratamiento')
        end
        DeleteEntity(DOCTOR_PED[data.index])
        DOCTOR_PED[data.index] = nil
    end
end

local function createDoctorPoints()
    for id, data in pairs(Config.locations) do
        local zone = lib.points.new({
            coords = data.coords,
            distance = 30,
            index = id,
            pedData = data,
            onEnter = spawnDoctor,
            onExit = yeetDoctor,
        })
        storedPoints[#storedPoints+1] = zone
    end
end

RegisterNetEvent('randol_doctor:client:cacheConfig', function(data)
    if GetInvokingResource() or not hasPlyLoaded() then return end
    Config = data
    createDoctorPoints()
end)

RegisterNetEvent('randol_doctor:client:attemptRevive', function(k)
    if GetInvokingResource() or not k then return end
    local coords = GetOffsetFromEntityInWorldCoords(DOCTOR_PED[k], 0.0, 0.5, 0.0)
    local name = Config.locations[k].name
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z-1.0)
    if lib.progressCircle({
        duration = Config.duration,
        position = 'bottom',
        label = ('%s está curando tus heridas..'):format(name),
        useWhileDead = true,
        canCancel = false,
        disable = { move = true, car = true, mouse = false, combat = true, },
    }) then
        local success = lib.callback.await('randol_doctor:server:revivePlayer', false, k)
        if success then
            DoNotification(('Has sido curado por %s.'):format(name), 'success')
        end
    end
end)

RegisterNetEvent('randol_doctor:client:syncAnim', function(k)
    if GetInvokingResource() or not k then return end

    -- Cambiamos la animación de tratamiento a la de agacharse
    TaskStartScenarioInPlace(DOCTOR_PED[k], 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

    SetTimeout(Config.duration, function()
        resetDoctor(k)
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deleteDoctor()
    end
end)
