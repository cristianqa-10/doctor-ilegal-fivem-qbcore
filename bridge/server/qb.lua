if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function GetPlayer(id)
    return QBCore.Functions.GetPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('QBCore:Notify', src, text, nType)
end

function GetCharacterName(Player)
    return Player.PlayerData.charinfo.firstname.. ' ' ..Player.PlayerData.charinfo.lastname
end

function RemovePlayerMoney(Player, amount, moneyType)
    local balance = Player.Functions.GetMoney(moneyType)
    if balance >= amount then
        Player.Functions.RemoveMoney(moneyType, amount, "doctor-fee")
        return true
    end
    return false
end

function handleRevive(src)
    if GetResourceState('qbx_medical') == 'started' then 
        TriggerClientEvent('qbx_medical:client:playerRevived', src)
    else
        TriggerClientEvent('hospital:client:Revive', src)
    end
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    PlayerHasLoaded(source)
end)