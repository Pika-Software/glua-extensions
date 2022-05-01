--[[-------------------------------------------------------------------------
    `boolean` game.ChangeMap( `string` map )
---------------------------------------------------------------------------]]

function game.ChangeMap( str )
    local mapName = str:Replace( ".bsp", "" )
    if game.HasMap( mapName ) then
        if console and isfunction( console.log ) then
            console.log( game.GetMap(), " -> ", mapName ):setTag( "Map Сhange" )
        end

        timer.Simple(0, function()
            RunConsoleCommand( "changelevel", mapName )
        end)

        return true
    end

    return false
end

--[[-------------------------------------------------------------------------
    game.Restart()
---------------------------------------------------------------------------]]

function game.Restart()
    game.ConsoleCommand("_restart\n")
end

do

    local resource_AddWorkshop = environment.saveFunc( "resource.AddWorkshop", resource.AddWorkshop )
    local table_insert = table.insert
    local ipairs = ipairs
    local print = print

    local workshop = {}

    --[[-------------------------------------------------------------------------
        `table` resource.GetWorkshop()
    ---------------------------------------------------------------------------]]
    function resource.GetWorkshop()
        return workshop
    end

    --[[-------------------------------------------------------------------------
        `boolean` resource.AddWorkshop( `string` id )
    ---------------------------------------------------------------------------]]
    function resource.AddWorkshop( id )
        for num, wsid in ipairs( workshop ) do
            if (wsid == id) then
                return false
            end
        end

        print( "\t+Addon (" .. id .. ")" )
        table_insert( workshop, id )
        resource_AddWorkshop( id )

        return true
    end

end

--[[-------------------------------------------------------------------------
    resource.AddWorkshopCollection( `string` id )
---------------------------------------------------------------------------]]

function resource.AddWorkshopCollection( id )
    http.Post("https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/",
    {
        ["collectioncount"] = "1",
        ["publishedfileids[0]"] = id
    },
    function( body, len, headers, code )
        if (code == 200) then
            local json = util.JSONToTable( body )
            if (json ~= nil) and (json.response ~= nil) then
                for num, collection in ipairs( json.response.collectiondetails ) do
                    if (collection.children == nil) then continue end

                    for num, addon in ipairs(collection.children) do
                        resource.AddWorkshop( addon.publishedfileid )
                    end

                    print( "Successfully added " .. #collection.children .. " addons to WorkshopDL from '" .. collection.publishedfileid )
                end

                return
            end
        end

        Error( "Error on adding collection '" .. id .. "' to WorkshopDL! (Code: " .. code .. ") Body:\n" .. body .. "\n" )
    end,
    function( err )
        print( "Error on adding collection '" .. id .. "' to WorkshopDL:\n" .. err )
    end)
end