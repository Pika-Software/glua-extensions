local math_floor = math.floor
local tonumber = tonumber
local ipairs = ipairs
local assert = assert
local type = type

--[[-------------------------------------------------------------------------
    pBit Lib
---------------------------------------------------------------------------]]

local pbit = false
local pbit_package = GPM.Loader.FindPackage("pBit")
if pbit_package and (pbit_package.state == "loaded") then
    pbit = true
end

--[[-------------------------------------------------------------------------
	HEX & Int Colors Support
---------------------------------------------------------------------------]]

do

    local _Color = environment.saveFunc( "Color", Color )
    function Color(hex, g, b, a)
        if (g == nil) and (b == nil) and (a == nil) then
            local type = type( hex )
            if (type == "string") then
                hex = hex:gsub("#", "")
                if (hex:len() == 3) then
                    return _Color( tonumber("0x" .. hex:sub(1, 1)) * 17, tonumber("0x" .. hex:sub(2, 2)) * 17, tonumber("0x" .. hex:sub(3, 3)) * 17 )
                else
                    return _Color( tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)) )
                end
            elseif (type == "number") and pbit then
                return _Color( pbit.Vec4FromInt( hex ) )
            end
        end

        return _Color( hex, g, b, a )
    end

end

--[[-------------------------------------------------------------------------
	Net tables compress method by DefaultOS#5913
---------------------------------------------------------------------------]]

do

    local util_Compress = util.Compress
    local util_TableToJSON = util.TableToJSON
    local net_WriteUInt = net.WriteUInt
    local net_WriteData = net.WriteData
    local net_ReadUInt = net.ReadUInt
    local util_JSONToTable = util.JSONToTable
    local util_Decompress = util.Decompress
    local net_ReadData = net.ReadData

    function net.WriteCompressTable(tbl)
        if (tbl == nil) then return end
        local data = util_Compress(util_TableToJSON(tbl))
        net_WriteUInt(#data, 16)
        net_WriteData(data, #data)
    end

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
	Angle improvements
---------------------------------------------------------------------------]]

local LerpAngle = LerpAngle

do

    local ANGLE = FindMetaTable("Angle")
    function ANGLE:Lerp(frac, b)
        return LerpAngle(frac, self, b)
    end

    function ANGLE:Floor()
        self[1] = math_floor(self[1])
        self[2] = math_floor(self[2])
        self[3] = math_floor(self[3])
        return self
    end

    function ANGLE:abs()
        self[1] = math_abs(self[1])
        self[2] = math_abs(self[2])
        self[3] = math_abs(self[3])
        return self
    end

    function ANGLE:NormalizeZero()
        self[1] = (self[1] == 0) and 0 or self[1]
        self[2] = (self[2] == 0) and 0 or self[2]
        self[3] = (self[3] == 0) and 0 or self[3]
        return self
    end

end

--[[-------------------------------------------------------------------------
	Vector improvements
---------------------------------------------------------------------------]]

local LerpVector = LerpVector

do

    local VECTOR = FindMetaTable("Vector")
    function VECTOR:Diameter(maxs)
        return math_max( maxs[1] + math_abs(self[1]), maxs[2] + math_abs(self[2]), maxs[3] + math_abs(self[3]) )
    end

    function VECTOR:InBox(vec1, vec2)
        return self[1] >= vec1[1] and self[1] <= vec2[1] and self[2] >= vec1[2] and self[2] <= vec2[2] and self[3] >= vec1[3] and self[3] <= vec2[3]
    end

    function VECTOR:Round(dec)
        return Vector( math_Round(self[1], dec or 0), math_Round(self[2], dec or 0), math_Round(self[3], dec or 0) )
    end

    function VECTOR:Floor()
        self[1] = math_floor(self[1])
        self[2] = math_floor(self[2])
        self[3] = math_floor(self[3])
        return self
    end

    function VECTOR:Abs()
        self[1] = math_abs(self[1])
        self[2] = math_abs(self[2])
        self[3] = math_abs(self[3])
        return self
    end

    function VECTOR:Middle( vec )
        if isvector( vec ) then
            return ( self + vec ) / 2
        else
            return (self[1] + self[2] + self[3]) / 3
        end
    end

    function VECTOR:Lerp(frac, b)
        return LerpVector(frac, self, b)
    end

end