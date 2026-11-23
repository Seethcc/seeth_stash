local stashes = {}
local plantModels = {}

for _, model in ipairs(Config.PottedPlantProps or {}) do
    plantModels[model] = true
end

local function publicStashes()
    local list = {}

    for key in pairs(stashes) do
        list[key] = { key = key }
    end

    return list
end

local function identifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local value = GetPlayerIdentifier(source, i)
        if value and value:find('license:', 1, true) == 1 then
            return value
        end
    end

    return GetPlayerIdentifier(source, 0)
end

local function opCrimeIdentifier(source)
    if GetResourceState('qbx_core') == 'started' then
        local ok, Player = pcall(function()
            return exports.qbx_core:GetPlayer(source)
        end)

        if ok and Player and Player.PlayerData and Player.PlayerData.citizenid then
            return Player.PlayerData.citizenid
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)

        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            return Player.PlayerData.citizenid
        end
    end

    return identifier(source)
end

local function round(value)
    local precision = Config.CoordPrecision or 1
    local multiplier = 10 ^ precision
    return math.floor(value * multiplier + 0.5) / multiplier
end

local function normalizeCoords(coords)
    return {
        x = round(coords.x + 0.0),
        y = round(coords.y + 0.0),
        z = round(coords.z + 0.0)
    }
end

local function stashId(owner)
    return ('jonni_stash_%s'):format(owner:gsub('[^%w]', '_'))
end

local function stashKey(model, coords)
    local precision = Config.CoordPrecision or 1
    local format = ('%%s:%%.%df:%%.%df:%%.%df'):format(precision, precision, precision)
    return format:format(model, coords.x, coords.y, coords.z)
end

local function registerStash(stash)
    Config.DebugPrint(('registering stash id=%s owner=%s organisation=%s'):format(
        stash.id,
        stash.owner,
        stash.organisation or 'unknown'
    ))

    exports.ox_inventory:RegisterStash(
        stash.id,
        'Secret Stash',
        Config.StashSlots,
        Config.StashWeight,
        stash.owner,
        nil,
        stash.coords
    )
end

local function loadStashes()
    local rows = MySQL.query.await('SELECT stash_key, stash_id, owner, organisation, model, x, y, z FROM jonni_stashes')

    for _, row in ipairs(rows or {}) do
        stashes[row.stash_key] = {
            id = row.stash_id,
            owner = row.owner,
            organisation = row.organisation,
            model = row.model,
            coords = {
                x = row.x,
                y = row.y,
                z = row.z
            }
        }

        registerStash(stashes[row.stash_key])
    end
end

local function createTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS jonni_stashes (
            stash_key VARCHAR(96) NOT NULL PRIMARY KEY,
            stash_id VARCHAR(96) NOT NULL,
            owner VARCHAR(96) NOT NULL,
            organisation VARCHAR(64) NOT NULL,
            model BIGINT NOT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_owner (owner)
        )
    ]])

    local column = MySQL.single.await([[
        SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'jonni_stashes'
            AND COLUMN_NAME = 'organisation'
    ]])

    if not column then
        MySQL.query.await("ALTER TABLE jonni_stashes ADD COLUMN organisation VARCHAR(64) NOT NULL DEFAULT 'unknown' AFTER owner")
    end

    local oldGangColumn = MySQL.single.await([[
        SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'jonni_stashes'
            AND COLUMN_NAME = 'gang'
    ]])

    if oldGangColumn then
        MySQL.query.await("ALTER TABLE jonni_stashes MODIFY COLUMN gang VARCHAR(64) NULL DEFAULT NULL")
    end
end

local function repairLegacyTable()
    local oldGangColumn = MySQL.single.await([[
        SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'jonni_stashes'
            AND COLUMN_NAME = 'gang'
    ]])

    if oldGangColumn then
        MySQL.query.await("ALTER TABLE jonni_stashes MODIFY COLUMN gang VARCHAR(64) NULL DEFAULT NULL")
    end
end

local function isAllowedModel(model)
    for _, allowedModel in ipairs(Config.AllowedProps) do
        if allowedModel == model then
            return true
        end
    end

    return false
end

local function isPlantModel(model)
    return plantModels[model] == true
end

local function hasPlantRequiredItem(source)
    local count = exports.ox_inventory:Search(source, 'count', Config.PlantRequiredItem)
    return count and count > 0
end

local function hasDestroyWeapon(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    return GetSelectedPedWeapon(ped) == Config.DestroyWeapon
end

local function isPolice(source)
    local job = Config.GetPlayerJob(source)
    return job and Config.PoliceJobs[job] == true
end

local function isStashEmpty(stash)
    local inventory = exports.ox_inventory:GetInventory(stash.id)
    if not inventory or not inventory.items then
        return true
    end

    for _, item in pairs(inventory.items) do
        if item and item.count and item.count > 0 then
            return false
        end
    end

    return true
end

local function getPlayerTurfZone(resource, source, owner, organisation)
    local orgId = type(organisation) == 'table' and organisation.id or nil
    local orgLabel = type(organisation) == 'table' and organisation.label or nil
    local checks = {
        { label = '(source)', call = function(export) return export(source) end },
        { label = '(owner)', call = function(export) return export(owner) end },
        { label = '(orgId)', call = function(export) return export(orgId) end },
        { label = '(orgLabel)', call = function(export) return export(orgLabel) end },
        { label = '()', call = function(export) return export() end }
    }

    for _, check in ipairs(checks) do
        local ok, result = pcall(function()
            return check.call(exports[resource].getPlayerTurfZone)
        end)

        Config.DebugPrint(('getPlayerTurfZone %s ok=%s result=%s'):format(check.label, tostring(ok), tostring(result)))

        if ok and result ~= nil then
            return result
        end
    end

    return nil
end

local function sameZone(left, right)
    if left == nil or right == nil then return false end
    return tostring(left) == tostring(right)
end

local function failTurfCheck(reason)
    Config.DebugPrint(reason)
    return false, reason
end

local function normaliseOrganisation(organisation)
    if type(organisation) ~= 'table' then return nil end

    local orgData = type(organisation.orgData) == 'table' and organisation.orgData or nil
    local id = organisation.id
        or organisation.orgIndex
        or organisation.identifier
        or (orgData and orgData.id)

    if not id and type(organisation.name) == 'string' then
        id = organisation.name:match('^gang_(.+)$')
    end

    local label = organisation.label
        or (orgData and orgData.label)
        or organisation.name

    if not id and not label then return nil end

    return {
        id = id and tostring(id) or nil,
        label = label and tostring(label) or nil,
        raw = organisation
    }
end

local function getPlayerOrganisation(resource, owner, clientOrganisation)
    local organisation = normaliseOrganisation(clientOrganisation)
    if organisation then return organisation end

    local ok, result = pcall(function()
        return exports[resource]:getPlayerOrganisation(owner)
    end)

    Config.DebugPrint(('getPlayerOrganisation(owner) ok=%s result=%s'):format(ok, tostring(result)))

    organisation = ok and normaliseOrganisation(result) or nil
    if organisation then return organisation end

    ok, result = pcall(function()
        return exports[resource]:getPlayerOrganisationForQB(owner)
    end)

    Config.DebugPrint(('getPlayerOrganisationForQB(owner) ok=%s result=%s'):format(ok, tostring(result)))

    return ok and normaliseOrganisation(result) or nil
end

local function organisationLabel(organisation)
    organisation = normaliseOrganisation(organisation)
    if not organisation then return nil end
    return organisation.label or organisation.id
end

local function canCreateInCurrentTurf(source, owner)
    local resource = Config.GetOPCrimeResource()
    if not resource then
        return failTurfCheck('OP Crime resource not started. Check Config.OPCrimeResources.')
    end

    local contextOk, context = pcall(function()
        return lib.callback.await('jonni_stash:client:getTurfContext', source)
    end)

    if not contextOk or type(context) ~= 'table' or not context.inTurf then
        return failTurfCheck(('client isInTurfZone failed. contextOk=%s inTurf=%s zone=%s'):format(
            tostring(contextOk),
            type(context) == 'table' and tostring(context.inTurf) or 'nil',
            type(context) == 'table' and tostring(context.zone) or 'nil'
        ))
    end

    local organisation = getPlayerOrganisation(resource, owner, context.organisation)

    if not organisation or not organisation.id then
        return failTurfCheck('OP Crime organisation not found for player')
    end

    local serverZone = getPlayerTurfZone(resource, source, owner, organisation)
    local zone = context.zone or serverZone
    Config.DebugPrint(('turf zones source=%s client=%s server=%s'):format(source, tostring(context.zone), tostring(serverZone)))

    if not zone then
        return failTurfCheck('no turf zone returned by client or server')
    end

    -- OP Crime's getPlayerTurfZone returns the player's owned turf zone. If it
    -- matches the turf the client is standing in, treat that as ownership.
    if sameZone(serverZone, context.zone) then
        Config.DebugPrint(('owned turf confirmed by matching zone source=%s zone=%s'):format(source, tostring(serverZone)))
        return true, organisation
    end

    if Config.AllowClientTurfOrganisationFallback then
        Config.DebugPrint(('client turf/org fallback accepted source=%s zone=%s organisation=%s'):format(
            source,
            tostring(zone),
            organisationLabel(organisation) or 'nil'
        ))
        return true, organisation
    end

    return failTurfCheck(('ownership failed. currentTurf=%s ownedTurf=%s organisation=%s'):format(
        tostring(context.zone),
        tostring(serverZone),
        organisationLabel(organisation) or 'nil'
    ))
end

local function validateCreateRequest(source, payload, notify)
    if type(payload) ~= 'table' or type(payload.coords) ~= 'table' then
        return false
    end

    local owner = identifier(source)
    if not owner then return false end

    local model = tonumber(payload.model)
    if not model or not isAllowedModel(model) then
        if notify then Config.Notify(source, 'This prop cannot be rigged.', 'error') end
        return false
    end

    if isPlantModel(model) and not hasPlantRequiredItem(source) then
        if notify then Config.Notify(source, 'You need a shovel to rig a plant stash.', 'error') end
        return false
    end

    local coords = normalizeCoords(payload.coords)
    local key = stashKey(model, coords)

    if payload.key ~= key then
        return false
    end

    if stashes[key] then
        if notify then
            TriggerClientEvent('jonni_stash:client:addStash', source, key, { key = key })
            Config.Notify(source, 'This prop already has a stash. Your target cache was refreshed.', 'error')
        end
        return false
    end

    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
    if distance > 5.0 then
        return false
    end

    local ownsCurrentTurf, turfContext = canCreateInCurrentTurf(source, opCrimeIdentifier(source))
    if not ownsCurrentTurf then
        if notify then
            local message = 'Your organisation does not control this turf.'
            if Config.Debug and turfContext then
                message = ('%s %s'):format(message, turfContext)
            end
            Config.Notify(source, message, 'error')
        end
        return false
    end

    local organisation = organisationLabel(turfContext)
    if not organisation then
        if notify then Config.Notify(source, 'You need to be in an organisation to do this.', 'error') end
        return false
    end

    local existing = MySQL.scalar.await('SELECT stash_id FROM jonni_stashes WHERE owner = ?', { owner })
    if existing then
        if notify then Config.Notify(source, 'You already have a secret stash.', 'error') end
        return false
    end

    return true, {
        key = key,
        owner = owner,
        organisation = organisation,
        model = model,
        coords = coords
    }
end

local function validateDestroyRequest(source, key, notify)
    local stash = stashes[key]
    if not stash then return false end

    local police = isPolice(source)

    if not police and identifier(source) ~= stash.owner then
        if notify then Config.Notify(source, 'This is not your secret stash.', 'error') end
        return false
    end

    if not police and not hasDestroyWeapon(source) then
        if notify then Config.Notify(source, 'You need a crowbar in your hand.', 'error') end
        return false
    end

    if isPlantModel(stash.model) and not hasPlantRequiredItem(source) then
        if notify then Config.Notify(source, 'You need a shovel to destroy a plant stash.', 'error') end
        return false
    end

    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - vector3(stash.coords.x, stash.coords.y, stash.coords.z))
    if distance > 5.0 then return false end

    if not isStashEmpty(stash) then
        if notify then Config.Notify(source, 'Empty your secret stash before destroying it.', 'error') end
        return false
    end

    return true, stash
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    createTable()
    loadStashes()

    SetTimeout(1500, function()
        TriggerClientEvent('jonni_stash:client:setStashes', -1, publicStashes())
    end)
end)

RegisterNetEvent('jonni_stash:server:requestStashes', function()
    TriggerClientEvent('jonni_stash:client:setStashes', source, publicStashes())
end)

lib.callback.register('jonni_stash:server:canCreateStash', function(source, payload)
    local allowed = validateCreateRequest(source, payload, true)
    return allowed == true
end)

lib.callback.register('jonni_stash:server:canDestroyStash', function(source, key)
    local allowed = validateDestroyRequest(source, key, true)
    return allowed == true
end)

RegisterNetEvent('jonni_stash:server:createStash', function(payload)
    local src = source

    local valid, request = validateCreateRequest(src, payload, true)
    if not valid then return end

    local stash = {
        id = stashId(request.owner),
        owner = request.owner,
        organisation = request.organisation,
        model = request.model,
        coords = request.coords
    }

    local insertOk, insertResult = pcall(function()
        return MySQL.insert.await([[
        INSERT INTO jonni_stashes (stash_key, stash_id, owner, organisation, model, x, y, z)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            request.key,
            stash.id,
            stash.owner,
            stash.organisation,
            stash.model,
            stash.coords.x,
            stash.coords.y,
            stash.coords.z
        })
    end)

    Config.DebugPrint(('stash insert ok=%s result=%s key=%s id=%s'):format(
        tostring(insertOk),
        tostring(insertResult),
        request.key,
        stash.id
    ))

    if not insertOk then
        repairLegacyTable()

        insertOk, insertResult = pcall(function()
            return MySQL.insert.await([[
            INSERT INTO jonni_stashes (stash_key, stash_id, owner, organisation, model, x, y, z)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                request.key,
                stash.id,
                stash.owner,
                stash.organisation,
                stash.model,
                stash.coords.x,
                stash.coords.y,
                stash.coords.z
            })
        end)

        Config.DebugPrint(('stash insert retry ok=%s result=%s key=%s id=%s'):format(
            tostring(insertOk),
            tostring(insertResult),
            request.key,
            stash.id
        ))
    end

    if not insertOk then
        local message = 'Could not create that stash.'
        if Config.Debug then
            message = ('%s %s'):format(message, tostring(insertResult))
        end

        Config.Notify(src, message, 'error')
        return
    end

    stashes[request.key] = stash
    registerStash(stash)

    TriggerClientEvent('jonni_stash:client:addStash', -1, request.key, { key = request.key })
    TriggerClientEvent('jonni_stash:client:setStashes', src, publicStashes())
    Config.Notify(src, 'Secret stash rigged.', 'success')
end)

RegisterNetEvent('jonni_stash:server:openStash', function(key)
    local src = source
    local stash = stashes[key]

    if not stash then return end

    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - vector3(stash.coords.x, stash.coords.y, stash.coords.z))
    if distance > 5.0 then return end

    exports.ox_inventory:forceOpenInventory(src, 'stash', {
        id = stash.id,
        owner = stash.owner
    })
end)

RegisterNetEvent('jonni_stash:server:destroyStash', function(key)
    local src = source
    local valid, stash = validateDestroyRequest(src, key, true)
    if not valid then return end

    local deleteOk, deleteResult = pcall(function()
        return MySQL.update.await('DELETE FROM jonni_stashes WHERE stash_key = ? AND owner = ?', {
            key,
            stash.owner
        })
    end)

    Config.DebugPrint(('stash delete ok=%s result=%s key=%s id=%s'):format(
        tostring(deleteOk),
        tostring(deleteResult),
        key,
        stash.id
    ))

    if not deleteOk then
        local message = 'Could not destroy that stash.'
        if Config.Debug then
            message = ('%s %s'):format(message, tostring(deleteResult))
        end

        Config.Notify(src, message, 'error')
        return
    end

    stashes[key] = nil
    exports.ox_inventory:ClearInventory(stash.id, true)

    TriggerClientEvent('jonni_stash:client:removeStash', -1, key)
    TriggerClientEvent('jonni_stash:client:setStashes', src, publicStashes())
    Config.Notify(src, 'Secret stash destroyed.', 'success')
end)
