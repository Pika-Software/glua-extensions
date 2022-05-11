--[[-------------------------------------------------------------------------
    `boolean` game.ChangeMap( `string` map )
---------------------------------------------------------------------------]]

function game.ChangeMap( str )
    local mapName = str:Replace( ".bsp", "" )
    if game.HasMap( mapName ) then
        if console and isfunction( console.log ) then
            console.log( game.GetMap(), " -> ", mapName ):setTag( "Map Сhange" )
        end

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

--[[-------------------------------------------------------------------------
    GM:OnPlayerDropWeapon( ply, wep, target, velocity )
---------------------------------------------------------------------------]]
do

    local PLAYER = FindMetaTable( "Player" )
    local drop_weapon = environment.saveFunc( "PLAYER.DropWeapon", PLAYER.DropWeapon )

    function PLAYER:DropWeapon( ... )
        hook.Run( "OnPlayerDropWeapon", self, ... )
        return drop_weapon( self, ... )
    end

end
