include( "shared.lua" )

local hook = hook
local file = file
local gui = gui

local LocalPlayer = LocalPlayer
local ipairs = ipairs

hook.Add( "RenderScene", "PlayerInitialized", function()
    hook.Remove( "RenderScene", "PlayerInitialized" )
    hook.Run( "PlayerInitialized", LocalPlayer() )
end )

-- ents
ents.Create = ents.CreateClientside

-- spawnmenu
do

    local tabs = spawnmenu.GetCreationTabs()

    function spawnmenu.RemoveCreationTab( name )
        tabs[ name ] = nil
    end

end

-- render
do

    local render_GetLightColor = render.GetLightColor

    function render.GetLightLevel( origin )
        local vec = render_GetLightColor( origin )
        return ( vec[ 1 ] + vec[ 2 ] + vec[ 3 ] ) / 3
    end
end

-- util
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

do

    local status = gui.IsGameUIVisible()

    hook.Add( "Think", "GameUIToggled", function()
        local current = gui.IsGameUIVisible()
        if status == current then return end
        status = current

        hook.Run( "GameUIToggled", current )
    end )

end

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

hook.Add( "ShutDown", "PlayerDisconnected", function()
    hook.Remove( "ShutDown", "PlayerDisconnected" )
    hook.Run( "PlayerDisconnected", LocalPlayer() )
end )

-- Player
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

-- Entity
do

    local ENTITY = FindMetaTable( "Entity" )

    function ENTITY:DrawModelWithChildren( flags, ignoreNoDraw )
        if not ignoreNoDraw and ( self:GetNoDraw() or self:IsEffectActive( EF_NODRAW ) ) then return end
        self:DrawModel( flags )

        for _, child in ipairs( self:GetChildren() ) do
            child:DrawModelWithChildren( flags )
        end
    end

end

-- string
do

    local string = string

    function string.Translate( str )
        return string.gsub( str, "%#[%w._-]+", language.GetPhrase )
    end

end

-- language
local language = language

function language.Exists( languageCode )
    return file.IsDir( "resource/localization/" .. languageCode, "GAME" )
end

do

    local select = select

    function language.GetAll()
        return select( -1, file.Find( "resource/localization/*", "GAME" ) )
    end

end

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

    function language.Get()
        return gmod_language:GetString()
    end

    function language.Set( languageCode )
        RunConsoleCommand( gmod_language:GetName(), languageCode )
    end

    function language.GetPhrases( str )
        local result = {}
        for placeholder, fullText in string.gmatch( str, "([%w_%-]-)=(%C+)" ) do
            result[ placeholder ] = string.uchar( fullText )
        end

        return result
    end

end