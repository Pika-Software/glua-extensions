include( "shared.lua" )

-- Libraries
local util = util
local game = game
local hook = hook

-- util.Explosion( pos, radius, damage )
do

    local EffectData = EffectData
    local DamageInfo = DamageInfo
    local up = Vector( 0, 0, 1 )
    local DMG_BLAST = DMG_BLAST

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

-- game.GetWorldSize()
function game.GetWorldSize()
    local world = game.GetWorld()
    return world:GetInternalVariable( "m_WorldMins" ), world:GetInternalVariable( "m_WorldMaxs" )
end

-- game.ChangeMap( `string` map )
do

    local RunConsoleCommand = RunConsoleCommand
    local logger = gpm.Logger
    local error = error

    function game.ChangeLevel( mapName )
        if not game.HasMap( mapName, addonTitle ) then
            error( "map does not exist" )
            return
        end

        logger:info( "Map change: %s -> %s", game.GetMap(), mapName )
        util.NextTick( RunConsoleCommand, "changelevel", mapName )
    end

end

-- numpad.IsToggled( ply, num )
function numpad.IsToggled( ply, num )
    if not pl.keystate then return false end
    return pl.keystate[ num ]
end

-- GM:PlayerInitialized( ply )
do

    hook.Add( "SetupMove", "PlayerInitialized", function( ply, _, cmd )
        if ply:IsFullyConnected() or not cmd:IsForced() then return end
        ply:SetNW2Bool( "fully-connected", true )
        hook.Run( "PlayerInitialized", ply )
    end )

end

-- GM:PlayerPickupedWeapon( ply, weapon )
hook.Add( "PlayerCanPickupWeapon", "PlayerPickupedWeapon", function( ply, weapon, locked )
    if locked == true or hook.Run( "PlayerCanPickupWeapon", ply, weapon, true ) == false then return end
    hook.Run( "PlayerPickupedWeapon", ply, weapon )
end )

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:Dissolve()
    function ENTITY:Dissolve()
        if not self:IsValid() then return false end

        local dissolver = ENTITY.Dissolver
        if not IsValid( dissolver ) then
            dissolver = ents.Create( "env_entity_dissolver" )
            dissolver:SetKeyValue( "dissolvetype", 0 )
            dissolver:SetKeyValue( "magnitude", 0 )
            dissolver:Spawn()

            ENTITY.Dissolver = dissolver
        end

        if not IsValid( dissolver ) then return false end
        dissolver:SetPos( self:GetPos() )

        local temporaryName = "dissolver" .. dissolver:EntIndex() .. "_" .. self:EntIndex()
        ENTITY.SetName( self, temporaryName )
        dissolver:Fire( "dissolve", temporaryName, 0 )

        return true
    end

end

do

    local PLAYER = FindMetaTable( "Player" )

    -- Player:IsFamilyShared()
    function PLAYER:IsFamilyShared()
        if self:IsBot() then return false end
        return self:SteamID64() ~= self:OwnerSteamID64()
    end

end
