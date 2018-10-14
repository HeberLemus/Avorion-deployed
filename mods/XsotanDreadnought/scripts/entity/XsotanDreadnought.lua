package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/XsotanDreadnought/?.lua"

require ("randomext")
require ("stringutility")
local Xsotan = require ("story/xsotan")
local Config = require("config/XsotanDreadnoughtConfig")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace XsotanDreadnought
XsotanDreadnought = {}

local State =
{
    Fighting = 0,
    Charging = 1,
}

XsotanDreadnought.state = State.Fighting
XsotanDreadnought.shieldDurability = 0
XsotanDreadnought.charge = 0
XsotanDreadnought.recharges = Config.Settings.recharges
XsotanDreadnought.initialDmgMulti = nil


function XsotanDreadnought.initialize()
	Config.log(4, "Initialize entity scripts")
	if i18n then i18n.registerMod("XsotanDreadnought") end
	
	XsotanDreadnought.initialDmgMulti = XsotanDreadnought.initialDmgMulti or Entity().damageMultiplier
	
	-- Increase shields, it should not be too easy :)
	if (Entity().maxDurability * Config.Settings.shieldMultiplier) - Entity().shieldMaxDurability > 0 then
		local bonus = (Entity().maxDurability / Entity().shieldMaxDurability) * Config.Settings.shieldMultiplier * (math.random() * 0.4 + 0.8)
		Config.log(4, "Multiply shields by "..bonus)
		Entity():addKeyedMultiplier(StatsBonuses.ShieldDurability, 99001001, bonus)
	end
	
	Entity().shieldDurability = Entity().shieldMaxDurability
	XsotanDreadnought.shieldDurability = Entity().shieldMaxDurability
	
	if Config.Settings.strongerAtCore or Config.Settings.strongerAtCore2 then
		--local x, y = Sector():getCoordinates()
		local dist = length(vec2(Sector():getCoordinates()))
		if Config.Settings.strongerAtCore2 and dist < Config.Settings.strongerAtCore2 then
			XsotanDreadnought.recharges = Config.Settings.recharges + 2
		elseif Config.Settings.strongerAtCore and dist < Config.Settings.strongerAtCore then
			XsotanDreadnought.recharges = Config.Settings.recharges + 1
		end
	end

    --if onServer() then
    --    Entity():registerCallback("onDestroyed", "onDestroyed")
    --end
end

function secure()
	local data = {
		initialDmgMulti = XsotanDreadnought.initialDmgMulti,
	}
	
	return data
end

function restore(data)
	XsotanDreadnought.initialDmgMulti = data.initialDmgMulti
end

if onServer() then
function XsotanDreadnought.getUpdateInterval()
    return 0.25
end
end

if onClient() then
function XsotanDreadnought.getUpdateInterval()
    return 0.033
end
end

function XsotanDreadnought.hasAllies()
    local allies = {Sector():getEntitiesByFaction(Entity().factionIndex)}

    local self = Entity()
    for _, ally in pairs(allies) do
        if ally.index ~= self.index and ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then
            return true
        end
    end

    return false
end

function XsotanDreadnought.aggroAllies()
    local ownIndex = Entity().factionIndex

    local sector = Sector()
    local allies = {sector:getEntitiesByFaction(Entity().factionIndex)}
    local factions = {sector:getPresentFactions()}

    for _, ally in pairs(allies) do
        if ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then

            local ai = ShipAI(ally.index)
            for _, factionIndex in pairs(factions) do
                if factionIndex ~= ownIndex then
                    ai:registerEnemyFaction(factionIndex)
                end
            end
        end
    end

    return false
end

function XsotanDreadnought.setFighting()
	Config.log(3, "Set fighting")
	XsotanDreadnought.state = State.Fighting
	Sector():broadcastChatMessage("", 3, "The Dreadnought finished charging and is vulnerable again"%_t)
end

function XsotanDreadnought.setCharging()
	Config.log(3, "Set charging")
	XsotanDreadnought.state = State.Charging
	local player = Player(Entity().factionIndex)
	Sector():broadcastChatMessage("", 3, "The Dreadnought charges up his weapons and shields"%_t)
	XsotanDreadnought.charge = XsotanDreadnought.charge + 1
	
	Entity().damageMultiplier = XsotanDreadnought.initialDmgMulti * (XsotanDreadnought.charge + 1)
	
	Entity().shieldDurability = Entity().shieldMaxDurability * 0.2
	XsotanDreadnought.shieldDurability = Entity().shieldDurability
	
	local numShips = math.floor((((math.random() * 0.6) + 0.7) * (Config.Settings.shipAmount)) + 0.5)
	local shipVolumeFactor = (XsotanDreadnought.charge + 1) * Config.Settings.shipVolumeFactor
	for i = 1, numShips do
		local position = MatrixLookUpPosition(vec3(0, 1, 0), vec3(1, 0, 0), Entity().translationf + random():getDirection() * random():getFloat(500, 750))
		
		Xsotan.createShip(position, shipVolumeFactor)
	end
end

function XsotanDreadnought.updateServer(timePassed)
	
	-- State: Fighting
	if XsotanDreadnought.state == State.Fighting then
		XsotanDreadnought.shieldDurability = Entity().shieldDurability
		
		if Entity().shieldDurability < (Entity().shieldMaxDurability * 0.2) and XsotanDreadnought.charge < XsotanDreadnought.recharges then
			XsotanDreadnought.setCharging()
		end
		
	-- State: Charging
	elseif XsotanDreadnought.state == State.Charging then
		local maxDurability = Entity().shieldMaxDurability
		if XsotanDreadnought.charge > 1 then
			local devider = 1 - ((XsotanDreadnought.charge - 1) / (XsotanDreadnought.recharges - 1) * 0.4)
			maxDurability = Entity().shieldMaxDurability * devider
			if maxDurability > Entity().shieldMaxDurability then
				maxDurability = Entity().shieldMaxDurability
			end
		end
		
		if XsotanDreadnought.shieldDurability < maxDurability then
			local shields = XsotanDreadnought.shieldDurability + XsotanDreadnought.getShieldChargeTick(timePassed)
			if shields > maxDurability then
				shields = maxDurability
			end
			Entity().shieldDurability = shields
		else
			Entity().shieldDurability = maxDurability
		end
		XsotanDreadnought.shieldDurability = Entity().shieldDurability
		
        if not XsotanDreadnought.hasAllies() then
            XsotanDreadnought.setFighting()
        end
	end
	
	if XsotanDreadnought.shieldDurability > (Entity().shieldMaxDurability * 0.1) then
		Entity().invincible = true
	else
		Entity().invincible = false
	end

	XsotanDreadnought.aggroAllies()
end

function XsotanDreadnought.updateClient(timePassed)
	registerBoss(Entity().index)
end

function XsotanDreadnought.getShieldChargeTick(timePassed)
	return (Entity().shieldMaxDurability * 0.8) * (timePassed / Config.Settings.shieldChargeDuration)
end


