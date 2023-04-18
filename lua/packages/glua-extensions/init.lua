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
local packageName = gpm.Package:GetIdentifier()
local getmetatable = getmetatable
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

-- C# math.Map = Lua math.Remap
math.Map = math.Remap

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

-- util.GetUUID()
function util.GetUUID()
    return string.gsub( "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx", "[xy]", function( c )
        return string.format( "%x", ( c == "x" ) and math.random( 0, 0xf ) or math.random( 8, 0xb ) )
    end )
end

-- file.ReadLine( filePath, len, gamePath )
function file.ReadLine( filePath, len, gamePath )
    local f = file.Open( filePath, "rb", gamePath or "GAME" )
    if not f then return "" end

    local str = f:Read( len )
    f:Close()

    return str
end

-- file.IsBSP( filePath, gamePath )
function file.IsBSP( filePath, gamePath )
    return file.ReadLine( filePath, 4, gamePath ) == "VBSP"
end

-- file.IsGMA( filePath, gamePath )
function file.IsGMA( filePath, gamePath )
    return file.ReadLine( filePath, 4, gamePath ) == "GMAD"
end

-- file.IsVTF( filePath, gamePath )
function file.IsVTF( filePath, gamePath )
    return file.ReadLine( filePath, 3, gamePath ) == "VTF"
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

    local gmad = gpm.gmad

    function game.GetGMAFiles( filePath, gamePath )
        local gma = gmad.Open( filePath, gamePath )
        if not gma then return end
        return gma:GetFiles()
    end

end

-- game.GetWorldSize()
function game.GetWorldSize()
    local world = game.GetWorld()
    return world:GetInternalVariable( "m_WorldMins" ), world:GetInternalVariable( "m_WorldMaxs" )
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

-- player.Random( noBots )
do

    local player = player

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

do

    local util_TableToJSON = util.TableToJSON
    local util_Compress = util.Compress
    local net = net

    -- net.ReadCompressTable()
    function net.ReadCompressTable( lenght )
        local len = net.ReadUInt( lenght or 16 )
        return util_JSONToTable( util_Decompress( net.ReadData( len ) ) )
    end

    -- net.WriteCompressTable( tbl )
    function net.WriteCompressTable( tbl, lenght )
        local data = util_Compress( util_TableToJSON( tbl ) )
        net.WriteUInt( #data, lenght or 16 )
        net.WriteData( data, #data )
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
    return file.Exists( "maps/" .. mapName .. ".bsp", addonTitle or "GAME" )
end

-- game.HasMapNav( mapName, addonTitle )
function game.HasMapNav( mapName, addonTitle )
    return file.Exists( "maps/" .. mapName .. ".nav", addonTitle or "GAME" )
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

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:IsProp()
    do

        local classes = list.GetForEdit( "Prop Classes" )
        classes["prop_physics_multiplayer"] = true
        classes["prop_physics_override"] = true
        classes["prop_dynamic_override"] = true
        classes["prop_dynamic"] = true
        classes["prop_ragdoll"] = true
        classes["prop_physics"] = true
        classes["prop_detail"] = true
        classes["prop_static"] = true

        function ENTITY:IsProp()
            return classes[ self:GetClass() ] or false
        end

    end

    -- Entity:IsDoor()
    do

        local classes = list.GetForEdit( "Door Classes" )
        classes["prop_testchamber_door"] = true
        classes["prop_door_rotating"] = true
        classes["func_door_rotating"] = true
        classes["func_door"] = true

        function ENTITY:IsDoor()
            return classes[ self:GetClass() ] or false
        end

    end

    -- Entity:IsButton()
    if SERVER then

        local classes = list.GetForEdit( "Button Classes" )
        classes["momentary_rot_button"] = true
        classes["func_rot_button"] = true
        classes["func_button"] = true
        classes["gmod_button"] = true

        function ENTITY:IsButton()
            return classes[ self:GetClass() ] or false
        end

    end

end

do

    local PLAYER = FindMetaTable( "Player" )

    -- Player:ConCommand( command )
    if SERVER then
        function PLAYER:ConCommand( command )
            net.Start( "Player:ConCommand" )
                net.WriteString( command )
            net.Send( self )
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

-- Only server features
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

    hook.Add( "PlayerInitialSpawn", packageName, function( ply )
        queue[ ply ] = true
    end )

    hook.Add( "SetupMove", packageName, function( ply, _, cmd )
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

    net.Receive( "Player:ConCommand", function()
        LocalPlayer():ConCommand( net.ReadString() )
    end )

    -- GM:PlayerInitialized( ply )
    hook.Add( "InitPostEntity", packageName, function()
        hook.Run( "PlayerInitialized", LocalPlayer() )
    end )

    -- ents.Create aliase for client
    ents.Create = ents.CreateClientside

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

        hook.Add( "OnScreenSizeChanged", packageName, function(  oldWidth, oldHeight )
            screenWidth, screenHeight = ScrW(), ScrH()
            hook.Run( "ScreenResolutionChanged", width, height, oldWidth, oldHeight )
        end )

    end

    -- GM:GameUIToggled( currentState )
    do

        local gui_IsGameUIVisible = gui.IsGameUIVisible
        local status = gui_IsGameUIVisible()

        hook.Add( "Think", packageName, function()
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

        hook.Add( "Think", packageName, function()
            local current = system_HasFocus()
            if focus == current then return end
            focus = current

            hook.Run( "WindowFocusChanged", current )
        end )

    end

    -- GM:PlayerDisconnected( ply )
    hook.Add( "ShutDown", packageName, function()
        hook.Remove( "ShutDown", packageName )
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
            if file.Exists( filePath0, "GAME" ) then return filePath0 end

            local filePath1 = "resource/localization/" .. countryCode .. ".png"
            if file.Exists( filePath1, "GAME" ) then return filePath1 end

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
end, packageName )

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