local engine = engine
local string = string
local debug = debug
local table = table
local math = math
local game = game
local file = file
local util = util
local hook = hook

local getmetatable = getmetatable
local ArgAssert = ArgAssert
local tonumber = tonumber
local IsValid = IsValid
local ipairs = ipairs
local pairs = pairs
local type = type

-- unrequire ( by danielga )
-- https://github.com/danielga/gmod_require/blob/master/includes/modules/unrequire.lua
do

    local is_windows = system.IsWindows()
    local is_linux = system.IsLinux()
    local is_osx = system.IsOSX()
    local is_x64 = jit.arch == "x64"

    local dll_prefix = CLIENT and "gmcl" or "gmsv"
    local dll_suffix = assert(
        ( is_windows and ( is_x64 and "win64" or "win32" ) ) or
        ( is_linux and ( is_x64 and "linux64" or "linux" ) ) or
        ( is_osx and ( is_x64 and "osx64" or "osx" ) )
    )

    do

        local package_loaded = package.loaded
        local _R = debug.getregistry()
        local _LOADLIB = _R._LOADLIB
        local _MODULES = _MODULES

        local separator = is_windows and "\\" or "/"
        local fmt = string.format(
            "^LOADLIB: .+%sgarrysmod%slua%sbin%s%s_%%s_%s.dll$",
            separator,
            separator,
            separator,
            separator,
            dll_prefix,
            dll_suffix
        )

        function unrequire( name )
            package_loaded[ name ] = nil
            _MODULES[ name ] = nil

            local loadlib = string.format( fmt, name )
            for name, mod in pairs( _R ) do
                if type( name ) ~= "string" then continue end
                if not string.find( name, loadlib ) then continue end
                _LOADLIB.__gc( mod )
                _R[ name ] = nil
            end
        end

    end

end

function AccessorFunc2( tbl, key, name, valueType )
    ArgAssert( tbl, 1, "table" )
    ArgAssert( key, 2, "string" )
    ArgAssert( name, 3, "string" )

    tbl[ "Get" .. name ] = function( self )
        return table.Lookup( self, key )
    end

    if not valueType then
        tbl[ "Set" .. name ] = function( self, value )
            table.SetValue( self, key, value )
            return self
        end

        return
    end

    tbl[ "Set" .. name ] = function( self, value )
        ArgAssert( value, 2, valueType )
        table.SetValue( self, key, value )
        return self
    end
end

function iscfunction( func )
    return debug.getinfo( func ).short_src == "[C]"
end

do

    local commandList, completeList = concommand.GetTable()

    function concommand.Exists( name )
        return commandList[ name ] ~= nil
    end

    function concommand.AutoCompleteExists( name )
        return completeList[ name ] ~= nil
    end

end

-- IMaterial
do

    local IMATERIAL = FindMetaTable( "IMaterial" )

    function ismaterial( any )
        return getmetatable( any ) == IMATERIAL
    end

    function IMATERIAL:GetSize()
        return self:GetInt( "$realwidth" ), self:GetInt( "$realheight" )
    end

end

-- table
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

do

    local setmetatable = setmetatable
    local next = next

    function table.DeepCopy( tbl )
        if type( tbl ) ~= "table" then
            return tbl
        end

        local copy = {}
        for key, value in next, tbl, nil do
            copy[ table.DeepCopy( key ) ] = table.DeepCopy( value )
        end

        setmetatable( copy, table.DeepCopy( getmetatable( tbl ) ) )

        return copy
    end

end

function table.Sub( tbl, offset, len )
    local newTbl = {}
    for i = 1, len do
        newTbl[ i ] = tbl[ i + offset ]
    end

    return newTbl
end

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

function table.ConcatKeys( tbl, concatenator )
    concatenator = concatenator or ""

    local str = ""
    for key in pairs( tbl ) do
        str = ( str ~= "" and concatenator or str ) .. key
    end

    return str
end

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

function table.RemoveByFunction( tbl, func )
    local result, fulfilled = {}, false
    while not fulfilled do
        fulfilled = true

        for index, value in ipairs( tbl ) do
            if not func( index, value ) then continue end
            result[ #result + 1 ] = table.remove( tbl, index )
            fulfilled = false
            break
        end
    end

    return result
end

function table.IValuesToKeys( tbl, value )
    local temp = {}
    for _, key in ipairs( tbl ) do
        temp[ key ] = value
    end

    table.Empty( tbl )
    return table.Merge( tbl, temp )
end

-- util
function util.NiceFloat( number )
    return string.TrimRight( string.TrimRight( string.format( "%f", number ), "0" ), "." )
end

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
                        return "player.GetByUniqueID2( \"" .. any:UniqueID2() .. "\" )"
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

function util.GetSteamVanityURL( str )
    if string.IsSteamID( str ) then
        return "https://steamcommunity.com/profiles/" .. util.SteamIDTo64( sid ) .. "/"
    end

    return "https://steamcommunity.com/profiles/" .. str .. "/"
end

function util.GetViewAngle( pos, ang, pos2 )
    local diff = pos2 - pos
    diff:Normalize()

    return math.abs( math.deg( math.acos( ang:Forward():Dot( diff ) ) ) )
end

function util.IsInFOV( pos, ang, pos2, fov )
    return util.GetViewAngle( pos, ang, pos2 ) <= ( fov or 90 )
end

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

-- file
function file.IsBSP( filePath, gamePath )
    return file.Read( filePath, gamePath, 4 ) == "VBSP"
end

function file.IsGMA( filePath, gamePath )
    return file.Read( filePath, gamePath, 4 ) == "GMAD"
end

function file.IsVTF( filePath, gamePath )
    return file.Read( filePath, gamePath, 3 ) == "VTF"
end

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

-- engine
function engine.GetAddon( wsid )
    for _, addon in ipairs( engine.GetAddons() ) do
        if addon.wsid == wsid then return addon end
    end
end

function engine.GetPlayerGravity()
    return physenv.GetGravity() * FrameTime() / 2
end

function engine.GetAddonFiles( wsid )
    local addon = engine.GetAddon( wsid )
    if not addon then return end
    return file.FindAll( "", addon.title )
end

-- game
do

    local gmad = gmad

    function game.GetGMAFiles( filePath, gamePath )
        local gma = gmad.Open( filePath, gamePath )
        if not gma then return end
        return gma:GetFiles()
    end

end

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

function game.HasMap( mapName, addonTitle )
    return file.IsFile( "maps/" .. mapName .. ".bsp", addonTitle or "GAME" )
end

function game.HasMapNav( mapName, addonTitle )
    return file.IsFile( "maps/" .. mapName .. ".nav", addonTitle or "GAME" )
end

function game.GetMaps( addonTitle )
    local result = {}
    local files, _ = file.Find( "maps/*%.bsp", addonTitle or "GAME" )
    for _, fileName in ipairs( files ) do
        result[ #result + 1 ] = string.sub( fileName, 1, #fileName - 4 )
    end

    return result
end

-- net
do

    local encoder = install( "packages/glua-encoder.lua", "https://raw.githubusercontent.com/Pika-Software/glua-encoder/main/lua/packages/glua-encoder.lua" )
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

    function net.Remove( name )
        net.Receivers[ name ] = nil
    end

end

-- properties
do

    local properties = properties

    function properties.GetAll()
        return properties.List
    end

    function properties.Remove( name )
        properties.List[ string.lower( name ) ] = nil
    end

end

-- ents
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

-- utf8
do

    local utf8 = utf8

    function utf8.HexToChar( hexString )
        return utf8.char( tonumber( hexString, 16 ) )
    end

    function string.uchar( str )
        return string.gsub( str, "\\u(%w%w%w%w)", utf8.HexToChar )
    end

end

-- string
function string.GetCharCount( str, char )
    local counter = 0
    for i = 1, #str do
        if str[ i ] == char then counter = counter + 1 end
    end

    return counter
end

function string.IsSteamID( str )
    if not str then return false end
    return string.match( str, "^STEAM_%d:%d:%d+$" ) ~= nil
end

function string.IsSteamID64( str )
    return #str == 17 and string.sub( str, 1, 4 ) == "7656"
end

function string.Capitalize( str )
    return string.upper( string.sub( str, 1, 1 ) ) .. string.sub( str, 2, #str )
end

-- Entity
local ENTITY = FindMetaTable( "Entity" )

do

    local packageMarker = gpm.Package:GetIdentifier( "entity-timers" )
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

    hook.Add( "GameContentChanged", "Clear Bone Cache", function()
        table.Empty( cache )
    end )

end

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

do

    local WorldToLocal = WorldToLocal

    function ENTITY:GetLocalBonePosition( bone )
        local pos, ang = ENTITY.GetAbsoluteBonePosition( self, bone )
        if pos ~= nil and ang ~= nil then
            return WorldToLocal( pos, ang, ENTITY.GetPos( self ), ENTITY.GetAngles( self ) )
        end
    end

end

function ENTITY:GetAbsoluteBonePositionByName( pattern )
    local bone = ENTITY.FindBone( self, pattern )
    if not bone or bone < 0 then return end
    return ENTITY.GetAbsoluteBonePosition( self, bone )
end

function ENTITY:GetLocalBonePositionByName( pattern )
    local bone = ENTITY.FindBone( self, pattern )
    if not bone or bone < 0 then return end
    return ENTITY.GetLocalBonePosition( self, bone )
end

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

    hook.Add( "GameContentChanged", "Clear Attachment Cache", function()
        table.Empty( cache )
    end )

end

function ENTITY:GetAttachmentByName( pattern )
    local index = ENTITY.FindAttachment( self, pattern )
    if not index or index <= 0 then return end

    local attachmet = ENTITY.GetAttachment( self, index )
    if attachmet then return attachmet end
end

function ENTITY:GetHitBox( bone )
    local hboxset = ENTITY.GetHitboxSet( self )
    if not hboxset then return end

    for hitbox = 0, ENTITY.GetHitBoxCount( self, hboxset ) - 1 do
        if ENTITY.GetHitBoxBone( self, hitbox, hboxset ) ~= bone then continue end
        return hitbox, hboxset
    end
end

function ENTITY:GetHitBoxBoundsByBone( bone )
    local mins, maxs = ENTITY.GetHitBox( self, bone )
    if not mins or not maxs then return end

    return ENTITY.GetHitBoxBounds( self, mins, maxs )
end

function ENTITY:GetViewAngle( pos )
    return util.GetViewAngle( self:EyePos(), self:EyeAngles(), pos )
end

function ENTITY:IsInFOV( pos, fov )
    return util.IsInFOV( self:EyePos(), self:EyeAngles(), pos, fov )
end

do

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

    -- player
    do

        local player = player

        function player.GetStaff()
            return table.Filter( player.GetAll(), PLAYER.IsAdmin )
        end

        function player.Find( str )
            local result = {}
            for _, ply in ipairs( player.GetAll() ) do
                if string.find( ply:Nick(), str ) ~= nil then
                    result[ #result + 1 ] = ply
                end
            end

            return result
        end

        function player.Random( noBots )
            local players = noBots and player.GetHumans() or player.GetAll()
            return players[ math.random( 1, #players ) ]
        end

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

        do

            local cache = {}

            function player.GetByUniqueID2( uid )
                local cached = cache[ uid ]
                if cached and ENTITY.IsValid( cached ) then
                    return cached
                end

                for _, ply in ipairs( player.GetAll() ) do
                    if ply:UniqueID2() ~= uid then continue end
                    cache[ uid ] = ply
                    return ply
                end
            end

            if SERVER then
                hook.Add( "PlayerDisconnected", "Clear player.GetByUniqueID2 Cache", function( ply )
                    cache[ ply:UniqueID2() ] = nil
                end )
            end

        end

    end

    -- Player
    do

        local TEAM_SPECTATOR = TEAM_SPECTATOR

        function PLAYER:IsSpectator()
            return self:Team() == TEAM_SPECTATOR
        end

    end

    do

        local TEAM_CONNECTING = TEAM_CONNECTING

        function PLAYER:IsConnecting()
            return self:Team() == TEAM_CONNECTING
        end

    end

    do

        local team_GetColor = team.GetColor

        function PLAYER:GetTeamColor()
            return team_GetColor( self:Team() )
        end

    end

    function PLAYER:GetHullCurrent()
        if self:Crouching() then
            return self:GetHullDuck()
        end

        return self:GetHull()
    end

    function PLAYER:IsFullyConnected()
        return self:GetNW2Bool( "fully-connected", false )
    end

    do

        local cache = {}

        function PLAYER:UniqueID2()
            if self:IsBot() then
                local nickname = self:Nick()

                local result = cache[ nickname ]
                if result then return result end

                result = util.MD5( nickname )
                cache[ nickname ] = result
                return result
            end

            local steamid64 = self:SteamID64() or self:Nick()

            local result = cache[ steamid64 ]
            if result then return result end

            result = util.MD5( steamid64 )
            cache[ steamid64 ] = result
            return result
        end

        function string.ToUniqueID2( str )
            return cache[ str ] or util.MD5( str )
        end

        if SERVER then
            hook.Add( "PlayerDisconnected", "Clear Player:UniqueID2 Cache", function( ply )
                if ply:IsBot() then
                    cache[ ply:Nick() ] = nil
                    return
                end

                cache[ ply:SteamID64() or ply:Nick() ] = nil
            end )
        end

    end

end

cvars.AddChangeCallback( "gmod_language", function( _, old, new )
    hook.Run( "LanguageChanged", new, old )
end, "LanguageChanged" )

-- http
do

    local http = http

    function http.Encode( str )
        return string.gsub( string.gsub( str, "[^%w _~%.%-]", function( char )
            return string.format( "%%%02X", string.byte( char ) )
        end ), " ", "+" )
    end

    function http.Decode( str )
        return string.gsub( string.gsub( str, "+", " " ), "%%(%x%x)", function( c )
            return string.char( tonumber( c, 16 ) )
        end )
    end

    function http.ParseQuery( str )
        local query = {}
        for key, value in string.gmatch( str, "([^&=?]-)=([^&=?]+)" ) do
            query[ key ] = http.Decode( value )
        end

        return query
    end

    function http.Query( tbl )
        local result = nil
        for key, value in pairs( tbl ) do
            result = ( result and ( result .. "&" ) or "" ) .. key .. "=" .. value
        end

        return "?" .. result
    end

    function http.PrepareUpload( content, filename )
        local boundary = "fboundary" .. math.random( 1, 100 )
        local header_bound = "Content-Disposition: form-data; name=\'file\'; filename=\'" .. filename .. "\'\r\nContent-Type: application/octet-stream\r\n"
        local data = string.format( "--%s\r\n%s\r\n%s\r\n--%s--\r\n", boundary, header_bound, content, boundary )

        return {
            { "Content-Length", #data },
            { "Content-Type", "multipart/form-data; boundary=" .. boundary }
        }, data
    end

end

do

    local bit = bit

    -- CMoveData
    do

        local CMoveData = FindMetaTable( "CMoveData" )

        function CMoveData:RemoveKey( inKey )
            self:SetButtons( bit.band( self:GetButtons(), bit.bnot( inKey ) ) )
        end

    end

    -- CTakeDamageInfo
    do

        local CTakeDamageInfo = FindMetaTable( "CTakeDamageInfo" )

        -- Enums
        local DMG_BULLET = DMG_BULLET
        local DMG_BLAST = DMG_BLAST
        local DMG_CRUSH = DMG_CRUSH
        local DMG_SHOCK = DMG_SHOCK
        local DMG_BURN = DMG_BURN

        function CTakeDamageInfo:IsPhysicsDamage()
            return bit.band( self:GetDamageType(), DMG_CRUSH ) == DMG_CRUSH
        end

        function CTakeDamageInfo:IsFireDamage()
            return bit.band( self:GetDamageType(), DMG_BURN ) == DMG_BURN
        end

        function CTakeDamageInfo:IsBulletDamage()
            return bit.band( self:GetDamageType(), DMG_BULLET ) == DMG_BULLET
        end

        function CTakeDamageInfo:IsExplosionDamage()
            return bit.band( self:GetDamageType(), DMG_BLAST ) == DMG_BLAST
        end

        function CTakeDamageInfo:IsShockDamage()
            return bit.band( self:GetDamageType(), DMG_SHOCK ) == DMG_SHOCK
        end

    end

end