local tonumber = tonumber
local type = type

local pbit = false
local pbit_package = GPM.Loader.FindPackage("pBit")
if pbit_package and (pbit_package.state == "loaded") then
    pbit = true
end

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
            return _Color( PLib.Vec4FromInt(hex) )
        end
    end

    return _Color( hex, g, b, a )
end