--[[
    siro_aimechanic - 3D Display
    Author: siro
    修理中の車両上に3Dテキスト（残り時間、プログレスバー）を表示
    DUIはFiveM環境で動作が不安定なため、3Dテキストベースで実装
]]

-- 表示関連の変数
local targetVehicle = nil
local totalRepairTime = 0
local startTime = 0
local currentPhase = ''
local displayActive = false

-- 3Dテキスト描画関数
local function DrawText3D(coords, text, scale, r, g, b)
    r = r or 255
    g = g or 255
    b = b or 255
    scale = scale or 0.35
    
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(0)
        SetTextProportional(true)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 200)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(x, y)
    end
    
    return onScreen, x, y
end

-- プログレスバーを描画
local function DrawProgressBar(x, y, width, height, progress, bgR, bgG, bgB, fgR, fgG, fgB)
    -- 背景
    DrawRect(x, y, width, height, bgR or 30, bgG or 30, bgB or 30, 200)
    
    -- 進捗部分
    local progressWidth = width * (progress / 100)
    local progressX = x - (width / 2) + (progressWidth / 2)
    DrawRect(progressX, y, progressWidth, height - 0.002, fgR or 255, fgG or 165, fgB or 0, 255)
    
    -- 枠線（上下左右）
    local borderThickness = 0.001
    DrawRect(x, y - height/2, width, borderThickness, 255, 165, 0, 255) -- 上
    DrawRect(x, y + height/2, width, borderThickness, 255, 165, 0, 255) -- 下
    DrawRect(x - width/2, y, borderThickness, height, 255, 165, 0, 255) -- 左
    DrawRect(x + width/2, y, borderThickness, height, 255, 165, 0, 255) -- 右
end

-- 時間をフォーマット（分:秒）
local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    if mins > 0 then
        return string.format('%d:%02d', mins, secs)
    else
        return string.format('%d秒', secs)
    end
end

-- 表示開始
RegisterNetEvent('siro_aimechanic:client:startDUI', function(vehicle, totalTime)
    if displayActive then return end
    
    targetVehicle = vehicle
    totalRepairTime = totalTime
    startTime = GetGameTimer()
    displayActive = true
    currentPhase = L('phase_welding')
    
    CreateThread(function()
        while displayActive and DoesEntityExist(targetVehicle) do
            Wait(0)
            
            local vehicleCoords = GetEntityCoords(targetVehicle)
            local displayCoords = vehicleCoords + vector3(0.0, 0.0, 2.0)
            
            -- カメラからの距離をチェック
            local camCoords = GetGameplayCamCoord()
            local distance = #(camCoords - displayCoords)
            
            if distance < 50.0 then
                -- 残り時間を計算
                local elapsedTime = (GetGameTimer() - startTime) / 1000
                local remainingTime = math.max(0, totalRepairTime - elapsedTime)
                local progress = math.min(100, (elapsedTime / totalRepairTime) * 100)
                
                -- スクリーン座標に変換
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(
                    displayCoords.x, 
                    displayCoords.y, 
                    displayCoords.z
                )
                
                if onScreen then
                    -- タイトル（修理中）
                    SetTextScale(0.5, 0.5)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(255, 165, 0, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 200)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry('STRING')
                    SetTextCentre(true)
                    AddTextComponentString('🔧 ' .. L('dui_repairing'))
                    DrawText(screenX, screenY - 0.05)
                    
                    -- フェーズ表示
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(135, 206, 235, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 200)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry('STRING')
                    SetTextCentre(true)
                    AddTextComponentString(currentPhase)
                    DrawText(screenX, screenY - 0.02)
                    
                    -- プログレスバー
                    DrawProgressBar(screenX, screenY + 0.015, 0.15, 0.015, progress, 30, 30, 30, 255, 165, 0)
                    
                    -- 残り時間
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(255, 255, 255, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 200)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry('STRING')
                    SetTextCentre(true)
                    AddTextComponentString(L('dui_time_remaining') .. ': ' .. FormatTime(remainingTime))
                    DrawText(screenX, screenY + 0.035)
                    
                    -- 進捗パーセント
                    SetTextScale(0.3, 0.3)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(200, 200, 200, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 200)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry('STRING')
                    SetTextCentre(true)
                    AddTextComponentString(string.format('%.0f%%', progress))
                    DrawText(screenX, screenY + 0.055)
                end
            end
        end
        
        displayActive = false
    end)
end)

-- フェーズ更新
RegisterNetEvent('siro_aimechanic:client:updatePhase', function(phase)
    currentPhase = phase
end)

-- 表示終了
RegisterNetEvent('siro_aimechanic:client:stopDUI', function()
    displayActive = false
    targetVehicle = nil
    totalRepairTime = 0
    startTime = 0
    currentPhase = ''
end)

-- 状態取得用のエクスポート
exports('IsDisplayActive', function()
    return displayActive
end)

print('^2[siro_aimechanic]^7 3D display script loaded successfully')
