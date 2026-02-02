--[[
    siro_aimechanic - Client Main
    Author: siro
    メインコマンド処理、車両選択メニューなどを担当
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- 言語ファイル読み込み
local function LoadLocale()
    local localeFile = ('locale/%s.lua'):format(Config.Locale)
    local chunk = LoadResourceFile(GetCurrentResourceName(), localeFile)
    if chunk then
        local fn, err = load(chunk)
        if fn then
            fn()
        else
            print(('[siro_aimechanic] Error loading locale: %s'):format(err))
        end
    end
end

LoadLocale()

-- ローカライズ取得
function L(key, ...)
    local locale = Locales[Config.Locale] or Locales['en']
    local text = locale[key] or key
    
    if ... then
        return text:format(...)
    end
    return text
end

-- 状態管理
local isRepairing = false
local currentRepairData = nil

-- 通知送信
local function Notify(message, type)
    QBCore.Functions.Notify(message, type or 'primary')
end

-- 周囲の車両を取得して距離順にソート
local function GetNearbyVehicles()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = {}
    
    -- GTA Nativeで周囲の車両を取得
    local handle, veh = FindFirstVehicle()
    local success = true
    
    while success do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local distance = #(playerCoords - vehCoords)
            
            -- 検索範囲内かチェック
            if distance <= Config.VehicleSearchRadius then
                local plate = GetVehicleNumberPlateText(veh)
                local model = GetEntityModel(veh)
                local displayName = GetDisplayNameFromVehicleModel(model)
                local labelName = GetLabelText(displayName)
                
                -- ラベルが取得できない場合はモデル名を使用
                if labelName == 'NULL' or labelName == '' then
                    labelName = displayName
                end
                
                table.insert(vehicles, {
                    entity = veh,
                    coords = vehCoords,
                    distance = distance,
                    plate = plate,
                    name = labelName,
                    model = model
                })
            end
        end
        
        success, veh = FindNextVehicle(handle)
    end
    
    EndFindVehicle(handle)
    
    -- 距離順にソート
    table.sort(vehicles, function(a, b)
        return a.distance < b.distance
    end)
    
    return vehicles
end

-- 車両選択メニューを表示
local function ShowVehicleSelectMenu(vehicles)
    local options = {}
    
    for i, vehData in ipairs(vehicles) do
        if i > 10 then break end -- 最大10台まで表示
        
        table.insert(options, {
            title = L('vehicle_option', vehData.name, vehData.distance),
            description = L('vehicle_plate', vehData.plate) .. '\n' .. L('repair_price', Config.Price),
            icon = 'car',
            onSelect = function()
                StartRepairProcess(vehData)
            end
        })
    end
    
    lib.registerContext({
        id = 'siro_aimechanic_vehicle_select',
        title = L('menu_title'),
        options = options
    })
    
    lib.showContext('siro_aimechanic_vehicle_select')
end

-- 修理プロセス開始
function StartRepairProcess(vehicleData)
    if isRepairing then
        Notify(L('already_repairing'), 'error')
        return
    end
    
    isRepairing = true
    currentRepairData = vehicleData
    
    Notify(L('npc_arriving'), 'primary')
    
    -- NPCをスポーンして修理開始
    TriggerEvent('siro_aimechanic:client:spawnNPCAndRepair', vehicleData)
end

-- 修理完了処理
function CompleteRepair()
    if not isRepairing or not currentRepairData then return end
    
    local vehicle = currentRepairData.entity
    
    -- 車両が存在するかチェック
    if DoesEntityExist(vehicle) then
        -- 車両を完全修復
        SetVehicleFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        
        -- タイヤ修復
        for i = 0, 7 do
            if IsVehicleTyreBurst(vehicle, i, false) then
                SetVehicleTyreBurst(vehicle, i, false, 1000.0)
                SetVehicleTyreFixed(vehicle, i)
            end
        end
        
        -- ウィンドウ修復
        for i = 0, 7 do
            if not IsVehicleWindowIntact(vehicle, i) then
                FixVehicleWindow(vehicle, i)
            end
        end
        
        -- ドア修復
        for i = 0, 5 do
            if IsVehicleDoorDamaged(vehicle, i) then
                SetVehicleDoorShut(vehicle, i, false)
            end
        end
    end
    
    -- 支払い処理
    lib.callback('siro_aimechanic:server:processPayment', false, function(success, reason)
        if success then
            Notify(L('payment_success', Config.Price), 'success')
            Notify(L('repair_complete'), 'success')
        else
            if reason == 'not_enough_money' then
                Notify(L('not_enough_money', Config.Price), 'error')
            else
                Notify(L('repair_cancelled'), 'error')
            end
        end
    end)
    
    isRepairing = false
    currentRepairData = nil
end

-- 修理キャンセル
function CancelRepair(reason)
    if not isRepairing then return end
    
    if reason == 'distance' then
        Notify(L('repair_cancelled_distance'), 'error')
    elseif reason == 'vehicle' then
        Notify(L('repair_cancelled_vehicle'), 'error')
    else
        Notify(L('repair_cancelled'), 'error')
    end
    
    isRepairing = false
    currentRepairData = nil
    
    -- NPC処理のクリーンアップをトリガー
    TriggerEvent('siro_aimechanic:client:cleanup')
end

-- 現在の修理状態を取得
function GetRepairState()
    return isRepairing, currentRepairData
end

-- メインコマンド登録
RegisterCommand('helpmec', function()
    -- まずメカニックが出勤中かチェック
    lib.callback('siro_aimechanic:server:checkMechanicDuty', false, function(isOnDuty)
        if isOnDuty then
            Notify(L('mechanic_on_duty'), 'error')
            return
        end
        
        -- お金チェック
        lib.callback('siro_aimechanic:server:checkMoney', false, function(hasEnoughMoney)
            if not hasEnoughMoney then
                Notify(L('not_enough_money', Config.Price), 'error')
                return
            end
            
            -- 周囲の車両を取得
            local vehicles = GetNearbyVehicles()
            
            if #vehicles == 0 then
                Notify(L('no_vehicles_nearby'), 'error')
                return
            end
            
            -- 車両選択メニューを表示
            ShowVehicleSelectMenu(vehicles)
        end)
    end)
end, false)

-- グローバルにエクスポート
exports('GetRepairState', GetRepairState)
exports('CancelRepair', CancelRepair)
exports('CompleteRepair', CompleteRepair)
exports('L', L)

print('^2[siro_aimechanic]^7 Client main script loaded successfully')
