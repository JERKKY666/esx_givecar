-- Define allowed groups here
local allowedGroups = {
    ['admin'] = true,
    ['superadmin'] = true,
    ['dono'] = true
}

-- Helper to generate random license plates
local function GeneratePlate()
    local charset = {}
    for c = 48, 57 do table.insert(charset, string.char(c)) end -- numbers
    for c = 65, 90 do table.insert(charset, string.char(c)) end -- capital letters

    math.randomseed(os.time())
    local plate = ''
    for i = 1, 7 do
        plate = plate .. charset[math.random(1, #charset)]
    end
    return plate
end

-- /givecar [playerId] [vehicleSpawnName] [plate]
RegisterCommand('givecar', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not allowedGroups[xPlayer.getGroup()] then
        xPlayer.showNotification('~r~You do not have permission to use this command.')
        return
    end

    local targetId = tonumber(args[1])
    local spawnName = args[2]
    local plate = args[3]

    if not targetId or not spawnName then
        xPlayer.showNotification('~r~Usage: /givecar [playerId] [spawnName] [plate (optional)]')
        return
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        xPlayer.showNotification('~r~Invalid target player.')
        return
    end

    if not plate then
        plate = GeneratePlate()
    end

    -- Insert into owned_vehicles database
    MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type) VALUES (?, ?, ?, ?)', {
        target.getIdentifier(),
        plate,
        json.encode({ model = GetHashKey(spawnName), plate = plate }),
        'car'
    }, function()
        xPlayer.showNotification('~g~Vehicle given successfully!')
        target.showNotification('~g~You received a new vehicle!')
    end)
end, false)

-- /delcarplate [plate]
RegisterCommand('delcarplate', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not allowedGroups[xPlayer.getGroup()] then
        xPlayer.showNotification('~r~You do not have permission to use this command.')
        return
    end

    local plate = args[1]
    if not plate then
        xPlayer.showNotification('~r~Usage: /delcarplate [plate]')
        return
    end

    -- Delete vehicle from owned_vehicles
    MySQL.update('DELETE FROM owned_vehicles WHERE plate = ?', {
        plate
    }, function(affectedRows)
        if affectedRows > 0 then
            xPlayer.showNotification('~g~Vehicle with plate '..plate..' deleted.')
        else
            xPlayer.showNotification('~r~No vehicle found with that plate.')
        end
    end)
end, false)
