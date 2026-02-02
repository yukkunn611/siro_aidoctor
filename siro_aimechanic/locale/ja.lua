--[[
    siro_aimechanic - 日本語言語ファイル
    Author: siro
]]

Locales = Locales or {}

Locales['ja'] = {
    -- コマンド関連
    ['command_name'] = 'helpmec',
    ['command_help'] = 'NPCメカニックを呼び出す',

    -- 通知メッセージ
    ['mechanic_on_duty'] = 'メカニックが出勤中のため、このサービスは利用できません',
    ['not_enough_money'] = 'お金が足りません（必要: $%s）',
    ['no_vehicles_nearby'] = '周囲に車両が見つかりません',
    ['repair_cancelled'] = '修理がキャンセルされました',
    ['repair_cancelled_distance'] = '対象から離れすぎたため、修理がキャンセルされました',
    ['repair_cancelled_vehicle'] = '対象車両が見つからないため、修理がキャンセルされました',
    ['repair_complete'] = '修理が完了しました！',
    ['payment_success'] = '$%s を支払いました',
    ['npc_arriving'] = 'NPCメカニックが向かっています...',
    ['already_repairing'] = '既に修理中です',

    -- メニュー関連
    ['menu_title'] = '修理する車両を選択',
    ['vehicle_option'] = '%s - 距離: %.1fm',
    ['vehicle_plate'] = 'ナンバー: %s',
    ['repair_price'] = '修理費用: $%s',

    -- 修理フェーズ
    ['phase_welding'] = '溶接作業中...',
    ['phase_underbody'] = '車体下を点検中...',
    ['phase_engine'] = 'エンジンを整備中...',

    -- DUI表示
    ['dui_repairing'] = '修理中',
    ['dui_time_remaining'] = '残り時間',

    -- エラーメッセージ
    ['error_spawn_npc'] = 'NPCのスポーンに失敗しました',
    ['error_spawn_vehicle'] = '車両のスポーンに失敗しました',

    -- 車両名（一般的なもの）
    ['vehicle_car'] = '乗用車',
    ['vehicle_bike'] = 'バイク',
    ['vehicle_truck'] = 'トラック',
    ['vehicle_suv'] = 'SUV',
    ['vehicle_van'] = 'バン',
    ['vehicle_unknown'] = '車両'
}
