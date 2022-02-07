local type = type

--[[-------------------------------------------------------------------------
	ScreenProcent by DefaultOS#5913
---------------------------------------------------------------------------]]

do

    local ScrW = ScrW
    local ScrH = ScrH

    local screenProcent = (ScrW() < ScrH() and ScrW() or ScrH()) / 100
    hook.Add("OnScreenSizeChanged", "Base Extensions:ScreenProcent", function()
        screenProcent = (ScrW() < ScrH() and ScrW() or ScrH()) / 100
    end)

    function ScreenProcent( procent )
        return ( type( procent ) == "number" ) and screenProcent * procent or screenProcent
    end

end

--[[-------------------------------------------------------------------------
	engine.LightLevel
---------------------------------------------------------------------------]]

do

    local render_GetLightColor = render.GetLightColor

    function engine.LightLevel( origin )
        local col = render_GetLightColor( origin ):ToColor()
        return (col["r"] / 255 + col["g"] / 255 + col["b"] / 255) / 3
    end

end