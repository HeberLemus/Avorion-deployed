--if onServer() then
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("faction")
require ("utility")

--required Data
lootCommand = {}
lootCommand.prefix = nil
lootCommand.active = false
lootCommand.squads = {}                  --[squadIndex] = squadIndex           --squads to manage
lootCommand.controlledFighters = {}      --[1-120] = fighterIndex        --List of all started fighters this command wants to controll/watch
--data
lootCommand.loot2FightersAndAnchor = {}
lootCommand.fighters2Loot = {}
lootCommand.freeFighters = {}
lootCommand.debugLogEnabled = false

--required UI
lootCommand.needsButton = true
lootCommand.inactiveButtonCaption = "Carrier - Start Collecting Loot"
lootCommand.activeButtonCaption = "Carrier - Stop Collecting Loot"                 --Notice: the activeButtonCaption shows the caption WHILE the command is active
lootCommand.activeTooltip = cc.l.actionTostringMap[7]
lootCommand.inactiveTooltip = cc.l.actionTostringMap[-1]

local waitTime = 0

function lootCommand.init()
	
end

function lootCommand.initConfigUI(scrollframe, pos, size)
    local label = scrollframe:createLabel(pos, "Looting config", 15)
    label.tooltip = "Select the Squad used for collecting loot."
    label.fontSize = 15
    label.font = FontType.Normal
    label.size = vec2(size.x-20, 35)
    pos = pos + vec2(0,35)

    local comboBox = scrollframe:createValueComboBox(Rect(pos+vec2(35,5),pos+vec2(200,25)), "onComboBoxSelected")
    cc.l.uiElementToSettingMap[comboBox.index] = "lootSquad"
	local hangar = Hangar()
	comboBox:addEntry(-1,"Choose Squad")	
	local squads = {hangar:getSquads()}
	local index, validSquad = next(squads, nil)
	local squadName = ""
	for squad = 0, 9 do		
		if(squad == validSquad) then
			squadName = hangar:getSquadName(squad)
			index, validSquad = next(squads, index)
		else
			squadName = " - "
		end
		comboBox:addEntry(squad,"Squad " .. (squad + 1) .. ": " .. squadName)	
	end
	
    pos = pos + vec2(0,35)

	local checkBox = scrollframe:createCheckBox(Rect(pos+vec2(0,5),pos+vec2(size.x-35, 25)), "Loot Ejected Pilots", "onCheckBoxChecked")
    cc.l.uiElementToSettingMap[checkBox.index] = lootCommand.prefix.."lootEjectedPilots"
    checkBox.tooltip = "Determines whether ejected pilots get picked up (checked), or not (unchecked)"
    checkBox.captionLeft = false
    checkBox.fontSize = 14
    pos = pos + vec2(0,35)

	local checkBox = scrollframe:createCheckBox(Rect(pos+vec2(0,5),pos+vec2(size.x-35, 25)), "Loot Turrets", "onCheckBoxChecked")
    cc.l.uiElementToSettingMap[checkBox.index] = lootCommand.prefix.."lootTurrets"
    checkBox.tooltip = "Determines whether turret loot gets picked up (checked), or not (unchecked)"
    checkBox.captionLeft = false
    checkBox.fontSize = 14
    pos = pos + vec2(0,35)

	local checkBox = scrollframe:createCheckBox(Rect(pos+vec2(0,5),pos+vec2(size.x-35, 25)), "Loot System Upgrades", "onCheckBoxChecked")
    cc.l.uiElementToSettingMap[checkBox.index] = lootCommand.prefix.."lootSystemUpgrades"
    checkBox.tooltip = "Determines whether system upgrade loot gets picked up (checked), or not (unchecked)"
    checkBox.captionLeft = false
    checkBox.fontSize = 14
    pos = pos + vec2(0,35)

	local checkBox = scrollframe:createCheckBox(Rect(pos+vec2(0,5),pos+vec2(size.x-35, 25)), "Loot Colors", "onCheckBoxChecked")
    cc.l.uiElementToSettingMap[checkBox.index] = lootCommand.prefix.."lootColors"
    checkBox.tooltip = "Determines whether color loot gets picked up (checked), or not (unchecked)"
    checkBox.captionLeft = false
    checkBox.fontSize = 14
    pos = pos + vec2(0,35)
	
	local checkBox = scrollframe:createCheckBox(Rect(pos+vec2(0,5),pos+vec2(size.x-35, 25)), "Loot Resources", "onCheckBoxChecked")
    cc.l.uiElementToSettingMap[checkBox.index] = lootCommand.prefix.."lootResources"
    checkBox.tooltip = "Determines whether resource loot gets picked up (checked), or not (unchecked)"
    checkBox.captionLeft = false
    checkBox.fontSize = 14
    pos = pos + vec2(0,35)
	
	local checkBox = scrollframe:createCheckBox(Rect(pos+vec2(0,5),pos+vec2(size.x-35, 25)), "Loot Money", "onCheckBoxChecked")
    cc.l.uiElementToSettingMap[checkBox.index] = lootCommand.prefix.."lootMoney"
    checkBox.tooltip = "Determines whether money loot gets picked up (checked), or not (unchecked)"
    checkBox.captionLeft = false
    checkBox.fontSize = 14
    pos = pos + vec2(0,35)

    return pos
end

-- returns the position of the available fighter or the mothership (in case there are only docked fighters available), otherwise nil
function lootCommand.isFighterAvailable()
	fighterId, value = next(lootCommand.freeFighters, nil)
	if(fighterId and Entity(fighterId)) then	
		return Entity(fighterId).translationf
	end 
	
	for _,squad in pairs(lootCommand.squads) do
		if(Hangar():getSquadFighters(squad) > 0) then
			return Entity().translationf
		end
	end
	return nil
end

function lootCommand.getFreeFighter()
	local fighterId = nil
	local value = nil
	fighterId, value = next(lootCommand.freeFighters, nil)

	if(fighterId) then
		lootCommand.debugLog("free fighter found: " .. tostring(fighterId) .. " / " .. tostring(lootCommand.freeFighters[fighterId]))
		return fighterId
	end
	local fighterController = FighterController()
	for _,squad in pairs(lootCommand.squads) do
		lootCommand.debugLog("Squad: " .. squad)
		fighter = fighterController:startFighter(squad, 0)
		if(fighter ~= nil) then
			lootCommand.debugLog("started fighter " .. tostring(fighter.index))
			lootCommand.freeFighters[fighter.index.string] = true
			return fighter.index.string
		end
	end
	return nil
end

function lootCommand.sendFighterAfterLoot(fighterId, loot)
	local blockPlan = BlockPlan()
	blockPlan:addBlock(vec3(0,0,0), vec3(.1,.1,.1), 0, -1, Color(), Material(MaterialType.Iron), Matrix(), BlockType.Hull);
	local matrix = Matrix()
	matrix.translation = loot.translationf;
	local fighterFlyToAnchor = Sector():createWreckage(blockPlan, matrix)
	local fighterAI = FighterAI(fighterId)
	if(fighterAI == nil) then
		if(lootCommand.freeFighters[fighterId]) then
			lootCommand.debugLog("fighter seems to have redocked, removing " .. tostring(fighterId) .. " from freeFighters")
			lootCommand.freeFighters[fighterId] = nil
		end		
		return
	end 
	lootCommand.debugLog("setting fly order for fighter " .. tostring(fighterId) .. " to loot " .. loot.index.string)
	fighterAI:setOrders(FighterOrders.FlyToLocation, fighterFlyToAnchor.index)
	lootCommand.debugLog("removing " .. tostring(fighterId) .. " from freeFighters")
	lootCommand.freeFighters[fighterId] = nil
	lootCommand.fighters2Loot[fighterId] = loot.index.string
	lootCommand.loot2FightersAndAnchor[loot.index.string] = {fighter = fighterId, anchor = fighterFlyToAnchor.index.string}
end

function lootCommand.collectLoot()	

	local maxloop = 12
	while (maxloop > 0) do	
		local position = lootCommand.isFighterAvailable()
		lootCommand.debugLog("available fighter position: " .. tostring(position))
		if(not position) then
			local squad, _ = next(lootCommand.squads)
			if(Hangar():getSquadMaxFighters(squad) == 0) then
				if(lootCommand.findLoot(Entity().translationf)) then
					cc.applyCurrentAction(lootCommand.prefix, "targetButNoFighter")
				end
			end
			return
		end
		local loot = lootCommand.findLoot(position)
		if(not loot) then 
			local lootId, _ = next(lootCommand.loot2FightersAndAnchor)
			if(not lootId) then
				cc.applyCurrentAction(lootCommand.prefix, "idle")
			end
			return 
		end

		local fighterId = lootCommand.getFreeFighter()
		if(not fighterId) then 
			return 
		end
		cc.applyCurrentAction(lootCommand.prefix, 7)
		lootCommand.sendFighterAfterLoot(fighterId, loot)

		maxloop = maxloop - 1
	end
end

function lootCommand.getSquadsToManage()
    local hangar = Hangar(Entity().index)
    if not hangar then cc.applyCurrentAction(lootCommand.prefix, "noHangar") return false end
	local squad = cc.settings["lootSquad"]
	if(squad == -1 or squad == nil) then
		lootCommand.debugLog("managed squad: none")
		return false
	end
	lootCommand.squads = {squad = squad}
	lootCommand.debugLog("managed squad: " .. squad)
	return true
end

-- check the sector for loot
function lootCommand.findLoot(fighterPosition)
    local lootItems = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()
	local shortestDistance2 = math.huge;
	local lootItem = nil
    for _, loot in pairs(lootItems) do
		if(    lootCommand.loot2FightersAndAnchor[loot.index.string] == nil and 
			  ((cc.settings[lootCommand.prefix.."lootEjectedPilots"] and loot:hasComponent(ComponentType.CrewLoot))
			or (cc.settings[lootCommand.prefix.."lootTurrets"] and loot:hasComponent(ComponentType.TurretLoot))
			or (cc.settings[lootCommand.prefix.."lootSystemUpgrades"] and loot:hasComponent(ComponentType.SystemUpgradeLoot))
			or (cc.settings[lootCommand.prefix.."lootColors"] and loot:hasComponent(ComponentType.ColorLoot))
			or (cc.settings[lootCommand.prefix.."lootResources"] and loot:hasComponent(ComponentType.ResourceLoot))
			or (cc.settings[lootCommand.prefix.."lootMoney"] and loot:hasComponent(ComponentType.MoneyLoot)))
			) then
		
			local distance2 = distance2(loot.translationf, fighterPosition)
			if loot:isCollectable(ship) and distance2 < shortestDistance2 then
				lootItem = loot
				shortestDistance2 = distance2            
			end
		end
    end

	return lootItem	
end

function lootCommand.fighterLanded(entityId, squadIndex, fighterId) 
	lootCommand.freeFighters[fighterId.string] = nil;
end

function onLootCollected(collector, lootIndex) 
	lootCommand.lootIsGone(lootIndex.string)
end

function lootCommand.lootIsGone(lootId) 
	local fighterAndAnchor = lootCommand.loot2FightersAndAnchor[lootId]
	if(fighterAndAnchor == nil) then 
		return 
	end
	local fighterId = fighterAndAnchor["fighter"]
	local anchorId = fighterAndAnchor["anchor"]
	lootCommand.loot2FightersAndAnchor[lootId] = nil
	lootCommand.fighters2Loot[fighterId] = nil
	lootCommand.freeFighters[fighterId] = true
	local fighterAI = FighterAI(fighterId)
	if(fighterAI) then
		lootCommand.debugLog("ordering Fighter " .. fighterAI.entity.index.string .. " to return to " .. Entity().index.string)
		FighterAI(fighterId):setOrders(FighterOrders.Return, Entity().index)
	end
	
	local entity = Entity(anchorId)
	if(valid(entity)) then
		lootCommand.debugLog("removing anchor " .. anchorId .. " / " .. tostring(valid(entity)) .. " / " .. entity.index.string)
		entity:setPlan(BlockPlan()) -- delete the anchor wreckage
	end
end

function lootCommand.checkAndAdjustAnchor(lootId, fighterId, anchorId)
	local loot = Entity(lootId)
	local anchor = Entity(anchorId)
	if(valid(loot) and not anchor) then 
		lootCommand.sendFighterAfterLoot(fighterId, loot)
		return
	end
	if (distance2(loot.translationf, anchor.translationf) > 1) then
		anchor.translation = loot.translation
	end
end

function lootCommand.updateServer(timestep)
	waitTime = waitTime - timestep
	if waitTime <= 0 then
		if lootCommand.active then
			for lootId, fighterAndAnchor in pairs(lootCommand.loot2FightersAndAnchor) do
				if(not valid(Entity(lootId))) then
					lootCommand.lootIsGone(lootId)
				else 
					lootCommand.checkAndAdjustAnchor(lootId, fighterAndAnchor["fighter"], fighterAndAnchor["anchor"])
				end
			end
			lootCommand.collectLoot()
		end
		waitTime = 5
	end
end

--<button> is clicked button-Object onClient and prefix onServer
function lootCommand.activate(button)
    if onClient() then
        cc.l.tooltipadditions[lootCommand.prefix] = "+ Looting"
        cc.setAutoAssignTooltip(cc.autoAssignButton.onPressedFunction == "StopAutoAssign")

        return
    end
	lootCommand.squads = {}
	if(not lootCommand.getSquadsToManage()) then cc.applyCurrentAction(lootCommand.prefix, "targetButNoFighter") end
	Sector():registerCallback("onLootCollected", "onLootCollected")
	lootCommand.collectLoot()
end

--<button> is clicked button-Object onClient and prefix onServer
function lootCommand.deactivate(button)
    if onClient() then
        cc.l.tooltipadditions[lootCommand.prefix] = "- Stopped Looting"
        cc.setAutoAssignTooltip(cc.autoAssignButton.onPressedFunction == "StopAutoAssign")
        return
    end
    -- space for stuff to do e.g. landing your fighters
    -- When docking: Make sure to not reset template.squads
    cc.applyCurrentAction(lootCommand.prefix, FighterOrders.Return)
end

function lootCommand.debugLog(logMsg)
	if(lootCommand.debugLogEnabled) then
		print(logMsg)
	end
end

return lootCommand
--end
