--[[
    siro_aidoctor - クライアント処理
    AI救急医が駆けつけて蘇生してくれるスクリプト
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- 状態管理
local isActive = false
local isAvailable = true
local hasArrived = false

-- エンティティ管理
local doctorVehicle = nil
local doctorPed = nil
local doctorBlip = nil

-- ローカライズ関数
local function L(key, ...)
    local locale = Config.Locale or 'ja'
    if Locales[locale] and Locales[locale][key] then
        return string.format(Locales[locale][key], ...)
    end
    return key
end

-- 通知関数
local function Notify(msg, msgType)
    QBCore.Functions.Notify(msg, msgType or 'primary')
end

-- プレイヤーがダウン状態か確認
local function IsPlayerDowned()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.metadata then return false end
    return playerData.metadata["isdead"] or playerData.metadata["inlaststand"]
end

-- エンティティ削除処理
local function CleanupEntities()
    -- ブリップ削除
    if doctorBlip and DoesBlipExist(doctorBlip) then
        RemoveBlip(doctorBlip)
        doctorBlip = nil
    end
    
    -- NPC削除
    if doctorPed and DoesEntityExist(doctorPed) then
        DeleteEntity(doctorPed)
        doctorPed = nil
    end
    
    -- 車両削除
    if doctorVehicle and DoesEntityExist(doctorVehicle) then
        DeleteEntity(doctorVehicle)
        doctorVehicle = nil
    end
    
    -- フラグリセット
    isActive = false
    hasArrived = false
    
    Wait(2000)
    isAvailable = true
end

-- 車両スポーン処理
local function SpawnDoctorVehicle(playerCoords)
    isAvailable = false
    hasArrived = false
    
    local vehHash = GetHashKey(Config.VehicleModel)
    local pedHash = GetHashKey(Config.PedModel)
    
    -- モデル読み込み
    RequestModel(vehHash)
    while not HasModelLoaded(vehHash) do
        Wait(10)
    end
    
    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Wait(10)
    end
    
    -- スポーン位置を探す
    local spawnRadius = Config.SpawnRadius or 60
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(
        playerCoords.x + math.random(-spawnRadius, spawnRadius),
        playerCoords.y + math.random(-spawnRadius, spawnRadius),
        playerCoords.z,
        0, 3, 0
    )
    
    if not found then
        Notify(L('spawn_failed'), 'error')
        isAvailable = true
        SetModelAsNoLongerNeeded(vehHash)
        SetModelAsNoLongerNeeded(pedHash)
        return false
    end
    
    -- 車両生成
    doctorVehicle = CreateVehicle(vehHash, spawnPos.x, spawnPos.y, spawnPos.z, spawnHeading, true, false)
    SetVehicleOnGroundProperly(doctorVehicle)
    SetVehicleNumberPlateText(doctorVehicle, Config.PlateText or 'AIDOC')
    SetEntityAsMissionEntity(doctorVehicle, true, true)
    SetVehicleEngineOn(doctorVehicle, true, true, false)
    
    -- サイレン
    if Config.UseSiren then
        SetVehicleSiren(doctorVehicle, true)
    end
    
    -- NPC生成
    doctorPed = CreatePedInsideVehicle(doctorVehicle, 26, pedHash, -1, true, false)
    SetEntityAsMissionEntity(doctorPed, true, true)
    SetBlockingOfNonTemporaryEvents(doctorPed, true)
    SetPedKeepTask(doctorPed, true)
    SetPedCanBeKnockedOffVehicle(doctorPed, 1)
    
    -- ブリップ設定
    doctorBlip = AddBlipForEntity(doctorVehicle)
    SetBlipSprite(doctorBlip, 61)
    SetBlipColour(doctorBlip, 1)
    SetBlipFlashes(doctorBlip, true)
    SetBlipRoute(doctorBlip, true)
    SetBlipRouteColour(doctorBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("AI Doctor")
    EndTextCommandSetBlipName(doctorBlip)
    
    -- 効果音
    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
    
    Wait(500)
    
    -- 運転タスク開始
    local driveSpeed = Config.DriveSpeed or 25.0
    TaskVehicleDriveToCoord(doctorPed, doctorVehicle, playerCoords.x, playerCoords.y, playerCoords.z, driveSpeed, 0, GetEntityModel(doctorVehicle), 787004, 5.0)
    
    isActive = true
    
    -- モデル解放
    SetModelAsNoLongerNeeded(vehHash)
    SetModelAsNoLongerNeeded(pedHash)
    
    return true
end

-- 蘇生処理
local function PerformRevive()
    local animDict = "mini@cpr@char_a@cpr_str"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    
    -- NPCをプレイヤーの方に向ける
    local playerCoords = GetEntityCoords(PlayerPedId())
    TaskTurnPedToFaceCoord(doctorPed, playerCoords.x, playerCoords.y, playerCoords.z, 1000)
    Wait(1000)
    
    -- CPRアニメーション開始
    TaskPlayAnim(doctorPed, animDict, "cpr_pumpchest", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- プログレスバー
    QBCore.Functions.Progressbar("aidoctor_revive", L('revive_progress'), Config.ReviveTime, false, false, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        -- 蘇生完了
        ClearPedTasks(doctorPed)
        Wait(500)
        
        TriggerEvent("hospital:client:Revive")
        StopScreenEffect('DeathFailOut')
        
        -- 蘇生完了時に請求
        TriggerServerEvent('siro_aidoctor:charge')
        
        Notify(L('revive_complete', Config.Price), 'success')
        
        Wait(1000)
        CleanupEntities()
    end, function()
        -- キャンセル時
        ClearPedTasks(doctorPed)
        Notify(L('revive_cancelled'), 'error')
        CleanupEntities()
    end)
    
    RemoveAnimDict(animDict)
end

-- メイン監視ループ
CreateThread(function()
    while true do
        Wait(500)
        
        if isActive and doctorVehicle and doctorPed then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehCoords = GetEntityCoords(doctorVehicle)
            local pedCoords = GetEntityCoords(doctorPed)
            
            local distToVeh = #(playerCoords - vehCoords)
            local distToPed = #(playerCoords - pedCoords)
            
            -- 車両が近くに来たらNPCを降ろす
            if distToVeh <= 15.0 and not hasArrived then
                hasArrived = true
                
                -- 車両停止
                SetVehicleForwardSpeed(doctorVehicle, 0.0)
                TaskVehicleTempAction(doctorPed, doctorVehicle, 1, 1000)
                
                Wait(1000)
                
                -- NPCを降車させる
                TaskLeaveVehicle(doctorPed, doctorVehicle, 0)
                
                -- 降車完了を待つ
                local timeout = 0
                while IsPedInVehicle(doctorPed, doctorVehicle, false) and timeout < 50 do
                    Wait(100)
                    timeout = timeout + 1
                end
                
                Wait(500)
                
                -- NPCの設定
                SetPedCanRagdoll(doctorPed, false)
                SetBlockingOfNonTemporaryEvents(doctorPed, true)
                SetPedKeepTask(doctorPed, true)
                
                -- プレイヤーの方へ歩かせる
                local targetCoords = GetEntityCoords(PlayerPedId())
                TaskGoToCoordAnyMeans(doctorPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, 0, false, 786603, 0xbf800000)
                
                -- サイレン停止
                SetVehicleSiren(doctorVehicle, false)
                
                -- ブリップをNPCに移動
                if doctorBlip and DoesBlipExist(doctorBlip) then
                    SetBlipRoute(doctorBlip, false)
                    RemoveBlip(doctorBlip)
                end
                
                doctorBlip = AddBlipForEntity(doctorPed)
                SetBlipSprite(doctorBlip, 61)
                SetBlipColour(doctorBlip, 1)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("AI Doctor")
                EndTextCommandSetBlipName(doctorBlip)
            end
            
            -- NPCがプレイヤーに到達したら蘇生開始
            if hasArrived and distToPed <= 2.5 then
                isActive = false
                ClearPedTasks(doctorPed)
                Wait(500)
                PerformRevive()
            end
            
            -- NPCが止まっている・動いていない場合は再度タスクを与える
            if hasArrived and distToPed > 2.5 and isActive then
                local pedSpeed = GetEntitySpeed(doctorPed)
                if pedSpeed < 0.5 then
                    local targetCoords = GetEntityCoords(PlayerPedId())
                    ClearPedTasks(doctorPed)
                    Wait(100)
                    TaskGoToCoordAnyMeans(doctorPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, 0, false, 786603, 0xbf800000)
                end
            end
        end
    end
end)

-- コマンド登録
RegisterCommand(Config.Command or 'help', function()
    -- ダウン状態確認
    if not IsPlayerDowned() then
        Notify(L('only_when_down'), 'error')
        return
    end
    
    -- 既に呼んでいるか確認
    if not isAvailable then
        Notify(L('already_called'), 'error')
        return
    end
    
    -- サーバーに確認
    QBCore.Functions.TriggerCallback('siro_aidoctor:checkAvailability', function(emsCount, canPay)
        if emsCount > Config.Doctor then
            Notify(L('ems_online'), 'error')
            return
        end
        
        if not canPay then
            Notify(L('not_enough_money'), 'error')
            return
        end
        
        -- 車両スポーン
        local success = SpawnDoctorVehicle(GetEntityCoords(PlayerPedId()))
        if success then
            Notify(L('ambulance_called'), 'primary')
        end
    end)
end, false)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupEntities()
    end
end)

-- プレイヤーデータ更新時
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)
