
-- Libraries
local engine = engine
local string = string
local table = table
local math = math
local game = game
local file = file
local util = util
local hook = hook

-- Variables
local getmetatable = getmetatable
local gPackage = gpm.Package
local IsValid = IsValid
local ipairs = ipairs
local pairs = pairs
local type = type

-- concommand.Exists( name )
do

    local commandList, completeList = concommand.GetTable()

    function concommand.Exists( name )
        return commandList[ name ] ~= nil
    end

    function concommand.AutoCompleteExists( name )
        return completeList[ name ] ~= nil
    end

end

-- string.Hash( str )
function string.Hash( str )
    local hash = 0
    for _, byte in ipairs( { string.byte( str, 0, #str ) } ) do
        hash = math.fmod( byte + ( ( hash * 32 ) - hash ), 0x07FFFFFF )
    end

    return hash
end

-- table.FastCopy( tbl, issequential, buffer )
function table.FastCopy( tbl, issequential, buffer )
    local copy = {}

    buffer = buffer or {}
    buffer[ tbl ] = copy

    if issequential then
        for index, value in ipairs( tbl ) do
            if type( value ) == "table" then
                if buffer[ value ] then
                    copy[ index ] = buffer[ value ]
                else
                    copy[ index ] = table.FastCopy( value, issequential, buffer )
                end
            else
                copy[ index ] = value
            end
        end
    end

    for key, value in pairs( tbl ) do
        if type( value ) == "table" then
            if buffer[ value ] then
                copy[ key ] = buffer[ value ]
            else
                copy[ key ] = table.FastCopy( value, issequential, buffer )
            end
        else
            copy[ key ] = value
        end
    end

    return copy
end

function table.Empty( tbl )
    for key in pairs( tbl ) do
        tbl[ key ] = nil
    end
end

-- table.DeepCopy( tbl )
do

    local setmetatable = setmetatable
    local next = next

    function table.DeepCopy( tbl )
        if type( tbl ) ~= "table" then return tbl end
        local copy = {}
        for key, value in next, tbl, nil do
            copy[ table.DeepCopy( key ) ] = table.DeepCopy( value )
        end

        setmetatable( copy, table.DeepCopy( getmetatable( tbl ) ) )

        return copy
    end

end

-- table.Sub( tbl, offset, len )
function table.Sub( tbl, offset, len )
    local newTbl = {}
    for i = 1, len do
        newTbl[ i ] = tbl[ i + offset ]
    end

    return newTbl
end

-- table.Filter( tbl, callback )
function table.Filter( tbl, callback )
    local i, e, c = 0, #tbl, 1
    if e == 0 then goto abort end

    ::startfilter::

    i = i + 1
    if callback( tbl[i] ) then tbl[ c ] = tbl[ i ]; c = c + 1 end
    if i < e then goto startfilter end

    i = c - 1
    ::startprune::

    i = i + 1
    tbl[i] = nil
    if i < e then goto startprune end

    ::abort::

    return tbl
end

-- table.FilterCopy( tbl, callback )
function table.FilterCopy( tbl, callback )
    local result = {}

    local i, e, c = 0, #tbl, 1
    if e == 0 then goto abort end

    ::startfilter::

    i = i + 1
    if callback( tbl[ i ] ) then result[ c ] = tbl[ i ]; c = c + 1 end
    if i < e then goto startfilter end

    ::abort::

    return result
end

-- table.ConcatKeys( tbl, concatenator )
function table.ConcatKeys( tbl, concatenator )
    concatenator = concatenator or ''

    local str = ''
    for key in pairs( tbl ) do
        str = ( str ~= '' and concatenator or str ) .. key
    end

    return str
end

-- table.MultiRemove( tbl, index, length )
function table.MultiRemove( tbl, index, length )
    if not length then
        length = index
        index = 1
    end

    local result = {}
    for i = 1, length do
        result[ i ] = table.remove( tbl, index )
    end

    return result
end

-- util.NiceFloat( number )
function util.NiceFloat( number )
    return string.TrimRight( string.TrimRight( string.format( "%f", number ), "0" ), "." )
end

-- util.TypeToString( any, depth )
do

    local tostring = tostring

    function util.TypeToString( any, depth )
        local valueType = type( any )
        if valueType ~= "table" then
            if valueType == "boolean" then
                return any == true and "true" or "false"
            elseif valueType == "number" then
                return tostring( util.NiceFloat( any ) )
            elseif valueType == "Entity" then
                if IsValid( any ) then
                    if any:IsPlayer() then
                        return "player.GetBySteamID( \"" .. any:SteamID() .. "\" )"
                    end

                    return "Entity( " .. any:EntIndex() .. " )"
                end

                return "NULL"
            elseif valueType == "Vector" or valueType == "Angle" then
                return string.format( "%s( %s, %s, %s )", valueType, util.TypeToString( any[ 1 ] ), util.TypeToString( any[ 2 ] ), util.TypeToString( any[ 3 ] ) )
            elseif valueType == "Color" then
                return string.format( "%s( %s, %s, %s, %s )", valueType, util.TypeToString( any.r ), util.TypeToString( any.g ), util.TypeToString( any.b ), util.TypeToString( any.a ) )
            end

            return "\"" .. tostring( any ) .. "\""
        end

        local isSequential, length = true, 0
        for _ in pairs( any ) do
            length = length + 1

            if isSequential and any[ length ] == nil then
                isSequential = false
            end
        end

        depth = ( depth or 0 ) + 1

        local tabs, str = "", "{"
        if not isSequential then
            tabs = string.rep( "\t", depth )
            str = str .. "\n"
        end

        local index = 0
        for key, value in pairs( any ) do
            index = index + 1
            str = str .. tabs

            if isSequential then
                str = str .. " "
            else
                local keyType = type( key )
                if keyType ~= "number" then
                    key = util.TypeToString( key, depth )
                end

                str = str .. "[ " .. key .. " ] = "
            end

            str = str .. util.TypeToString( value, depth )

            if index ~= length then
                str = str .. ","
            elseif isSequential then
                str = str .. " "
            end

            if not isSequential then
                str = str .. "\n"
            end
        end

        if not isSequential then
            str = str .. string.rep( "\t", depth - 1 )
        end

        return str .. "}"
    end

end

-- util.RandomUUID()
-- https://gitlab.com/DBotThePony/DLib/-/blob/develop/lua_src/dlib/util/util.lua#L598
function util.RandomUUID()
    return string.format( "%.8x-%.4x-%.4x-%.4x-%.8x%.4x",
        math.random( 0, 0xFFFFFFFF ), -- 32
        math.random( 0, 0xFFFF ), -- 48
        math.random( 0, 0xFFFF ), -- 64
        math.random( 0, 0xFFFF ), -- 80
        math.random( 0, 0xFFFFFFFF ), -- 112
        math.random( 0, 0xFFFF ) -- 128
    )
end

-- util.GetSteamVanityURL( str )
function util.GetSteamVanityURL( str )
    if string.IsSteamID( str ) then
        return "https://steamcommunity.com/profiles/" .. util.SteamIDTo64( sid ) .. "/"
    end

    return "https://steamcommunity.com/profiles/" .. str .. "/"
end

-- util.GetViewAngle( pos, ang, pos2 )
function util.GetViewAngle( pos, ang, pos2 )
    local diff = pos2 - pos
    diff:Normalize()

    return math.abs( math.deg( math.acos( ang:Forward():Dot( diff ) ) ) )
end

-- util.IsInFOV( pos, ang, pos2, fov )
function util.IsInFOV( pos, ang, pos2, fov )
    return util.GetViewAngle( pos, ang, pos2 ) <= ( fov or 90 )
end

-- util.TracePenetration( traceData, onPenetration, remainingTraces )
function util.TracePenetration( traceData, onPenetration, remainingTraces )
    if not remainingTraces then
        remainingTraces = 100
    end

    local traceResult = util.TraceLine( traceData )
    traceData.start = traceResult.HitPos + traceResult.Normal
    remainingTraces = remainingTraces - 1

    local result = onPenetration( traceResult )
    if type( result ) == "table" then
        table.Merge( traceData, result )
    end

    if result ~= false and remainingTraces > 0 and traceResult.HitPos:Distance( traceData.endpos ) > 1 then
        return util.TracePenetration( traceData, onPenetration, remainingTraces )
    end

    return traceResult
end

do

    local Vector = Vector

    function util.TraceReflection( traceData, onReflect, remainingTraces )
        if not remainingTraces then
            remainingTraces = 10
        end

        local vec = Vector( 2 ^ 16 )
        vec:Rotate( traceData.angle )

        traceData.endpos = traceData.start + vec

        local traceResult = util.TraceLine( traceData )
        if not traceResult.Hit then return traceResult end

        traceData.start = traceResult.HitPos
        traceData.angle = -traceData.angle

        local result = onReflect( traceResult )
        if type( result ) == "table" then
            table.Merge( traceData, result )
        end

        if result ~= false and remainingTraces > 0 then
            return util.TraceReflection( traceData, onReflect, remainingTraces - 1 )
        end

        return traceResult
    end

end

-- file.IsBSP( filePath, gamePath )
function file.IsBSP( filePath, gamePath )
    return file.Read( filePath, gamePath, 4 ) == "VBSP"
end

-- file.IsGMA( filePath, gamePath )
function file.IsGMA( filePath, gamePath )
    return file.Read( filePath, gamePath, 4 ) == "GMAD"
end

-- file.IsVTF( filePath, gamePath )
function file.IsVTF( filePath, gamePath )
    return file.Read( filePath, gamePath, 3 ) == "VTF"
end

-- file.FindAll( filePath, gamePath )
function file.FindAll( filePath, gamePath )
    if #filePath ~= 0 then
        filePath = filePath .. "/"
    end

    local result = {}

    local files, folders = file.Find( filePath .. "*", gamePath )
    for _, fileName in ipairs( files ) do
        result[ #result + 1 ] = filePath .. fileName
    end

    for _, folderName in ipairs( folders ) do
        for _, fileName in ipairs( file.FindAll( filePath .. folderName, gamePath ) ) do
            result[ #result + 1 ] = fileName
        end
    end

    return result
end

-- engine.GetAddon( wsid )
function engine.GetAddon( wsid )
    for _, addon in ipairs( engine.GetAddons() ) do
        if addon.wsid == wsid then return addon end
    end
end

-- game.GetAddonFiles( wsid )
function game.GetAddonFiles( wsid )
    local addon = engine.GetAddon( wsid )
    if not addon then return end
    return file.FindAll( "", addon.title )
end

-- engine.GetGMAFiles( filePath )
do

    local gmad = gmad

    function game.GetGMAFiles( filePath, gamePath )
        local gma = gmad.Open( filePath, gamePath )
        if not gma then return end
        return gma:GetFiles()
    end

end

-- game.AmmoList
function game.GetAmmoList()
    local last = game.GetAmmoName( 1 )
    local result = { last }

    while last ~= nil do
        local index = #result + 1
        result[ index ] = last

        last = game.GetAmmoName( index )
    end

    return result
end

do

    local encoder = install( "packages/glua-encoder", "https://github.com/Pika-Software/glua-encoder" )
    local net = net

    function net.ReadCompressedType( bitsCount )
        return encoder.Decode( net.ReadData( net.ReadUInt( bitsCount or 16 ) ), true )
    end

    function net.WriteCompressedType( any, bitsCount )
        local data = encoder.Encode( any, true )
        local length = string.len( data )
        net.WriteUInt( length, bitsCount or 16 )
        net.WriteData( data, length )
        return length, data
    end

    -- net.Remove( name )
    function net.Remove( name )
        net.Receivers[ name ] = nil
    end

end

do

    local properties = properties

    -- properties.GetAll()
    function properties.GetAll()
        return properties.List
    end

    -- properties.Remove( name )
    function properties.Remove( name )
        properties.List[ string.lower( name ) ] = nil
    end

end

-- IMaterial improvements
do

    local IMATERIAL = FindMetaTable( "IMaterial" )

    function ismaterial( any )
        return getmetatable( any ) == IMATERIAL
    end

    function IMATERIAL:GetSize()
        return self:GetInt( "$realwidth" ), self:GetInt( "$realheight" )
    end

end

-- ents.Closest( tbl, pos )
function ents.Closest( tbl, pos )
    local distance, result = nil, nil

    for _, ent in ipairs( tbl ) do
        local dist = ent:GetPos():DistToSqr( pos )
        if distance == nil or dist < distance then
            distance = dist
            result = ent
        end
    end

    return result
end

-- game.HasMap( mapName, addonTitle )
function game.HasMap( mapName, addonTitle )
    return file.IsFile( "maps/" .. mapName .. ".bsp", addonTitle or "GAME" )
end

-- game.HasMapNav( mapName, addonTitle )
function game.HasMapNav( mapName, addonTitle )
    return file.IsFile( "maps/" .. mapName .. ".nav", addonTitle or "GAME" )
end

-- game.GetMaps( addonTitle )
function game.GetMaps( addonTitle )
    local result = {}
    local files, _ = file.Find( "maps/*%.bsp", addonTitle or "GAME" )
    for _, fileName in ipairs( files ) do
        result[ #result + 1 ] = string.sub( fileName, 1, #fileName - 4 )
    end

    return result
end

-- string.GetCharCount( str, char )
function string.GetCharCount( str, char )
    local counter = 0
    for i = 1, #str do
        if str[ i ] == char then counter = counter + 1 end
    end

    return counter
end

-- string.IsSteamID( str )
function string.IsSteamID( str )
    if not str then return false end
    return string.match( str, "^STEAM_%d:%d:%d+$" ) ~= nil
end

-- string.IsSteamID64( str )
function string.IsSteamID64( str )
    return #str == 17 and string.sub( str, 1, 4 ) == "7656"
end

-- string.Capitalize( str )
function string.Capitalize( str )
    return string.upper( string.sub( str, 1, 1 ) ) .. string.sub( str, 2, #str )
end

do

    local ENTITY = FindMetaTable( "Entity" )

    do

        local classes = list.GetForEdit( "prop-classes" )
        classes["prop_physics_multiplayer"] = true
        classes["prop_physics_override"] = true
        classes["prop_dynamic_override"] = true
        classes["prop_dynamic"] = true
        classes["prop_ragdoll"] = true
        classes["prop_physics"] = true
        classes["prop_detail"] = true
        classes["prop_static"] = true

        -- util.IsPropClass( className )
        function util.IsPropClass( className )
            return classes[ className ] or false
        end

        -- Entity:IsProp()
        function ENTITY:IsProp()
            return util.IsPropClass( ENTITY.GetClass( self ) )
        end

    end

    do

        local classes = list.GetForEdit( "door-classes" )
        classes["prop_testchamber_door"] = true
        classes["prop_door_rotating"] = true
        classes["func_door_rotating"] = true
        classes["func_door"] = true

        -- util.IsDoorClass( className )
        function util.IsDoorClass( className )
            return classes[ className ] or false
        end

        -- Entity:IsDoor()
        function ENTITY:IsDoor()
            return util.IsDoorClass( ENTITY.GetClass( self ) )
        end

    end

    do

        local classes = list.GetForEdit( "button-classes" )
        classes["momentary_rot_button"] = true
        classes["func_rot_button"] = true
        classes["func_button"] = true
        classes["gmod_button"] = true

        -- util.IsButtonClass( className )
        function util.IsButtonClass( className )
            return classes[ className ] or false
        end

        -- Entity:IsButton()
        function ENTITY:IsButton()
            return util.IsButtonClass( ENTITY.GetClass( self ) )
        end

    end

    do

        local classes = list.GetForEdit( "window-classes" )

        classes["func_breakable_surf"] = true
        classes["func_breakable"] = true
        classes["func_physbox"] = true

        -- util.IsWindowClass( className )
        function util.IsWindowClass( className )
            return classes[ className ] or false
        end

        -- Entity:IsWindow()
        function ENTITY:IsWindow()
            return util.IsWindowClass( ENTITY.GetClass( self ) )
        end

    end

    do

        local classes = list.GetForEdit( "info-node-classes" )

        classes["info_node"] = true
        classes["info_hint"] = true
        classes["info_node_hint"] = true
        classes["info_node_air_hint"] = true
        classes["info_node_air"] = true
        classes["info_node_climb"] = true

        -- util.IsInfoNodeClass( className )
        function util.IsInfoNodeClass( className )
            return classes[ className ] or false
        end

        -- Entity:IsInfoNode()
        function ENTITY:IsInfoNode()
            return util.IsInfoNodeClass( ENTITY.GetClass( self ) )
        end

    end

    do

        local classes = list.GetForEdit( "player-spawns" )

        -- Garry's Mod
        classes["info_player_start"] = true

        -- Garry's Mod (old)
        classes["gmod_player_start"] = true

        -- Half-Life 2: Deathmatch
        classes["info_player_deathmatch"] = true
        classes["info_player_combine"] = true
        classes["info_player_rebel"] = true

        -- Counter-Strike: Source & Counter-Strike: Global Offensive
        classes["info_player_counterterrorist"] = true
        classes["info_player_terrorist"] = true

        -- Day of Defeat: Source
        classes["info_player_axis"] = true
        classes["info_player_allies"] = true

        -- Team Fortress 2
        classes["info_player_teamspawn"] = true

        -- Insurgency
        classes["ins_spawnpoint"] = true

        -- AOC
        classes["aoc_spawnpoint"] = true

        -- Dystopia
        classes["dys_spawn_point"] = true

        -- Pirates, Vikings, and Knights II
        classes["info_player_pirate"] = true
        classes["info_player_viking"] = true
        classes["info_player_knight"] = true

        -- D.I.P.R.I.P. Warm Up
        classes["diprip_start_team_blue"] = true
        classes["diprip_start_team_red"] = true

        -- OB
        classes["info_player_red"] = true
        classes["info_player_blue"] = true

        -- Synergy
        classes["info_player_coop"] = true

        -- Zombie Panic! Source
        classes["info_player_human"] = true
        classes["info_player_zombie"] = true

        -- Zombie Master
        classes["info_player_zombiemaster"] = true

        -- Fistful of Frags
        classes["info_player_fof"] = true
        classes["info_player_desperado"] = true
        classes["info_player_vigilante"] = true

        -- Left 4 Dead & Left 4 Dead 2
        classes["info_survivor_rescue"] = true
        -- classes["info_survivor_position"] = true

        -- util.IsSpawnPointClass( className )
        function util.IsSpawnPointClass( className )
            return classes[ className ] or false
        end

        -- Entity:IsSpawnPoint()
        function ENTITY:IsSpawnPoint()
            return util.IsSpawnPointClass( ENTITY.GetClass( self ) )
        end

    end

    if SERVER then

        -- Entity:GetUnbreakable()
        function ENTITY:GetUnbreakable()
            return self.__unbreakable or false
        end

        -- Entity:SetUnbreakable( bool )
        function ENTITY:SetUnbreakable( bool )
            self.__unbreakable = bool == true
        end

        hook.Add( "EntityTakeDamage", "Unbreakable", function( ent )
            if ent.__unbreakable then return true end
        end )

        -- GM:PlayerPickupedWeapon( ply, weapon )
        hook.Add( "PlayerCanPickupWeapon", "PlayerPickupedWeapon", function( ply, weapon, locked )
            if locked == true or hook.Run( "PlayerCanPickupWeapon", ply, weapon, true ) == false then return end
            hook.Run( "PlayerPickupedWeapon", ply, weapon )
        end )

        -- Entity:Dissolve()
        function ENTITY:Dissolve()
            if not self:IsValid() then return false end

            local dissolver = ENTITY.Dissolver
            if not IsValid( dissolver ) then
                dissolver = ents.Create( "env_entity_dissolver" )
                dissolver:SetKeyValue( "dissolvetype", 0 )
                dissolver:SetKeyValue( "magnitude", 0 )
                dissolver:Spawn()

                ENTITY.Dissolver = dissolver
            end

            if not IsValid( dissolver ) then return false end
            dissolver:SetPos( self:GetPos() )

            local temporaryName = "dissolver" .. dissolver:EntIndex() .. "_" .. self:EntIndex()
            ENTITY.SetName( self, temporaryName )
            dissolver:Fire( "dissolve", temporaryName, 0 )

            return true
        end

        -- Entity timers
        do

            local packageMarker = gPackage:GetIdentifier( "entity-timers" )
            local timer = timer

            -- Entity:GetTimerIdentifier( identifier )
            function ENTITY:GetTimerIdentifier( identifier )
                if type( identifier ) ~= "string" then
                    return packageMarker .. " - N/A [" .. self:EntIndex() .. "]"
                end

                return packageMarker .. " - " .. identifier .. " [" .. self:EntIndex() .. "]"
            end

            -- Entity:CreateTimer( identifier, delay, repetitions, func )
            function ENTITY:CreateTimer( identifier, delay, repetitions, func )
                identifier = self:GetTimerIdentifier( identifier )

                timer.Create( identifier, delay, repetitions, function()
                    if IsValid( self ) then
                        func( self )
                        return
                    end

                    timer.Remove( identifier )
                end )
            end

            -- Entity:RemoveTimer( identifier )
            function ENTITY:RemoveTimer( identifier )
                timer.Remove( self:GetTimerIdentifier( identifier ) )
            end

            -- Entity:IsTimerExists( identifier )
            function ENTITY:IsTimerExists( identifier )
                return timer.Exists( self:GetTimerIdentifier( identifier ) )
            end

            -- Entity:SimpleTimer( delay, func )
            function ENTITY:SimpleTimer( delay, func )
                timer.Simple( delay, function()
                    if IsValid( self ) then
                        func( self )
                    end
                end )
            end

        end

    end

    -- Entity:FindBone( pattern )
    do

        local cache = {}

        function ENTITY:FindBone( pattern )
            local model = ENTITY.GetModel( self )
            local modelCache = cache[ model ]
            if not modelCache then
                modelCache = {}; cache[ model ] = modelCache
            end

            local result = modelCache[ pattern ]
            if result ~= nil then
                if result == false then return end
                return result
            end

            local invalid, count = 0, ENTITY.GetBoneCount( self )
            for index = 0, count do
                local boneName = ENTITY.GetBoneName( self, index )
                if not boneName then continue end

                if boneName == "__INVALIDBONE__" then
                    invalid = invalid + 1
                    continue
                end

                if not string.find( boneName, pattern ) then continue end

                modelCache[ pattern ] = index
                return index
            end

            if invalid >= count then return end
            modelCache[ pattern ] = false
        end

    end

    -- Entity:GetAbsoluteBonePosition( bone )
    function ENTITY:GetAbsoluteBonePosition( bone )
        local pos, ang = ENTITY.GetBonePosition( self, bone )
        if pos == ENTITY.GetPos( self ) then
            local matrix = ENTITY.GetBoneMatrix( self, bone )
            if type( matrix ) == "VMatrix" then
                pos, ang = matrix:GetTranslation(), matrix:GetAngles()
            end
        end

        return pos, ang
    end

    -- Entity:GetLocalBonePosition( bone )
    do

        local WorldToLocal = WorldToLocal

        function ENTITY:GetLocalBonePosition( bone )
            local pos, ang = ENTITY.GetAbsoluteBonePosition( self, bone )
            return WorldToLocal( pos, ang, ENTITY.GetPos( self ), ENTITY.GetAngles( self ) )
        end

    end

    -- Entity:GetAbsoluteBonePositionByName( pattern )
    function ENTITY:GetAbsoluteBonePositionByName( pattern )
        local bone = ENTITY.FindBone( self, pattern )
        if not bone or bone < 0 then return end
        return ENTITY.GetAbsoluteBonePosition( self, bone )
    end

    -- Entity:GetLocalBonePositionByName( pattern )
    function ENTITY:GetLocalBonePositionByName( pattern )
        local bone = ENTITY.FindBone( self, pattern )
        if not bone or bone < 0 then return end
        return ENTITY.GetLocalBonePosition( self, bone )
    end

    -- Entity:FindAttachment( pattern )
    do

        local cache = {}

        function ENTITY:FindAttachment( pattern )
            local model = ENTITY.GetModel( self )
            local modelCache = cache[ model ]
            if not modelCache then
                modelCache = {}; cache[ model ] = modelCache
            end

            local result = modelCache[ pattern ]
            if result ~= nil then
                if result == false then return end
                return result
            end

            for _, data in ipairs( ENTITY.GetAttachments( self ) ) do
                if not string.find( data.name, pattern ) then continue end
                modelCache[ pattern ] = data.id
                return data.id
            end

            modelCache[ pattern ] = false
        end

    end

    -- Entity:GetAttachmentByName( pattern )
    function ENTITY:GetAttachmentByName( pattern )
        local index = ENTITY.FindAttachment( self, pattern )
        if not index or index <= 0 then return end

        local attachmet = ENTITY.GetAttachment( self, index )
        if attachmet then return attachmet end
    end

    -- Entity:GetHitBox( bone )
    function ENTITY:GetHitBox( bone )
        for hboxset = 0, ENTITY.GetHitboxSetCount( self ) - 1 do
            for hitbox = 0, ENTITY.GetHitBoxCount( self, hboxset ) - 1 do
                if ENTITY.GetHitBoxBone( self, hitbox, hboxset ) ~= bone then continue end
                return hitbox, hboxset
            end
        end
    end

    -- Entity:GetHitBoxBoundsByBone( bone )
    function ENTITY:GetHitBoxBoundsByBone( bone )
        local mins, maxs = ENTITY.GetHitBox( self, bone )
        if not mins or not maxs then return end

        return ENTITY.GetHitBoxBounds( self, mins, maxs )
    end

    -- Entity:GetHitBoxBoundsByBoneName( pattern )
    function ENTITY:GetHitBoxBoundsByBoneName( pattern )
        local bone = ENTITY.FindBone( self, pattern )
        if not bone or bone < 0 then return end
        return ENTITY.GetHitBoxBoundsByBone( self, bone )
    end

    -- Entity:GetViewAngle( pos )
    function ENTITY:GetViewAngle( pos )
        return util.GetViewAngle( self:EyePos(), self:EyeAngles(), pos )
    end

    -- Entity:IsInFOV( pos, fov )
    function ENTITY:IsInFOV( pos, fov )
        return util.IsInFOV( self:EyePos(), self:EyeAngles(), pos, fov )
    end

    -- Entity:IsScreenVisible( pos, limit, fov )
    local defaultLimit = 512 ^ 2
    function ENTITY:IsScreenVisible( pos, limit, fov )
        if not fov and self:IsPlayer() or self:IsNextBot() then
            fov = self:GetFOV()
        end

        return self:EyePos():DistToSqr( pos ) <= ( limit or defaultLimit ) and self:IsLineOfSightClear( pos ) and self:IsInFOV( pos, fov )
    end

end

do

    local PLAYER = FindMetaTable( "Player" )


    -- Player:IsLocalPlayer()
    if CLIENT then

        local index = nil

        hook.Add( "PlayerInitialized", "IsLocalPlayer", function( ply )
            hook.Remove( "PlayerInitialized", "IsLocalPlayer" )
            index = ply:EntIndex()
        end )

        function PLAYER:IsLocalPlayer()
            return self:EntIndex() == index
        end

    end

    do

        local player = player

        -- player.GetStaff()
        function player.GetStaff()
            return table.Filter( player.GetAll(), PLAYER.IsAdmin )
        end

        -- player.Find( str )
        function player.Find( str )
            local result = {}
            for _, ply in ipairs( player.GetAll() ) do
                if string.find( ply:Nick(), str ) ~= nil then
                    result[ #result + 1 ] = ply
                end
            end

            return result
        end

        -- player.Random( noBots )
        function player.Random( noBots )
            local players = noBots and player.GetHumans() or player.GetAll()
            return players[ math.random( 1, #players ) ]
        end

        -- player.GetListenServerHost()
        if game.SinglePlayer() then

            local Entity = Entity

            function player.GetListenServerHost()
                return Entity( 1 )
            end

        else

            if game.IsDedicated() then
                player.GetListenServerHost = debug.fempty
            else

                function player.GetListenServerHost()
                    for _, ply in ipairs( player.GetHumans() ) do
                        if ply:IsListenServerHost() then return ply end
                    end
                end

            end

        end

    end

    if SERVER then

        local messageName = gPackage:GetIdentifier( "player-actions" )

        util.AddNetworkString( messageName )

        -- Player:ConCommand( command )
        function PLAYER:ConCommand( command )
            net.Start( messageName )
                net.WriteBit( true )
                net.WriteString( command )
            net.Send( self )
        end

        -- Player:OpenURL( url )
        function PLAYER:OpenURL( url )
            net.Start( messageName )
                net.WriteBit( false )
                net.WriteString( url )
            net.Send( self )
        end


        -- Player:IsFamilyShared()
        function PLAYER:IsFamilyShared()
            if self:IsBot() then return false end
            return self:SteamID64() ~= self:OwnerSteamID64()
        end

    end

    -- Player:IsSpectator()
    do

        local TEAM_SPECTATOR = TEAM_SPECTATOR

        function PLAYER:IsSpectator()
            return self:Team() == TEAM_SPECTATOR
        end

    end


    -- Player:IsConnecting()
    do

        local TEAM_CONNECTING = TEAM_CONNECTING

        function PLAYER:IsConnecting()
            return self:Team() == TEAM_CONNECTING
        end

    end

    -- Player:GetTeamColor()
    do

        local team_GetColor = team.GetColor

        function PLAYER:GetTeamColor()
            return team_GetColor( self:Team() )
        end

    end

    -- Player:GetHullCurrent()
    function PLAYER:GetHullCurrent()
        if self:Crouching() then
            return self:GetHullDuck()
        end

        return self:GetHull()
    end

    -- Player:IsFullyConnected()
    function PLAYER:IsFullyConnected()
        return self:GetNW2Bool( "m_pInitialized", false )
    end

end

if SERVER then

    -- util.Explosion( pos, radius, damage )
    do

        local EffectData = EffectData
        local DamageInfo = DamageInfo
        local up = Vector( 0, 0, 1 )

        function util.Explosion( pos, radius, damage )
            local dmg = DamageInfo()

            dmg:SetDamage( type( damage ) == "number" and damage or 250 )
            dmg:SetDamageType( DMG_BLAST )

            local fx = EffectData()
            fx:SetRadius( radius )
            fx:SetOrigin( pos )
            fx:SetNormal( up )

            util.NextTick( function()
                util.Effect( "Explosion", fx )
                util.Effect( "HelicopterMegaBomb", fx )
                util.BlastDamageInfo( dmg, pos, radius )
            end )

            return dmg, fx
        end

    end

    -- game.GetWorldSize()
    function game.GetWorldSize()
        local world = game.GetWorld()
        return world:GetInternalVariable( "m_WorldMins" ), world:GetInternalVariable( "m_WorldMaxs" )
    end

    -- game.ChangeMap( `string` map )
    function game.ChangeLevel( mapName )
        if not game.HasMap( mapName, addonTitle ) then
            error( "map does not exist" )
            return
        end

        gpm.Logger:info( "Map change: %s -> %s", game.GetMap(), mapName )
        util.NextTick( RunConsoleCommand, "changelevel", mapName )
    end

    -- numpad.IsToggled( ply, num )
    function numpad.IsToggled( ply, num )
        if not pl.keystate then return false end
        return pl.keystate[ num ]
    end

    -- GM:PlayerInitialized( ply )
    local queue = {}

    hook.Add( "PlayerInitialSpawn", "PlayerInitialized", function( ply )
        queue[ ply ] = true
    end )

    hook.Add( "SetupMove", "PlayerInitialized", function( ply, _, cmd )
        if queue[ ply ] and not cmd:IsForced() then
            ply:SetNW2Bool( "m_pInitialized", true )
            queue[ ply ] = nil

            hook.Run( "PlayerInitialized", ply )
        end
    end )

end

do

    local CMoveData = FindMetaTable( "CMoveData" )

    -- CMoveData:RemoveKey( inKey )
    function CMoveData:RemoveKey( inKey )
        self:SetButtons( bit.band( self:GetButtons(), bit.bnot( inKey ) ) )
    end

end

if CLIENT then

    -- cam.Start2D()
    do

        local data = {
            ["type"] = "2D"
        }

        function cam.Start2D()
            cam.Start( data )
        end

    end

    net.Receive( gPackage:GetIdentifier( "player-actions" ), function()
        local isCommand = net.ReadBool()
        local str = net.ReadString()
        if #str < 1 then return end

        if isCommand then
            LocalPlayer():ConCommand( str )
            return
        end

        gui.OpenURL( str )
    end )

    -- GM:PlayerInitialized( ply )
    hook.Add( "RenderScene", "PlayerInitialized", function()
        hook.Remove( "RenderScene", "PlayerInitialized" )
        hook.Run( "PlayerInitialized", LocalPlayer() )
    end )

    -- ents.Create aliase for client
    ents.Create = ents.CreateClientside

    -- spawnmenu.RemoveCreationTab( name )
    do

        local tabs = spawnmenu.GetCreationTabs()

        function spawnmenu.RemoveCreationTab( name )
            tabs[ name ] = nil
        end

    end

    -- vgui.Exists( className )
    do

        local vgui = vgui

        function vgui.Exists( className )
            return vgui.GetControlTable( className ) ~= nil
        end

    end

    -- render.GetLightLevel( origin )
    do

        local render_GetLightColor = render.GetLightColor

        function render.GetLightLevel( origin )
            local vec = render_GetLightColor( origin )
            return ( vec[ 1 ] + vec[ 2 ] + vec[ 3 ] ) / 3
        end
    end

    -- GM:ScreenResolutionChanged( width, height, oldWidth, oldHeight )
    do

        local ScrW, ScrH = ScrW, ScrH
        local width, height = ScrW(), ScrH()

        function util.ScreenResolution()
            return width, height
        end

        hook.Add( "OnScreenSizeChanged", "ScreenResolutionChanged", function(  oldWidth, oldHeight )
            screenWidth, screenHeight = ScrW(), ScrH()
            hook.Run( "ScreenResolutionChanged", width, height, oldWidth, oldHeight )
        end )

    end

    -- GM:GameUIToggled( currentState )
    do

        local gui_IsGameUIVisible = gui.IsGameUIVisible
        local status = gui_IsGameUIVisible()

        hook.Add( "Think", "GameUIToggled", function()
            local current = gui_IsGameUIVisible()
            if status == current then return end
            status = current

            hook.Run( "GameUIToggled", current )
        end )

    end

    -- GM:WindowFocusChanged( hasFocus )
    do

        local system_HasFocus = system.HasFocus
        local focus = system_HasFocus()

        hook.Add( "Think", "WindowFocusChanged", function()
            local current = system_HasFocus()
            if focus == current then return end
            focus = current

            hook.Run( "WindowFocusChanged", current )
        end )

    end

    -- GM:PlayerDisconnected( ply )
    hook.Add( "ShutDown", "PlayerDisconnected", function()
        hook.Remove( "ShutDown", "PlayerDisconnected" )
        hook.Run( "PlayerDisconnected", LocalPlayer() )
    end )

    local language = language

    -- string.Translate( str )
    function string.Translate( str )
        return string.gsub( str, "%#[%w._-]+", language.GetPhrase )
    end

    -- language.Exists( languageCode )
    function language.Exists( languageCode )
        return file.IsDir( "resource/localization/" .. languageCode, "GAME" )
    end

    -- language.GetAll()
    do

        local select = select

        function language.GetAll()
            return select( -1, file.Find( "resource/localization/*", "GAME" ) )
        end

    end

    -- language.GetFlag( languageCode )
    do

        local langToCountry = {
            ["zh-CN"] = "cn",
            ["zh-TW"] = "tw",
            ["es-ES"] = "es",
            ["pt-BR"] = "br",
            ["pt-PT"] = "pt",
            ["sv-SE"] = "se",
            ["da"] = "dk",
            ["el"] = "gr",
            ["en"] = "gb",
            ["he"] = "il",
            ["ja"] = "jp",
            ["ko"] = "kr",
            ["uk"] = "ua"
        }

        function language.GetFlag( languageCode )
            local countryCode = langToCountry[ languageCode ] or languageCode

            local filePath0 = "materials/flags16/" .. countryCode .. ".png"
            if file.IsFile( filePath0, "GAME" ) then return filePath0 end

            local filePath1 = "resource/localization/" .. countryCode .. ".png"
            if file.IsFile( filePath1, "GAME" ) then return filePath1 end

            return "html/img/unk_flag.png"
        end

    end

    do

        local gmod_language = GetConVar( "gmod_language" )

        -- language.Get()
        function language.Get()
            return gmod_language:GetString()
        end

        -- language.Set( languageCode )
        function language.Set( languageCode )
            RunConsoleCommand( gmod_language:GetName(), languageCode )
        end

    end

end

-- GM:LanguageChanged( languageCode, oldLanguageCode )
cvars.AddChangeCallback( "gmod_language", function( _, old, new )
    hook.Run( "LanguageChanged", new, old )
end, "LanguageChanged" )

local http = http

-- http.Encode( str )
function http.Encode( str )
    return string.gsub( string.gsub( str, "[^%w _~%.%-]", function( char )
        return string.format( "%%%02X", string.byte( char ) )
    end ), " ", "+" )
end

-- http.Decode( str )
do

    local tonumber = tonumber

    function http.Decode( str )
        return string.gsub( string.gsub( str, "+", " " ), "%%(%x%x)", function( c )
            return string.char( tonumber( c, 16 ) )
        end )
    end

end

-- http.ParseQuery( str )
function http.ParseQuery( str )
    local query = {}
    for key, value in string.gmatch( str, "([^&=?]-)=([^&=?]+)" ) do
        query[ key ] = http.Decode( value )
    end

    return query
end

-- http.Query( tbl )
function http.Query( tbl )
    local result = nil
    for key, value in pairs( tbl ) do
        result = ( result and ( result .. "&" ) or "" ) .. key .. "=" .. value
    end

    return "?" .. result
end

-- http.PrepareUpload( content, filename )
function http.PrepareUpload( content, filename )
    local boundary = "fboundary" .. math.random( 1, 100 )
    local header_bound = "Content-Disposition: form-data; name=\'file\'; filename=\'" .. filename .. "\'\r\nContent-Type: application/octet-stream\r\n"
    local data = string.format( "--%s\r\n%s\r\n%s\r\n--%s--\r\n", boundary, header_bound, content, boundary )

    return {
        { "Content-Length", #data },
        { "Content-Type", "multipart/form-data; boundary=" .. boundary }
    }, data
end
