_menuPool = NativeUI.CreatePool()
mainMenu = NativeUI.CreateMenu("Main Menu", "~b~Evidence Storage")
_menuPool:Add(mainMenu)

local trunkWeapons = {}

function IsPlayerBehindVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed, false)
    local inFrontOfVeh = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.5, 0.0) -- Reduced distance (1.5 units)
    local rayHandle = StartShapeTestRay(playerCoords.x, playerCoords.y, playerCoords.z, inFrontOfVeh.x, inFrontOfVeh.y, inFrontOfVeh.z, 10, playerPed, 0)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)

    if IsEntityAVehicle(vehicle) and IsEntityAtCoord(vehicle, inFrontOfVeh.x, inFrontOfVeh.y, inFrontOfVeh.z, 3.0, 3.0, 2.0, 0, 1, 0) then
        local bootBoneIndex = GetEntityBoneIndexByName(vehicle, "boot") -- Use "boot" for the trunk bone name, adjust if needed
        if bootBoneIndex ~= -1 then
            local trunkCoords = GetWorldPositionOfEntityBone(vehicle, bootBoneIndex)
            local playerForwardVector = vector3(GetEntityForwardX(playerPed), GetEntityForwardY(playerPed), 0.0)
            local vectorToTrunk = vector3(trunkCoords.x - playerCoords.x, trunkCoords.y - playerCoords.y, 0.0)
            local angle = math.deg(math.abs(math.atan2(vectorToTrunk.y, vectorToTrunk.x) - math.atan2(playerForwardVector.y, playerForwardVector.x)))
            return angle <= 90 or angle >= 270 -- Adjust this angle range as needed
        end
    end

    return false
end

-- Function to handle the trunk interaction
function HandleTrunkInteraction()
    local playerPed = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(playerPed)

    if weaponHash ~= nil and weaponHash ~= -1569615261 then -- Not unarmed weapon (-1569615261)
        if IsPlayerBehindVehicle() then
            RemoveWeaponFromPed(playerPed, weaponHash) -- Remove the weapon from the player
            table.insert(trunkWeapons, weaponHash) -- Store the weapon in the trunk
            notify('You stored the weapon in the trunk.')
        else
            notify('You can only store the weapon in the trunk while standing behind a vehicle.')
        end
    else
        notify('You cannot store this weapon in the trunk.')
    end
end

-- Function to handle retrieving all weapons from the trunk
function HandleRetrieveAllFromTrunk()
    if IsPlayerBehindVehicle() then
        local playerPed = PlayerPedId()
        for _, weaponHash in ipairs(trunkWeapons) do
            GiveWeaponToPed(playerPed, weaponHash, 0, false, true)
        end

        trunkWeapons = {} -- Clear all items from the trunk
        notify('You retrieved all items from the trunk.')
    else
        notify('You can only retrieve items from the trunk while standing behind a vehicle.')
    end
end

function TrunkInteractionItem(menu)
    local trunkInteraction = NativeUI.CreateItem("Place equipped item in the boot", "Interact with the vehicle trunk.")
    menu:AddItem(trunkInteraction)

    trunkInteraction.Activated = function(sender, item)
        if IsPlayerBehindVehicle() then
            HandleTrunkInteraction()
        else
            notify("You can only interact with the trunk while standing behind a vehicle.")
        end
    end
end

function RetrieveAllFromTrunkItem(menu)
    local retrieveAll = NativeUI.CreateItem("Retrieve all items from the boot", "Retrieve all items from the trunk.")
    menu:AddItem(retrieveAll)

    retrieveAll.Activated = function(sender, item)
        if IsPlayerBehindVehicle() then
            HandleRetrieveAllFromTrunk()
        else
            notify("You can only retrieve items from the trunk while standing behind a vehicle.")
        end
    end
end


TrunkInteractionItem(mainMenu)
RetrieveAllFromTrunkItem(mainMenu)

_menuPool:RefreshIndex()

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if IsPlayerBehindVehicle() then
            if IsControlJustPressed(1, 51) then -- "E" button
                mainMenu:Visible(not mainMenu:Visible())
            end
        end

        _menuPool:ProcessMenus()
    end
end)

function notify(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(true, true)
end

