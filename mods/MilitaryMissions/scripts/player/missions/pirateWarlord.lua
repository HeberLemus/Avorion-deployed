package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/MilitaryMissions/?.lua"

local PirateGenerator = require("pirategenerator")
require("stringutility")
require("mission")

local PlanGenerator = require("plangenerator")
local TurretGenerator = require("turretgenerator")
local UpgradeGenerator = require("upgradegenerator")
local Config = require("config/MilitaryMissionsConfig")

-- Only required for addPirateEquipment cause vanilla function is bugged
local ShipUtility = require ("shiputility")

missionData.brief = "Eliminate Pirate Warlord"%_t
missionData.title = "Eliminate Pirate Warlord in (${location.x}:${location.y})"%_t
missionData.description = "The ${giver} asked you to take care of a pirate warlord that is currently located in sector (${location.x}:${location.y})."%_t

function initialize(giverIndex, x, y, reward)

    if onClient() then
        sync()
    else
        Player():registerCallback("onSectorEntered", "onSectorEntered")

        -- don't initialize data if there is none
        if not giverIndex then return end

        local station = Entity(giverIndex)

        missionData.giver = Sector().name .. " " .. station.translatedTitle
		missionData.giverFactionIndex = station.factionIndex
        missionData.location = {x = x, y = y}
        missionData.reward = reward
        missionData.justStarted = true
    end

end

-- This usely should be executed in mission.lua. Vanilla script bug or I just don't understand what I did wrong.
function onSectorEntered()
	if not missionData.location then
        terminate()
        return
    end
	
	if missionData.location and missionData.location.x and missionData.location.y then
		local x, y = Sector():getCoordinates()
        if x == missionData.location.x and y == missionData.location.y then
            if cstOnTargetLocationEntered then
                cstOnTargetLocationEntered(x, y)
            end
        end
    end
end

function cstOnTargetLocationEntered(x, y)
	Config.log(3, "Mission sector entered")
    if getNumPirates() == 0 then
		-- create pirate ships
		local numShips = math.random(4, 6)

		PirateGenerator.createRaider(generator:getPositionInSector(5000))

		for i = 1, numShips do
			PirateGenerator.createMarauder(generator:getPositionInSector(5000))
			PirateGenerator.createPirate(generator:getPositionInSector(5000))
			PirateGenerator.createBandit(generator:getPositionInSector(5000))
		end
    end
	if not missionData.bossIndex then
		Config.log(3, "Creating boss")
		local boss = createBoss()
		boss:registerCallback("onDestroyed", "onBossDestroyed")
		generateFluff(Entity(missionData.bossIndex))
	end
end

function getNumPirates()
    local faction = PirateGenerator.getPirateFaction()

    local num = 0
    for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.Owner)}) do
        if entity.factionIndex == faction.index then
            num = num + 1
        end
    end

    return num
end

-- Same function from spawnswoks.lua
function piratePosition()
    local pos = random():getVector(-2000, 2000)
    return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
end

--Generate the boss & his loot
function createBoss()

    local lootType
    local loot
    local x, y = Sector():getCoordinates()

    
    local boss
	
    PirateGenerator.pirateLevel = PirateGenerator.pirateLevel or Balancing_GetPirateLevel(x, y)

    local faction = Galaxy():getPirateFaction(PirateGenerator.pirateLevel)
    local volume = Balancing_GetSectorShipVolume(x, y) * Config.Settings.Warlord.volumeMultiplier;
    local plan = PlanGenerator.makeShipPlan(faction, volume)
	
    local boss = Sector():createShip(faction, "", plan, piratePosition())
	
	if not boss then
		Config.log(1, "Could not create boss, skipping")
		return false
	end
    
	--PirateGenerator.addPirateEquipment(boss, "Mothership") -- Force mothership weapons and anti torps
	-- The vanilla function is bugged, manually do all the stuff until its fixed
	local type = random():getInt(1, 2)
	if type == 1 then
		ShipUtility.addCarrierEquipment(boss)
	elseif type == 2 then
		ShipUtility.addFlagShipEquipment(boss)
	end
	ShipUtility.addBossAntiTorpedoEquipment(boss)
	
	
    boss.title = "Warlord"%_t
	boss:setValue("is_pirate", 1)
	
	if Config.Settings.Warlord.damageMultiplier > 1 then
		boss.damageMultiplier = Config.Settings.Warlord.damageMultiplier
	end
	
	boss:addScript("mods/MilitaryMissions/scripts/entity/pirateWarlord.lua")

    --20% chance for exotic loot, else exceptional
    if math.random() < 0.8 then
		lootType = RarityType.Exceptional
	else
        lootType = RarityType.Exotic
    end
	
	
    if math.random() < 0.4 then
		loot = InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(lootType)))
	else
        UpgradeGenerator.initialize(random():createSeed())
        loot = UpgradeGenerator.generateSystem(Rarity(lootType))
    end

    Loot(boss.index):insert(loot)
	
    missionData.bossIndex = boss.index

    return boss

end

--function that generates and executes the warlord's "battlecry"
function generateFluff(sender)
    local faction = Faction(missionData.factionIndex)
    
    local player  = Player()
    local playerName = player.name

    local messages =
    {
        "So, "..faction.name.." sent YOU to do their dirty job? Shame, they'll have to find someone else pretty soon."%_t,
        "I'm gonna use what's left of you to grease my ship, "..playerName%_t
    }
    
    --return title,  
    player:sendChatMessage(sender.title, 0, getRandomEntry(messages))
end

function onBossDestroyed()
	local player = Player()
	player:receive("Earned %1% credits for killing the Warlord."%_T, missionData.reward)
	awardRep(player,Faction(missionData.giverFactionIndex),18000)
	player:sendChatMessage(missionData.giver, 0, "Thank you for taking care of this scum. We transferred the reward to your account."%_t)
	finish()
end

-- Should be moved to mission bulletin, but this doesnt seem possible without modding the bulletin
-- Maybe add it as a global function anywhere...
function awardRep(player, faction, baseAmount)
    local trust = (faction:getTrait("naive") + 2) / 2 -- 0.5 to 1.5

    local repAmount = baseAmount + baseAmount * ((0.5 - math.random()) / 2) -- make a random varity of +-25%
    repAmount = repAmount*trust

    Galaxy():changeFactionRelations(player, faction, repAmount)
end