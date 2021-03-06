
package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AIMine
AIMine = {}

local minedAsteroid = nil
local minedLoot = nil
local collectCounter = 0
local canMine = nil
local noAsteroidsLeft = true --false
--Mine Mod
local firstmsg = false -- indicator for first message (resource asteroids farmed) has been sent or not
local check1 = false -- check1 true means, that no more resource asteroids are findable
local check2 = false -- check2 true means, that no more asteroids at all are findable (precheck for check3) still, a message has to be sent to the player.
local check3 = false -- check3 true means, everything is done, set ship to idle

function AIMine.getUpdateInterval()
    if noAsteroidsLeft then return 15 end

    return 1
end

function AIMine.checkIfAbleToMine()
    if onServer() then
        local ship = Entity()
        if ship.numTurrets > 0 then
            canMine = true
        else
            local hangar = Hangar()
            local squads = {hangar:getSquads()}

            for _, index in pairs(squads) do
                local category = hangar:getSquadMainWeaponCategory(index)
                if category == WeaponCategory.Mining then
                    canMine = true
                    break
                end
            end
        end

        if not canMine then
            local player = Player(Entity().factionIndex)
            if player then
                player:sendChatMessage("Server", ChatMessageType.Error, "Your ship needs mining turrets or fighters to mine."%_T)
            end
            terminate()
        end
    end
end

-- this function will be executed every frame on the server only
function AIMine.updateServer(timeStep)
    local ship = Entity()

    if canMine == nil then
        AIMine.checkIfAbleToMine()
    end

    if ship.hasPilot or ship:getCrewMembers(CrewProfessionType.Captain) == 0 then
        terminate()
        return
    end

    -- find an asteroid that can be harvested
    AIMine.updateMining(timeStep)
end

-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign minedLoot
function AIMine.findMinedLoot()

    local loots = {Sector():getEntitiesByType(EntityType.Loot)}

    local ship = Entity()

    minedLoot = nil
    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) < 150 * 150 then
            minedLoot = loot
            break
        end
    end

end

-- check the sector for an asteroid that can be mined
-- if there is one, assign minedAsteroid
function AIMine.findMinedAsteroid()
	--Mine Mod
	if check3 == false then
		local radius = 20
		local ship = Entity()
		local sector = Sector()
		local player = Player(Entity().factionIndex)
		local x, y = Sector():getCoordinates()
		local coords = tostring(x) .. ":" .. tostring(y)
		local mineables
		local nearest
		local resources

		minedAsteroid = nil

		if check1 == false then -- Fange mit Resourcen-Asteroiden an
		mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
		nearest = math.huge
			for _, a in pairs(mineables) do
				if a.type == EntityType.Asteroid then
					resources = a:getMineableResources()
					if resources ~= nil and resources > 0 then

						local dist = distance2(a.translationf, ship.translationf)
						if dist < nearest then
							nearest = dist
							minedAsteroid = a
						end

					end
				end
			end

			if minedAsteroid then
				broadcastInvokeClientFunction("setMinedAsteroid", minedAsteroid.index)
			else
				check1 = true
			end
		end

		if check1 == true and check2 == false then -- Keine Resourcen-Asteroiden sind mehr vorhanden. Mache mit normalen weiter.

			if firstmsg == false then
				player:sendChatMessage(ship.name or "", ChatMessageType.Error, "No more asteroids in sector %s. We continue farming normal asteroids."%_T, coords)
				player:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more asteroids in \\s(%s)! We continue farming normal asteroids."%_T, coords)
				firstmsg = true
			end

			mineables = {sector:getEntitiesByType(EntityType.Asteroid)}
			nearest = math.huge

			for _, a in pairs(mineables) do
				if a.type == EntityType.Asteroid then
						dist = distance2(a.translationf, ship.translationf)
						if dist < nearest then
							nearest = dist
							minedAsteroid = a
						end
				end
			end

			if minedAsteroid then
				noAsteroidsLeft = false
				broadcastInvokeClientFunction("setMinedAsteroid", minedAsteroid.index)
			else
				noAsteroidsLeft = true
				check2 = true
			end
		end

		if check1 == true and check2 == true then -- Garkeine Asteroiden sind mehr vorhanden. Lege Arbeit nieder.
			player:sendChatMessage(ship.name or "", ChatMessageType.Error, "All asteroids in %s are gone."%_T, coords)
			player:sendChatMessage(ship.name or "", ChatMessageType.Normal, "All asteroids in \\s(%s) are gone."%_T, coords)
			ShipAI(ship.index):setPassive()
			ship:invokeFunction("craftorders.lua", "setAIAction")
			check3 = true
		end
	end --Mine Mod End
end

function AIMine.updateMining(timeStep)

    -- highest priority is collecting the resources
    if not valid(minedAsteroid) and not valid(minedLoot) then

        -- first, check if there is loot to collect
        AIMine.findMinedLoot()

        -- then, if there's no loot, check if there is an asteroid to mine
        if not valid(minedLoot) then
            AIMine.findMinedAsteroid()
        end

    end

    local ship = Entity()
    local ai = ShipAI()

    if valid(minedLoot) then

        -- there is loot to collect, fly there
        collectCounter = collectCounter + timeStep
        if collectCounter > 3 then
            collectCounter = collectCounter - 3
            ai:setFly(minedLoot.translationf, 0)
        end

    elseif valid(minedAsteroid) then

        -- if there is an asteroid to collect, attack it
        if ship.selectedObject == nil
            or ship.selectedObject.index ~= minedAsteroid.index
            or ai.state ~= AIState.Attack then

            ai:setAttack(minedAsteroid)
        end
    end

end

function AIMine.setMinedAsteroid(index)
    minedAsteroid = Entity(index)
end

---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--
--    if valid(minedAsteroid) then
--        drawDebugSphere(minedAsteroid:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end
