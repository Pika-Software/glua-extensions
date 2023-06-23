include( "shared.lua" )

-- Libraries
local hook = hook
local file = file
local cam = cam
local gui = gui
local net = net

-- Variables
local LocalPlayer = LocalPlayer

-- cam.Start2D()
do

    local data = {
        ["type"] = "2D"
    }

    function cam.Start2D()
        cam.Start( data )
    end

end

net.Receive( _PKG:GetIdentifier( "player-actions" ), function()
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

    local status = gui.IsGameUIVisible()

    hook.Add( "Think", "GameUIToggled", function()
        local current = gui.IsGameUIVisible()
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

-- Player:IsLocalPlayer()
do

    local PLAYER = FindMetaTable( "Player" )
    local index = nil

    hook.Add( "PlayerInitialized", "IsLocalPlayer", function( ply )
        hook.Remove( "PlayerInitialized", "IsLocalPlayer" )
        index = ply:EntIndex()
    end )

    function PLAYER:IsLocalPlayer()
        return self:EntIndex() == index
    end

end

-- string.Translate( str )
do

    local string = string

    function string.Translate( str )
        return string.gsub( str, "%#[%w._-]+", language.GetPhrase )
    end

end

local language = language

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