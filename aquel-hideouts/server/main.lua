local ApartmentObjects = {}
local QBCore = exports['qb-core']:GetCoreObject()

-- Functions

local function CreateApartmentId(type)
    local UniqueFound = false
    local AparmentId = nil

    while not UniqueFound do
        AparmentId = tostring(math.random(1, 9999))
        local result = MySQL.query.await('SELECT COUNT(*) as count FROM hideouts WHERE name = ?', { tostring(type .. AparmentId) })
        if result[1].count == 0 then
            UniqueFound = true
        end
    end
    return AparmentId
end

local function GetApartmentInfo(apartmentId)
    local retval = nil
    local result = MySQL.query.await('SELECT * FROM hideouts WHERE name = ?', { apartmentId })
    if result[1] ~= nil then
        retval = result[1]
    end
    return retval
end

-- Events

RegisterNetEvent('hideouts:server:SetInsideMeta', function(house, insideId, bool, isVisiting)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local insideMeta = Player.PlayerData.metadata['inside']

    if bool then
        local routeId = insideId:gsub('[^%-%d]', '')
        if not isVisiting then
            insideMeta.apartment.apartmentType = house
            insideMeta.apartment.apartmentId = insideId
            insideMeta.house = nil
            Player.Functions.SetMetaData('inside', insideMeta)
        end
        QBCore.Functions.SetPlayerBucket(src, tonumber(routeId))
    else
        insideMeta.apartment.apartmentType = nil
        insideMeta.apartment.apartmentId = nil
        insideMeta.house = nil


        Player.Functions.SetMetaData('inside', insideMeta)
        QBCore.Functions.SetPlayerBucket(src, 0)
    end
end)

RegisterNetEvent('hideouts:returnBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

RegisterNetEvent('hideouts:server:openStash', function(CurrentApartment)
    local src = source
    exports['qb-inventory']:OpenInventory(src, CurrentApartment)
end)

local function GenerateNextPaymentDate()
    local timeShift = 7 * 24 * 60 * 60
    return os.date('%x', os.time() + timeShift)
end

local function GetStashSlotCount(orgname)
    local result = 50
    local tabletupgrades = json.decode(MySQL.single.await('SELECT tabletupgrades FROM organizations WHERE name = ? LIMIT 1', { orgname }).tabletupgrades)

    for _,v in pairs(tabletupgrades) do
        if v.name == "Slots in a stash" and v.unlocked == false then
            v.unlocked = true
            MySQL.update('UPDATE organizations SET tabletupgrades = ? WHERE name = ?', { json.encode(tabletupgrades), orgname })
        end
        if v.name == "Slots in a stash" and v.purchased then
            result = 100
        end
    end

    return result
end

RegisterNetEvent('hideouts:server:updateStashRegister', function(orgname)
    local result = MySQL.single.await('SELECT * FROM hideouts WHERE organization = ?', { orgname })
    if result then
        exports.ox_inventory:RegisterStash("org_" .. orgname, "Szafka organizacji", GetStashSlotCount(orgname), 200000, false)
    end
end)

RegisterNetEvent('hideouts:server:UpdateApartment', function(name, type, label)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local num = CreateApartmentId(type)
    MySQL.update('UPDATE hideouts SET type = ?, label = ? WHERE organization = ?', { type, label, Player.PlayerData.gang.name })
    MySQL.insert('INSERT INTO hideouts (name, type, label, organization, nextpayment) VALUES (?, ?, ?, ?, ?)', {
        name,
        type,
        label,
        Player.PlayerData.gang.name,
        GenerateNextPaymentDate()
    })
    
    exports.ox_inventory:RegisterStash("org_" .. Player.PlayerData.gang.name, "Szafka organizacji", GetStashSlotCount(Player.PlayerData.gang.name), 200000, false)
    TriggerClientEvent('QBCore:Notify', src, "Przeniesiono bazę")
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local organizations = MySQL.query.await('SELECT * FROM hideouts', { })
        local today = os.date('%x')

        for _, v in pairs(organizations) do
            if v.nextpayment == today then
                local result = MySQL.single.await('SELECT walletid FROM organizations WHERE name = ?', { v.organization })
                if result then 
                    local data = MySQL.single.await('SELECT amount FROM aquel_crypto WHERE wallet_id = ?', { result.walletid })

                    if tonumber(data.amount) < tonumber(Apartments.Payment) then
                        MySQL.single.await('DELETE FROM hideouts WHERE organization = ? LIMIT 1', { v.organization })
                    else
                        local success = MySQL.update.await('UPDATE aquel_crypto SET amount = ? WHERE wallet_id = ?', { data.amount - Apartments.Payment, result.walletid })
                        MySQL.update('UPDATE hideouts SET nextpayment = ? WHERE organization = ?', { GenerateNextPaymentDate(), v.organization })
                    end
                end
            end

            exports.ox_inventory:RegisterStash('org_' .. v.organization, "Szafka organizacji", GetStashSlotCount(v.organization), 200000)
        end
    end
end)

RegisterNetEvent('hideouts:server:RingDoor', function(apartmentId, apartment)
    local src = source
    if ApartmentObjects[apartment].apartments[apartmentId] ~= nil and next(ApartmentObjects[apartment].apartments[apartmentId].players) ~= nil then
        for k, _ in pairs(ApartmentObjects[apartment].apartments[apartmentId].players) do
            TriggerClientEvent('hideouts:client:RingDoor', k, src)
        end
    end
end)

RegisterNetEvent('hideouts:server:OpenDoor', function(target, apartmentId, apartment)
    local OtherPlayer = QBCore.Functions.GetPlayer(target)
    if OtherPlayer ~= nil then
        TriggerClientEvent('hideouts:client:SpawnInApartment', OtherPlayer.PlayerData.source, apartmentId, apartment)
    end
end)

RegisterNetEvent('hideouts:server:AddObject', function(apartmentId, apartment, offset)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil and ApartmentObjects[apartment].apartments[apartmentId] ~= nil then
        ApartmentObjects[apartment].apartments[apartmentId].players[src] = Player.PlayerData.citizenid
    else
        if ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil then
            ApartmentObjects[apartment].apartments[apartmentId] = {}
            ApartmentObjects[apartment].apartments[apartmentId].offset = offset
            ApartmentObjects[apartment].apartments[apartmentId].players = {}
            ApartmentObjects[apartment].apartments[apartmentId].players[src] = Player.PlayerData.citizenid
        else
            ApartmentObjects[apartment] = {}
            ApartmentObjects[apartment].apartments = {}
            ApartmentObjects[apartment].apartments[apartmentId] = {}
            ApartmentObjects[apartment].apartments[apartmentId].offset = offset
            ApartmentObjects[apartment].apartments[apartmentId].players = {}
            ApartmentObjects[apartment].apartments[apartmentId].players[src] = Player.PlayerData.citizenid
        end
    end
end)

RegisterNetEvent('hideouts:server:RemoveObject', function(apartmentId, apartment)
    local src = source
    if ApartmentObjects[apartment].apartments[apartmentId].players ~= nil then
        ApartmentObjects[apartment].apartments[apartmentId].players[src] = nil
        if next(ApartmentObjects[apartment].apartments[apartmentId].players) == nil then
            ApartmentObjects[apartment].apartments[apartmentId] = nil
        end
    end
end)

RegisterNetEvent('hideouts:server:setCurrentApartment', function(ap)
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return end

    Player.Functions.SetMetaData('currentapartment', ap)
end)

-- Callbacks

QBCore.Functions.CreateCallback('hideouts:GetAvailableApartments', function(_, cb, apartment)
    local apartments = {}
    if ApartmentObjects ~= nil and ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil then
        for k, _ in pairs(ApartmentObjects[apartment].apartments) do
            if (ApartmentObjects[apartment].apartments[k] ~= nil and next(ApartmentObjects[apartment].apartments[k].players) ~= nil) then
                local apartmentInfo = GetApartmentInfo(k)
                apartments[k] = apartmentInfo.label
            end
        end
    end
    cb(apartments)
end)

QBCore.Functions.CreateCallback('hideouts:GetApartmentOffset', function(_, cb, apartmentId)
    local retval = 0
    if ApartmentObjects ~= nil then
        for k, _ in pairs(ApartmentObjects) do
            if (ApartmentObjects[k].apartments[apartmentId] ~= nil and tonumber(ApartmentObjects[k].apartments[apartmentId].offset) ~= 0) then
                retval = tonumber(ApartmentObjects[k].apartments[apartmentId].offset)
            end
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('hideouts:GetApartmentOffsetNewOffset', function(_, cb, apartment)
    local retval = Apartments.SpawnOffset
    if ApartmentObjects ~= nil and ApartmentObjects[apartment] ~= nil and ApartmentObjects[apartment].apartments ~= nil then
        for k, _ in pairs(ApartmentObjects[apartment].apartments) do
            if (ApartmentObjects[apartment].apartments[k] ~= nil) then
                retval = ApartmentObjects[apartment].apartments[k].offset + Apartments.SpawnOffset
            end
        end
    end
    cb(retval)
end)

QBCore.Functions.CreateCallback('hideouts:GetOwnedApartment', function(source, cb, organization)
    if organization ~= nil then
        local result = MySQL.query.await('SELECT * FROM hideouts WHERE organization = ?', { organization })
        if result[1] ~= nil then
            return cb(result[1])
        end
        return cb(nil)
    else
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local result = MySQL.query.await('SELECT * FROM hideouts WHERE organization = ?', { Player.PlayerData.gang.name })
        if result[1] ~= nil then
            return cb(result[1])
        end
        return cb(nil)
    end
end)

QBCore.Functions.CreateCallback('hideouts:IsOwner', function(source, cb, apartment)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player ~= nil then
        local result = MySQL.query.await('SELECT * FROM hideouts WHERE organization = ? AND name = ?', { Player.PlayerData.gang.name, apartment })
        if result[1] ~= nil then
            cb(true)
        else
            cb(false)
        end
    end
end)

QBCore.Functions.CreateCallback('hideouts:GetOutfits', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local result = MySQL.query.await('SELECT * FROM player_outfits WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
        end
    end
end)

QBCore.Functions.CreateCallback('hideouts:IsLocationAvaible', function(source, cb, apartment)
    local result = MySQL.query.await('SELECT * FROM hideouts WHERE name = ?', { apartment })
    if result[1] == nil then
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('hideouts:DoesOrganizationAlreadyHaveLocation', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local result = MySQL.query.await('SELECT * FROM hideouts WHERE organization = ?', { Player.PlayerData.gang.name })
        if result[1] ~= nil then
            cb(true)
        else
            cb(false)
        end
    end
end)


