--[[
    siro_aimechanic - Server Main
    Author: siro
    メカニック出勤チェック、支払い処理などを担当
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- メカニックが出勤中かチェック
local function IsMechanicOnDuty()
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            local job = Player.PlayerData.job
            if job and job.onduty then
                for _, blockJob in ipairs(Config.BlockJobs) do
                    if job.name == blockJob then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- プレイヤーの所持金をチェック
local function HasEnoughMoney(source, amount, paymentType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local money = Player.PlayerData.money[paymentType] or 0
    return money >= amount
end

-- プレイヤーからお金を徴収
local function TakeMoney(source, amount, paymentType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local success = Player.Functions.RemoveMoney(paymentType, amount, 'helpmec-repair')
    return success
end

-- メカニック出勤状況をチェックするコールバック
lib.callback.register('siro_aimechanic:server:checkMechanicDuty', function(source)
    return IsMechanicOnDuty()
end)

-- プレイヤーのお金をチェックするコールバック
lib.callback.register('siro_aimechanic:server:checkMoney', function(source)
    return HasEnoughMoney(source, Config.Price, Config.PaymentType)
end)

-- 支払い処理
lib.callback.register('siro_aimechanic:server:processPayment', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- 再度お金チェック
    if not HasEnoughMoney(source, Config.Price, Config.PaymentType) then
        return false, 'not_enough_money'
    end
    
    -- 支払い実行
    local success = TakeMoney(source, Config.Price, Config.PaymentType)
    if success then
        if Config.Debug then
            print(('[siro_aimechanic] Player %s paid $%s for repair'):format(source, Config.Price))
        end
        return true
    end
    
    return false, 'payment_failed'
end)

-- デバッグ用コマンド
if Config.Debug then
    RegisterCommand('helpmec_debug', function(source)
        local isOnDuty = IsMechanicOnDuty()
        local Player = QBCore.Functions.GetPlayer(source)
        local money = Player and Player.PlayerData.money[Config.PaymentType] or 0
        
        TriggerClientEvent('QBCore:Notify', source, 
            ('Mechanic on duty: %s | Money: $%s | Required: $%s'):format(
                tostring(isOnDuty), 
                money, 
                Config.Price
            ), 
            'primary'
        )
    end, false)
end

print('^2[siro_aimechanic]^7 Server script loaded successfully')
