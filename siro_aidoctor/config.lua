--[[
    siro_aidoctor - 設定ファイル
    AI救急医が駆けつけて蘇生してくれるスクリプト
]]

Config = {}

-- 言語設定 ('ja' = 日本語, 'en' = 英語)
Config.Locale = 'ja'

-- EMS人数制限 (この人数以下の時のみ使用可能)
Config.Doctor = 0

-- 蘇生料金
Config.Price = 400000

-- 蘇生にかかる時間 (ミリ秒)
Config.ReviveTime = 20000

-- コマンド名
Config.Command = 'help'

-- 救急車のモデル
Config.VehicleModel = 'ambulance'

-- 医師のモデル
Config.PedModel = 's_m_m_doctor_01'

-- 救急車のナンバープレート
Config.PlateText = 'AIDOC'

-- サイレンを鳴らすか
Config.UseSiren = true

-- スポーン距離 (プレイヤーからの距離)
Config.SpawnRadius = 60

-- 運転速度
Config.DriveSpeed = 25.0
