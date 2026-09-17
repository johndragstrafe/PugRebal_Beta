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

const float PHASE_TP_MAX_RANGE			= 840.0
const float PHASE_TP_STEP_HEIGHT		= 18.0
const int   PHASE_TP_STEP_RETRY_MAX		= 6
const int   PHASE_TP_FIT_BACKOFF_MAX	= 8
const float PHASE_TP_FIT_BACKOFF_STEP	= 16.0
const float PHASE_TP_SNAP_TOLERANCE		= 8.0
const float PHASE_TP_FIZZLE_FRACTION	= 0.05
const float PHASE_TP_FIZZLE_COST_FRAC	= 0.1
const float PHASE_TP_EMBARK_RANGE		= 840.0
const float PHASE_TP_CONE_ANGLE			= 5.0

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

	#if SERVER
	entity target = PhaseTeleport_FindTarget( weaponOwner )
	vector destination = IsValid( target ) ? target.GetOrigin() : PhaseTeleport_ComputeDestination( weaponOwner )

	if ( !IsValid( target ) && Distance( weaponOwner.GetOrigin(), destination ) < PHASE_TP_MAX_RANGE * PHASE_TP_FIZZLE_FRACTION )
	{
		// TODO: needs its own fx, this is just the normal appear fx in place
		PlayFX( $"P_phase_shift_main", weaponOwner.GetOrigin() )
		PlayerUsedOffhand( weaponOwner, weapon )

		int fizzleCost = int( weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire ) * PHASE_TP_FIZZLE_COST_FRAC )
		if ( fizzleCost < 1 )
			fizzleCost = 1
		return fizzleCost
	}
	#endif

	int phaseResult = PhaseShift( weaponOwner, warmupTime, phase_time )
	#if SERVER
	if (!phaseResult)
	{
		return 0
	}
	thread AbilityShifter_DisplaceTeleport( weaponOwner, destination, target )
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

#if SERVER
entity function PhaseTeleport_FindTarget( entity player )
{
	array<VisibleEntityInCone> embarkResults = FindVisibleEntitiesInCone( player.EyePosition(), player.GetViewVector(), PHASE_TP_EMBARK_RANGE, PHASE_TP_CONE_ANGLE, [player], TRACE_MASK_PLAYERSOLID, VIS_CONE_ENTS_TEST_HITBOXES, player )
	foreach( result in embarkResults )
	{
		entity visibleEnt = result.ent

		if ( !IsAlive( visibleEnt ) )
			continue

		if ( visibleEnt.IsPhaseShifted() )
			continue

		if( visibleEnt.IsTitan() && visibleEnt.GetBossPlayer() == player && !visibleEnt.GetTitanSoul().IsEjecting() )
			return visibleEnt
	}

	return null   // own titan only, no telefrag targets - the cone is too easy for a one shot
}

vector function PhaseTeleport_ComputeDestination( entity player )
{
	vector mins = player.GetPlayerMins()
	vector maxs = player.GetPlayerMaxs()
	vector origin = player.GetOrigin()

	vector sweepMaxs = maxs
	float eyeHeight = player.EyePosition().z - origin.z   // hull stands ~18 taller than your eyeline
	if ( eyeHeight < sweepMaxs.z )
		sweepMaxs.z = eyeHeight   // sweep tops out at eye level: if you can see it you can go there
	if ( sweepMaxs.z < mins.z + 1.0 )
		sweepMaxs.z = mins.z + 1.0

	float lift = 0.0
	TraceResults up = TraceHull( origin, origin + < 0.0, 0.0, PHASE_TP_STEP_HEIGHT >, mins, sweepMaxs, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
	if ( !up.startSolid )
		lift = PHASE_TP_STEP_HEIGHT * up.fraction

	float totalLift = lift
	vector pos = origin + < 0.0, 0.0, lift >
	vector forward = AnglesToForward( player.EyeAngles() )
	float remaining = PHASE_TP_MAX_RANGE

	bool steppedUp = false
	vector preStepPos = pos
	float preStepLift = totalLift

	for( int i = 0; i < PHASE_TP_STEP_RETRY_MAX; i++ )
	{
		TraceResults result = TraceHull( pos, pos + forward * remaining, mins, sweepMaxs, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
		if ( result.startSolid )
		{
			if ( steppedUp )
			{
				pos = preStepPos
				totalLift = preStepLift
			}
			break
		}

		pos = result.endPos
		remaining -= remaining * result.fraction

		if ( steppedUp )   // a step only counts if it landed on something, else you vault barriers
		{
			TraceResults ground = TraceHull( pos, pos - < 0.0, 0.0, PHASE_TP_STEP_HEIGHT + PHASE_TP_SNAP_TOLERANCE >, mins, sweepMaxs, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
			if ( ground.fraction >= 1.0 )
				break   // stepped out over an edge, let them fly

			pos = ground.endPos
			totalLift = preStepLift
			steppedUp = false

			if ( Distance( pos, preStepPos ) < 1.0 )
				break   // stepped up and got nowhere
		}

		if ( result.fraction >= 1.0 || remaining <= 1.0 )
			break

		TraceResults stepUp = TraceHull( pos, pos + < 0.0, 0.0, PHASE_TP_STEP_HEIGHT >, mins, sweepMaxs, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
		if ( stepUp.startSolid || stepUp.fraction < 1.0 )
			break

		preStepPos = pos
		preStepLift = totalLift
		pos = stepUp.endPos
		totalLift += PHASE_TP_STEP_HEIGHT
		steppedUp = true
	}

	// you can sweep through gaps you can't stand in; back up to the last spot that fits
	for( int i = 0; i < PHASE_TP_FIT_BACKOFF_MAX; i++ )
	{
		TraceResults fit = TraceHull( pos, pos + < 0.0, 0.0, 1.0 >, mins, maxs, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
		if ( !fit.startSolid )
			break

		pos -= forward * PHASE_TP_FIT_BACKOFF_STEP
	}

	TraceResults down = TraceHull( pos, pos - < 0.0, 0.0, totalLift + PHASE_TP_SNAP_TOLERANCE >, mins, maxs, [player], TRACE_MASK_PLAYERSOLID, TRACE_COLLISION_GROUP_PLAYER )
	if ( !down.startSolid && down.fraction < 1.0 )
		pos = down.endPos

	return pos
}
#endif

void function AbilityShifter_DisplaceTeleport( entity player, vector destination, entity target )
{
	#if SERVER
	vector startpos = player.GetOrigin()

	wait 0.1

	if ( !IsValid( player ) )
		return

	vector endpos = startpos

	if( IsValid( target ) )
	{
		player.SetOrigin( target.GetOrigin() )
		if( target.IsTitan() && target.GetBossPlayer() == player && CanEmbark( player ) )
		{
			PilotBecomesTitan( player, target )
			player.SetAngles( target.GetAngles() )
			if ( IsValid( target ) )
				target.Destroy()
		}
		endpos = player.GetOrigin()
	}
	else
	{
		player.SetOrigin( destination )
		PutPhasePlayerInSafeSpot( player, 1 )
		endpos = player.GetOrigin()
	}
	PlayFX( $"P_phase_shift_main", endpos )
    vector translation = endpos-startpos;
    if ( Length(translation) > 32 ) {
        StartParticleEffectInWorldWithControlPoint( GetParticleSystemIndex($"wpn_arc_cannon_beam"), startpos, VectorToAngles(translation), endpos)
    }
	CancelPhaseShift(player)
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