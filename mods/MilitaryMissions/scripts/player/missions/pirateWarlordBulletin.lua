
package.path = package.path .. ";data/scripts/lib/?.lua;"
package.path = package.path .. ";data/scripts/?.lua;"
package.path = package.path .. ";mods/MilitaryMissions/?.lua"

local SectorSpecifics = require ("sectorspecifics")
local Balancing = require ("galaxy")

local pirateWarlordBulletin = {}

pirateWarlordBulletin.target = {}
pirateWarlordBulletin.reward = 0

function pirateWarlordBulletin.getBulletin()

    -- find a sector that has pirates
    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 2, 15)
    local serverSeed = Server().seed
    pirateWarlordBulletin.target = nil

    for _, coord in pairs(coords) do
        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

        if offgrid and not blocked then
            specs:initialize(coord.x, coord.y, serverSeed)

            if specs.generationTemplate.path == "sectors/pirateasteroidfield" then
				pirateWarlordBulletin.target = coord
                if not Galaxy():sectorExists(coord.x, coord.y) then
                    break
                end
            end
        end
    end

    if not pirateWarlordBulletin.target then
		pirateWarlordBulletin.reward = nil -- No mission, reset reward
		return
	end
	
	pirateWarlordBulletin.reward = pirateWarlordBulletin.generateReward(70000)

    local description = "A pirate warlord has been spotted in a nearby sector, filled to the brim with pirates.\nWe cannot let him get away, we need someone to put an end to him.\n\nSector: (${x} : ${y})"%_t

	-- You may modify brief, description, difficulty, msg
	-- You MUST set script correctly
    local bulletin =
    {
        brief = "Eliminate Pirate Warlord"%_t,					-- Name
        description = description,								-- Description
        difficulty = "Medium /*difficulty*/"%_t,				-- Difficulty
        script = "mods/MilitaryMissions/scripts/player/missions/pirateWarlord.lua",	-- Script file for the mission, REQUIRED
        msg = "He's located in \\s(%i:%i)."%_T,					-- Message
    }

    return bulletin
end

function pirateWarlordBulletin.generateReward(amount)
    local reward = amount * Balancing.GetSectorRichnessFactor(Sector():getCoordinates())
    local faction = Faction(Entity().factionIndex)
    
    --The more generous, the more money they give. The more greedy, the less. +-25%
    return reward + (reward * 0.25 * faction:getTrait("generous") )
end

pirateWarlordBulletin.mission = {
	getBulletin = function() return pirateWarlordBulletin.getBulletin() end,		-- generate new bulletin, not just return the generated one
	getReward = function() return pirateWarlordBulletin.reward end,				-- return generated reward
	getTarget = function() return pirateWarlordBulletin.target end,				-- return generated target
}

return pirateWarlordBulletin.mission