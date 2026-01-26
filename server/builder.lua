local function toBoolean(num)
    if num == 1 or num == true then return true end
    return false
end

local function GenerateItemsFile()
    print('^3[RSG-Builder] ^7Fetching items from Database to generate items.lua...')
    
    MySQL.query('SELECT * FROM ll_items ORDER BY name ASC', {}, function(result)
        if not result or #result == 0 then
            print('^1[RSG-Builder] ^7Error: Database is empty! Aborting file generation to save your server.')
            return
        end

        -- 1. Start the file string
        local content = "RSGShared = RSGShared or {}\nRSGShared.Items = {\n"

        -- 2. Loop through every database row and format it into Lua code
        for _, row in ipairs(result) do
            -- Prepare optional fields (handle nulls)
            local decayStr = row.decay and ("decay = %s,"):format(row.decay) or ""
            local ammoStr = row.ammotype and ("ammotype = '%s',"):format(row.ammotype) or "ammotype = nil,"
            
            -- Format the line
            -- We use string.format to make it look exactly like the original file
            local line = string.format(
                "    ['%s'] = { name = '%s', label = '%s', weight = %s, type = '%s', image = '%s', unique = %s, useable = %s, shouldClose = %s, description = '%s', %s delete = %s, %s },\n",
                row.name, -- Key
                row.name,
                row.label:gsub("'", "\\'"), -- Escape apostrophes in labels (e.g., "Chef's Knife")
                row.weight,
                row.type,
                row.image,
                tostring(toBoolean(row.unique)),
                tostring(toBoolean(row.usable)), -- Maps DB 'usable' to Lua 'useable'
                tostring(toBoolean(row.shouldClose)),
                row.description:gsub("'", "\\'"), -- Escape apostrophes in description
                decayStr,
                tostring(toBoolean(row.delete)),
                ammoStr
            )
            
            content = content .. line
        end

        -- 3. Close the table
        content = content .. "}\n"

        -- 4. Overwrite the file
        -- SaveResourceFile is a FiveM/RedM native that writes to the current resource folder
        local saved = SaveResourceFile(GetCurrentResourceName(), "shared/items.lua", content, -1)

        if saved then
            print('^2[RSG-Builder] ^7Successfully generated shared/items.lua from Database!')
            print('^3[RSG-Builder] ^7PLEASE RESTART THE SERVER FOR CHANGES TO APPLY.')
        else
            print('^1[RSG-Builder] ^7Failed to write file. Check permissions or folder structure.')
        end
    end)
end

-- Create a console command to run this manually
RegisterCommand('builditems', function(source, args)
    if source == 0 then -- Only allow from console (security)
        GenerateItemsFile()
    end
end, true)

-- OPTIONAL: Run automatically on server start?
-- Uncomment the line below if you want it to rebuild every time the server boots up.
-- CreateThread(function() Wait(1000) GenerateItemsFile() end)