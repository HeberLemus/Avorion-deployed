
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("randomext")
require ("utility")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getNumBonusTurrets(seed, rarity, permanent)
    if permanent then
        return math.max(1, math.floor((rarity.value + 1) / 2))
    end

    return 0
end

function getNumTurrets(seed, rarity, permanent)
    return math.max(1, rarity.value * 15) + getNumBonusTurrets(seed, rarity, permanent)
end

function onInstalled(seed, rarity, permanent)
    addMultiplyableBias(StatsBonuses.ArmedTurrets, getNumTurrets(seed, rarity, permanent))
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "Turret Control System M-TCS-${num}"%_t % {num = getNumTurrets(seed, rarity, permanent)}
end

function getIcon(seed, rarity)
    return "data/textures/icons/turret.png"
end

function getEnergy(seed, rarity, permanent)
    local num = getNumTurrets(seed, rarity, permanent)
    return num * 200 * 1000 * 10 / (1.2 ^ rarity.value)
end

function getPrice(seed, rarity)
    local num = getNumTurrets(seed, rarity, permanent)
    local price = 60 * num;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
    return
    {
        {ltext = "Armed Turret Slots"%_t, rtext = "+" .. getNumTurrets(seed, rarity, permanent), icon = "data/textures/icons/turret.png", boosted = permanent}
    },
    {
        {ltext = "Armed Turret Slots"%_t, rtext = "+" .. getNumBonusTurrets(seed, rarity, true), icon = "data/textures/icons/turret.png"}
    }
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Military Turret Control System"%_t, rtext = "", icon = ""},
        {ltext = "Adds slots for armed turrets"%_t, rtext = "", icon = ""}
    }
end
