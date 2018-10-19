if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("randomext")
require ("stringutility")
local Placer = require("placer")
local AsyncPirateGenerator = require ("asyncpirategenerator")
local AsyncShipGenerator = require("asyncshipgenerator")
local UpgradeGenerator = require ("upgradegenerator")
local TurretGenerator = require ("turretgenerator")


local ships = {}
local reward = 0
local reputation = 0

local participants = {}

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace PirateAttack
PirateAttack = {}
PirateAttack.attackersGenerated = false


function PirateAttack.secure()
    return {reward = reward, reputation = reputation, ships = ships}
end

function PirateAttack.restore(data)
    ships = data.ships
    reputation = data.reputation
    reward = data.reward
end

function PirateAttack.initialize()

    -- no pirate attacks at the very edge of the galaxy
    local x, y = Sector():getCoordinates()
    if length(vec2(x, y)) > 430 then
        print ("Too far out for pirate attacks.")
        terminate()
        return
    end

    if Sector():getValue("neutral_zone") then
        print ("No pirate attacks in neutral zones.")
        terminate()
        return
    end

    ships = {}
    participants = {}
    reward = 0
    reputation = 0

    local scaling = Sector().numPlayers
    if scaling == 0 then
        terminate()
        return
    end

    if scaling == 1 then
        local player = Sector():getPlayers()
        local hx, hy = player:getHomeSectorCoordinates()
        if hx == x and hy == y and player.playtime < 30 * 60 then
            print ("Player's playtime is below 30 minutes (%is), cancelling pirate attack.", player.playtime)
            terminate()
            return
        end
    end

    -- create attacking ships
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1000

    local attackType = getInt(1, 10)

    local distance = 75

    local generator = AsyncPirateGenerator(PirateAttack, PirateAttack.onPiratesGenerated)
    generator:startBatch()

	local rndScale = getInt(0, 10)

	local rndScaleFactor = 1 + (rndScale / 5)

	local threatlvl = rndScale * attackType
    Sector():broadcastChatMessage("Server"%_t, 2, string.format("Pirates are attacking the sector! Scanner show a threat level of : %i)."%_t, threatlvl))

	if attackType == 10 then
        reward = 12.0 * rndScale

		Sector():broadcastChatMessage("Server"%_t, 2, "The whole pirate fleet appeared for a retaliation strike! Fight for your lives!"%_t)
		rndScaleFactor = rndScaleFactor + 0.5
        generator:createScaledBoss(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledBoss(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledBoss(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance * 3.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * 3.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance * 4.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * 4.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * -distance * 5.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * distance * 5.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * -distance * 6.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * distance * 6.0), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance * 7.0), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance * 7.0), rndScaleFactor)

	elseif attackType == 9 then
        reward = 9.6 * rndScale

		Sector():broadcastChatMessage("Server"%_t, 2, "A pirate flagship appeared!"%_t)

        generator:createScaledBoss(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance * 3.0), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance * 3.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 4.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 4.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 5.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 5.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * -distance * 6.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * distance * 6.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance * 7.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * 7.0), rndScaleFactor)

	elseif attackType == 8 then
        reward = 7.9 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A huge pirate fleet appeared!"%_t)

        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance * 3.0), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance * 3.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 4.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 4.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 5.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 5.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * -distance * 6.0), rndScaleFactor)
        generator:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * distance * 6.0), rndScaleFactor)


	elseif attackType == 7 then
        reward = 6.6 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A raider elite group appeared!"%_t)

        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)

	elseif attackType == 6 then
        reward = 5.95 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A pirate raid fleet appeared!"%_t)

        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 3.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 3.0), rndScaleFactor)

	elseif attackType == 5 then
        reward = 4.56 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A pirate raid appeared!"%_t)

        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)


    elseif attackType == 4 then
        reward = 3.18 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A small pirate raid appeared!"%_t)

        generator:createScaledRaider(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)

    elseif attackType == 3 then
        reward = 2.97 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A small group of bandits appeared!"%_t)

        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)

    elseif attackType == 2 then
        reward = 1.75 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A small group of pirates appeared!"%_t)

        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
    else
        reward = 1.25 * rndScale

        Sector():broadcastChatMessage("Server"%_t, 2, "A small group of outlaws appeared!"%_t)

        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0), rndScaleFactor)
        generator:createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0), rndScaleFactor)
    end

	--if attackType == 10 then
	--	PirateAttack.createDefender(4)
--	elseif attackType > 5 then
--		local defenceChance = getInt(1, 10)
--		if defenceChance < attackType then
--			PirateAttack.createDefender(getInt(1, 3))
--		end
--		reward = reward / 1.38
	--end

    generator:endBatch()

    reputation = reward * 4050
    reward = reward * 11554 * Balancing_GetSectorRichnessFactor(Sector():getCoordinates())

end


function PirateAttack.createDefender(amount)
    local sector = Sector()
    local x, y = sector:getCoordinates()

    local faction = Galaxy():getControllingFaction(x, y)
		if not faction or not faction.isAIFaction then
        -- print ("no local AI faction found")
		return
	end
	PirateAttack.spawnDefender(faction, amount);
end


function PirateAttack.spawnDefender(faction, amount)
    local x, y = Sector():getCoordinates()

    local position = random():getDirection() * 1500
    local dir = normalize(-position)
    local up = vec3(0, 1, 0)
    local right = normalize(cross(up, dir))
    up = normalize(cross(right, dir))

    local onFinished = function(ships)
        for _, ship in pairs(ships) do
            ship:removeScript("entity/antismuggle.lua")
            ship:addScriptOnce("data/scripts/sector/factionwar/temporarydefender.lua")
        end

        Placer.resolveIntersections(ships)
    end

    local generator = AsyncShipGenerator(PirateAttack, onFinished)
    generator:startBatch()

    for i = -amount, amount do
        local pos = position + right * i * 100
        local ship
        generator:createDefender(faction, MatrixLookUpPosition(dir, up, pos))
    end
    generator:endBatch()

    Sector():broadcastChatMessage("Server"%_t, 2, "The local faction dispatched a defence fleet!"%_t)
end


function PirateAttack.getUpdateInterval()
    return 15
end

function PirateAttack.onPiratesGenerated(generated)

    for _, ship in pairs(generated) do
        if valid(ship) then -- this check is necessary because ships could get destroyed before this callback is executed
            ships[ship.index.string] = true
            ship:registerCallback("onDestroyed", "onShipDestroyed")
        end
    end

    -- resolve intersections between generated ships
    Placer.resolveIntersections(generated)

    PirateAttack.attackersGenerated = true
end

function PirateAttack.update(timeStep)

    if not PirateAttack.attackersGenerated then return end

    -- check if all ships are still there
    -- ships might have changed sector or deleted in another way, which doesn't trigger destruction callback
    local sector = Sector()
    for id, _ in pairs(ships) do
        local pirate = sector:getEntity(Uuid(id))
        if pirate == nil then
            ships[id] = nil
        end
    end

    -- if not -> end event
    if tablelength(ships) == 0 then
        PirateAttack.endEvent()
    end
end

function PirateAttack.onShipDestroyed(shipIndex)

    ships[shipIndex.string] = nil

    local ship = Entity(shipIndex)
    local damagers = {ship:getDamageContributorPlayers()}
    for i, v in pairs(damagers) do
        participants[v] = v
    end

    -- if they're all destroyed, the event ends
    if tablelength(ships) == 0 then
        PirateAttack.endEvent()
    end
end


function PirateAttack.endEvent()

    local faction = Galaxy():getLocalFaction(Sector():getCoordinates())
    if faction then

        local messages =
        {
            "Thank you for defeating those pirates. You have our endless gratitude."%_t,
            "We thank you for taking care of those ships. We transferred a reward to your account."%_t,
            "Thank you for taking care of those pirates. We transferred a reward to your account."%_t,
        }

        -- give payment to players who participated
        for i, v in pairs(participants) do
            local player = Player(i)

            player:sendChatMessage(faction.name, 0, getRandomEntry(messages))
            --Mod Warning - Better Enemies removes message
            player:receive("Received %1% credits for defeating a pirate attack."%_T, reward)
            Galaxy():changeFactionRelations(player, faction, reputation)

            local x, y = Sector():getCoordinates()
            local object

            if random():getFloat() < 0.5 then
                object = InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exceptional)))
            else
                UpgradeGenerator.initialize(random():createSeed())
                object = UpgradeGenerator.generateSystem(Rarity(RarityType.Rare))
            end

            if object then player:getInventory():add(object) end
        end
    end

    terminate()
end

end

