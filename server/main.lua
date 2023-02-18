if Config.oldESX then
	ESX = nil
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
else
	ESX = exports["es_extended"]:getSharedObject()
end

ESX.RegisterServerCallback("cy-testVehicle:removeMoney", function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.getMoney() >= Config.Amount then
        xPlayer.removeMoney(Config.Amount)
        xPlayer.showNotification("$ "..Config.Amount.." 已扣除為測試車子的費用!")
        
        cb(true)
    elseif xPlayer.getAccount('bank').money >= Config.Amount then
        xPlayer.removeAccountMoney('bank', Config.Amount)
        xPlayer.showNotification("$ "..Config.Amount.." 已扣除為測試車子的費用!")

        cb(true)
    else
        xPlayer.showNotification("你沒有足夠的錢")

        cb(false)
    end
end)