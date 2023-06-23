AddCSLuaFile( "shared.lua" )
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

    local queue = {}

    hook.Add( "PlayerInitialSpawn", "PlayerInitialized", function( ply )
        queue[ ply ] = true
    end )

    hook.Add( "SetupMove", "PlayerInitialized", function( ply, _, cmd )
        if queue[ ply ] and not cmd:IsForced() then
            ply:SetNW2Bool( "m_pInitialized", true )
            queue[ ply ] = nil

            hook.Run( "PlayerInitialized", ply )
        end
    end )

end

-- GM:PlayerPickupedWeapon( ply, weapon )
hook.Add( "PlayerCanPickupWeapon", "PlayerPickupedWeapon", function( ply, weapon, locked )
    if locked == true or hook.Run( "PlayerCanPickupWeapon", ply, weapon, true ) == false then return end
    hook.Run( "PlayerPickupedWeapon", ply, weapon )
end )

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:GetUnbreakable()
    function ENTITY:GetUnbreakable()
        return self:GetNW2Bool( "Unbreakable", false )
    end

    -- Entity:SetUnbreakable( bool )
    function ENTITY:SetUnbreakable( bool )
        self:SetNW2Bool( "Unbreakable", bool )
    end

    hook.Add( "EntityTakeDamage", "Unbreakable", function( entity )
        if entity:GetUnbreakable() then
            return true
        end
    end )

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

    do

        local packageMarker = _PKG:GetIdentifier( "entity-timers" )
        local timer = timer

        -- Entity:GetTimerIdentifier( identifier )
        function ENTITY:GetTimerIdentifier( identifier )
            if type( identifier ) ~= "string" then
                return packageMarker .. " - N/A [" .. self:EntIndex() .. "]"
            end

            return packageMarker .. " - " .. identifier .. " [" .. self:EntIndex() .. "]"
        end

        -- Entity:CreateTimer( identifier, delay, repetitions, func )
        function ENTITY:CreateTimer( identifier, delay, repetitions, func )
            identifier = self:GetTimerIdentifier( identifier )

            timer.Create( identifier, delay, repetitions, function()
                if IsValid( self ) then
                    func( self )
                    return
                end

                timer.Remove( identifier )
            end )
        end

        -- Entity:RemoveTimer( identifier )
        function ENTITY:RemoveTimer( identifier )
            timer.Remove( self:GetTimerIdentifier( identifier ) )
        end

        -- Entity:IsTimerExists( identifier )
        function ENTITY:IsTimerExists( identifier )
            return timer.Exists( self:GetTimerIdentifier( identifier ) )
        end

        -- Entity:SimpleTimer( delay, func )
        function ENTITY:SimpleTimer( delay, func )
            timer.Simple( delay, function()
                if IsValid( self ) then
                    func( self )
                end
            end )
        end

    end

end

do

    local messageName = _PKG:GetIdentifier( "player-actions" )
    local PLAYER = FindMetaTable( "Player" )

    util.AddNetworkString( messageName )

    -- Player:ConCommand( command )
    function PLAYER:ConCommand( command )
        net.Start( messageName )
            net.WriteBit( true )
            net.WriteString( command )
        net.Send( self )
    end

    -- Player:OpenURL( url )
    function PLAYER:OpenURL( url )
        net.Start( messageName )
            net.WriteBit( false )
            net.WriteString( url )
        net.Send( self )
    end


    -- Player:IsFamilyShared()
    function PLAYER:IsFamilyShared()
        if self:IsBot() then return false end
        return self:SteamID64() ~= self:OwnerSteamID64()
    end

end
