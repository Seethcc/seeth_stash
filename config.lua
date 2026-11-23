Config = {}

Config.TargetLabel = 'Rig a secret stash'
Config.OpenLabel = 'Open secret stash'
Config.DestroyLabel = 'Destroy secret stash'
Config.ProgressLabel = 'Rigging secret stash...'
Config.DestroyProgressLabel = 'Destroying secret stash...'
Config.BuildTime = 10000
Config.DestroyTime = 8000
Config.BuildEmote = 'mechanic'
Config.PlantEmote = 'garden'
Config.CancelEmoteCommand = 'e c'
Config.DestroyWeapon = `weapon_crowbar`
Config.PlantRequiredItem = 'shovel'
Config.PoliceJobs = {
    police = true
}

Config.StashSlots = 4
Config.StashWeight = 20000

Config.TargetDistance = 2.0
Config.CoordPrecision = 1

Config.OPCrimeResources = {
    'op-crime',
    'op_crime',
    'opcrime'
}

Config.Debug = true

-- This OP Crime build does not expose a reliable server ownership export, so
-- allow creation when the player is in a turf and belongs to an organisation.
Config.AllowClientTurfOrganisationFallback = true

function Config.GetPlayerJob(source)
    if GetResourceState('qbx_core') == 'started' then
        local ok, Player = pcall(function()
            return exports.qbx_core:GetPlayer(source)
        end)

        if ok and Player and Player.PlayerData and Player.PlayerData.job then
            return Player.PlayerData.job.name
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)

        if Player and Player.PlayerData and Player.PlayerData.job then
            return Player.PlayerData.job.name
        end
    end

    if GetResourceState('es_extended') == 'started' then
        local ESX = exports.es_extended:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)

        if Player and Player.job then
            return Player.job.name
        end
    end

    return nil
end

Config.AllowedProps = {
    -- Dumpsters
    `prop_dumpster_01a`,
    `prop_dumpster_02a`,
    `prop_dumpster_02b`,
    `prop_dumpster_3a`,
    `prop_dumpster_4a`,
    `prop_dumpster_4b`,

    -- Air conditioners / vents
    `prop_aircon_l_01`,
    `prop_aircon_l_02`,
    `prop_aircon_l_03`,
    `prop_aircon_l_04`,
    `prop_aircon_m_01`,
    `prop_aircon_m_02`,
    `prop_aircon_m_03`,

    -- Electrical boxes
    `prop_elecbox_01a`,
    `prop_elecbox_01b`,
    `prop_elecbox_02a`,
    `prop_elecbox_02b`,
    `prop_elecbox_03a`,
    `prop_elecbox_04a`,
    `prop_elecbox_05a`,
    `prop_elecbox_06a`,
    `prop_elecbox_07a`,
    `prop_elecbox_08`,
    `prop_elecbox_09`,
    `prop_elecbox_10`,
    `prop_elecbox_10_cr`,
    `prop_elecbox_11`,
    `prop_elecbox_13`,
    `prop_elecbox_14`,
    `prop_elecbox_15`,
    `prop_elecbox_16`,
    `prop_elecbox_17`,
    `prop_elecbox_18`,
    `prop_elecbox_19`,
    `prop_elecbox_20`,
    `prop_elecbox_21`,
    `prop_elecbox_22`,
    `prop_elecbox_23`,

    -- Car wrecks
    `prop_rub_carwreck_1`,
    `prop_rub_carwreck_2`,
    `prop_rub_carwreck_3`,
    `prop_rub_carwreck_4`,
    `prop_rub_carwreck_5`,
    `prop_rub_carwreck_6`,
    `prop_rub_carwreck_7`,
    `prop_rub_carwreck_8`,
    `prop_rub_carwreck_9`,
    `prop_rub_carwreck_10`,
    `prop_rub_carwreck_11`,
    `prop_rub_carwreck_12`,
    `prop_rub_carwreck_13`,
    `prop_rub_carwreck_14`,
    `prop_rub_carwreck_15`,
    `prop_rub_carwreck_16`,

    -- Letterboxes / mailboxes
    `prop_letterbox_01`,
    `prop_letterbox_02`,
    `prop_letterbox_03`,
    `prop_letterbox_04`,

    -- Potted plants
    `prop_pot_plant_01a`,
    `prop_pot_plant_01b`,
    `prop_pot_plant_01c`,
    `prop_pot_plant_01d`,
    `prop_pot_plant_01e`,
    `prop_pot_plant_02a`,
    `prop_pot_plant_02b`,
    `prop_pot_plant_02c`,
    `prop_pot_plant_02d`,
    `prop_pot_plant_03a`,
    `prop_pot_plant_03b`,
    `prop_pot_plant_03b_cr2`,
    `prop_pot_plant_03c`,
    `prop_pot_plant_04a`,
    `prop_pot_plant_04b`,
    `prop_pot_plant_04c`,
    `prop_pot_plant_05a`,
    `prop_pot_plant_05b`,
    `prop_pot_plant_05c`,
    `prop_pot_plant_05d`,
    `prop_pot_plant_6a`,
    `prop_pot_plant_6b`,
    `prop_pot_plant_bh1`,
    `prop_pot_plant_inter_03a`,
    `prop_plant_int_01a`,
    `prop_plant_int_01b`,
    `prop_plant_int_02a`,
    `prop_plant_int_02b`,
    `prop_plant_int_03a`,
    `prop_plant_int_03b`,
    `prop_plant_int_03c`,
    `prop_plant_int_04a`,
    `prop_plant_int_04b`,
    `prop_plant_int_04c`,
    `prop_plant_int_05a`,
    `prop_plant_int_05b`,
    `prop_plant_int_06a`,
    `prop_plant_int_06b`,
    `prop_plant_int_06c`,
    `prop_plant_paradise`,
    `prop_plant_paradise_b`,

    -- Newspaper stands
    `prop_news_disp_01a`,
    `prop_news_disp_02a`,
    `prop_news_disp_02b`,
    `prop_news_disp_02c`,
    `prop_news_disp_02d`,
    `prop_news_disp_02e`,
    `prop_news_disp_03a`,
    `prop_news_disp_03c`,
    `prop_news_disp_05a`,
}

Config.PottedPlantProps = {
    `prop_pot_plant_01a`,
    `prop_pot_plant_01b`,
    `prop_pot_plant_01c`,
    `prop_pot_plant_01d`,
    `prop_pot_plant_01e`,
    `prop_pot_plant_02a`,
    `prop_pot_plant_02b`,
    `prop_pot_plant_02c`,
    `prop_pot_plant_02d`,
    `prop_pot_plant_03a`,
    `prop_pot_plant_03b`,
    `prop_pot_plant_03b_cr2`,
    `prop_pot_plant_03c`,
    `prop_pot_plant_04a`,
    `prop_pot_plant_04b`,
    `prop_pot_plant_04c`,
    `prop_pot_plant_05a`,
    `prop_pot_plant_05b`,
    `prop_pot_plant_05c`,
    `prop_pot_plant_05d`,
    `prop_pot_plant_6a`,
    `prop_pot_plant_6b`,
    `prop_pot_plant_bh1`,
    `prop_pot_plant_inter_03a`,
    `prop_plant_int_01a`,
    `prop_plant_int_01b`,
    `prop_plant_int_02a`,
    `prop_plant_int_02b`,
    `prop_plant_int_03a`,
    `prop_plant_int_03b`,
    `prop_plant_int_03c`,
    `prop_plant_int_04a`,
    `prop_plant_int_04b`,
    `prop_plant_int_04c`,
    `prop_plant_int_05a`,
    `prop_plant_int_05b`,
    `prop_plant_int_06a`,
    `prop_plant_int_06b`,
    `prop_plant_int_06c`,
    `prop_plant_paradise`,
    `prop_plant_paradise_b`,
}

function Config.GetOPCrimeResource()
    for _, resource in ipairs(Config.OPCrimeResources) do
        if GetResourceState(resource) == 'started' then
            return resource
        end
    end

    return nil
end

function Config.DebugPrint(message)
    if Config.Debug then
        print(('[jonni_stash] %s'):format(message))
    end
end

function Config.Notify(source, message, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Secret stash',
        description = message,
        type = notifyType or 'inform'
    })
end
