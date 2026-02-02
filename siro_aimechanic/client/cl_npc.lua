--[[
    siro_aimechanic - NPC Control
    Author: siro
    NPCのスポーン、移動、修理演出などを担当
]]

-- NPC関連の変数
local npcPed = nil
local npcVehicle = nil
local repairBlip = nil
local repairThread = nil
local duiActive = false

-- モデルをロード
local function LoadModel(model)
    local modelHash = type(model) == 'string' and joaat(model) or model
    
    if not IsModelValid(modelHash) then
        print(('[siro_aimechanic] Invalid model: %s'):format(model))
        return nil
    end
    
    RequestModel(modelHash)
    local timeout = 5000
    while not HasModelLoaded(modelHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    
    if not HasModelLoaded(modelHash) then
        print(('[siro_aimechanic] Failed to load model: %s'):format(model))
        return nil
    end
    
    return modelHash
end

-- アニメーション辞書をロード
local function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then
        return false
    end
    
    RequestAnimDict(dict)
    local timeout = 5000
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    
    return HasAnimDictLoaded(dict)
end

-- NPCを目的地まで運転させる
local function DriveNPCToLocation(ped, vehicle, destination)
    if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then
        return false
    end
    
    TaskVehicleDriveToCoordLongrange(
        ped,
        vehicle,
        destination.x,
        destination.y,
        destination.z,
        20.0,
        786603,
        10.0
    )
    
    -- 到着を待つ
    local timeout = 60000 -- 60秒タイムアウト
    while timeout > 0 do
        Wait(500)
        timeout = timeout - 500
        
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(vehCoords - destination)
        
        if distance < 15.0 then
            -- 近くに来たら停止
            TaskVehicleTempAction(ped, vehicle, 27, 2000) -- ブレーキ
            Wait(1000)
            return true
        end
        
        -- 車両やNPCが消えたらキャンセル
        if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then
            return false
        end
    end
    
    return false
end

-- NPCを徒歩で目的地まで移動させる
local function WalkNPCToLocation(ped, destination, timeout)
    if not DoesEntityExist(ped) then return false end
    
    timeout = timeout or 30000
    
    TaskGoStraightToCoord(ped, destination.x, destination.y, destination.z, 1.0, timeout, 0.0, 0.0)
    
    while timeout > 0 do
        Wait(500)
        timeout = timeout - 500
        
        local pedCoords = GetEntityCoords(ped)
        local distance = #(pedCoords - destination)
        
        if distance < 1.5 then
            return true
        end
        
        if not DoesEntityExist(ped) then
            return false
        end
    end
    
    return true
end

-- シナリオを再生
local function PlayScenario(ped, scenario, duration)
    if not DoesEntityExist(ped) then return end
    
    TaskStartScenarioInPlace(ped, scenario, 0, true)
    
    local elapsed = 0
    while elapsed < duration * 1000 do
        Wait(100)
        elapsed = elapsed + 100
        
        -- 修理状態をチェック
        local isRepairing, repairData = exports['siro_aimechanic']:GetRepairState()
        if not isRepairing then
            ClearPedTasks(ped)
            return false
        end
        
        -- プレイヤーとの距離チェック
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local npcCoords = GetEntityCoords(ped)
        local distance = #(playerCoords - npcCoords)
        
        if distance > Config.CancelDistance then
            ClearPedTasks(ped)
            exports['siro_aimechanic']:CancelRepair('distance')
            return false
        end
        
        -- 対象車両の存在チェック
        if repairData and not DoesEntityExist(repairData.entity) then
            ClearPedTasks(ped)
            exports['siro_aimechanic']:CancelRepair('vehicle')
            return false
        end
    end
    
    ClearPedTasks(ped)
    return true
end

-- 車両のドア/ボンネット/トランクを開く
local function OpenVehicleParts(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    -- ボンネット (4)
    SetVehicleDoorOpen(vehicle, 4, false, false)
    -- トランク (5)
    SetVehicleDoorOpen(vehicle, 5, false, false)
    -- 各ドア
    for i = 0, 3 do
        SetVehicleDoorOpen(vehicle, i, false, false)
    end
end

-- 車両のドアを閉じる
local function CloseVehicleParts(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    for i = 0, 5 do
        SetVehicleDoorShut(vehicle, i, false)
    end
end

-- 修理演出を実行
local function PerformRepairSequence(ped, targetVehicle)
    local totalTime = Config.StageTimes.welding + Config.StageTimes.underbody + Config.StageTimes.engine
    local vehicleCoords = GetEntityCoords(targetVehicle)
    local vehicleHeading = GetEntityHeading(targetVehicle)
    
    -- DUI表示開始
    TriggerEvent('siro_aimechanic:client:startDUI', targetVehicle, totalTime)
    
    -- フェーズ1: 溶接作業（運転席ドア横）
    local phase1Pos = GetOffsetFromEntityInWorldCoords(targetVehicle, -1.5, 0.5, 0.0)
    if not WalkNPCToLocation(ped, phase1Pos, 15000) then return false end
    
    FreezeEntityPosition(ped, false)
    local heading = GetHeadingFromVector_2d(vehicleCoords.x - phase1Pos.x, vehicleCoords.y - phase1Pos.y)
    SetEntityHeading(ped, heading)
    
    -- 溶接シナリオ
    TriggerEvent('siro_aimechanic:client:updatePhase', L('phase_welding'))
    if not PlayScenario(ped, Config.Scenarios.welding, Config.StageTimes.welding) then
        return false
    end
    
    -- フェーズ2: 車体下作業
    local phase2Pos = GetOffsetFromEntityInWorldCoords(targetVehicle, -1.0, 0.0, 0.0)
    if not WalkNPCToLocation(ped, phase2Pos, 10000) then return false end
    
    SetEntityHeading(ped, heading)
    
    TriggerEvent('siro_aimechanic:client:updatePhase', L('phase_underbody'))
    if not PlayScenario(ped, Config.Scenarios.underbody, Config.StageTimes.underbody) then
        return false
    end
    
    -- フェーズ3: エンジン整備
    OpenVehicleParts(targetVehicle)
    
    local phase3Pos = GetOffsetFromEntityInWorldCoords(targetVehicle, 0.0, 2.5, 0.0)
    if not WalkNPCToLocation(ped, phase3Pos, 15000) then return false end
    
    local engineHeading = GetHeadingFromVector_2d(vehicleCoords.x - phase3Pos.x, vehicleCoords.y - phase3Pos.y)
    SetEntityHeading(ped, engineHeading)
    
    TriggerEvent('siro_aimechanic:client:updatePhase', L('phase_engine'))
    if not PlayScenario(ped, Config.Scenarios.engine, Config.StageTimes.engine) then
        CloseVehicleParts(targetVehicle)
        return false
    end
    
    CloseVehicleParts(targetVehicle)
    
    -- DUI終了
    TriggerEvent('siro_aimechanic:client:stopDUI')
    
    return true
end

-- NPCを退出させる
local function MakeNPCLeave(ped, vehicle, startCoords)
    if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then return end
    
    -- NPCを車に戻す
    local vehicleCoords = GetEntityCoords(vehicle)
    TaskGoStraightToCoord(ped, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 1.5, 30000, 0.0, 0.0)
    
    Wait(3000)
    
    -- 車に乗せる
    TaskEnterVehicle(ped, vehicle, 10000, -1, 2.0, 1, 0)
    
    local timeout = 15000
    while not IsPedInVehicle(ped, vehicle, false) and timeout > 0 do
        Wait(500)
        timeout = timeout - 500
    end
    
    if not IsPedInVehicle(ped, vehicle, false) then
        -- 強制的に乗せる
        SetPedIntoVehicle(ped, vehicle, -1)
    end
    
    Wait(500)
    
    -- 遠くへ運転して退出
    local leaveCoords = startCoords + vector3(Config.LeaveDistance, 0.0, 0.0)
    TaskVehicleDriveToCoordLongrange(ped, vehicle, leaveCoords.x, leaveCoords.y, leaveCoords.z, 25.0, 786603, 50.0)
    
    -- 距離が離れたら削除
    Wait(5000)
    CreateThread(function()
        local timeout = 30000
        while timeout > 0 do
            Wait(1000)
            timeout = timeout - 1000
            
            if DoesEntityExist(vehicle) then
                local vehCoords = GetEntityCoords(vehicle)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - vehCoords)
                
                if distance > 80.0 then
                    CleanupNPC()
                    return
                end
            else
                return
            end
        end
        
        CleanupNPC()
    end)
end

-- NPCと車両を削除
function CleanupNPC()
    if DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
        npcPed = nil
    end
    
    if DoesEntityExist(npcVehicle) then
        DeleteEntity(npcVehicle)
        npcVehicle = nil
    end
    
    if repairBlip and DoesBlipExist(repairBlip) then
        RemoveBlip(repairBlip)
        repairBlip = nil
    end
    
    TriggerEvent('siro_aimechanic:client:stopDUI')
end

-- メインの修理イベント
RegisterNetEvent('siro_aimechanic:client:spawnNPCAndRepair', function(vehicleData)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetVehicle = vehicleData.entity
    local targetCoords = vehicleData.coords
    
    -- NPCモデルをロード
    local npcModel = LoadModel(Config.NPCModel)
    if not npcModel then
        QBCore.Functions.Notify(L('error_spawn_npc'), 'error')
        exports['siro_aimechanic']:CancelRepair()
        return
    end
    
    -- NPC車両モデルをロード
    local carModel = LoadModel(Config.NPCCarModel)
    if not carModel then
        SetModelAsNoLongerNeeded(npcModel)
        QBCore.Functions.Notify(L('error_spawn_vehicle'), 'error')
        exports['siro_aimechanic']:CancelRepair()
        return
    end
    
    -- スポーン位置を計算（道路上）
    local spawnFound, spawnCoords, spawnHeading = GetClosestVehicleNodeWithHeading(
        playerCoords.x + Config.SpawnDistance,
        playerCoords.y,
        playerCoords.z,
        1, -- 通常の道路
        3.0,
        0
    )
    
    if not spawnFound then
        spawnCoords = playerCoords + vector3(Config.SpawnDistance, 0.0, 0.0)
        spawnHeading = 0.0
    end
    
    -- NPC車両をスポーン
    npcVehicle = CreateVehicle(carModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
    if not DoesEntityExist(npcVehicle) then
        SetModelAsNoLongerNeeded(npcModel)
        SetModelAsNoLongerNeeded(carModel)
        QBCore.Functions.Notify(L('error_spawn_vehicle'), 'error')
        exports['siro_aimechanic']:CancelRepair()
        return
    end
    
    SetVehicleOnGroundProperly(npcVehicle)
    SetEntityAsMissionEntity(npcVehicle, true, true)
    SetVehicleEngineOn(npcVehicle, true, true, false)
    
    -- NPCをスポーン（車内に）
    npcPed = CreatePedInsideVehicle(npcVehicle, 4, npcModel, -1, true, false)
    if not DoesEntityExist(npcPed) then
        DeleteEntity(npcVehicle)
        npcVehicle = nil
        SetModelAsNoLongerNeeded(npcModel)
        SetModelAsNoLongerNeeded(carModel)
        QBCore.Functions.Notify(L('error_spawn_npc'), 'error')
        exports['siro_aimechanic']:CancelRepair()
        return
    end
    
    SetEntityAsMissionEntity(npcPed, true, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetPedFleeAttributes(npcPed, 0, false)
    SetPedCombatAttributes(npcPed, 17, true)
    SetPedCanBeTargetted(npcPed, false)
    
    SetModelAsNoLongerNeeded(npcModel)
    SetModelAsNoLongerNeeded(carModel)
    
    -- ブリップを追加
    repairBlip = AddBlipForEntity(npcVehicle)
    SetBlipSprite(repairBlip, 446) -- レンチアイコン
    SetBlipColour(repairBlip, 5)
    SetBlipScale(repairBlip, 0.8)
    SetBlipAsShortRange(repairBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('NPC Mechanic')
    EndTextCommandSetBlipName(repairBlip)
    
    -- NPCを対象車両の近くまで運転させる
    local driveSuccess = DriveNPCToLocation(npcPed, npcVehicle, targetCoords)
    
    if not driveSuccess then
        CleanupNPC()
        exports['siro_aimechanic']:CancelRepair()
        return
    end
    
    -- 修理状態をチェック
    local isRepairing, _ = exports['siro_aimechanic']:GetRepairState()
    if not isRepairing then
        CleanupNPC()
        return
    end
    
    -- NPCを車から降ろす
    TaskLeaveVehicle(npcPed, npcVehicle, 0)
    
    local exitTimeout = 10000
    while IsPedInAnyVehicle(npcPed, false) and exitTimeout > 0 do
        Wait(100)
        exitTimeout = exitTimeout - 100
    end
    
    Wait(500)
    
    -- 修理演出を実行
    local repairSuccess = PerformRepairSequence(npcPed, targetVehicle)
    
    if repairSuccess then
        -- 修理完了処理
        exports['siro_aimechanic']:CompleteRepair()
        
        -- NPCを退出させる
        MakeNPCLeave(npcPed, npcVehicle, spawnCoords)
    else
        CleanupNPC()
    end
end)

-- クリーンアップイベント
RegisterNetEvent('siro_aimechanic:client:cleanup', function()
    CleanupNPC()
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CleanupNPC()
    end
end)

print('^2[siro_aimechanic]^7 NPC control script loaded successfully')
