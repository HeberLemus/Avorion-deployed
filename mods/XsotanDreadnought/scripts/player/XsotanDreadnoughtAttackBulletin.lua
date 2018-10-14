
package.path = package.path .. ";data/scripts/lib/?.lua;"
package.path = package.path .. ";data/scripts/?.lua;"
package.path = package.path .. ";mods/XsotanDreadnought/?.lua"

local SectorSpecifics = require ("sectorspecifics")
local Balancing = require ("galaxy")

local XsotanDreadnoughtAttackBulletin = {}

XsotanDreadnoughtAttackBulletin.target = {}

function XsotanDreadnoughtAttackBulletin.getBulletin()

    -- find a sector that has pirates
    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 7, 25)
    local serverSeed = Server().seed
    XsotanDreadnoughtAttackBulletin.target = nil

    for _, coord in pairs(coords) do

		local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, Server().seed)

		if not regular and not offgrid and not blocked and not home and not (coord.x == 0 and coord.y == 0) then
			XsotanDreadnoughtAttackBulletin.target = {x=coord.x, y=coord.y}
			
			if not Galaxy():sectorExists(coord.x, coord.y) then
				break
			end
		end
	end

    local description = "Our sensors picked up very curious subspace signals in sector (${x} : ${y}).\nPlease examine their source and get rid of all enemies you find there."%_t

	-- You may modify brief, description, difficulty, msg
	-- You MUST set script correctly
    local bulletin =
    {
        brief = "Curious subspace signals"%_t,			-- Name
        description = description,						-- Description
        difficulty = "Medium /*difficulty*/"%_t,		-- Difficulty
        script = "mods/XsotanDreadnought/scripts/player/XsotanDreadnoughtAttack.lua",	-- Script file for that mission, REQUIRED
        --msg = "Their location is \\s(%i:%i)."%_T,							-- Message
    }

    return bulletin
end

function XsotanDreadnoughtAttackBulletin.getReward(amount)
	local reward = amount * Balancing.GetSectorRichnessFactor(Sector():getCoordinates())
	local faction = Faction(Entity().factionIndex)
	
	--The more generous, the more money they give. The more greedy, the less. +-25%
	return reward + (reward * 0.25 * faction:getTrait("generous") )
end

XsotanDreadnoughtAttackBulletin.mission = {
	getBulletin = function() return XsotanDreadnoughtAttackBulletin.getBulletin() end,
	getReward = function() return XsotanDreadnoughtAttackBulletin.getReward(90000) end,
	getTarget = function() return XsotanDreadnoughtAttackBulletin.target end,
}

return XsotanDreadnoughtAttackBulletin.mission