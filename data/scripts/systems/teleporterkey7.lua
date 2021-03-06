package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

-- this key is dropped by the mad scientist

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

function getBonuses(seed, rarity)
    return 6.0, 4.25
end

function onInstalled(seed, rarity, permanent)
    if not permanent then return end

    local energy, charge = getBonuses(seed, rarity)

    addBaseMultiplier(StatsBonuses.GeneratedEnergy, energy)
    addBaseMultiplier(StatsBonuses.BatteryRecharge, charge)
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "XSTN-K VII"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/key7.png"
end

function getPrice(seed, rarity)
    return 10000
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local energy, charge = getBonuses(seed, rarity)

    table.insert(texts, {ltext = "Generated Energy"%_t, rtext = string.format("%+i%%", energy * 100), icon = "data/textures/icons/electric.png", boosted = permanent})
    table.insert(texts, {ltext = "Recharge Rate"%_t, rtext = string.format("%+i%%", charge * 100), icon = "data/textures/icons/energise.png", boosted = permanent})

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "This system has 7 vertical "%_t, rtext = "", icon = ""},
        {ltext = "scratches on its surface."%_t, rtext = "", icon = ""}
    }
end
