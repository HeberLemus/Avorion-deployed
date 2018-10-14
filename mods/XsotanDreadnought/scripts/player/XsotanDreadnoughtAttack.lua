package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";mods/XsotanDreadnought/?.lua"

-- copy pasted some of the scripts. Check whats really required. Still too lazy to do :(
require ("galaxy")
require ("randomext")
require ("utility")
require ("stringutility")
require ("defaultscripts")
require ("mission")

missionData.brief = "Curious subspace signals"%_t
missionData.title = "Curious subspace signals"%_t
missionData.description = "The ${giver} asked you to investigate the source of some curious subspace in sector (${location.x}:${location.y})."%_t


local TurretGenerator = require ("turretgenerator")
local UpgradeGenerator = require ("upgradegenerator")
local ShipUtility = require ("shiputility")
local PlanGenerator = require ("plangenerator")
local SectorSpecifics = require ("sectorspecifics")
local Xsotan = require("data/scripts/lib/story/xsotan")
local Config = require("config/XsotanDreadnoughtConfig")

local generated = 0
local timeSinceCall = 0
local customBulletin = nil -- Used to get target sector when using custom initialization


function getUpdateInterval()
    return 1
end

--function secure()
--    return {dummy = 1}
--end

--function restore(data)
 --   terminate()
--end

--function initialize(firstInitialization)
function initialize(tmpvar, inX, inY, reward)
	if missionData.giverIndex then tmpvar = missionData.giverIndex end
	if missionData.isEvent then tmpvar = missionData.isEvent end
	
	if i18n then i18n.registerMod("XsotanDreadnought") end
	
	Config.log(4, "Initialize mission")
	if onClient() then
		Config.log(4, "Initialize client")
		invokeServerFunction("sendCoordinates")
	else
		Config.log(4, "Initialize server")
		local firstInitialization
		local player = Player()
		
		-- Mission is initialized by random event or custom command
		if tmpvar == true or tmpvar == nil or tmpvar == false then
			Config.log(3, "Determined custom initialization")
			firstInitialization = tmpvar
			missionData.isEvent = true
			
			local specs = SectorSpecifics()
			local x, y = Sector():getCoordinates()
			local coords = specs.getShuffledCoordinates(random(), x, y, 7, 18)
			
			if not customBulletin then
				customBulletin = require("scripts/player/XsotanDreadnoughtAttackBulletin")
				customBulletin.getBulletin() -- We do not need bulletin, but it generates the target
			end
			
			missionData.location = customBulletin.getTarget()
			
			
			-- if no empty sector could be found, exit silently
			if not missionData.location then
				Config.log(3, "Could not find sector for custom initialization - terminate")
				terminate()
			end
			
			if firstInitialization then
				player:sendChatMessage("", 0, "Your sensors picked up very curious subspace signals at \\s(%i:%i)."%_t, missionData.location.x, missionData.location.y)
				player:sendChatMessage("", 3, "Your sensors picked up subspace signals at %i:%i."%_t, missionData.location.x, missionData.location.y)
			end
		elseif tmpvar and valid(Entity(tmpvar)) then
			Config.log(3, "Determined initialization by military outpost")
			missionData.giverIndex = tmpvar.string
			
			local station = Entity(missionData.giverIndex)
			
			missionData.giverFactionIndex = station.factionIndex
			
			missionData.giver = Sector().name .. " " .. station.translatedTitle
			missionData.location = {x = inX, y = inY}
			missionData.reward = reward
			missionData.justStarted = true
		else
			Config.log(1, "Could not determine parameters given to mission script - terminate")
			terminate()
		end


		
		player:registerCallback("onSectorEntered", "onSectorEntered")
		player:registerCallback("onSectorLeft", "onSectorLeft")

		
	end
end

function updateServer(timeStep)
    local x, y = Sector():getCoordinates()
    if generated == 0 then
        timeSinceCall = timeSinceCall + timeStep

        if timeSinceCall > 30 * 60 then
            terminate()
        end
    end
end

function onSectorLeft(player, x, y)
	if x ~= missionData.location.x or y ~= missionData.location.y then return end
	
	--delete the Xsotan Dreadnought and terminate.
	local sector = Sector()
	
	local entities = {sector:getEntities()}
	for _, entity in pairs(entities) do
		if entity:hasScript("mods/XsotanDreadnought/scripts/entity/XsotanDreadnought.lua") then
			sector:deleteEntity(entity)
		end
	end
	
    terminate()
end

function onSectorEntered(player, x, y)

    if x ~= missionData.location.x or y ~= missionData.location.y then return end

	if generated == 0 then
		boss = createXsotanDreadnought()
		boss:registerCallback("onDestroyed", "onBossDestroyed")
	end
	generated = 1
end

function createXsotanDreadnought()
	Config.log(4, "Create Dreadnought")
	local x, y = Sector():getCoordinates()
    local position = Matrix()
	local dist = length(vec2(x, y))
	
    local volume = Balancing_GetSectorShipVolume(x, y)
	
	local coreFactor = 1
	if dist < Config.Settings.coreDistance then
		coreFactor = Config.Settings.bossVolumeFactorCore * (1 - (dist / Config.Settings.coreDistance))
	end

    volume = volume * Config.Settings.bossVolumeFactor * coreFactor

    
    local probabilities = Balancing_GetMaterialProbability(x, y)
	
    local material = Material(getValueFromDistribution(probabilities))
	
    local faction = Xsotan.getFaction()
    local plan = PlanGenerator.makeShipPlan(faction, volume, nil, material)
	Config.log(4, "Shields: "..plan:getStats().shield)
	-- Add shields to the ship when it does not have any
	if not plan:getStats().shield or plan:getStats().shield == 0 then
		plan:addBlock(vec3(0, 0, 0), vec3(4, 4, 4), plan.rootIndex, -1, Color(), material, Matrix(), BlockType.ShieldGenerator) 
		Config.log(3, "Add shields to plan")
	end
	
    local ship = Sector():createShip(faction, "", plan, position)

    Xsotan.infectShip(ship)
	
	
	local numTurrets = math.max(2, Balancing_GetEnemySectorTurrets(x, y))
	-- Lets add 2 random turret types
	for i = 1, 2 do
		TurretGenerator.initialize(random():createSeed())
		local turret = TurretGenerator.generateArmed(x, y, 0, Rarity(RarityType.Rare))
		local weapons = {turret:getWeapons()}
		turret:clearWeapons()
		for _, weapon in pairs(weapons) do
			weapon.reach = Config.Settings.weaponRange * 100
			if weapon.isBeam then
				weapon.blength = Config.Settings.weaponRange * 100
			else
				weapon.pmaximumTime = weapon.reach / weapon.pvelocity
			end
			turret:addWeapon(weapon)
		end

		turret.coaxial = false
		ShipUtility.addTurretsToCraft(ship, turret, numTurrets)
	end
	ShipUtility.addBossAntiTorpedoEquipment(ship)
	
	if Config.Settings.useTorps or (Config.Settings.useTorpsCore and dist < Config.Settings.coreDistance) then
		ShipUtility.addTorpedoBoatEquipment(ship)
	end
	
	if Config.Settings.upScale then
		Xsotan.upScale(ship)
	end
	
	Config.log(4, "Initial damage multiplier:", ship.damageMultiplier)
	
	local coreMulti = 1
	if dist < Config.Settings.coreDistance and Config.Settings.damageMultiplierCore > 1 then
		coreMulti = Config.Settings.damageMultiplierCore * (1 - (dist / Config.Settings.coreDistance))
	end
	ship.damageMultiplier = ship.damageMultiplier * Config.Settings.damageMultiplier * coreMulti
	
	Config.log(4, "Total damage multiplier:", ship.damageMultiplier)

	ship.title = "Xsotan Dreadnought"%_t
    ship.crew = ship.minCrew
	
	-- Reduce automatic shield recharge and movement speed, its annoying when it always moves directly in front of you...
	ship:addBaseMultiplier(StatsBonuses.Velocity, -0.7)
    ship:addBaseMultiplier(StatsBonuses.Acceleration, -0.7)
	ship:addBaseMultiplier(StatsBonuses.ShieldRecharge, 10)
	
	-- Generate loot
	local loot =
    {
        {rarity = Rarity(RarityType.Legendary), amount = 1},
        {rarity = Rarity(RarityType.Exotic), amount = 2},
        {rarity = Rarity(RarityType.Exceptional), amount = 3},
        {rarity = Rarity(RarityType.Rare), amount = 3},
        {rarity = Rarity(RarityType.Uncommon), amount = 4},
        {rarity = Rarity(RarityType.Common), amount = 6},
    }
	
    UpgradeGenerator.initialize(random():createSeed())
    for _, p in pairs(loot) do
        for i = 1, p.amount do
			-- 60% upgrades, 40% weapons
			if math.random() > 0.4 then
				Loot(ship.index):insert(UpgradeGenerator.generateSystem(p.rarity))
			else
				Loot(ship.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, p.rarity)))
			end
        end
    end

    AddDefaultShipScripts(ship)

    ship:addScript("ai/patrol.lua")
    ship:addScript("mods/XsotanDreadnought/scripts/entity/XsotanDreadnought.lua")
    ship:addScript("story/xsotanbehaviour.lua")
    ship:setValue("is_xsotan", 1)
    ship:setValue("xsotan_dreadnought", 1) -- Support for carrier command priority setting

    return ship
end

function sendCoordinates()
    invokeClientFunction(Player(callingPlayer), "receiveCoordinates", missionData.location, missionData.giverIndex, missionData.isEvent)
end

function onBossDestroyed()
	if missionData.giverIndex and missionData.giver then
		local player = Player(callingPlayer)
		--local giverFactionIndex = Entity(missionData.giverIndex).factionIndex
		
		player:receive("Earned %1% credits for investigate the sector."%_t, missionData.reward)
		player:sendChatMessage(missionData.giver, 0, "Thank you for investigating and clearing this sector."%_t)
		awardRep(player,Faction(missionData.giverFactionIndex),20000)
	end
	finish()
end


if onClient() then

	function receiveCoordinates(target_in, giver, event)
		if not event then 
			sync()
		end
		missionData.location = target_in
		missionData.giverIndex = giver
		missionData.isEvent = event
	end
	
	function getMissionDescription()
		if missionData.isEvent then
			return string.format("You received curious subaspace signals by an unknown source. Their position is %i:%i."%_t, missionData.location.x, missionData.location.y)
		elseif missionData.giverIndex then
			return missionData.description%_t % missionData
		end
		Config.log(3, "Could not determine mission desc")
		return "-"
	end
end


-- Should be moved to mission bulletin, but this doesnt seem possible without modding the bulletin
-- Maybe add it as a global function anywhere...
function awardRep(player, faction, baseAmount)
    local trust = (faction:getTrait("naive") + 2) / 2 -- 0.5 to 1.5

    local repAmount = baseAmount + baseAmount * ((0.5 - math.random()) / 2) -- make a random varity of +-25%
    repAmount = repAmount*trust

    Galaxy():changeFactionRelations(player, faction, repAmount)
end

