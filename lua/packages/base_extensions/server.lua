local logger = GPM.Logger( "Base Extensions" )

--[[-------------------------------------------------------------------------
    `boolean` game.ChangeMap( `string` map )
---------------------------------------------------------------------------]]

function game.ChangeMap( str )
    local mapName = str:Replace( ".bsp", "" )
    if game.HasMap( mapName ) then
        logger:info( "Map change: {1} -> {2}", game.GetMap(), mapName )

        timer.Simple(0, function()
            RunConsoleCommand( "changelevel", mapName )
        end)

        return true
    end

    return false
end

--[[-------------------------------------------------------------------------
    game.Restart()
---------------------------------------------------------------------------]]

function game.Restart()
    game.ConsoleCommand("_restart\n")
end

--[[---------------------------------------------------------
	`boolean` numpad.IsToggled( ply, num )
-----------------------------------------------------------]]
do
    local tonumber = tonumber
    function numpad.IsToggled( pl, num )
        if (pl.keystate == nil) then return false end
        return pl.keystate[ tonumber( num ) ] or false
    end
end
