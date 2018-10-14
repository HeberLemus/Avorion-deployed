local Config = {}

Config.Author = "Nexus, Dirtyredz, Hammelpilaw, Maxx4u, Laserzwei"
Config.ModName = "CarrierCommander"
Config.version = {
    major=1, minor=8, patch = 5,
    string = function()
        return  Config.version.major .. '.' ..
                Config.version.minor .. '.' ..
                Config.version.patch
    end
}

--new commands go here, <namespcae used by the script> = {name = <button text>, <path> = relative path from the /mods/-folder to the command, without .lua ending }
Config.carrierScripts = {
    dockAll = {name="Dock all Fighters", path = "mods/CarrierCommander/scripts/entity/ai/dockAllFighters"},
    salvage = {name="Salvage Command", path = "mods/CCBasicCommands/scripts/entity/ai/salvageCommand"},
    mine = {name="Mine Command", path = "mods/CCBasicCommands/scripts/entity/ai/mineCommand"},
    attack = {name="Attack Command", path = "mods/CCBasicCommands/scripts/entity/ai/aggressiveCommand"},
    repair = {name="Repair Command", path = "mods/CCBasicCommands/scripts/entity/ai/repairCommand"},
    loot = {name="lootCommand", path = "mods/CarrierCommander/scripts/entity/ai/"}
    --lootCommand = {name="Loot Command", path = "mods/CCLootPlugin/scripts/entity/ai/lootCommand"}
}


Config.basePriorities = {
    ship = 20,
    guardian = 15,
    station = 10,
    fighter = 5,
}
Config.additionalPriorities = { --Only for modded additions. Modders: When creating a new Boss then use Entity():setValue("customBoss", someValidValue), to mark it. The Attack script will then activley search for those marked enemies and assign the priority set in the config

    --customBoss = 25
}

return Config