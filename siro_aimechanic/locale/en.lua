--[[
    siro_aimechanic - English Language File
    Author: siro
]]

Locales = Locales or {}

Locales['en'] = {
    -- Command related
    ['command_name'] = 'helpmec',
    ['command_help'] = 'Call NPC mechanic for repair',

    -- Notification messages
    ['mechanic_on_duty'] = 'A mechanic is on duty, this service is unavailable',
    ['not_enough_money'] = 'Not enough money (Required: $%s)',
    ['no_vehicles_nearby'] = 'No vehicles found nearby',
    ['repair_cancelled'] = 'Repair has been cancelled',
    ['repair_cancelled_distance'] = 'Repair cancelled - you moved too far away',
    ['repair_cancelled_vehicle'] = 'Repair cancelled - target vehicle not found',
    ['repair_complete'] = 'Repair complete!',
    ['payment_success'] = 'Paid $%s',
    ['npc_arriving'] = 'NPC mechanic is on the way...',
    ['already_repairing'] = 'Already repairing',

    -- Menu related
    ['menu_title'] = 'Select Vehicle to Repair',
    ['vehicle_option'] = '%s - Distance: %.1fm',
    ['vehicle_plate'] = 'Plate: %s',
    ['repair_price'] = 'Repair Cost: $%s',

    -- Repair phases
    ['phase_welding'] = 'Welding...',
    ['phase_underbody'] = 'Inspecting underbody...',
    ['phase_engine'] = 'Working on engine...',

    -- DUI display
    ['dui_repairing'] = 'Repairing',
    ['dui_time_remaining'] = 'Time Remaining',

    -- Error messages
    ['error_spawn_npc'] = 'Failed to spawn NPC',
    ['error_spawn_vehicle'] = 'Failed to spawn vehicle',

    -- Vehicle names (generic)
    ['vehicle_car'] = 'Car',
    ['vehicle_bike'] = 'Motorcycle',
    ['vehicle_truck'] = 'Truck',
    ['vehicle_suv'] = 'SUV',
    ['vehicle_van'] = 'Van',
    ['vehicle_unknown'] = 'Vehicle'
}
