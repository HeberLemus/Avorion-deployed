package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

-- this key is dropped by the 4

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

function getBonuses(seed, rarity)

    local energy = 0.9
    local recharge = 0.25
    local militarySlots = 20
    local arbitrarySlots = 10
    local civilSlots = 20
    local shields = 0.45

    local hsReach = 10
    local hsCdFactor = -0.6
    local hsEnergy = -0.55

    local cargo = 0.7
    local velocity = 0.5

    local lootRange = 40
    local deepScan = 7
    local radar = 9

    return energy, recharge, militarySlots, arbitrarySlots, civilSlots, shields, hsReach, hsCdFactor, hsEnergy, cargo, velocity, lootRange, deepScan, radar
end

function onInstalled(seed, rarity, permanent)
    if not permanent then return end

    local energy, recharge, militarySlots, arbitrarySlots, civilSlots, shields, hsReach, hsCdFactor, hsEnergy, cargo, velocity, lootRange, deepScan, radar = getBonuses(seed, rarity)

    addBaseMultiplier(StatsBonuses.GeneratedEnergy, energy)
    addBaseMultiplier(StatsBonuses.BatteryRecharge, recharge)

    addAbsoluteBias(StatsBonuses.ArmedTurrets, militarySlots)
    addAbsoluteBias(StatsBonuses.ArbitraryTurrets, arbitrarySlots)
    addAbsoluteBias(StatsBonuses.UnarmedTurrets, civilSlots)

    addBaseMultiplier(StatsBonuses.ShieldDurability, shields)

    addAbsoluteBias(StatsBonuses.HyperspaceReach, hsReach)
    addBaseMultiplier(StatsBonuses.HyperspaceCooldown, hsCdFactor)
    addBaseMultiplier(StatsBonuses.HyperspaceRechargeEnergy, hsEnergy)

    addBaseMultiplier(StatsBonuses.CargoHold, cargo)

    addBaseMultiplier(StatsBonuses.Velocity, velocity)

    addAbsoluteBias(StatsBonuses.LootCollectionRange, lootRange)

    addAbsoluteBias(StatsBonuses.HiddenSectorRadarReach, deepScan)
    addAbsoluteBias(StatsBonuses.RadarReach, radar)

end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "XSTN-K V"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/key5.png"
end

function getPrice(seed, rarity)
    return 10000
end

function getTooltipLines(seed, rarity, permanent)
    local energy, recharge, militarySlots, arbitrarySlots, civilSlots, shields, hsReach, hsCdFactor, hsEnergy, cargo, velocity, lootRange, deepScan, radar = getBonuses(seed, rarity)

    local texts =
    {
        {ltext = "Generated Energy"%_t, rtext = string.format("%+i%%", energy * 100), icon = "data/textures/icons/electric.png", boosted = permanent},
        {ltext = "Recharge Rate"%_t, rtext = string.format("%+i%%", recharge * 100), icon = "data/textures/icons/energise.png", boosted = permanent},

        {ltext = "Armed Turret Slots"%_t, rtext = "+" .. militarySlots, icon = "data/textures/icons/turret.png", boosted = permanent},
        {ltext = "Armed or Unarmed Turret Slots"%_t, rtext = "+" .. arbitrarySlots, icon = "data/textures/icons/turret.png", boosted = permanent},
        {ltext = "Unarmed Turret Slots"%_t, rtext = "+" .. civilSlots, icon = "data/textures/icons/turret.png", boosted = permanent},

        {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", shields * 100), icon = "data/textures/icons/health-normal.png", boosted = permanent},

        {ltext = "Jump Range"%_t, rtext = string.format("%+i", hsReach), icon = "data/textures/icons/star-cycle.png", boosted = permanent},
        {ltext = "Hyperspace Cooldown"%_t, rtext = string.format("%+i%%", hsCdFactor * 100), icon = "data/textures/icons/hourglass.png", boosted = permanent},
        {ltext = "Recharge Energy"%_t, rtext = string.format("%+i%%", hsEnergy * 100), icon = "data/textures/icons/electric.png", boosted = permanent},

        {ltext = "Cargo Hold"%_t, rtext = string.format("%+i%%", cargo * 100), icon = "data/textures/icons/wooden-crate.png", boosted = permanent},

        {ltext = "Velocity"%_t, rtext = string.format("%+i%%", velocity * 100), icon = "data/textures/icons/lucifer-cannon.png", boosted = permanent},

        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = lootRange / 100}, icon = "data/textures/icons/coins.png", boosted = permanent},

        {ltext = "Deep Scan Range"%_t, rtext = string.format("%+i", deepScan), icon = "data/textures/icons/radar-sweep.png", boosted = permanent},
        {ltext = "Radar Range"%_t, rtext = string.format("%+i", radar), icon = "data/textures/icons/radar-sweep.png", boosted = permanent},

    }

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "When you can't decide what to upgrade."%_t, lcolor = ColorRGB(1, 0.5, 0.5)},
        {ltext = "", boosted = permanent},
        {ltext = "This system has 5 vertical "%_t, rtext = "", icon = ""},
        {ltext = "scratches on its surface."%_t, rtext = "", icon = ""}
    }
end
