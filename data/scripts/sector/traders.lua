if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";?"

require ("galaxy")
require ("randomext")
local TradingUtility = require ("tradingutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Traders
Traders = {}

function Traders.getUpdateInterval()
    return 60
end

function Traders.update(timeStep)

    -- find all stations that buy or sell goods
    local scripts = TradingUtility.getTradeableScripts()
    local sector = Sector()

    local tradingStations = {}

    local stations = {sector:getEntitiesByType(EntityType.Station)}

    for _, station in pairs(stations) do

        if not TradingUtility.hasTraders(station) then

            for _, script in pairs(scripts) do

                local tradingStation = nil

                if TradingUtility.getSellsToOthers(station, script) then
                    local results = {station:invokeFunction(script, "getSoldGoods")}
                    local callResult = results[1]

                    if callResult == 0 then -- call was successful, the station sells goods
                        tradingStation = {station = station, script = script, bought = {}, sold = {}}
                        tradingStation.sold = {}

                        for i = 2, tablelength(results) do
                            table.insert(tradingStation.sold, results[i])
                        end
                    end
                end

                if TradingUtility.getBuysFromOthers(station, script) then
                    local results = {station:invokeFunction(script, "getBoughtGoods")}
                    local callResult = results[1]
                    if callResult == 0 then -- call was successful, the station buys goods

                        if tradingStation == nil then
                            tradingStation = {station = station, script = script, bought = {}, sold = {}}
                        end

                        for i = 2, tablelength(results) do
                            table.insert(tradingStation.bought, results[i])
                        end

                    end
                end

                if tradingStation then
                    table.insert(tradingStations, tradingStation)
                end
            end
        end
    end

    -- find stations that need goods or would sell goods
    local tradingPossibilities = {}

    for _, v in pairs(tradingStations) do
        local station = v.station
        local bought = v.bought
        local sold = v.sold
        local script = v.script

        -- these are all possibilities for goods to be bought from stations
        for _, name in pairs(sold) do
            local err, amount, maxAmount = station:invokeFunction(script, "getStock", name)
            if err == 0 and maxAmount > 0 and amount / maxAmount > 0.6 then
                table.insert(tradingPossibilities, {tradeType = TradingUtility.TradeType.BuyFromStation, station = station, script = script, name = name})
            end
        end

        -- these are all possibilities for goods to be sold to stations
        for _, name in pairs(bought) do
            local err, amount, maxAmount = station:invokeFunction(script, "getStock", name)
            if err == 0 and maxAmount > 0 and amount / maxAmount < 0.4 then
                table.insert(tradingPossibilities, {tradeType = TradingUtility.TradeType.SellToStation, station = station, script = script, name = name, amount = maxAmount - amount})
            end
        end

    end

    -- if there is no way for trade, exit
    if #tradingPossibilities == 0 then return end

    -- choose one at random
    local trade = tradingPossibilities[getInt(1, #tradingPossibilities)]

    -- create a trader ship that will fly to this station to trade
    -- don't create traders when there are no players in the sector to witness it. instead, do the trade transaction immediately
    TradingUtility.spawnTrader(trade, Traders, sector.numPlayers == 0)
end



end
