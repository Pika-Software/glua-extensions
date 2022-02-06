local math_floor = math.floor
local tonumber = tonumber
local ipairs = ipairs
local assert = assert
local type = type

--[[-------------------------------------------------------------------------
	Net tables compress method by DefaultOS#5913
---------------------------------------------------------------------------]]

do

    local util_TableToJSON = util.TableToJSON
    local util_Compress = util.Compress
    local net_WriteUInt = net.WriteUInt
    local net_WriteData = net.WriteData

    function net.WriteCompressTable( tbl )
        if (type( tbl ) == "table") then
            local data = util_Compress( util_TableToJSON( tbl ) )
            net_WriteUInt( #data, 16 )
            net_WriteData( data, #data )
        end
    end

end

do

    local util_JSONToTable = util.JSONToTable
    local util_Decompress = util.Decompress
    local net_ReadData = net.ReadData
    local net_ReadUInt = net.ReadUInt

    function net.ReadCompressTable()
        local len = net_ReadUInt(16)
        return util_JSONToTable(util_Decompress(net_ReadData(len)))
    end

end

--[[-------------------------------------------------------------------------
	ents.Create on Client
---------------------------------------------------------------------------]]

if CLIENT then
    ents.Create = ents.CreateClientside
end

--[[-------------------------------------------------------------------------
	ents.closest
---------------------------------------------------------------------------]]

do

    local math_huge = math.huge
    function ents.closest( tbl, pos )
        local distance, entity = math_huge

        for num, ent in ipairs( tbl ) do
            local dist = ent:GetPos():DistToSqr( pos )
            if (dist < distance) then
                distance = dist
                entity = ent
            end
        end

        return entity
    end

end

--[[-------------------------------------------------------------------------
    player.GetListenServerHost
---------------------------------------------------------------------------]]

do

    local player_GetHumans = player.GetHumans
    function player.GetListenServerHost()
        for num, ply in ipairs( player_GetHumans() ) do
            if ply:IsListenServerHost() then
                return ply
            end
        end
    end

end

--[[-------------------------------------------------------------------------
    player.FindInSphere
---------------------------------------------------------------------------]]

do

    local ents_FindInSphere = ents.FindInSphere
    local table_insert = table.insert

    function player.FindInSphere( origin, radius )
        local players = {}
        for num, ent in ipairs( ents_FindInSphere( origin, radius ) ) do
            if ent:IsPlayer() then
                table_insert( players, ent )
            end
        end

        return players
    end

end

--[[-------------------------------------------------------------------------
    engine.GetAddon
---------------------------------------------------------------------------]]

do

    local engine_GetAddons = engine.GetAddons
    function engine.GetAddon(id)
        for num, addon in ipairs( engine_GetAddons() ) do
            if (addon["wsid"] == id) then
                return addon
            end
        end
    end

end

--[[-------------------------------------------------------------------------
    string.Hash - string to hash
---------------------------------------------------------------------------]]

do

    local math_fmod = math.fmod
    function string.Hash( str )
        local hash = 0
        for _, v in ipairs({ str:byte( 0, str:len() ) }) do
            hash = math_fmod( v + ((hash * 32) - hash), 0x07FFFFFF )
        end

        return hash
    end

end

--[[-------------------------------------------------------------------------
    string.FormatSeconds - seconds to formated time string
---------------------------------------------------------------------------]]

do

    local full = "%s:%s:%s"
    local hoursMinutes = "%s:%s"

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
    string.FindFromTable
---------------------------------------------------------------------------]]

function string.FindFromTable( str, tbl )
	for num, char in ipairs( tbl ) do
		if str:find( char ) then
			return true
		end
	end

	return false
end

--[[-------------------------------------------------------------------------
    string.charCount - returns char counts from string
---------------------------------------------------------------------------]]

function string.charCount( str, char )
	assert( type( str ) == "string", "bad argument #1 (string expected)" )
	assert( type( char ) == "string", "bad argument #2 (string expected)" )

    local count = 0
	for num, chr in ipairs( str:ToTable() ) do
		if (chr == char) then
			count = count + 1
		end
	end

	return count
end

--[[-------------------------------------------------------------------------
	C# math.Map = Lua math.Remap
---------------------------------------------------------------------------]]

math.Map = math.Remap

--[[-------------------------------------------------------------------------
    Color Extension
---------------------------------------------------------------------------]]

local _Lerp = environment.saveFunc( "Lerp", Lerp )
function LerpColor( frac, a, b )
    a["r"] = _Lerp( frac, b["r"], a["r"] )
	a["g"] = _Lerp( frac, b["g"], a["g"] )
	a["b"] = _Lerp( frac, b["b"], a["b"] )
	a["a"] = _Lerp( frac, b["a"] or 255, a["a"] or 255 )

    return a
end

do

    local _Color = environment.saveFunc( "Color", Color )
    function Color( hex, g, b, a )
        if (type( hex ) == "string") then
            hex = hex:gsub("#", "")
            if (hex:len() == 3) then
                return _Color( tonumber("0x" .. hex:sub(1, 1)) * 17, tonumber("0x" .. hex:sub(2, 2)) * 17, tonumber("0x" .. hex:sub(3, 3)) * 17 )
            else
                return _Color( tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)) )
            end
        end

        if (g == nil) and (b == nil) and (a == nil) and (type( hex ) == "number") and (type( pbit ) == "table") and (type(pbit.Vec4FromInt) == "function") then
            return _Color( pbit.Vec4FromInt( hex ) )
        end

        return _Color( hex, g, b, a )
    end

    local COLOR = FindMetaTable("Color")
    function COLOR:SetAlpha(alpha)
        self["a"] = alpha
        return self
    end

    function COLOR:Lerp( frac, b )
        return LerpColor( frac, self, b )
    end

end

do

    local VMATRIX = FindMetaTable( "VMatrix" )
    local vector_origin = vector_origin
    local angle_zero = angle_zero

    local __scale = Vector( 1, 1 )
    function VMATRIX:Reset( scale )
        self:Zero()
        self:SetScale( scale or __scale )
        self:SetAngles( angle_zero )
        self:SetTranslation( vector_origin )
        self:SetField(1, 1, 1)
        self:SetField(2, 2, 1)
        self:SetField(3, 3, 1)
        self:SetField(4, 4, 1)
    end

end

--[[-------------------------------------------------------------------------
	Angle improvements
---------------------------------------------------------------------------]]

local LerpAngle = LerpAngle

do

    local ANGLE = FindMetaTable("Angle")
    function ANGLE:Lerp( frac, b )
        return LerpAngle( frac, self, b )
    end

end

--[[-------------------------------------------------------------------------
	Vector improvements
---------------------------------------------------------------------------]]

local LerpVector = LerpVector

do

    local VECTOR = FindMetaTable("Vector")
    function VECTOR:Middle( vec )
        if isvector( vec ) then
            return ( self + vec ) / 2
        else
            return ( self[1] + self[2] + self[3] ) / 3
        end
    end

    function VECTOR:Lerp( frac, b )
        return LerpVector( frac, self, b )
    end

end

--[[-------------------------------------------------------------------------
    Improvement Lerp
---------------------------------------------------------------------------]]

function Lerp( frac, a, b )
    if IsColor( a ) then
        return LerpColor( frac, a, b )
    elseif isvector( a ) then
        return LerpVector( frac, a, b )
    elseif isangle( a ) then
        return LerpAngle( frac, a, b )
    else
        return _Lerp( frac, a, b )
    end
end

--[[-------------------------------------------------------------------------
    PlayerInitialized Hook
---------------------------------------------------------------------------]]

if CLIENT then
    hook.Add( "RenderScene", "Base Extensions:PlayerInitialized", function()
        hook.Remove( "RenderScene", "Base Extensions:PlayerInitialized" )
        local ply = LocalPlayer()
        ply["Initialized"] = true
        hook.Run("PlayerInitialized", ply)
    end)
else
    hook.Add("PlayerInitialSpawn", "Base Extensions:PlayerInitialized", function(ply)
        hook.Add("SetupMove", ply, function( self, ply, _, cmd )
            if (self == ply) and not cmd:IsForced() then
                hook.Remove("SetupMove", self)
                self["Initialized"] = true
                hook.Run("PlayerInitialized", self)
            end
        end)
    end)
end