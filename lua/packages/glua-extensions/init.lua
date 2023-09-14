include( "shared.lua" )

local util = util
local game = game
local hook = hook

do

    local ipairs = ipairs
    local unpack = unpack
    local funcs = {}

    util.NextTick( function()
        for _, tbl in ipairs( funcs ) do
            local args = tbl.Args
            if args then
                tbl.Function( unpack( args ) )
                return
            end

            tbl.Function()
        end

        funcs = nil
    end )

    function ServerInitialized( func, ... )
        if not funcs then
            return func( ... )
        end

        local args = { ... }
        local tbl = {
            ["Function"] = func
        }

        if #args ~= 0 then
            tbl.Args = args
        end

        funcs[ #funcs + 1 ] = tbl
    end

end

-- util
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

-- game
function game.GetWorldSize()
    local world = game.GetWorld()
    return world:GetInternalVariable( "m_WorldMins" ), world:GetInternalVariable( "m_WorldMaxs" )
end

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

-- numpad
function numpad.IsToggled( ply, num )
    if not pl.keystate then return false end
    return pl.keystate[ num ]
end

do

    hook.Add( "SetupMove", "PlayerInitialized", function( ply, _, cmd )
        if ply:IsFullyConnected() or not cmd:IsForced() then return end
        ply:SetNW2Bool( "fully-connected", true )
        hook.Run( "PlayerInitialized", ply )
    end )

end

hook.Add( "PlayerCanPickupWeapon", "PlayerPickupedWeapon", function( ply, weapon, locked )
    if locked == true or hook.Run( "PlayerCanPickupWeapon", ply, weapon, true ) == false then return end
    hook.Run( "PlayerPickupedWeapon", ply, weapon )
end )

-- Entity
do

    local ENTITY = FindMetaTable( "Entity" )

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

-- Player
do

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:IsFamilyShared()
        if self:IsBot() then return false end
        return self:SteamID64() ~= self:OwnerSteamID64()
    end

end

-- Literally garrysmod-requests #1845
hook.Add( "EntityFireBullets", "Bullet Callback", function( _, data )
    local func = data.Callback
    function data.Callback( ... )
        hook.Run( "OnFireBulletCallback", ... )
        if not func then return end
        return func( ... )
    end
end, HOOK_MONITOR_HIGH )

hook.Add( "OnFireBulletCallback", "EntityTakeDamage", function( _, traceResult, damageInfo )
    local entity = traceResult.Entity
    if not IsValid( entity ) then return end
    hook.Run( "EntityTakeDamage", entity, damageInfo )
end )