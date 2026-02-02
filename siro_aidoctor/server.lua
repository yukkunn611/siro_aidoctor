--[[
    siro_aidoctor - サーバー処理
    AI救急医が駆けつけて蘇生してくれるスクリプト
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- ローカライズ関数
local function L(key, ...)
    local locale = Config.Locale or 'ja'
    if Locales[locale] and Locales[locale][key] then
        return string.format(Locales[locale][key], ...)
    end
    return key
end

-- EMS人数とプレイヤーの支払い能力を確認
QBCore.Functions.CreateCallback('siro_aidoctor:checkAvailability', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then
        cb(999, false)
        return
    end
    
    -- EMS人数カウント
    local emsCount = 0
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local targetPlayer = QBCore.Functions.GetPlayer(playerId)
        if targetPlayer and targetPlayer.PlayerData.job.name == 'ambulance' then
            emsCount = emsCount + 1
        end
    end
    
    -- 支払い能力確認
    local canPay = false
    local cashAmount = player.PlayerData.money["cash"] or 0
    local bankAmount = player.PlayerData.money["bank"] or 0
    
    if cashAmount >= Config.Price or bankAmount >= Config.Price then
        canPay = true
    end
    
    cb(emsCount, canPay)
end)

-- 蘇生完了時の請求処理
RegisterNetEvent('siro_aidoctor:charge', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    local cashAmount = player.PlayerData.money["cash"] or 0
    local price = Config.Price
    
    -- 現金優先で引き落とし
    if cashAmount >= price then
        player.Functions.RemoveMoney("cash", price, "ai-doctor-revive")
    else
        player.Functions.RemoveMoney("bank", price, "ai-doctor-revive")
    end
    
    -- ambulanceの組織資金に追加
    local success, err = pcall(function()
        TriggerEvent("qb-bossmenu:server:addAccountMoney", 'ambulance', price)
    end)
    
    if not success then
        print('[siro_aidoctor] Warning: Could not add money to ambulance account - ' .. tostring(err))
    end
    
    print(string.format('[siro_aidoctor] Player %s (ID: %d) paid $%d for AI Doctor revive', 
        player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        src,
        price
    ))
end)

-- QBCore更新時
AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

-- リソース開始時のログ
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[siro_aidoctor] AI Doctor script loaded successfully')
        print(string.format('[siro_aidoctor] Price: $%d | EMS Limit: %d | Revive Time: %dms', 
            Config.Price, 
            Config.Doctor, 
            Config.ReviveTime
        ))
    end
end)
