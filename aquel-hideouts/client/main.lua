local QBCore = exports['qb-core']:GetCoreObject()
local UseTarget = GetConvar('UseTarget', 'false') == 'true'
local InApartment = false
local ClosestHouse = nil
local CurrentApartment = nil
local IsOwned = false
local CurrentDoorBell = 0
local CurrentOffset = 0
local HouseObj = {}
local POIOffsets = nil
local RangDoorbell = nil

-- target variables
local InApartmentTargets = {}

-- polyzone variables
local IsInsideEntranceZone = false
local IsInsideExitZone = false
local IsInsideStashZone = false
local IsInsideOutfitsZone = false
local IsInsideLogoutZone = false

-- polyzone integration

local function OpenEntranceMenu()
    local headerMenu = {}

    if IsOwned then
        headerMenu[#headerMenu + 1] = {
            header = "Wejdź do bazy",
            params = {
                event = 'hideouts:client:EnterApartment',
                args = {}
            }
        }
    elseif not IsOwned then
        headerMenu[#headerMenu + 1] = {
            header = "Przenieś bazę",
            params = {
                event = 'hideouts:client:UpdateApartment',
                args = {}
            }
        }
    end

    headerMenu[#headerMenu + 1] = {
        header = "Zadzwoń",
        params = {
            event = 'hideouts:client:DoorbellMenu',
            args = {}
        }
    }

    headerMenu[#headerMenu + 1] = {
        header = "Zamknij",
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    }

    exports['qb-menu']:openMenu(headerMenu)
end

local function OpenExitMenu()
    local headerMenu = {}

    headerMenu[#headerMenu + 1] = {
        header = "Otwórz drzwi",
        params = {
            event = 'hideouts:client:OpenDoor',
            args = {}
        }
    }

    headerMenu[#headerMenu + 1] = {
        header = "Wyjdź",
        params = {
            event = 'hideouts:client:LeaveApartment',
            args = {}
        }
    }

    headerMenu[#headerMenu + 1] = {
        header = "Zamknij menu",
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    }

    exports['qb-menu']:openMenu(headerMenu)
end

-- exterior entrance (polyzone)

local function RegisterApartmentEntranceZone(apartmentID, apartmentData)
    local coords = apartmentData.coords['enter']
    local boxName = 'apartmentEntrance_' .. apartmentID
    local boxData = apartmentData.polyzoneBoxData

    if boxData.created then
        return
    end

    local zone = BoxZone:Create(coords, boxData.length, boxData.width, {
        name = boxName,
        heading = 340.0,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = false
    })

    zone:onPlayerInOut(function(isPointInside)
        if isPointInside and not InApartment then
            exports['qb-core']:DrawText("Opcje", 'left')
        else
            exports['qb-core']:HideText()
        end
        IsInsideEntranceZone = isPointInside
    end)

    boxData.created = true
    boxData.zone = zone
end

-- exterior entrance (target)

local function RegisterApartmentEntranceTarget(apartmentID, apartmentData)
    local coords = apartmentData.coords['enter']
    local boxName = 'apartmentEntrance_' .. apartmentID
    local boxData = apartmentData.polyzoneBoxData

    if boxData.created then
        return
    end

    local options = {}
    if QBCore.Functions.GetPlayerData().gang.name ~= 'none' then
        if apartmentID == ClosestHouse and IsOwned then
            options = {
                {
                    type = 'client',
                    event = 'hideouts:client:EnterApartment',
                    icon = 'fas fa-door-open',
                    label = "Wejdź do bazy",
                },
            }
        else
            options = {
                {
                    type = 'client',
                    event = 'hideouts:client:UpdateApartment',
                    icon = 'fas fa-hotel',
                    label = "Przenieś bazę",
                }
            }
        end
    end

    options[#options + 1] = {
        type = 'client',
        event = 'hideouts:client:DoorbellMenu',
        icon = 'fas fa-concierge-bell',
        label = "Zadzwoń",
    }

    exports['qb-target']:AddBoxZone(boxName, coords, boxData.length, boxData.width, {
        name = boxName,
        heading = boxData.heading,
        debugPoly = boxData.debug,
        minZ = boxData.minZ,
        maxZ = boxData.maxZ,
    }, {
        options = options,
        distance = boxData.distance
    })

    boxData.created = true
end

-- interior interactable points (polyzone)

local function RegisterInApartmentZone(targetKey, coords, heading, text)
    if not InApartment then
        return
    end

    if InApartmentTargets[targetKey] and InApartmentTargets[targetKey].created then
        return
    end

    Wait(1500)

    local boxName = 'inApartmentTarget_' .. targetKey

    local zone = BoxZone:Create(coords, 1.5, 1.5, {
        name = boxName,
        heading = heading,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = false
    })

    zone:onPlayerInOut(function(isPointInside)
        if isPointInside and text then
            exports['qb-core']:DrawText(text, 'left')
        else
            exports['qb-core']:HideText()
        end

        if targetKey == 'entrancePos' then
            IsInsideExitZone = isPointInside
        end

        if targetKey == 'stashPos' then
            IsInsideStashZone = isPointInside
        end

        if targetKey == 'outfitsPos' then
            IsInsideOutfitsZone = isPointInside
        end
    end)

    InApartmentTargets[targetKey] = InApartmentTargets[targetKey] or {}
    InApartmentTargets[targetKey].created = true
    InApartmentTargets[targetKey].zone = zone
end

-- interior interactable points (target)

local function RegisterInApartmentTarget(targetKey, coords, heading, options)
    if not InApartment then
        return
    end

    if InApartmentTargets[targetKey] and InApartmentTargets[targetKey].created then
        return
    end

    local boxName = 'inApartmentTarget_' .. targetKey
    exports['qb-target']:AddBoxZone(boxName, coords, 1.5, 1.5, {
        name = boxName,
        heading = heading,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = false,
    }, {
        options = options,
        distance = 1
    })

    InApartmentTargets[targetKey] = InApartmentTargets[targetKey] or {}
    InApartmentTargets[targetKey].created = true
end

-- shared

local function SetApartmentsEntranceTargets()
    if Apartments.Locations and next(Apartments.Locations) then
        for id, apartment in pairs(Apartments.Locations) do
            if apartment and apartment.coords and apartment.coords['enter'] then
                if UseTarget then
                    RegisterApartmentEntranceTarget(id, apartment)
                else
                    RegisterApartmentEntranceZone(id, apartment)
                end
            end
        end
    end
end

local function GetCoordsForTarget(event)
    return vector3(Apartments.Locations[ClosestHouse].coords.enter.x + POIOffsets[event].x, Apartments.Locations[ClosestHouse].coords.enter.y + POIOffsets[event].y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets[event].z)
end

local function SetInApartmentTargets()
    if not POIOffsets then
        -- do nothing
        return
    end

    if UseTarget then
        RegisterInApartmentTarget('entrancePos', GetCoordsForTarget("exit"), 0, {
            {
                type = 'client',
                event = 'hideouts:client:OpenDoor',
                icon = 'fas fa-door-open',
                label = "Otwórz drzwi",
            },
            {
                type = 'client',
                event = 'hideouts:client:LeaveApartment',
                icon = 'fas fa-door-open',
                label = "Wyjdź",
            },
        })
        RegisterInApartmentTarget('stashPos', GetCoordsForTarget("stash"), 0, {
            {
                type = 'client',
                event = 'hideouts:client:OpenStash',
                icon = 'fas fa-box-open',
                label = "Otwórz szafkę",
            },
        })
        RegisterInApartmentTarget('outfitsPos', GetCoordsForTarget("clothes"), 0, {
            {
                type = 'client',
                event = 'hideouts:client:ChangeOutfit',
                icon = 'fas fa-tshirt',
                label = "Przebierz się",
            },
        })
        RegisterInApartmentTarget('laptop', GetCoordsForTarget("laptop"), 0, {
            {
                type = 'client',
                event = 'hideouts:client:OpenLaptop',
                icon = 'fas fa-laptop',
                label = "Otwórz laptop",
            },
        })
    else
        --RegisterInApartmentZone('stashPos', stashPos, 0, '[E] ' .. Lang:t('text.open_stash'))
        --RegisterInApartmentZone('outfitsPos', outfitsPos, 0, '[E] ' .. Lang:t('text.change_outfit'))
        --RegisterInApartmentZone('logoutPos', logoutPos, 0, '[E] ' .. Lang:t('text.logout'))
        --RegisterInApartmentZone('entrancePos', entrancePos, 0, Lang:t('text.options'))
    end
end

local function DeleteApartmentsEntranceTargets()
    if Apartments.Locations and next(Apartments.Locations) then
        for id, apartment in pairs(Apartments.Locations) do
            if UseTarget then
                exports['qb-target']:RemoveZone('apartmentEntrance_' .. id)
            else
                if apartment.polyzoneBoxData.zone then
                    apartment.polyzoneBoxData.zone:destroy()
                    apartment.polyzoneBoxData.zone = nil
                end
            end
            apartment.polyzoneBoxData.created = false
        end
    end
end

local function DeleteInApartmentTargets()
    IsInsideExitZone = false
    IsInsideStashZone = false
    IsInsideOutfitsZone = false
    IsInsideLogoutZone = false

    if InApartmentTargets and next(InApartmentTargets) then
        for id, apartmentTarget in pairs(InApartmentTargets) do
            if UseTarget then
                exports['qb-target']:RemoveZone('inApartmentTarget_' .. id)
            else
                if apartmentTarget.zone then
                    apartmentTarget.zone:destroy()
                    apartmentTarget.zone = nil
                end
            end
        end
    end
    InApartmentTargets = {}
end

-- utility functions

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function openHouseAnim()
    loadAnimDict('anim@heists@keycard@')
    TaskPlayAnim(PlayerPedId(), 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, 0, 0, 0)
    Wait(400)
    ClearPedTasks(PlayerPedId())
end

local function EnterApartment(house, apartmentId, new)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_open', 0.1)
    openHouseAnim()
    Wait(250)
    QBCore.Functions.TriggerCallback('hideouts:GetApartmentOffset', function(offset)
        if offset == nil or offset == 0 then
            QBCore.Functions.TriggerCallback('hideouts:GetApartmentOffsetNewOffset', function(newoffset)
                if newoffset > 230 then
                    newoffset = 210
                end
                CurrentOffset = newoffset
                TriggerServerEvent('hideouts:server:AddObject', apartmentId, house, CurrentOffset)
                local coords = { x = Apartments.Locations[house].coords.enter.x, y = Apartments.Locations[house].coords.enter.y, z = Apartments.Locations[house].coords.enter.z - CurrentOffset }
                local data = exports['qb-interior']:CreateWarehouseForOrganizations1(coords, Apartments.WarehouseProps)
                Wait(100)
                HouseObj = data[1]
                POIOffsets = data[2]
                InApartment = true
                CurrentApartment = apartmentId
                ClosestHouse = house
                RangDoorbell = nil
                Wait(500)
                TriggerEvent('qb-weathersync:client:DisableSync')
                Wait(100)
                TriggerServerEvent('hideouts:server:SetInsideMeta', house, apartmentId, true, false)
                TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_close', 0.1)
                TriggerServerEvent('hideouts:server:setCurrentApartment', CurrentApartment)
            end, house)
        else
            if offset > 230 then
                offset = 210
            end
            CurrentOffset = offset
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_open', 0.1)
            TriggerServerEvent('hideouts:server:AddObject', apartmentId, house, CurrentOffset)
            local coords = { x = Apartments.Locations[ClosestHouse].coords.enter.x, y = Apartments.Locations[ClosestHouse].coords.enter.y, z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset }
            local data = exports['qb-interior']:CreateWarehouseForOrganizations1(coords, Apartments.WarehouseProps)
            Wait(100)
            HouseObj = data[1]
            POIOffsets = data[2]
            InApartment = true
            CurrentApartment = apartmentId
            Wait(500)
            TriggerEvent('qb-weathersync:client:DisableSync')
            Wait(100)
            TriggerServerEvent('hideouts:server:SetInsideMeta', house, apartmentId, true, true)
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_close', 0.1)
            TriggerServerEvent('hideouts:server:setCurrentApartment', CurrentApartment)
        end

        if new ~= nil then
            if new then
                TriggerEvent('qb-interior:client:SetNewState', true)
            else
                TriggerEvent('qb-interior:client:SetNewState', false)
            end
        else
            TriggerEvent('qb-interior:client:SetNewState', false)
        end
    end, apartmentId)
end

local function LeaveApartment(house)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_open', 0.1)
    openHouseAnim()
    TriggerServerEvent('hideouts:returnBucket')
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    exports['qb-interior']:DespawnInterior(HouseObj, function()
        TriggerEvent('qb-weathersync:client:EnableSync')
        SetEntityCoords(PlayerPedId(), Apartments.Locations[house].coords.enter.x, Apartments.Locations[house].coords.enter.y, Apartments.Locations[house].coords.enter.z)
        SetEntityHeading(PlayerPedId(), Apartments.Locations[house].coords.enter.w)
        Wait(1000)
        TriggerServerEvent('hideouts:server:RemoveObject', CurrentApartment, house)
        TriggerServerEvent('hideouts:server:SetInsideMeta', CurrentApartment, false)
        CurrentApartment = nil
        InApartment = false
        CurrentOffset = 0
        DoScreenFadeIn(1000)
        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'houses_door_close', 0.1)
        TriggerServerEvent('hideouts:server:setCurrentApartment', nil)

        DeleteInApartmentTargets()
        DeleteApartmentsEntranceTargets()
    end)
end

local function SetClosestApartment()
    local pos = GetEntityCoords(PlayerPedId())
    local current = nil
    local dist = 100
    for id, _ in pairs(Apartments.Locations) do
        local distcheck = #(pos - vector3(Apartments.Locations[id].coords.enter.x, Apartments.Locations[id].coords.enter.y, Apartments.Locations[id].coords.enter.z))
        if distcheck < dist then
            current = id
            dist = distcheck
        end
    end
    if current ~= ClosestHouse and LocalPlayer.state.isLoggedIn and not InApartment then
        ClosestHouse = current
        QBCore.Functions.TriggerCallback('hideouts:IsOwner', function(result)
            IsOwned = result
            DeleteApartmentsEntranceTargets()
            DeleteInApartmentTargets()
        end, ClosestHouse)
    end
end

function MenuOwners()
    QBCore.Functions.TriggerCallback('hideouts:GetAvailableApartments', function(apartments)
        if next(apartments) == nil then
            QBCore.Functions.Notify("Nikogo nie ma w środku", 'error', 3500)
            CloseMenuFull()
        else
            local apartmentMenu = {
                {
                    header = "Mieszkańcy",
                    isMenuHeader = true
                }
            }

            for k, v in pairs(apartments) do
                apartmentMenu[#apartmentMenu + 1] = {
                    header = v,
                    txt = '',
                    params = {
                        event = 'hideouts:client:RingMenu',
                        args = {
                            apartmentId = k
                        }
                    }

                }
            end

            apartmentMenu[#apartmentMenu + 1] = {
                header = "Zamnknij menu",
                txt = '',
                params = {
                    event = 'qb-menu:client:closeMenu'
                }

            }
            exports['qb-menu']:openMenu(apartmentMenu)
        end
    end, ClosestHouse)
end

function CloseMenuFull()
    exports['qb-menu']:closeMenu()
end

-- Event Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if HouseObj ~= nil then
            exports['qb-interior']:DespawnInterior(HouseObj, function()
                CurrentApartment = nil
                TriggerEvent('qb-weathersync:client:EnableSync')
                DoScreenFadeIn(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                SetEntityCoords(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y, Apartments.Locations[ClosestHouse].coords.enter.z)
                SetEntityHeading(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.w)
                Wait(1000)
                InApartment = false
                DoScreenFadeIn(1000)
            end)
        end

        DeleteApartmentsEntranceTargets()
        DeleteInApartmentTargets()
    end
end)


-- Events

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CurrentApartment = nil
    InApartment = false
    CurrentOffset = 0

    DeleteApartmentsEntranceTargets()
    DeleteInApartmentTargets()
end)

RegisterNetEvent('hideouts:client:OpenLaptop', function()
    TriggerEvent("skr-syn:client:zlecenie")
end)


RegisterNetEvent('hideouts:client:SpawnInApartment', function(apartmentId, apartment)
    local pos = GetEntityCoords(PlayerPedId())
    if RangDoorbell ~= nil then
        local doorbelldist = #(pos - vector3(Apartments.Locations[RangDoorbell].coords.enter.x, Apartments.Locations[RangDoorbell].coords.enter.y, Apartments.Locations[RangDoorbell].coords.enter.z))
        if doorbelldist > 5 then
            QBCore.Functions.Notify("Jesteś za daleko od drzwi")
            return
        end
    end
    ClosestHouse = apartment
    EnterApartment(apartment, apartmentId, true)
    IsOwned = true
end)

RegisterNetEvent('hideouts:client:LastLocationHouse', function(apartmentType, apartmentId)
    ClosestHouse = apartmentType
    EnterApartment(apartmentType, apartmentId, false)
end)

RegisterNetEvent('hideouts:client:SetHomeBlip', function(home)
    CreateThread(function()
        SetClosestApartment()
        for name, _ in pairs(Apartments.Locations) do
            if Apartments.Locations[name].blip ~= nil then
                RemoveBlip(Apartments.Locations[name].blip)
            end

            if (name == home) then
                Apartments.Locations[name].blip = AddBlipForCoord(Apartments.Locations[name].coords.enter.x, Apartments.Locations[name].coords.enter.y, Apartments.Locations[name].coords.enter.z)
                SetBlipSprite(Apartments.Locations[name].blip, 473)
                SetBlipDisplay(Apartments.Locations[name].blip, 4)
                SetBlipScale(Apartments.Locations[name].blip, 0.65)
                SetBlipAsShortRange(Apartments.Locations[name].blip, true)
                SetBlipColour(Apartments.Locations[name].blip, 3)
                AddTextEntry(Apartments.Locations[name].label, "Baza organizacji")
                BeginTextCommandSetBlipName(Apartments.Locations[name].label)
                EndTextCommandSetBlipName(Apartments.Locations[name].blip)
            end
        end
    end)
end)

RegisterNetEvent('hideouts:client:RingMenu', function(data)
    RangDoorbell = ClosestHouse
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'doorbell', 0.1)
    TriggerServerEvent('hideouts:server:RingDoor', data.apartmentId, ClosestHouse)
end)

RegisterNetEvent('hideouts:client:RingDoor', function(player, _)
    CurrentDoorBell = player
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'doorbell', 0.1)
    QBCore.Functions.Notify("Użyłeś dzwonka")
end)

RegisterNetEvent('hideouts:client:DoorbellMenu', function()
    MenuOwners()
end)

RegisterNetEvent('hideouts:client:EnterApartment', function()
    QBCore.Functions.TriggerCallback('hideouts:GetOwnedApartment', function(result)
        if result ~= nil then
            EnterApartment(ClosestHouse, result.name)
        end
    end)
end)

RegisterNetEvent('hideouts:client:UpdateApartment', function()
    QBCore.Functions.TriggerCallback('hideouts:IsLocationAvaible', function(result)
        if result == true then
            QBCore.Functions.TriggerCallback('hideouts:DoesOrganizationAlreadyHaveLocation', function(alreadyHave)
                if not alreadyHave then
                    QBCore.Functions.TriggerCallback('aquel-crypto:server:getWalletFromCID', function(walletid)
                        QBCore.Functions.TriggerCallback('aquel-crypto:server:takeCryptoFromWallet', function(success)
                            if success == true then
                                local apartmentType = "basement"
                                local apartmentLabel = Apartments.Locations[ClosestHouse].label
                                TriggerServerEvent('hideouts:server:UpdateApartment', ClosestHouse, apartmentType, apartmentLabel)
                                IsOwned = true
                        
                                DeleteApartmentsEntranceTargets()
                                DeleteInApartmentTargets()
                            else
                                QBCore.Functions.Notify("Nie stać Cię na przeniesienie bazy")
                            end
                        end, walletid, Apartments.FirstPayment)
                    end, QBCore.Functions.GetPlayerData().citizenid)
                else
                    QBCore.Functions.Notify("Organizacja posiada już bazę")
                end
            end)
        else
            QBCore.Functions.Notify("Lokalizacja jest już zajęta")
        end
    end, ClosestHouse)
end)

RegisterNetEvent('hideouts:client:OpenDoor', function()
    if CurrentDoorBell == 0 then
        QBCore.Functions.Notify("Nikogo nie ma przy drzwiach")
        return
    end
    TriggerServerEvent('hideouts:server:OpenDoor', CurrentDoorBell, CurrentApartment, ClosestHouse)
    CurrentDoorBell = 0
end)

RegisterNetEvent('hideouts:client:LeaveApartment', function()
    LeaveApartment(ClosestHouse)
end)

RegisterNetEvent('hideouts:client:OpenStash', function()
    local stashId = "org_" .. QBCore.Functions.GetPlayerData().gang.name
    if CurrentApartment then
        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'StashOpen', 0.4)
        --TriggerServerEvent('hideouts:server:openStash', CurrentApartment)
        exports.ox_inventory:openInventory('stash', {id = stashId})
    end
end)

RegisterNetEvent('hideouts:client:ChangeOutfit', function()
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Clothes1', 0.4)
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('hideouts:client:Logout', function()
    TriggerServerEvent('qb-houses:server:LogoutLocation')
end)


-- Threads

if UseTarget then
    CreateThread(function()
        local sleep = 5000
        while not LocalPlayer.state.isLoggedIn do
            -- do nothing
            Wait(sleep)
        end

        while true do
            sleep = 1000

            if not InApartment then
                SetClosestApartment()
                SetApartmentsEntranceTargets()
            elseif InApartment then
                SetInApartmentTargets()
            end
            Wait(sleep)
        end
    end)
else
    CreateThread(function()
        local sleep = 5000
        while not LocalPlayer.state.isLoggedIn do
            -- do nothing
            Wait(sleep)
        end

        while true do
            sleep = 1000

            if not InApartment then
                SetClosestApartment()
                SetApartmentsEntranceTargets()

                if IsInsideEntranceZone then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        OpenEntranceMenu()
                        exports['qb-core']:HideText()
                    end
                end
            elseif InApartment then
                sleep = 0

                SetInApartmentTargets()

                if IsInsideExitZone then
                    if IsControlJustPressed(0, 38) then
                        OpenExitMenu()
                        exports['qb-core']:HideText()
                    end
                end

                if IsInsideStashZone then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('hideouts:client:OpenStash')
                        exports['qb-core']:HideText()
                    end
                end

                if IsInsideOutfitsZone then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('hideouts:client:ChangeOutfit')
                        exports['qb-core']:HideText()
                    end
                end

                if IsInsideLogoutZone then
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('hideouts:client:Logout')
                        exports['qb-core']:HideText()
                    end
                end
            end

            Wait(sleep)
        end
    end)
end
