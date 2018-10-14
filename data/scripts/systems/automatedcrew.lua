
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- Automated Crew 0.1

function getBonuses(seed, rarity)
	math.randomseed(seed)
	
	--stats that the mod changes
	local workForce = {engineers = 0, mechanics = 0, gunners = 0,miners = 0,sergeants = 0,lieutenants = 0,commanders = 0,generals = 0}
	
	
	---------------------------
	local rarityPlus2 = rarity.value + 2
	
	local count = 1
	if rarity.value <= 0 then--if the rarity is either petty or common
		
		for _, worker in pairs(workForce) do
			getWorkForceBasedOnRarity(workForce,count,5,70,3,5,0, rarityPlus2)
			count = count + 1
		end
	elseif rarity.value == 1 then--if the rarity is uncommon
		for _, worker in pairs(workForce) do
			getWorkForceBasedOnRarity(workForce,count,6,70,5,12,0.1, rarityPlus2)
			count = count + 1
		end
	elseif rarity.value == 2 then--if the rarity is rare
		for _, worker in pairs(workForce) do
			getWorkForceBasedOnRarity(workForce,count,8,75,20,45,0.11, rarityPlus2)
			count = count + 1
		end
	elseif rarity.value == 3 then --if the rarity is exceptional
		for _, worker in pairs(workForce) do
			getWorkForceBasedOnRarity(workForce,count,9,80,50,80, 0.12, rarityPlus2)
			count = count + 1
		end
	elseif rarity.value == 4 then--if the rarity is exotic
		for _, worker in pairs(workForce) do
			getWorkForceBasedOnRarity(workForce,count,9,85,95,160, 0.13, rarityPlus2)
			count = count + 1
		end
	elseif rarity.value == 5 then--if the rarity is legendary
		for _, worker in pairs(workForce) do
			getWorkForceBasedOnRarity(workForce,count,9,95,300,500, 0.15, rarityPlus2)
			count = count + 1
		end
	end
	
	--fail safe to keep the system upgrades from having nothing on them!
	if getWorkForceNumbers(workForce) == 0 then
		workForce.engineers = getInt(1,5) * rarityPlus2
		workForce.mechanics = getInt(1,5) * rarityPlus2
	end
	
	
	
	return workForce
end

function getWorkForceNumbers(workForce)

	return workForce.engineers + workForce.mechanics + workForce.gunners + workForce.miners
	
end

function getWorkForceBasedOnRarity(workForce, count, breakLimit, addWorkerChance, workerMin, workerMax, highRankerScale, rarityPlus)
	if count >= breakLimit then
		return
	end
	if chance(addWorkerChance) == true then 
		if count == 1 then
			workForce.engineers = getInt(workerMin,workerMax)
		elseif count == 2 then
			workForce.mechanics = getInt(workerMin,workerMax)
		elseif count == 3 then
			workForce.gunners = getInt(workerMin,workerMax)
		elseif count == 4 then
			workForce.miners = getInt(workerMin,workerMax)
		elseif count == 5 then --changed high ranking crew to be dependnt on the number of crew already on the system so it kind of will support itself.
			workForce.sergeants =  math.ceil(getInt(getWorkForceNumbers(workForce) * 0.75,getWorkForceNumbers(workForce) * 1.25) * highRankerScale)
		elseif count == 6 then
			workForce.lieutenants = math.ceil(getInt(getWorkForceNumbers(workForce) * 0.75,getWorkForceNumbers(workForce) * 1.25) * highRankerScale * 0.33)
		elseif count == 7 then
			workForce.commanders = math.ceil(getInt(getWorkForceNumbers(workForce) * 0.75,getWorkForceNumbers(workForce) * 1.25) * highRankerScale * 0.1089)
		elseif count == 8 then
			workForce.generals = math.ceil(getInt(getWorkForceNumbers(workForce) * 0.75,getWorkForceNumbers(workForce) * 1.25) * highRankerScale * 0.035937)
		end
	end
	return
end

function chance(chance)
	local passed = false
	if math.random(100) <= chance then
		passed = true
	else
		passed = false
	end
	return passed
end

function onInstalled(seed,rarity)
	local workForce = getBonuses(seed,rarity)
	
	
	addAbsoluteBias(StatsBonuses.Engineers,workForce.engineers)
	addAbsoluteBias(StatsBonuses.Mechanics,workForce.mechanics)
	addAbsoluteBias(StatsBonuses.Gunners,workForce.gunners)
	addAbsoluteBias(StatsBonuses.Miners,workForce.miners)
	addAbsoluteBias(StatsBonuses.Sergeants,workForce.sergeants)
	addAbsoluteBias(StatsBonuses.Lieutenants,workForce.lieutenants)
	addAbsoluteBias(StatsBonuses.Commanders,workForce.commanders)
	addAbsoluteBias(StatsBonuses.Generals,workForce.generals)
end


function getEnergy(seed,rarity)
	local workForce = getBonuses(seed,rarity)
	
	local num = 0
	num = num + workForce.engineers
	num = num + workForce.mechanics
	num = num + workForce.gunners
	num = num + workForce.miners
	num = num + (workForce.sergeants * 1.2)
	num = num + (workForce.lieutenants * 1.3)
	num = num + (workForce.commanders * 1.4)
	num = num + (workForce.generals * 1.5)
	
	return num * 75 * 1000 * 500 / 2 * (1.1 ^ (rarity.value + 1)) / 3
end

function getPrice(seed,rarity)
	local workForce = getBonuses(seed,rarity)
	
	local num = 0
	num = num + workForce.engineers
	num = num + workForce.mechanics
	num = num + workForce.gunners
	num = num + workForce.miners
	num = num + (workForce.sergeants * 1.2)
	num = num + (workForce.lieutenants * 1.3)
	num = num + (workForce.commanders * 1.4)
	num = num + (workForce.generals * 1.5)
	local price = 110 * num
	price = price * 2.5 ^ rarity.value * 2 * 1.35
	
	--price is scaled from the number of crew on a system.
	--the code below keeps the prices from being out of control. base without scale down would be like 7-8 mil for rarity 4 and 50+ mil for rarity 5
	--this really only applies if you would change how your systems are spawned in shops(shops don't sell rarity 4-5 systems or turrets or fighters) unless you change it so they do =)
	--or if you would try to sell it to the vender, it just keeps the price from becomeing game braeking.
	if rarity.value == 4 then
		price = price / 3 -- 2.5 should keep the prices around 900k-1.5 mil tp buy
	end
	if rarity.value == 5 then
		price = price / 8 -- 8 should keep the prices around 5 mil to buy
	end
	--break down eng and mech cost 150 each gunners and miners cost 300 each a epic system can have between 300-500 of each crew member
	--300 * 150 = 45,000 * 2 = 90k. 300 * 300 = 90,000 * 2 = 180k. 90,000 + 180,000 = 270,000 this is baseline work force.
	--high ranking work force would be 300 * 4 / 10 (4 types of baseline crew) (need 1 sergeant for every 10 baseline crew) = 120
	--mod is set up to give you 33% of the next tier officer so, lieutenant would be 33% of sergeants ect.
	--120 sergeants, 40 lieutenants,14 commanders, 5 generals
	--120 * 750 + 40 * 2000 + 14 * 5000 + 5 * 10000 = 290,000
	--290,000 + 270,000 = 560,000
	return price
end



function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "Automated Crew"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/processor.png"
end

 

 function getTooltipLines(seed, rarity)
	local texts = {}
	local workForce = getBonuses(seed,rarity)
	
	if workForce.engineers ~= 0 then
		table.insert(texts,{ltext = "Automated Engineers"%_t, rtext = string.format("+%i", workForce.engineers), icon = "data/textures/icons/gear-hammer.png"})
	end
	if workForce.mechanics ~= 0 then
		table.insert(texts,{ltext = "Automated Mechanics"%_t, rtext = string.format("+%i", workForce.mechanics), icon = "data/textures/icons/tinker.png"})
	end
	if workForce.gunners ~= 0 then
		table.insert(texts,{ltext = "Automated Gunners"%_t, rtext = string.format("+%i", workForce.gunners), icon = "data/textures/icons/reticule.png"})
	end
	if workForce.miners ~= 0 then
		table.insert(texts,{ltext = "Automated Miners"%_t, rtext = string.format("+%i", workForce.miners), icon = "data/textures/icons/drill.png"})
	end
	if workForce.sergeants ~= 0 then
		table.insert(texts,{ltext = "Automated Sergeants"%_t, rtext = string.format("+%i", workForce.sergeants), icon = "data/textures/icons/rank1.png"})
	end
	if workForce.lieutenants ~= 0 then
		table.insert(texts,{ltext = "Automated Lieutenants"%_t, rtext = string.format("+%i", workForce.lieutenants), icon = "data/textures/icons/rank2.png"})
	end
	if workForce.commanders ~= 0 then
		table.insert(texts,{ltext = "Automated Commanders"%_t, rtext = string.format("+%i", workForce.commanders), icon = "data/textures/icons/rank3.png"})
	end
	if workForce.generals ~= 0 then
		table.insert(texts,{ltext = "Automated Generals"%_t, rtext = string.format("+%i", workForce.generals), icon = "data/textures/icons/winged-shield.png"})
	end
	
	return texts
 end
 

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "Adds bounus to your workforce! "%_t, rtext = "", icon = ""}
    }
end
