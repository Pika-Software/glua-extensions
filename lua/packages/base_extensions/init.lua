local ipairs = ipairs
local type = type

do

    local math_random = math.random
    local table_GetKeys = table.GetKeys

    function table.OnlyRandom( tab, issequential )
        local keys = issequential and tab or table_GetKeys( tab )
        local rand = keys[ math_random(1, #keys) ]
        return tab[rand]
    end

end

--[[-------------------------------------------------------------------------
    table.FastCopyList( `table` tbl )
---------------------------------------------------------------------------]]

do
    local ipairs = ipairs
    function table.FastCopyList( tab )
        local copy = {}
        for key, value in ipairs( tab ) do
            copy[ key ] = value
        end

        return copy
    end
end

--[[-------------------------------------------------------------------------
    table.FastCopy( `table` tbl, `boolean` issequential )
---------------------------------------------------------------------------]]

do
    local pairs = pairs
    function table.FastCopy( tab, issequential )
        if (issequential) then
            return table.FastCopyList( tab )
        end

        local copy = {}
        for key, value in pairs( tab ) do
            copy[ key ] = value
        end

        return copy
    end
end

-- http://lua-users.org/wiki/CopyTable
--[[-------------------------------------------------------------------------
    table.DeepCopy( `table` tbl )
---------------------------------------------------------------------------]]

do

    local getmetatable = getmetatable
    local setmetatable = setmetatable
    local table_type = "table"
    local type = type
    local next = next

    function table.DeepCopy( tab )
        if (type( tab ) == table_type) then
            local copy = {}
            for key, value in next, tab, nil do
                copy[ table.DeepCopy( key ) ] = table.DeepCopy( value )
            end

            setmetatable( copy, table.DeepCopy( getmetatable(tab) ) )

            return copy
        end

        return tab
    end

end

-- engine.GetAddon( wsid )
do

    local engine_GetAddons = engine.GetAddons

    function engine.GetAddon( wsid )
        for _, tbl in ipairs( engine_GetAddons() ) do
            if tbl.wsid == wsid then return tbl end
        end
    end

end

-- engine.GetGMAFiles( `string` path )
-- do

--     local empty = {}
--     local game_MountGMA = game.MountGMA
--     function engine.GetGMAFiles( path )
--         local ok, files = game_MountGMA( path )
--         return ok and files or empty
--     end

-- end

-- engine.GetAddonFiles( id )
-- do

--     local empty = {}
--     local engine_GetAddon = engine.GetAddon
--     local engine_GetGMAFiles = engine.GetGMAFiles

--     function engine.GetAddonFiles( id )
--         local addon = engine_GetAddon( id )
--         if (addon == nil) then
--             return empty
--         end

--         return engine_GetGMAFiles( addon.file )
--     end

-- end

-- Net tables compress method by DefaultOS#5913
-- do

--     local util_TableToJSON = util.TableToJSON
--     local util_Compress = util.Compress
--     local net_WriteUInt = net.WriteUInt
--     local net_WriteData = net.WriteData

--     function net.WriteCompressTable( tbl )
--         if (type( tbl ) == "table") then
--             local data = util_Compress( util_TableToJSON( tbl ) )
--             net_WriteUInt( #data, 16 )
--             net_WriteData( data, #data )
--         end
--     end

-- end

-- do

--     local util_JSONToTable = util.JSONToTable
--     local util_Decompress = util.Decompress
--     local net_ReadData = net.ReadData
--     local net_ReadUInt = net.ReadUInt

--     function net.ReadCompressTable()
--         local len = net_ReadUInt(16)
--         return util_JSONToTable(util_Decompress(net_ReadData(len)))
--     end

-- end

-- IMaterial improvements
do

    local IMATERIAL = FindMetaTable( "IMaterial" )

    do
        local getmetatable = getmetatable
        function ismaterial( any )
            return getmetatable( any ) == IMATERIAL
        end
    end

    function IMATERIAL:GetSize()
        return self:GetInt( "$realwidth" ), self:GetInt( "$realheight" )
    end

end

-- concommand.Exists( name )
do

    local concommand_GetTable = concommand.GetTable

    function concommand.Exists( name )
        return concommand_GetTable()[ name ] ~= nil
    end

end

-- ents.closest( tbl, pos )
do

    local math_huge = math.huge
    function ents.closest( tbl, pos )
        local distance, entity = math_huge

        for _, ent in ipairs( tbl ) do
            local dist = ent:GetPos():DistToSqr( pos )
            if dist < distance then
                distance = dist
                entity = ent
            end
        end

        return entity
    end

end

-- player.GetListenServerHost
do

    if game.SinglePlayer() then

        local Entity = Entity

        function player.GetListenServerHost()
            return Entity( 1 )
        end

    else

        if game.IsDedicated() then
            player.GetListenServerHost = environment.loadFunc()
        else

            local player_GetHumans = player.GetHumans

            function player.GetListenServerHost()
                for _, ply in ipairs( player_GetHumans() ) do
                    if type( ply.IsListenServerHost ) ~= "function" then continue end
                    if ply:IsListenServerHost() then return ply end
                end
            end

        end

    end

end

-- player.Random( noBots )
do

    local player_GetHumans = player.GetHumans
    local player_GetAll = player.GetAll
    local math_random = math.random

    function player.Random( noBots )
        local players = noBots and player_GetHumans() or player_GetAll()
        return players[ math_random( 1, #players ) ]
    end

end

local table_insert = table.insert

-- game.AmmoList
-- do

--     local game_GetAmmoName = game.GetAmmoName

--     function game.AmmoList()
--         local last = game_GetAmmoName( 1 )
--         local ammoList = { last }

--         while last ~= nil do
--             last = game_GetAmmoName( table_insert( ammoList, last ) )
--         end

--         return ammoList
--     end

-- end

-- game.GetMaps()
-- do

--     local file_Find = file.Find

--     function game.GetMaps()
--         local maps = {}
--         for num, fl in ipairs( file_Find( "maps/*", "GAME" ) ) do
--             if fl:GetExtensionFromFilename() == "bsp" then
--                 table_insert( maps, fl:sub( 1, #fl - 4 ) )
--             end
--         end

--         return maps
--     end

-- end

-- game.HasMap( map )
-- do

--     local game_GetMaps = game.GetMaps
--     function game.HasMap( str )
--         local mapName = str:Replace( ".bsp", "" )
--         for num, map in ipairs( game_GetMaps() ) do
--             if (map == mapName) then
--                 return true
--             end
--         end

--         return false
--     end

-- end

-- game.GetWorldSize()
function game.GetWorldSize()
    local world = game.GetWorld()
    if not world then return end

    return world:GetInternalVariable( "m_WorldMins" ), world:GetInternalVariable( "m_WorldMaxs" )
end

-- string.Hash( str )
do

    local math_fmod = math.fmod
    function string.Hash( str )
        local hash = 0
        for num, v in ipairs({ str:byte( 0, str:len() ) }) do
            hash = math_fmod( v + ((hash * 32) - hash), 0x07FFFFFF )
        end

        return hash
    end

end

-- string.FormatSeconds( `string` sec ) - seconds to formated time string
do

    local full = "%s:%s:%s"
    local hoursMinutes = "%s:%s"
    local math_floor = math.floor

    function string.FormatSeconds( sec )
        local hours = math_floor( sec / 3600 )
        local minutes = math_floor( ( sec % 3600 ) / 60 )
        local seconds = sec % 60

        if (minutes < 10) then
            minutes = "0" .. minutes
        end

        if (seconds < 10) then
            seconds = "0" .. seconds
        end

        if (hours > 0) then
            return full:format( hours, minutes, seconds )
        else
            return hoursMinutes:format( minutes, seconds )
        end
    end

end

--[[-------------------------------------------------------------------------
    string.charCount - returns char counts from string
---------------------------------------------------------------------------]]

function string.charCount( str, char )
    ArgAssert( str, 1, "string" )
    ArgAssert( char, 2, "string" )

    local counter = 0
    for i = 1, #str do
        if str[ i ] == char then
            counter = counter + 1
        end
    end

    return count
end

-- table
function table.Sub( tbl, offset, len )
    local newTbl = {}
    for i = 1, len do
        newTbl[i] = tbl[i + offset]
    end

    return newTbl
end

function table.Min( tbl )
    local min = nil
    for key, value in ipairs( tbl ) do
        if (min == nil) or (value < min) then
            min = value
        end
    end

    return min
end

function table.Max( tbl )
    local max = nil
    for key, value in ipairs( tbl ) do
        if (max == nil) or (value > max) then
            max = value
        end
    end

    return max
end

do

    local table_Copy = table.Copy
    function table.Lookup( tbl, key, default )
        local lookup = table_Copy( tbl )

        for num, fragment in ipairs( key:Split( "." ) ) do
            lookup = lookup[fragment]

            if not lookup then
                return default
            end
        end

        return lookup
    end

end

--[[-------------------------------------------------------------------------
    C# math.Map = Lua math.Remap
---------------------------------------------------------------------------]]

math.Map = math.Remap

--[[-------------------------------------------------------------------------
    Angle improvements
---------------------------------------------------------------------------]]

do

    local ANGLE = FindMetaTable("Angle")
    local LerpAngle = LerpAngle

    function ANGLE:Lerp( frac, b )
        return LerpAngle( frac, self, b )
    end

end

-- vector
do

    local VECTOR = FindMetaTable("Vector")
    local LerpVector = LerpVector
    function VECTOR:Lerp( frac, b )
        return LerpVector( frac, self, b )
    end

end

local ENTITY = FindMetaTable( "Entity" )

do

    local doorClasses = {
        ["prop_testchamber_door"] = true,
        ["prop_door_rotating"] = true,
        ["func_door_rotating"] = true,
        ["func_door"] = true
    }

    function ENTITY:IsDoor()
        return doorClasses[self:GetClass()] or false
    end

end

do

    local propClasses = {
        ["prop_detail"] = true,
        ["prop_static"] = true,
        ["prop_physics"] = true,
        ["prop_ragdoll"] = true,
        ["prop_dynamic"] = true,
        ["prop_physics_override"] = true,
        ["prop_dynamic_override"] = true,
        ["prop_physics_multiplayer"] = true
    }

    function ENTITY:IsProp()
        return propClasses[self:GetClass()] or false
    end

end

--[[-------------------------------------------------------------------------
    ENTITY:GetSpeed
---------------------------------------------------------------------------]]

do
    local math_abs = math.abs
    function ENTITY:GetSpeed()
        return math_abs( self:GetVelocity():Length() )
    end
end

do

    local file_Exists = file.Exists

    function game.MapHasNav( mapName )
        ArgAssert( mapName, 1, "string" )
        return file_Exists( "maps/" .. mapName .. ".nav" )
    end

end

-- MySQL Debug
-- do

--     local debug = CreateConVar( "mysql_debug", "0", FCVAR_NONE, " - Enables displaying mysql errors.", 0, 1 ):GetBool()
--     cvars.AddChangeCallback("mysql_debug", function( name, old, new )
--         debug = new == "1"
--     end, gpm.Package:GetName() )

--     sql.m_strError = nil
--     setmetatable(sql, { __newindex = function( table, key, value )
--         if debug and (key == "m_strError") and value then
--             print("[SQL Error] " .. value )
--         end
--     end })

-- end

if SERVER then
    -- game.ChangeMap( `string` map )
    -- function game.ChangeMap( str )
    --     local mapName = str:Replace( ".bsp", "" )
    --     if game.HasMap( mapName ) then
    --         logger:info( "Map change: {1} -> {2}", game.GetMap(), mapName )

    --         timer.Simple( 0, function()
    --             RunConsoleCommand( "changelevel", mapName )
    --         end )

    --         return true
    --     end

    --     return false
    -- end

    -- game.Restart()
    function game.Restart()
        game.ConsoleCommand( "_restart\n" )
    end

    -- numpad.IsToggled( ply, num )
    function numpad.IsToggled( ply, num )
        if not pl.keystate then return false end
        return pl.keystate[ num ]
    end
end

if CLIENT then

    ents.Create = ents.CreateClientside

    do
        local render_GetLightColor = render.GetLightColor
        function render.GetLightLevel( origin )
            local vec = render_GetLightColor( origin )
            return ( vec[ 1 ] + vec[ 2 ] + vec[ 3 ] ) / 3
        end
    end

end