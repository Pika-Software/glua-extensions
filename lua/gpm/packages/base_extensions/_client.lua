local type = type

--[[-------------------------------------------------------------------------
	ents.Create for Client
---------------------------------------------------------------------------]]

ents.Create = ents.CreateClientside

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
        return (type( procent ) == "number") and screenProcent * procent or screenProcent
    end

end

--[[-------------------------------------------------------------------------
    engine.LightLevel( `vector` origin )
---------------------------------------------------------------------------]]

do
    local render_GetLightColor = render.GetLightColor
    function engine.LightLevel( origin )
        local col = render_GetLightColor( origin ):ToColor()
        return (col["r"] / 255 + col["g"] / 255 + col["b"] / 255) / 3
    end
end

--[[-------------------------------------------------------------------------
    render.ResetStencil()
---------------------------------------------------------------------------]]

do

    local render_SetStencilCompareFunction = render.SetStencilCompareFunction
    local render_SetStencilZFailOperation = render.SetStencilZFailOperation
    local render_SetStencilReferenceValue = render.SetStencilReferenceValue
    local render_SetStencilPassOperation = render.SetStencilPassOperation
    local render_SetStencilFailOperation = render.SetStencilFailOperation
    local render_SetStencilWriteMask = render.SetStencilWriteMask
    local render_SetStencilTestMask = render.SetStencilTestMask
    local render_ClearStencil = render.ClearStencil

    local STENCIL_ALWAYS = STENCIL_ALWAYS
    local STENCIL_KEEP = STENCIL_KEEP

    function render.ResetStencil()
        render_SetStencilWriteMask( 0xFF )
        render_SetStencilTestMask( 0xFF )
        render_SetStencilReferenceValue( 0 )
        render_SetStencilCompareFunction( STENCIL_ALWAYS )
        render_SetStencilPassOperation( STENCIL_KEEP )
        render_SetStencilFailOperation( STENCIL_KEEP )
        render_SetStencilZFailOperation( STENCIL_KEEP )
        render_ClearStencil()
    end

end

--[[-------------------------------------------------------------------------
    Simple Render Gradient
---------------------------------------------------------------------------]]

do

    local surface_SetMaterial = surface.SetMaterial
    local surface_DrawRect = surface.DrawRect
    local Material = Material

    do
        local mat_grad = Material( "gui/gradient" )
        function draw.GradientSimple( x, y, w, h )
            surface_SetMaterial( mat_grad )
            surface_DrawRect( x, y, w, h )
        end
    end

    do
        local mat_grad_down = Material( "gui/gradient_down" )
        function draw.GradientDown( x, y, w, h )
            surface_SetMaterial( mat_grad_down )
            surface_DrawRect( x, y, w, h )
        end
    end

    do
        local mat_grad_up = Material( "gui/gradient_up" )
        function draw.GradientUp( x, y, w, h )
            surface_SetMaterial( mat_grad_up )
            surface_DrawRect( x, y, w, h )
        end
    end

    do
        local mat_grad_center = Material( "gui/center_gradient" )
        function draw.GradientCenter( x, y, w, h )
            surface_SetMaterial( mat_grad_center )
            surface_DrawRect( x, y, w, h )
        end
    end

end

--[[-------------------------------------------------------------------------
    PrePlayerChat
---------------------------------------------------------------------------]]

local hook_Run = hook.Run
hook.Add("OnPlayerChat", "GPM:PrePlayerChat", function( ... )
	local ret = hook_Run( "PrePlayerChat", ... )
	if (ret != nil) then return ret end
end)