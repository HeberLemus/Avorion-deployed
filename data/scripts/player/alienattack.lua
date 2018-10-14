if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("stringutility")
require ("randomext")
require ("utility")
require ("galaxy")

local ShipGenerator = require ("shipgenerator")
local Xsotan = require("story/xsotan")

local minute = 0
local attackType = 1

function initialize(attackType_in)
    attackType = attackType_in or 1
    deferredCallback(1.0, "update", 1.0)

    if Sector():getValue("neutral_zone") then
        print ("No xsotan attacks in neutral zones.")
        terminate()
        return
    end

    local first = Sector():getEntitiesByFaction(Xsotan.getFaction().index)
    if first then
        terminate()
        return
    end

end

function getUpdateInterval()
    return 60
end

function update(timeStep)

    minute = minute + 1
	local size = math.random(1, 10)
	local megaInvasion = 0
	local threatlvl = 0

	if attackType == 0 then -- Start
		megaInvasion = getInt(0, 30)
	elseif attackType == 1 then -- Middle
		megaInvasion = getInt(0, 60)
	elseif attackType == 2 then -- Middle-End
		megaInvasion = getInt(0, 80)
	elseif attackType == 3 then -- Center-Edge
		megaInvasion = getInt(0, 100)
	end

	threatlvl = (round(megaInvasion / 10) * size)

    if minute == 1 then Player():sendChatMessage("Server"%_t, 3, "Your sensors picked up a short burst of subspace signals."%_t)
    elseif minute == 4 then
		if attackType == 0 then
			Player():sendChatMessage("Server"%_t, 3, "More strange subspace signals, they're getting stronger."%_t)
        elseif attackType == 1 then
            Player():sendChatMessage("Server"%_t, 3, "The signals are growing stronger."%_t)
        elseif attackType == 2 then
            Player():sendChatMessage("Server"%_t, 3, "There are lots and lots of subspace signals! Careful!"%_t)
        elseif attackType == 3 then
            Player():sendChatMessage("Server"%_t, 3, "The subspace signals are getting too strong for your scanners. Brace yourself!"%_t)
		end
	elseif minute == 5 then
		Player():sendChatMessage("Server"%_t, 2, string.format("Aliens are attacking the sector! Scanner show a threat level of : %i)."%_t, threatlvl))

		if megaInvasion < 20 then
				createEnemies(size,{
					{size=1*size, title="Xsotan Scout"%_t},
					{size=1*size, title="Xsotan Scout"%_t},
					{size=1*size, title="Xsotan Scout"%_t},
					})
				Player():sendChatMessage("Server"%_t, 2, "A small group of alien ships appeared!"%_t)
				terminate()

		elseif megaInvasion < 40 then
				createEnemies(size,{
					{size=1*size, title="Xsotan Scout"%_t},
					{size=3*size, title="Xsotan Ship"%_t},
					{size=3*size, title="Xsotan Ship"%_t},
					{size=1*size, title="Xsotan Scout"%_t},
					})
				Player():sendChatMessage("Server"%_t, 2, "A group of alien ships warped in!"%_t)
				terminate()

		elseif megaInvasion < 60 then
				createEnemies(size,{
					{size=1*size, title="Xsotan Scout"%_t},
					{size=2*size, title="Xsotan Scout"%_t},
					{size=3*size, title="Xsotan Ship"%_t},
					{size=5*size, title="Big Xsotan Ship"%_t},
					{size=3*size, title="Xsotan Ship"%_t},
					{size=2*size, title="Xsotan Scout"%_t},
					{size=1*size, title="Xsotan Scout"%_t},
					})
				Player():sendChatMessage("Server"%_t, 2, "A large group of alien ships appeared!"%_t)
				terminate()

		elseif megaInvasion < 75 then
			createEnemies(size,{
                {size=1*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                {size=2*size, title="Xsotan Scout"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=2*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                })
			Player():sendChatMessage("Server"%_t, 2, "Danger! A large fleet of alien ships appeared!"%_t)
			terminate()

		elseif megaInvasion < 90 then
			createEnemies(size,{
                {size=1*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                {size=2*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                {size=2*size, title="Xsotan Scout"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=2*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                {size=2*size, title="Xsotan Scout"%_t},
                {size=1*size, title="Xsotan Scout"%_t},
                })
			Player():sendChatMessage("Server"%_t, 2, "Danger! A very large fleet of alien ships appeared!"%_t)
			terminate()

		elseif megaInvasion < 101 then
			createEnemies(size,{
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=15*size, title="Xsotan Mother Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=3*size, title="Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                {size=5*size, title="Big Xsotan Ship"%_t},
                })

			Player():sendChatMessage("Server"%_t, 2, "Danger! A Xostan mothership fleet appeared! It's an Invasion!"%_t)
			terminate()
		else
			createEnemies(size,{
				{size=1*size, title="Xsotan Scout"%_t},
				{size=1*size, title="Xsotan Scout"%_t},
				{size=1*size, title="Xsotan Scout"%_t},
				})

			Player():sendChatMessage("Server"%_t, 2, "A small group of alien ships appeared!"%_t)
			terminate()
		end
	end
end



function createEnemies(size, volumes)

    local first = Sector():getEntitiesByFaction(Xsotan.getFaction().index)
    if first then
        terminate()
        return
    end

    local galaxy = Galaxy()

    local faction = Xsotan.getFaction()

    local player = Player()
    local others = Galaxy():getNearestFaction(Sector():getCoordinates())
    Galaxy():changeFactionRelations(faction, player, -200000)
    Galaxy():changeFactionRelations(faction, others, -200000)

    -- create the enemies
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500

    local volume = (Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()));
	volume = volume * size;
    for _, p in pairs(volumes) do

        local enemy = Xsotan.createShip(MatrixLookUpPosition(-dir, up, pos), p.size)
        enemy.title = p.title

        local distance = enemy:getBoundingSphere().radius + 20

        pos = pos + right * distance

        enemy.translation = dvec3(pos.x, pos.y, pos.z)

        pos = pos + right * distance + 20

        -- patrol.lua takes care of setting aggressive
    end
end



end
