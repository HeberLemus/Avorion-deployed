package.path = package.path .. ";mods/MilitaryMissions/?.lua"

local Config = require("config/MilitaryMissionsConfig")

local boss

function initialize()
	boss = Entity()
	
	if Config.Settings.Warlord.enhanceShields and Entity().maxDurability - Entity().shieldMaxDurability > 0 then
		-- Increase shields, it should not be too easy :)
		local bonus = (Entity().maxDurability / Entity().shieldMaxDurability) * (math.random() * 0.4 + 0.8) -- Random multiplier between 0.8 and 1.2
		Config.log(4, "Multiply shields by "..bonus)
		Entity():addKeyedMultiplier(StatsBonuses.ShieldDurability, 99999999, bonus)
	end
end