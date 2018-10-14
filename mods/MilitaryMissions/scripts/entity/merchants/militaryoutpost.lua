
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";mods/MilitaryMissions/?.lua"

local Config = require("config/MilitaryMissionsConfig")

local SectorSpecifics = require ("sectorspecifics")
local Balancing = require ("galaxy")
local Dialog = require("dialogutility")
require ("stringutility")

local bulletinScripts = {}

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MilitaryOutpost
MilitaryOutpost = {}

function MilitaryOutpost.initialize()
    if onServer() and Entity().title == "" then
        Entity().title = "Military Outpost"%_t
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/military.png"
        InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
    end
	
	for i,item in pairs(Config.Missions) do
		if item.bulletin then
			Config.log(2, "Initialize mission "..i..": "..item.bulletin)
			bulletinScripts[i] = require(item.bulletin)
		elseif not item.bulletinFnc then
			Config.log(2, "Failed to load mission "..i)
		end
	end
end

function MilitaryOutpost.getUpdateInterval()
    return 0.2--1
end

function MilitaryOutpost.updateServer(timeStep)
    MilitaryOutpost.updateBulletins(timeStep)
end


local updateFrequency
local updateTime

function MilitaryOutpost.updateBulletins(timeStep)
	local settings = GameSettings()
	
	math.randomseed(os.time())
	
    if not updateFrequency then
        -- more frequent updates when there are more ingredients
        updateFrequency = 60 * 30
		if settings.devMode then
			updateFrequency = 5
		end
    end

    if not updateTime then
        -- by adding half the time here, we have a chance that a factory immediately has a bulletin
        updateTime = 0

		if not settings.devMode then -- 5 sec update frequency in dev mode, no need to simulate
			local minutesSimulated = 50
			for i = 1, minutesSimulated do -- simulate bulletin posting / removing
				MilitaryOutpost.updateBulletins(60)
			end
		end
    end

    updateTime = updateTime + timeStep

    -- don't execute the following code if the time hasn't exceeded the posting frequency
    if updateTime < updateFrequency then return end
    updateTime = updateTime - updateFrequency
	
	Config.log(4, "Update bulletin")
	
	-- Determine if add a new mission or remove one
	local add
    if math.random() < 0.65 then
		add = true
    end
	
	local action = "add"
	if not add then action = "remove" end
	
	local scriptId = MilitaryOutpost.getMissionId(Config.Missions, add)
	
	--local script =  MilitaryOutpost.getMission(Config.Missions, add)
	local script =  Config.Missions[scriptId]
	
	
	if not script then
		Config.log(1, "Could not load bulletin script path.")
		return
	end
	
	local bulletin
	
	-- Vanilla missions bulletin must not be loaded from external file
	if script.bulletinFnc then
		if script.bulletinFnc == "getClear" then
			bulletin = MilitaryOutpost.getClear()
		elseif script.bulletinFnc == "getExplore" then
			bulletin = MilitaryOutpost.getExplore()
		end
	-- Modded missions bulletin must be loaded from external file instead
	elseif script.bulletin then
		Config.log(2,"Script: "..script.bulletin)
		
		if not bulletinScripts[scriptId] then
			Config.log(1,"Could not load bulletin script")
			return
		end
		
		-- Generate mission bulletin once per misson!
		local missionBulletin = bulletinScripts[scriptId].getBulletin()
		
		if not missionBulletin or not missionBulletin.script then
			Config.log(1,"No script set in bulletin or bulletin could not be loaded")
			return
		end
		
		Config.log(2,"brief: "..missionBulletin.brief)
		
		local target = bulletinScripts[scriptId].getTarget()
		local reward = bulletinScripts[scriptId].getReward()
		
		if not target then
			Config.log(1, "Could not load target, skipping")
			return
		end
		
		-- lets set some default values wich must not be set in plugins then
		bulletin =
		{
			brief = "Default mission",
			description = "",
			difficulty = "Medium /*difficulty*/"%_t,
			reward = "$${reward}",
			--script = "mods/MilitaryMissions/scripts/player/missions/example.lua", -- must be set in plugin
			arguments = {Entity().index, target.x, target.y, reward},
			formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
			msg = "The sector is \\s(%i:%i)."%_t,
			entityTitle = Entity().title,
			entityTitleArgs = Entity():getTitleArguments(),
			onAccept = [[
				local self, player = ...
				local title = self.entityTitle % self.entityTitleArgs
				player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
			]]
		}
		
		-- import mission script and set some vars. Script is required.
		if missionBulletin.brief then bulletin.brief = missionBulletin.brief end
		if missionBulletin.description then bulletin.description = missionBulletin.description end
		if missionBulletin.difficulty then bulletin.difficulty = missionBulletin.difficulty end
		if missionBulletin.msg then bulletin.msg = missionBulletin.msg end
		bulletin.script = missionBulletin.script
	end
	
	if not bulletin or not bulletin.script then
		Config.log(1, "Could not load bulletin")
		return
	end
	
	
	
	Config.log(3, action.." bulletin mission: "..bulletin.brief)
	
	if add then
		Entity():invokeFunction("bulletinboard", "postBulletin", bulletin)
	else
		Entity():invokeFunction("bulletinboard", "removeBulletin", bulletin.brief)
	end
end


function MilitaryOutpost.getMissionId(items, add)
	local distance = length(vec2(Sector():getCoordinates()))
	
	
    local probability = math.random() * 100
	local itemProbability
	local itemMaxDistance
	
	local tbl = {}
	for i in pairs(items) do
		tbl[i] = i
	end
	
	local shuffledItems = MilitaryOutpost.shuffleTable(tbl)
	
    for _,i in pairs(shuffledItems) do
		itemMaxDistance = items[i].maxDistance or math.huge
		if distance <= itemMaxDistance then
			itemProbability = items[i].probability or 100
			if probability <= itemProbability or not add then
				return i
			end
		end
	end
end

function MilitaryOutpost.shuffleTable( t )
    local j
 
    for i = #t, 2, -1 do
		j = math.random( i )
		t[i], t[j] = t[j], t[i]
    end
    return t
end


-- ###########################################################
-- Bulletin stuff below should be moved into plugins in future
-- ###########################################################

function MilitaryOutpost.getExplore()
    return MilitaryOutpost.getExploreSectorBulletin()
end

function MilitaryOutpost.getClear()
    return MilitaryOutpost.getClearSectorBulletin()
end

function MilitaryOutpost.getExploreSectorBulletin()
    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 10, 20)
    local serverSeed = Server().seed
    local target = nil

    for _, coord in pairs(coords) do
        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

        if not regular and offgrid and not blocked and not home then
            specs:initialize(coord.x, coord.y, serverSeed)

            --only sectors with containerfield, cultists, wreckage, pirates, resitance or smugglers should be used
            if specs.generationTemplate.path == "sectors/containerfield"
                or specs.generationTemplate.path == "sectors/cultists"
                or specs.generationTemplate.path == "sectors/functionalwreckage"
                or specs.generationTemplate.path == "sectors/pirateastroidfield"
                or specs.generationTemplate.path == "sectors/piratefight"
                or specs.generationTemplate.path == "sectors/piratestation"
                or specs.generationTemplate.path == "sectors/resitancecell"
                or specs.generationTemplate.path == "sectors/smugglerhideout"
                or specs.generationTemplate.path == "sectors/stationwreckage"
                or specs.generationTemplate.path == "sectors/wreckageastroidfield"
                or specs.generationTemplate.path == "sectors/wreckagefiled" then
                target = coord
            end
        end
    end

    if not target then return end

    local description = "We are interested in a nearby sector. We need someone to explore it in our name.\n\nSector: (${x} : ${y})"%_t

    reward =  MilitaryOutpost.generateReward(25000)

    local bulletin =
    {
        brief = "Explore Sector"%_t,
        description = description,
        difficulty = "Easy /*difficulty*/"%_t,
        reward = "$${reward}",
        script = "missions/exploresector/exploresector.lua",
        arguments = {Entity().index, target.x, target.y, reward},
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "The sector is \\s(%i:%i)."%_T,
        entityTitle = Entity().title,
        entityTitleArgs = Entity():getTitleArguments(),
        onAccept = [[
            local self, player = ...
            local title = self.entityTitle % self.entityTitleArgs
            player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]]
    }

    return bulletin

end

function MilitaryOutpost.getClearSectorBulletin()

    -- find a sector that has pirates
    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 2, 15)
    local serverSeed = Server().seed
    local target = nil

    for _, coord in pairs(coords) do
        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

        if offgrid and not blocked then
            specs:initialize(coord.x, coord.y, serverSeed)

            if specs.generationTemplate.path == "sectors/pirateasteroidfield" then
                if not Galaxy():sectorExists(coord.x, coord.y) then
                    target = coord
                    break
                end
            end
        end
    end

    if not target then return end

    local description = "A nearby sector has been occupied by pirates and they have been attacking our convoys and traders.\nWe cannot let that scum do whatever they like. We need someone to take care of them.\n\nSector: (${x} : ${y})"%_t

    reward =  MilitaryOutpost.generateReward(55000)

    local bulletin =
    {
        brief = "Wipe out Pirates"%_t,
        description = description,
        difficulty = "Medium /*difficulty*/"%_t,
        reward = "$${reward}",
        script = "missions/clearsector.lua",
        arguments = {Entity().index, target.x, target.y, reward},
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Their location is \\s(%i:%i)."%_T,
        entityTitle = Entity().title,
        entityTitleArgs = Entity():getTitleArguments(),
        onAccept = [[
            local self, player = ...
            local title = self.entityTitle % self.entityTitleArgs
            player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]]
    }

    return bulletin
end


function MilitaryOutpost.generateReward(amount)
    local reward = amount * Balancing.GetSectorRichnessFactor(Sector():getCoordinates())
    local faction = Faction(Entity().factionIndex)
    
    --The more generous, the more money they give. The more greedy, the less. (getTrait returns a -1,1 float i think)
    return reward + (reward * 0.25 * faction:getTrait("generous") )
end