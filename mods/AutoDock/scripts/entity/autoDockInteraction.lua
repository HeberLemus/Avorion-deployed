package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
require("stringutility")
require ("faction")

local player
local playerCraft
local station

function printError(errStr)
   if onServer() then
        local x,y = Sector():getCoordinates()
        print("AutoDockInteraction ERROR: ("..tostring(x)..":"..tostring(y).."):"..errStr%_t)
    end 
end

function interactionPossible(playerIndex, option)
    player = Player(playerIndex)
    station = Entity()   --Entity() points to the Station

    playerCraft = player.craft
    if playerCraft == nil then return false end

    local playerShip = Entity(playerCraft.index)

    if playerShip then
        --player is already engaged in an Auto-Docking Sequence
        if playerShip:getValue("autoDockInProgress") == true then
            return false
        end
        --player is already docked to this Station; no need to initiate Auto-Docking Sequence
        if station:isDocked(playerShip) then
            return false
        end
    end
    return true
end

-- create all required UI elements for the client side
function initUI()
    ScriptUI():registerInteraction("Auto-Dock to Station"%_t, "onInteract")
end

function onInteract()
    if onClient() then
        local ship = Player().craft
        if ship == nil then return end

        local station = Entity()
        if station == nil then return end

        invokeServerFunction("resolveInteraction", station.index, Player().index)

        ScriptUI():stopInteraction()

        return
    end
end

function resolveInteraction(stationIndex, playerInd)
    if not stationIndex then
        printError("onInteract - stationIndex nil. Aborting.")
        return
    end
    if not playerInd then
        printError("onInteract - playerInd nil. Aborting.")
        return
    end

    player = Player(playerInd)
    station = Entity()   --Entity() points to the Station

    playerCraft = player.craft
    if playerCraft == nil then
        printError("onInteract - could not get playerCraft: value is nil.")
        return false
    end

    local playerShip = Entity(playerCraft.index)

    if playerShip then
        --we don't service drones (because they're buggy and will glitch getting stuck near the dock sometimes - tractor beam code doesn't expect Mining Drones)
        if playerShip.type == EntityType.Drone then
            player:sendChatMessage(station.translatedTitle.." "..station.name, 4, "Request to dock denied. Sorry, we do not extend this service to drones."%_t)
            return false
        end
    end

    if station.type == EntityType.Station then
        --if CheckFactionInteraction(playerInd, -10000) then
            --Everything A-OK. We can dock!
            playerShip:addScriptOnce("mods/AutoDock/scripts/entity/ai/autoDock.lua", playerInd, stationIndex)
            return true
        --else
        --    player:sendChatMessage(station.translatedTitle.." "..station.name, 4, "Request to dock denied. Our records say that we're not allowed to do business with you.\nCome back when your relations to our faction are better."%_t)
        --    return false
        --end
    end
end
