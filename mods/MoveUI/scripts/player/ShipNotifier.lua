-- Author: DracoNB
-- Version: 1.0
-- Requires MoveUI - Dirtyredz|David McClain
package.path = package.path .. ";mods/MoveUI/scripts/lib/?.lua"
local MoveUI = require('MoveUI')

package.path = package.path .. ";data/scripts/lib/?.lua"
FactionsMap = require ("factionsmap")
require ("stringutility")

-- namespace ShipNotifier
ShipNotifier = {}

local OverridePosition

local Title = 'ShipNotifier'
local Icon = "data/textures/icons/fighter.png"
local Description = "Will display ships in the current sector."
local DefaultOptions = {
    AllowFriendlyShips = true,
    AllowCivilianShips = true,
    AllowClickable = true,
    FriendlyRelationAmount = 0,
    FS = 15 -- Font Size
}
local AllowFriendlyShips_OnOff
local AllowCivilianShips_OnOff
local AllowClickable_OnOff
local FriendlyRelationAmount_Slide
local FS_Slide

local ShipData

local FactionData
local rect
local res
local DefaulPosition
local LoadedOptions
local AllowMoving
local ScanSectorTimer = 5
local player
local RelationColors = {
    {Relation = -100000, R = 0.9, G = 0, B = 0.1},
    {Relation = -90000, R = 0.9, G = 0, B = 0},
    {Relation = -80000, R = 0.9, G = 0, B = 0},
    {Relation = -70000, R = 0.9, G = 0, B = 0},
    {Relation = -60000, R = 0.9, G = 0, B = 0},
    {Relation = -50000, R = 0.75, G = 0, B = 0.2},
    {Relation = -40000, R = 0.6, G = 0, B = 0.2},
    {Relation = -30000, R = 0.5, G = 0, B = 0.4},
    {Relation = -20000, R = 0.4, G = 0, B = 0.6},
    {Relation = -10000, R = 0.2, G = 0, B = 0.8},
    {Relation = 0, R = 0.3, G = 0, B = 1},
    {Relation = 10000, R = 0.4, G = 1, B = 0.9},
    {Relation = 20000, R = 0.3, G = 1, B = 0.8},
    {Relation = 30000, R = 0.2, G = 1, B = 0.7},
    {Relation = 40000, R = 0.1, G = 1, B = 0.6},
    {Relation = 50000, R = 0, G = 1, B = 0.5},
    {Relation = 60000, R = 0, G = 1, B = 0.4},
    {Relation = 70000, R = 0, G = 1, B = 0.3},
    {Relation = 80000, R = 0, G = 1, B = 0.2},
    {Relation = 90000, R = 0, G = 1, B = 0.1},
    {Relation = 100000, R = 0, G = 1, B = 0}
}
function ShipNotifier.initialize()
    if onClient() then
        player = Player()

        player:registerCallback("onPreRenderHud", "onPreRenderHud")
        ShipNotifier.detect()
        LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)

        rect = Rect(vec2(), vec2(150, 200))
        res = getResolution();
        DefaulPosition = vec2(res.x * 0.73, res.y * 0.85)
        rect.position = MoveUI.CheckOverride(player, DefaulPosition, OverridePosition, Title)
    end
end

function ShipNotifier.buildTab(tabbedWindow)
    local FileTab = tabbedWindow:createTab("", Icon, Title)
    local container = FileTab:createContainer(Rect(vec2(0, 0), FileTab.size));

    --split it 30/70
    local mainSplit = UIHorizontalSplitter(Rect(vec2(0, 0), FileTab.size), 0, 0, 0.3)

    --Top Message
    local TopHSplit = UIHorizontalSplitter(mainSplit.top, 0, 0, 0.3)
    local TopMessage = container:createLabel(TopHSplit.top.lower + vec2(10, 10), Title, 16)
    TopMessage.centered = 1
    TopMessage.size = vec2(FileTab.size.x - 40, 20)

    local Description = container:createTextField(TopHSplit.bottom, Description)

    local OptionsSplit = UIHorizontalMultiSplitter(mainSplit.bottom, 0, 0, 8)

    local TextVSplit = UIVerticalSplitter(OptionsSplit:partition(0), 0, 5, 0.65)
    local name = container:createLabel(TextVSplit.left.lower, "Show Friendly Ships", 16)
    AllowFriendlyShips_OnOff = container:createCheckBox(TextVSplit.right, "On / Off", 'onAllowFriendlyShips')
    AllowFriendlyShips_OnOff.tooltip = 'Will show friendly ships as well.'

    local TextVSplit = UIVerticalSplitter(OptionsSplit:partition(1), 0, 5, 0.65)
    local name = container:createLabel(TextVSplit.left.lower, "Show Civilian Ships", 16)
    AllowCivilianShips_OnOff = container:createCheckBox(TextVSplit.right, "On / Off", 'onAllowCivilianShips')
    AllowCivilianShips_OnOff.tooltip = 'Will show civilian ships as well.'

    local TextVSplit = UIVerticalSplitter(OptionsSplit:partition(2), 0, 5, 0.65)
    local name = container:createLabel(TextVSplit.left.lower, "Allow Clicking to select Ship", 16)
    AllowClickable_OnOff = container:createCheckBox(TextVSplit.right, "On / Off", 'onAllowClickable')
    AllowClickable_OnOff.tooltip = 'Select ships by clicking on them in mouse mode (will sometimes trigger while panning mouse).'

    local TextVSplit = UIVerticalSplitter(OptionsSplit:partition(3), 0, 5, 0.65)
    local name = container:createLabel(TextVSplit.left.lower, "Friendly Faction Amount", 16)
    FriendlyRelationAmount_Slide = container:createSlider(TextVSplit.right, - 100000, 100000, 80, "Faction Amount", 'onChangeFriendlyRelationAmount')
    FriendlyRelationAmount_Slide.tooltip = 'What relation amount you want to show as friendly faction (Default 0 for Neutral).'

    local TextVSplit = UIVerticalSplitter(OptionsSplit:partition(5), 0, 5, 0.65)
    local name = container:createLabel(TextVSplit.left.lower, "Font Size", 16)
    FS_Slide = container:createSlider(TextVSplit.right, 10, 30, 20, "Font Size", 'onChangeFont')
    FS_Slide.tooltip = 'Changes the Font size and rect size.'

    --Pass the name of the function, and the checkbox
    return {checkbox = {onAllowFriendlyShips = AllowFriendlyShips_OnOff, onAllowCivilianShips = AllowCivilianShips_OnOff, onAllowClickable = AllowClickable_OnOff}, button = {}, slider = {onChangeFont = FS_Slide, onChangeFriendlyRelationAmount = FriendlyRelationAmount_Slide}}
end

function ShipNotifier.onChangeFont(slider)
    local LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    MoveUI.SetVariable(Title.."_Opt", {FS = slider.value, AllowFriendlyShips = LoadedOptions.AllowFriendlyShips, AllowCivilianShips = LoadedOptions.AllowCivilianShips, AllowClickable = LoadedOptions.AllowClickable, FriendlyRelationAmount = LoadedOptions.FriendlyRelationAmount})
end

function ShipNotifier.onAllowFriendlyShips(checkbox, value)
    local LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    MoveUI.SetVariable(Title.."_Opt", {AllowFriendlyShips = value, FS = LoadedOptions.FS, AllowCivilianShips = LoadedOptions.AllowCivilianShips, AllowClickable = LoadedOptions.AllowClickable, FriendlyRelationAmount = LoadedOptions.FriendlyRelationAmount})
end

function ShipNotifier.onAllowCivilianShips(checkbox, value)
    local LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    MoveUI.SetVariable(Title.."_Opt", {AllowFriendlyShips = LoadedOptions.AllowFriendlyShips, FS = LoadedOptions.FS, AllowCivilianShips = value, AllowClickable = LoadedOptions.AllowClickable, FriendlyRelationAmount = LoadedOptions.FriendlyRelationAmount})
end

function ShipNotifier.onAllowClickable(checkbox, value)
    local LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    MoveUI.SetVariable(Title.."_Opt", {AllowFriendlyShips = LoadedOptions.AllowFriendlyShips, FS = LoadedOptions.FS, AllowCivilianShips = LoadedOptions.AllowCivilianShips, AllowClickable = value, FriendlyRelationAmount = LoadedOptions.FriendlyRelationAmount})
end

function ShipNotifier.onChangeFriendlyRelationAmount(slider)
    local LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    MoveUI.SetVariable(Title.."_Opt", {AllowFriendlyShips = LoadedOptions.AllowFriendlyShips, FS = LoadedOptions.FS, AllowCivilianShips = LoadedOptions.AllowCivilianShips, AllowClickable = LoadedOptions.AllowClickable, FriendlyRelationAmount = slider.value})
end

--Executed when the Main UI Interface is opened.
function ShipNotifier.onShowWindow()
    --Get the player options
    local LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    AllowFriendlyShips_OnOff.checked = LoadedOptions.AllowFriendlyShips
    AllowCivilianShips_OnOff.checked = LoadedOptions.AllowCivilianShips
    AllowClickable_OnOff.checked = LoadedOptions.AllowClickable
    FriendlyRelationAmount_Slide:setValueNoCallback(LoadedOptions.FriendlyRelationAmount)
    FS_Slide:setValueNoCallback(LoadedOptions.FS)
end

function ShipNotifier.onPreRenderHud()
    if onClient() then
        if not LoadedOptions.FS then LoadedOptions.FS = 15 end
        local NewRect = Rect(rect.lower, rect.upper + vec2(22 * (LoadedOptions.FS - 10), 8 * (LoadedOptions.FS - 10)))

        if ShipData then
            local Length = #ShipData.Ships - 1
            Length = Length * 15
            NewRect = Rect(rect.lower, rect.upper + vec2(22 * (LoadedOptions.FS - 10), Length + 8 * (LoadedOptions.FS - 10)))
        end

        if OverridePosition then
            rect.position = OverridePosition
        end

        if AllowMoving then
            OverridePosition, Moving = MoveUI.Enabled(NewRect, OverridePosition)
            if OverridePosition and not Moving then
                MoveUI.AssignPlayerOverride(Title, OverridePosition)
                OverridePosition = nil
            end

            drawTextRect(Title, NewRect, 0, 0, ColorRGB(1, 1, 1), 10, 0, 0, 0)
            return
        end

        drawRect(NewRect, ColorARGB(0.2, 0.1, 0.1, 0.1))
        if not ShipData then return end

        local enemyShips = {}
        local enemyCivShips = {}
        local friendlyShips = {}
        local friendlyCivShips = {}
        local FontSize = LoadedOptions.FS or 15

        if (#ShipData.Ships < 2) then -- We don't count
            drawTextRect("No Ships Detected", NewRect, - 1, 0, ColorRGB(0, 1, 0), FontSize, 0, 0, 0)
            return
        end

        local maxSize = -1 -- We don't want to count the player

        -- We can't split these on the server side due to the options not being there.. doh!
        for _, ship in pairs(ShipData.Ships) do
            local isPlayersShip = ship.index == player.craftIndex
            if (not isPlayersShip) then
                if (ship.relation >= LoadedOptions.FriendlyRelationAmount) then
                    if (ship.civilship) then
                        table.insert(friendlyCivShips, ship)
                    else
                        table.insert(friendlyShips, ship)
                    end
                else
                    if (ship.civilship) then
                        table.insert(enemyCivShips, ship)
                    else
                        table.insert(enemyShips, ship)
                    end
                end
            end
        end

        -- We need to get the count, plus a header for each
        if (#friendlyCivShips > 0) then
            maxSize = maxSize + #friendlyCivShips + 1
        end

        if (#friendlyShips > 0) then
            maxSize = maxSize + #friendlyShips + 1
        end
        if (#enemyCivShips > 0) then
            maxSize = maxSize + #enemyCivShips + 1
        end
        if (#enemyShips > 0) then
            maxSize = maxSize + #enemyShips + 1
        end

        local HSplit = UIHorizontalMultiSplitter(NewRect, 5, 5, math.max(maxSize, 10))

        local textPlane = 0

        if #enemyShips > 0 then
            drawTextRect("Enemy Ships:", HSplit:partition(textPlane), - 1, 0, ColorRGB(0.8, 0, 0.1), FontSize, 0, 0, 0)
            textPlane = textPlane + 1
            for _, shipData in pairs(enemyShips) do
                local MainVSplit = UIVerticalSplitter(HSplit:partition(textPlane), 5, 5, 0.80)
                drawTextRect(shipData.title .. " (" .. shipData.name .. ")", MainVSplit.left, - 1, 0, ColorRGB(GetRelationColor(shipData.relation)), FontSize - 2, 0, 0, 0)
                --drawRect(HSplit:partition(textPlane), ColorARGB(0.2, 0.1, 0.1, 0.1))
                if LoadedOptions.AllowClickable then
                    ShipNotifier.AllowClick(player, HSplit:partition(textPlane), (function () Player().selectedObject = Entity(shipData.index) end))
                end
                textPlane = textPlane + 1
            end
        end

        if LoadedOptions.AllowCivilianShips and #enemyCivShips > 0 then
            drawTextRect("Enemy Civilian Ships: ", HSplit:partition(textPlane), - 1, 0, ColorRGB(0.9, 0, 0.1), FontSize, 0, 0, 0)
            textPlane = textPlane + 1

            for _, shipData in pairs(enemyCivShips) do
                local MainVSplit = UIVerticalSplitter(HSplit:partition(textPlane), 5, 5, 0.80)
                drawTextRect(shipData.title .. " (" .. shipData.name .. ")", MainVSplit.left, - 1, 0, ColorRGB(GetRelationColor(shipData.relation)), FontSize - 2, 0, 0, 0)
                if LoadedOptions.AllowClickable then
                    ShipNotifier.AllowClick(player, HSplit:partition(textPlane), (function () Player().selectedObject = Entity(shipData.index) end))
                end
                textPlane = textPlane + 1
            end
        end

        if LoadedOptions.AllowFriendlyShips and #friendlyShips > 1 then
            drawTextRect("Friendly Ships:", HSplit:partition(textPlane), - 1, 0, ColorRGB(0, 1, 0), FontSize, 0, 0, 0)
            textPlane = textPlane + 1
            for _, shipData in pairs(friendlyShips) do
                local MainVSplit = UIVerticalSplitter(HSplit:partition(textPlane), 5, 5, 0.80)
                drawTextRect(shipData.title .. " (" .. shipData.name .. ")", MainVSplit.left, - 1, 0, ColorRGB(GetRelationColor(shipData.relation)), FontSize - 2, 0, 0, 0)
                if LoadedOptions.AllowClickable then
                    ShipNotifier.AllowClick(player, HSplit:partition(textPlane), (function () Player().selectedObject = Entity(shipData.index) end))
                end
                textPlane = textPlane + 1
            end
        end

        if LoadedOptions.AllowFriendlyShips and LoadedOptions.AllowCivilianShips and #friendlyCivShips > 0 then
            drawTextRect("Civilian Ships: ", HSplit:partition(textPlane), - 1, 0, ColorRGB(0, 1, 0), FontSize, 0, 0, 0)
            textPlane = textPlane + 1

            for _, shipData in pairs(friendlyCivShips) do
                local MainVSplit = UIVerticalSplitter(HSplit:partition(textPlane), 5, 5, 0.80)
                drawTextRect(shipData.title .. " (" .. shipData.name .. ")", MainVSplit.left, - 1, 0, ColorRGB(GetRelationColor(shipData.relation)), FontSize - 2, 0, 0, 0)
                if LoadedOptions.AllowClickable then
                    ShipNotifier.AllowClick(player, HSplit:partition(textPlane), (function () Player().selectedObject = Entity(shipData.index) end))
                end
                textPlane = textPlane + 1
            end
        end
    end
end

function ShipNotifier.AllowClick(player, rect, func)
    local mouse = Mouse()
    local Inside = false

    if mouse.position.x < rect.upper.x and mouse.position.x > rect.lower.x then
        if mouse.position.y < rect.upper.y and mouse.position.y > rect.lower.y then
            Inside = true
            drawRect(rect, ColorARGB(0.2, 0.1, 0.1, 0.1))
        end
    end

    if Inside and (mouse:mouseDown(3) or mouse:mouseDown(1)) then -- middle mouse button deselects right away :(
        func()
    end
    --end
end

function ShipNotifier.updateClient(timeStep)
    ScanSectorTimer = ScanSectorTimer - timeStep
    if ScanSectorTimer < 0 then
        ShipNotifier.detect()
    end
    LoadedOptions = MoveUI.GetVariable(Title.."_Opt", DefaultOptions)
    AllowMoving = MoveUI.AllowedMoving()
end

function ShipNotifier.getUpdateInterval()
    return 1
end

function ShipNotifier.onSectorEntered(playerIndex)
    ShipNotifier.detect()
end

function ShipNotifier.detect()
    if onClient() then
        invokeServerFunction('detect')
        return
    end

    local ships = {Sector():getEntitiesByType(EntityType.Ship)}

    local playerFaction = Faction()

    ShipData = {}
    ShipData.Ships = {}

    for _, ship in pairs(ships) do
        local index = ship.index
        local name = ship.name
        local title = ship.translatedTitle
        local factionIndex = ship.factionIndex
        local civilship = ship:hasScript("civilship.lua")
        local relation = playerFaction:getRelations(factionIndex)
        --print (tostring(name) .. " | " .. tostring(title) .. " | " .. tostring(factionIndex) .. " | " .. tostring(civilship) .. " | " .. tostring(relation))
        local shipData = {index = index, name = name, title = title, factionIndex = factionIndex, civilship = civilship, relation = relation}
        table.insert(ShipData.Ships, shipData)
    end

    ShipNotifier.sync()
end

function ShipNotifier.sync(values)
    if onClient() then
        if values then
            ShipData = values.ShipData
            return
        end
        invokeServerFunction('sync')
    end

    invokeClientFunction(Player(), 'sync', {ShipData = ShipData})
end

function GetRelationColor(relation)
    for _, RC in pairs(RelationColors) do
        local result = RC.Relation - relation
        --print(RC.Relation,relation,math.abs(result))
        if math.abs(result) < 10000 then
            return RC.R, RC.G, RC.B
        end
    end
end

return ShipNotifier
