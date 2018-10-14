local Config = {}

Config.Author = "Hammelpilaw"
Config.ModName = "XsotanDreadnought"
Config.version = {
    major=0, minor=4, patch = 0,
    string = function()
        return  Config.version.major .. '.' ..
                Config.version.minor .. '.' ..
                Config.version.patch
    end
}

Config.Settings = {
	recharges = 1,				-- How often does the boss recharge shield and weapons and calls supporter ships
	damageMultiplier = 5,		-- Boss entity damage multiplier
	weaponRange = 20,			-- Weapon range in km
	useTorps = true,			-- Dreadnought uses torpedoes
	shieldMultiplier = 3,		-- Boss will have about this times more shields then hull lifepoints
	shieldChargeDuration = 6,	-- Duration for recharging shields in seconds
	bossVolumeFactor = 50,		-- Volume multiplier compared to a default xsotan ship
	shipVolumeFactor = 2,		-- Volume multiplier for supporter ships
	shipAmount = 6,				-- Amount of supporter ships per wave
	upScale = true,				-- Use vanilla Xsotan upscaling inside core
	
	
	-- Core settings to make Dreadnought stronger near the center of galaxy.
	-- These settings will not overwrite settings above, it will be multiplied to it.
	coreDistance = 150,			-- Distance from core, where core settings stop being applied
	strongerAtCore2 = 150,		-- If > 0 the amount of shield recharges will increase +2 below of that distance to core.
	strongerAtCore = 250,		-- If > 0 the amount of shield recharges will increase +1 below of that distance to core.
	
	useTorpsCore = true,		-- If useTorps config deactivated the Dreadnought will only use torpedoes when inside core distance
	
	
	-- ATTENTION: since mod version 0.4.0 the core configs below are MULTIPLIED instead of added to the configs above.
	-- If you did 'damageMultiplier = 10' and 'damageMultiplierCore = 2', it got a total of 20 in sector 0:0.
	bossVolumeFactorCore = 1,	-- Volume multiplier at core. Will reduce the more far away from core you are
	damageMultiplierCore = 1,	-- Boss entity damage multiplier. Will reduce the more far away from core you are.
								
	
	
	
}

Config.logLevel = 1
if GameSettings().devMode then
	Config.logLevel = 5
end

Config.log = function(logLevel, ...) if logLevel <= Config.logLevel then print("["..Config.ModName.." - "..Config.version.string().."]", ...) end end

return Config
