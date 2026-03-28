/*
PUGREBAL:
phase tp
*/
global function OnWeaponPrimaryAttack_shifter
global function MpAbilityShifterWeapon_Init
global function MpAbilityShifterWeapon_OnWeaponTossPrep
global function AbilityShifter_ApplyInProgressStimIfNeeded

const SHIFTER_WARMUP_TIME = 0.0
const SHIFTER_WARMUP_TIME_FAST = 0.0

const string PHASEEXIT_IMPACT_TABLE_PROJECTILE	= "default"
const string PHASEEXIT_IMPACT_TABLE_TRACE		= "superSpectre_groundSlam_impact"

struct
{
	int phaseExitExplodeImpactTable
} file;

void function MpAbilityShifterWeapon_Init()
{
	// "exp_rocket_archer"
	// "exp_xlarge"
	// "exp_arc_ball"
	file.phaseExitExplodeImpactTable = PrecacheImpactEffectTable( PHASEEXIT_IMPACT_TABLE_PROJECTILE )
	PrecacheImpactEffectTable( PHASEEXIT_IMPACT_TABLE_TRACE )
}

void function MpAbilityShifterWeapon_OnWeaponTossPrep( entity weapon, WeaponTossPrepParams prepParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()
	int pmLevel = GetPVEAbilityLevel( weapon )
	if ( (pmLevel >= 2) && IsValid( weaponOwner ) && weaponOwner.IsPhaseShifted() )
		weapon.SetScriptTime0( Time() )
	else
		weapon.SetScriptTime0( 0.0 )
}

int function GetPVEAbilityLevel( entity weapon )
{
	if ( weapon.HasMod( "pm2" ) )
		return 2
	if ( weapon.HasMod( "pm1" ) )
		return 1
	if ( weapon.HasMod( "pm0" ) )
		return 0

	return -1
}

const float PMMOD_ENDLESS_STRENGTH = 0.8
var function OnWeaponPrimaryAttack_shifter( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	if ( weapon.HasMod( "phase_teleport") )
	{
		return OnWeaponPrimaryAttack_phase_teleport( weapon, attackParams )
	}
	float warmupTime = SHIFTER_WARMUP_TIME
	if ( weapon.HasMod( "short_shift" ) )
	{
		warmupTime = SHIFTER_WARMUP_TIME_FAST
	}

	entity weaponOwner = weapon.GetWeaponOwner()

	int pmLevel = GetPVEAbilityLevel( weapon )
	if ( weaponOwner.IsPlayer() && (pmLevel >= 0) )
	{
		if ( weaponOwner.IsPhaseShifted() )
		{
			float scriptTime = weapon.GetScriptTime0()
			if ( (pmLevel >= 2) && (scriptTime != 0.0) )
			{
				float chargeMaxTime = weapon.GetWeaponSettingFloat( eWeaponVar.custom_float_0 )
				float chargeTime = (Time() - scriptTime)
				if ( chargeTime >= chargeMaxTime )
				{
					DoPhaseExitExplosion( weaponOwner, weapon )
					StatusEffect_AddTimed( weaponOwner, eStatusEffect.move_slow, 1.0, 1.5, 1.5 )	// "stick" a bit more than usual on exit
				}
			}

			CancelPhaseShift( weaponOwner );
			EndlessStimEnd( weaponOwner )

			if ( pmLevel >= 0 )
				StatusEffect_AddTimed( weaponOwner, eStatusEffect.move_slow, 0.75, 0.75, 0.75 )	// "stick" a bit on exit

			return weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire )
		}
		else
		{
			PhaseShift( weaponOwner, 0, 99999 );
			if ( pmLevel >= 1 )
				EndlessStimBegin( weaponOwner, PMMOD_ENDLESS_STRENGTH )
			return 0
		}
	}
	else // vanilla phase
	{
		int phaseResult = PhaseShift( weaponOwner, warmupTime, weapon.GetWeaponSettingFloat( eWeaponVar.fire_duration ) )
		if ( phaseResult )
		{
			PlayerUsedOffhand( weaponOwner, weapon )
			#if BATTLECHATTER_ENABLED && SERVER
				TryPlayWeaponBattleChatterLine( weaponOwner, weapon )
			#endif
			return weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire )
		}
	}
	
	return 0
}

var function OnWeaponPrimaryAttack_phase_teleport( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	float warmupTime = SHIFTER_WARMUP_TIME
	if ( weapon.HasMod( "short_shift" ) )
	{
		warmupTime = SHIFTER_WARMUP_TIME_FAST
	}

	entity weaponOwner = weapon.GetWeaponOwner()
	// if this duration is too low the vfx is cancer and blinds you
	//float phase_time = weapon.GetWeaponSettingFloat( eWeaponVar.fire_duration )
	float phase_time = 1.0
	int phaseResult = PhaseShift( weaponOwner, warmupTime, phase_time )
	#if SERVER
	if (!phaseResult)
	{
		return 0
	}
	thread AbilityShifter_DisplaceTeleport( weaponOwner )
	#endif
	PlayerUsedOffhand( weaponOwner, weapon )
	#if BATTLECHATTER_ENABLED && SERVER
			TryPlayWeaponBattleChatterLine( weaponOwner, weapon )
	#endif
	return weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire )
}

void function ApplyInProgressStimIfNeededThread( entity player )
{
	wait 0.5  // timed to kick in when the notify appears on player's screen

	if ( !IsAlive( player ) )
		return
	if ( !player.IsPhaseShifted() )
		return

	EndlessStimBegin( player, PMMOD_ENDLESS_STRENGTH )
}

void function AbilityShifter_ApplyInProgressStimIfNeeded( entity player )
{
	thread ApplyInProgressStimIfNeededThread( player )
}

void function DoPhaseExitExplosion( entity player, entity phaseWeapon )
{
#if CLIENT
	if ( !phaseWeapon.ShouldPredictProjectiles() )
		return
#endif //

	player.PhaseShiftCancel()

	vector origin = player.GetWorldSpaceCenter() + player.GetForwardVector() * 16.0

	//DebugDrawLine( player.GetWorldSpaceCenter(), origin, 255, 0, 0, true, 5.0 )

	int damageType = (DF_RAGDOLL | DF_EXPLOSION | DF_ELECTRICAL)
	entity nade = phaseWeapon.FireWeaponGrenade( origin, <0,0,1>, <0,0,0>, 0.01, damageType, damageType, true, true, true )
	if ( !nade )
		return

	player.PhaseShiftBegin( 0, 1.0 )

	nade.SetImpactEffectTable( file.phaseExitExplodeImpactTable )
	nade.GrenadeExplode( <0,0,0> )

#if SERVER
	PlayImpactFXTable( player.GetOrigin(), player, PHASEEXIT_IMPACT_TABLE_TRACE, SF_ENVEXPLOSION_INCLUDE_ENTITIES )
#endif //
}

void function AbilityShifter_DisplaceTeleport( entity player )
{
	#if SERVER
	wait 0.2
    vector startpos = player.GetOrigin()
	entity telefragEntity
	vector endpos = startpos
	array<VisibleEntityInCone> results = FindVisibleEntitiesInCone( player.EyePosition(), player.GetViewVector(), 640, 5, [player], TRACE_MASK_PLAYERSOLID, VIS_CONE_ENTS_TEST_HITBOXES, player )
	foreach( result in results )
	{
		entity visibleEnt = result.ent

		if ( !IsAlive( visibleEnt ) )
			continue

		if ( visibleEnt.IsPhaseShifted() )
			continue
		
		if( visibleEnt.IsTitan() && visibleEnt.GetBossPlayer() == player && !visibleEnt.GetTitanSoul().IsEjecting() )
		{
			telefragEntity = visibleEnt
			break
		}

		if ( visibleEnt.GetTeam() == player.GetTeam() )
			continue

		if ( IsTurret( visibleEnt ) )
			continue
			
		if( !IsHumanSized( visibleEnt ) )
			continue

		telefragEntity = visibleEnt
		break
	}
	
	if( IsValid( telefragEntity ) )
	{
		player.SetOrigin( telefragEntity.GetOrigin() )
		if( telefragEntity.IsTitan() && telefragEntity.GetBossPlayer() == player && CanEmbark( player ) )
		{
			PilotBecomesTitan( player, telefragEntity )
			player.SetAngles( telefragEntity.GetAngles() )
			if ( IsValid( telefragEntity ) )
				telefragEntity.Destroy()
		}
		endpos = player.GetOrigin()
	}
	else
	{
		vector origin = player.GetOrigin()
		origin.z += 1
		vector angles = player.EyeAngles()
		vector forward = AnglesToForward( angles )
		vector oldresult = origin
		TraceResults result
		result = TraceHull( origin, origin + forward * 40, player.GetPlayerMins(), player.GetPlayerMaxs(), [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
		if ( !result.startSolid )
		{
			for( int i = 0; i < 20; i++ )
			{
				oldresult = result.endPos
				result = TraceHull( oldresult, oldresult + forward * 40, player.GetPlayerMins() * 1.1, player.GetPlayerMaxs() * 1.1, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
				if ( result.startSolid )
					break
			}
		}
		player.SetOrigin( oldresult )
		PutPhasePlayerInSafeSpot( player, 1 )
        endpos = player.GetOrigin()
	}
	PlayFX( $"P_phase_shift_main", endpos )
    vector translation = endpos-startpos;
    if ( Length(translation) > 32 ) {
        StartParticleEffectInWorldWithControlPoint( GetParticleSystemIndex($"wpn_arc_cannon_beam"), startpos, VectorToAngles(translation), endpos)
    }
	#endif
}

#if SERVER
void function PutPhasePlayerInSafeSpot( entity player, int severity )
{
	vector baseOrigin = player.GetOrigin()

	if ( PutEntityInSafeSpot( player, player, null, < baseOrigin.x, baseOrigin.y + severity, baseOrigin.z >, baseOrigin ) )
		return

	if ( PutEntityInSafeSpot( player, player, null, < baseOrigin.x, baseOrigin.y - severity, baseOrigin.z >, baseOrigin ) )
		return

	if ( PutEntityInSafeSpot( player, player, null, < baseOrigin.x + severity, baseOrigin.y, baseOrigin.z >, baseOrigin ) )
		return

	if ( PutEntityInSafeSpot( player, player, null, < baseOrigin.x - severity, baseOrigin.y, baseOrigin.z >, baseOrigin ) )
        return

	if ( PutEntityInSafeSpot( player, player, null, < baseOrigin.x, baseOrigin.y, baseOrigin.z + severity >, baseOrigin ) )
		return

	if ( PutEntityInSafeSpot( player, player, null, < baseOrigin.x, baseOrigin.y, baseOrigin.z - severity >, baseOrigin ) )
		return

	return PutPhasePlayerInSafeSpot( player, severity + 5 )
}
#endif