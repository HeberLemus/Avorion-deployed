local DockBuilderConfig = {}

DockBuilderConfig.Author = "Theoman02/Hammelpilaw/Dirtyredz/Laserzwei"
DockBuilderConfig.Version = "[1.0.0]"
DockBuilderConfig.ModName = "[DockBuilder]"

DockBuilderConfig.ScriptStations = {}

--[[ ##### Dockbuilding settings #######
	Chose prices for the buildings.
	To remove a factory from build list set price to 0, then it can't be created anymore.
]]
DockBuilderConfig.ScriptStations.equipmentDock = 50000000		-- Equipment Dock
DockBuilderConfig.ScriptStations.turretFactory = 40000000		-- Turret Factory
DockBuilderConfig.ScriptStations.researchStation = 50000000	-- Research Station
DockBuilderConfig.ScriptStations.repairDock = 30000000		-- Repair Dock
DockBuilderConfig.ScriptStations.shipyard = 50000000			-- Shipyard
DockBuilderConfig.ScriptStations.fighterfactory = 50000000	-- Fighter Factory
DockBuilderConfig.ScriptStations.resourcetrader = 40000000	-- Resource Trader

return DockBuilderConfig
