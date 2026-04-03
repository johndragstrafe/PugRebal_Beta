global function InitPUGRebalLoadouts

void function InitPUGRebalLoadouts()
{
	AddCallback_OnPlayerGetsNewPilotLoadout( OverridePUGPilotLoadout )
}

void function OverridePUGPilotLoadout( entity player, PilotLoadoutDef loadout )
{
	give_phasetp(player)
	low_ttk_mods(player)
	give_semi_alternator(player)
	gunrunner_mods(player)
	//frag_toggle(player) //no kv changed needed - got it all working in _grenade.nut
}
void function give_phasetp( entity player ) {
	if (GetCurrentPlaylistVarInt("riff_phasetp", 1) != 1) {
		return
	}
	if ( player.GetOffhandWeapon( OFFHAND_SPECIAL ).GetWeaponClassName() == "mp_weapon_grenade_sonar" ) // Replace pulse blade with instant teleport phase shift
	{
		player.TakeOffhandWeapon( OFFHAND_SPECIAL )
		player.GiveOffhandWeapon( "mp_ability_shifter", OFFHAND_SPECIAL, ["phase_teleport"] )
	}
}
void function give_semi_alternator( entity player ) {
	if (GetCurrentPlaylistVarInt( "riff_semialternator", 0 ) != 1) {
		return
	}
	
    array<entity> weapons = player.GetMainWeapons()
    foreach (entity weapon in weapons) {
        if (weapon.GetWeaponClassName() == "mp_weapon_alternator_smg") {
			if (weapon.HasMod("base_lowttk")) {
				weapon.RemoveMod("base_lowttk") // game kills itself if u use both
			}
            tryaddmod_hahahaahahhaahahaha(weapon, "strafe_semi_alternator")
			weapon.SetWeaponPrimaryClipCount(weapon.GetWeaponPrimaryClipCountMax())
        }
    }
}
void function low_ttk_mods( entity player ) {
	if (GetCurrentPlaylistVarInt( "riff_ttktoggle", 0 ) != 1) {
		return
	}
	array<entity> weapons = player.GetMainWeapons()
    foreach (entity weapon in weapons) {
		string name = weapon.GetWeaponClassName()
		array<string> appliedmods = weapon.GetMods()
		array<string> availableMods = GetWeaponMods_Global(name)

		foreach (string mod in appliedmods) {
			string mod_lowttk = mod+"_lowttk"
			if (mod == "strafe_semi_alternator") {
				weapon.RemoveMod(mod) // game kills itself if u use both
			}
			if (availableMods.contains(mod_lowttk)) {
				weapon.RemoveMod(mod)
				tryaddmod_hahahaahahhaahahaha(weapon, mod_lowttk)
			}
		}
		tryaddmod_hahahaahahhaahahaha(weapon, "base_lowttk")
		try {
			int newammo = weapon.GetWeaponPrimaryClipCountMax()
			weapon.SetWeaponPrimaryClipCount(newammo)
		}
		catch (ex) {}
    }
}
/*void function frag_toggle( entity player ){
	if(GetCurrentPlaylistVarInt("riff_fragtoggle", 0) == 1){
		return
	}
	if(player.GetOffhandWeapon( OFFHAND_RIGHT ).GetWeaponClassName() == "mp_weapon_frag_grenade"){
		player.GetOffhandWeapon( OFFHAND_RIGHT ).AddMod("normed_frags") 
	}
}*/

void function gunrunner_mods( entity player ) {
	int gunrunnermode = GetCurrentPlaylistVarInt( "riff_gunrunner", 1 )
	array<string> altgunrunner = [ "pas_run_and_gun", "", "gunrunner_animation", "gunrunner_sprintout" ]
	if (gunrunnermode == 0) {
		return
	}
	array<entity> weapons = player.GetMainWeapons()
    foreach (entity weapon in weapons) {
		string name = weapon.GetWeaponClassName()
		if (name == "mp_weapon_hemlok") {
			continue // hemlok "gunrunner" = starburst
		}
		array<string> availableMods = GetWeaponMods_Global(name)
		if (!availableMods.contains("gunrunner_animation")) {
			continue
		}

		array<string> appliedmods = weapon.GetMods()
		foreach (string mod in appliedmods) {
			if (mod == "pas_run_and_gun") {
				weapon.RemoveMod(mod)
				if (gunrunnermode != 1)
					tryaddmod_hahahaahahhaahahaha(weapon, altgunrunner[gunrunnermode])
			}
		}
    }
}
void function tryaddmod_hahahaahahhaahahaha(entity weapon, string mod) {
	
		try {
			//printt("DEBUG|| try " + mod)
			weapon.AddMod( mod )
		}
		catch(ex) {
			//printt("DEBUG|| caught ex on " + mod + " : " + ex)
		}
}