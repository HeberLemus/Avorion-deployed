local Config = {}

Config.Author = "Hammelpilaw"
Config.ModName = "MilitaryMissions"
Config.version = {
    major=0, minor=3, patch = 3,
    string = function()
        return  Config.version.major .. '.' ..
                Config.version.minor .. '.' ..
                Config.version.patch
    end
}

-- Config section
Config.Settings = {
	
	-- Pirate Warlord
	Warlord = {
		enhanceShields = false,		-- Make shields stronger and force warlord even to have shields in iron zone. Possible values: true, false
		damageMultiplier = 1,		-- Damage Multiplier. Possible values: 1 or higher
		volumeMultiplier = 30,		-- Volume Multiplier for boss. Default 30. Possible values: 1 or higher
	}
}

-- Missions section
Config.Missions = {
	-- Vanilla missions - do not change
	-- Do NOT add custom missions like this, vanilla missions are not added like custom missions.
	{bulletin = false, bulletinFnc = "getClear"}, -- Clear sector
	{bulletin = false, bulletinFnc = "getExplore"}, -- Explore sector
	
	-- XsotanDreadnought
	-- Requires Xsotan Dreadnought mod 0.3.0 or higher
	-- Remove the leading "--" from the line below to activate the Dreadnought as plugin for military outpost
	{bulletin = "mods/XsotanDreadnought/scripts/player/XsotanDreadnoughtAttackBulletin", probability = 30, maxDistance = 250},
	
	
	-- #####################
	-- CUSTOM MISSIONS BELOW
	-- bulletin = script to bulletin file without lua ending. Required!
	-- probability = % chance that outposts offer this missin. Values: 0-100. Initial value is 100%. Leave blank to use default
	-- maxDistance = The mission will not be offered when distance to core is below this. Leave blank for not limiting.
	--
	-- Example when not using optional settings:
	--{bulletin = "mods/yourmission/scripts/player/missions/yourmissionBulletin"},
	-- 
	-- Example when using optional settings - 50% chance to find, max distance from core 250:
	--{bulletin = "mods/yourmission/scripts/player/missions/yourmissionBulletin", probability = 50, maxDistance = 250},
	-- #####################
	{bulletin = "mods/MilitaryMissions/scripts/player/missions/pirateWarlordBulletin", probability = 100, maxDistance = 300},
	
	
	
}

Config.logLevel = 1
if GameSettings().devMode then
	Config.logLevel = 5
end

Config.log = function(logLevel, ...) if logLevel <= Config.logLevel then print("["..Config.ModName.." - "..Config.version.string().."]", ...) end end

return Config
