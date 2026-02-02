--[[
    siro_aimechanic - 設定ファイル
    Author: siro
]]

Config = {}

-- 言語設定 ('ja' / 'en')
Config.Locale = 'ja'

-- 修理費用
Config.Price = 500000

-- 支払い方法 ('cash' / 'bank')
Config.PaymentType = 'bank'

-- 修理時間（秒）
Config.StageTimes = {
    welding = 60,    -- 溶接作業
    underbody = 60,  -- 車体下作業
    engine = 60      -- エンジン整備
}

-- 使用シナリオ/エモート
Config.Scenarios = {
    welding = 'WORLD_HUMAN_WELDING',
    underbody = 'WORLD_HUMAN_VEHICLE_MECHANIC',
    engine = 'PROP_HUMAN_BUM_BIN'
}

-- 使用不可にするジョブ（これらのジョブが1人でも出勤中なら使用不可）
Config.BlockJobs = {
    'mechanic1',
    'mechanic2',
    'mechanic3',
    'mechanic4'
}

-- NPC設定
Config.NPCModel = 's_m_y_xmech_02'     -- NPCのモデル
Config.NPCCarModel = 'utillitruck3'    -- NPCの車両モデル

-- 車両検索範囲（メートル）
Config.VehicleSearchRadius = 30.0

-- 修理キャンセル距離（メートル）- プレイヤーがこの距離以上離れたらキャンセル
Config.CancelDistance = 50.0

-- NPCスポーン距離（メートル）- プレイヤーからこの距離にNPCがスポーン
Config.SpawnDistance = 80.0

-- NPC退出距離（メートル）- 修理完了後、NPCがこの距離まで走り去る
Config.LeaveDistance = 100.0

-- デバッグモード
Config.Debug = false
