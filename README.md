This is a mod that rebalances weapons and abilities for use in Competitve CTF pickup games (and less brainrotted PvP). It is required on ***both*** the server and client in order to work properly, as balance changes and toggle features have caused key-value compilation issues which are fixed by the mod calling "weapon reparse" on the client end.



This mod features two toggleable balance options for use in Comp CTF. One is the "classic balance" that mirrors what has been the standard Competitive balance for the last few years. The other is a rebal designed to create more viable weapon variety while still maintaining the "status quo" in terms of meta options (car is still the best lmao).



This mod is an amalgamation/derivative of 3 other mods available on thunderstore. Those are:



PugRebalance by Aoloach/MrBlaBlak: https://thunderstore.io/c/northstar/p/Aoloach/PugRebalance/



rebal BETA by botmm: https://thunderstore.io/c/northstar/p/botmm/rebal\_BETA/



LTS Rebalance by Dinorush: https://thunderstore.io/c/northstar/p/Dinorush/LTS\_Rebalance/



The only actual "content" included from LTS Rebalance is a modified version of the KeyValue fix, but it is an integral to this mods functionality so I thought it should be crediited.



In terms of actual features, botmm/Voltaic\_Gold did most of the scripting to make this mod possible. It includes custom settings that allow us to control:

* aimpunch scaling
* regen speed
* pilot outline size
* mantle speed scaling
* custom headshot modifiers
* QoL screenshake settings
* experimental gunrunner changes
* balance mode toggle



In terms of the actual balance, for the purposes of this readme, the two modes will be labelled as v6.0 and v5.4. Those being "new" and "old" balance respectively. Both of these Rebals are designed to be used with 120% pilot hp.



All changes are listed in this format: default (vanilla) value -> changed value



# v6.0.0 Balance:

### Assault Rifles

* Flatline

  * Near damage: 30 -> 27
  * Far damage: 20 -> 22
  * viewkick\_air\_scale\_ads: 2 -> 1.0
  * Headshot multiplier: 1.5 -> 1.35
* G2

  * viewkick\_air\_scale\_ads: 3 -> 1.0
* Hemlok

  * viewkick\_air\_scale\_ads: 2 -> 1.0
  * Starburst mod replaces Quick Swap:

    * 5 round burst
    * 25 round mag
    * Heavy recoil
* R101 \& R201

  * Magazine size: 24 -> 28
  * Extended ammo: 30 -> 34
  * Near damage: 25 -> 22
  * viewkick\_air\_scale\_ads: 2 -> 1.0
  * viewkick\_pitch\_hardScale: 0.5 -> 0.3
  * viewkick\_yaw\_hardScale: 0.8 -> 0.6
  * Headshot multiplier: 1.5 -> 1.35
* R201

  * viewkick\_scale\_max\_ads: 2.5 -> 2.0

    * This equalizes the performance of R201 and R101

### SMGs

* Alternator - semi auto rework

  * Fire rate: 10 -> 6
  * Magazine size: 20 -> 16
  * Extended ammo: 25 -> 20
  * Near damage: 35 -> 40
  * Far damage: 18 -> 30
  * Very far damage: 14 -> 18
  * Far range: 1500 -> 1600
  * Very far range: 3000 -> 2800
  * viewkick\_scale\_firstshot\_hipfire: 0.3 -> 0.6
  * viewkick\_roll\_hardScale: 1.65 -> 1.2
  * viewkick\_roll\_softScale: 1.0 -> 0.85
  * Firstshot hipfire spread in air: 1.5 -> 0.0
  * Headshot multiplier: 1.5 -> 1.3
* CAR

  * Magazine size: 30 -> 33
  * Extended ammo: 36 -> 38
  * Near damage: 25 -> 22
  * Far damage: 13 -> 14
  * Very far damage: 10 -> 9
  * Near range: 1000 -> 1100
  * Very far damage: 3000 -> 2735
  * Firstshot hipfire spread in air: 1.5 -> 0.0
  * Headshot multiplier: 1.5 -> 1.35
* R97

  * Magazine size: 40 -> 42
  * Extended ammo: 48 -> 50
  * Near damage: 20 -> 18
  * Firstshot hipfire spread in air: 1.5 -> 0.0
  * Headshot multiplier: 1.5 -> 1.3
* Volt

  * Very far damage: 12 -> 13
  * Firstshot hipfire spread in air: 1.5 -> 0.0
  * Headshot multiplier: 1.5 -> 1.4



# v5.4.0 Balance:

### Assault Rifles

* Flatline

  * viewkick\_air\_scale\_ads: 2 -> 1.2
* G2

  * viewkick\_air\_scale\_ads: 3 -> 1.2
* Hemlok

  * viewkick\_air\_scale\_ads: 2 -> 1.2
  * Starburst mod replaces Quick Swap:

    * 5 round burst
    * 25 round mag
    * Heavy recoil
  * Extended Mag attachment gives a flat +6 rounds
* R101

  * viewkick\_air\_scale\_ads: 2 -> 1.2
  * viewkick\_pitch\_hardScale: 0.5 -> 0.3
  * viewkick\_yaw\_hardScale: 0.8 -> 0.6
* R201

  * viewkick\_air\_scale\_ads: 2 -> 1.2
  * viewkick\_pitch\_hardScale: 0.5 -> 0.3
  * viewkick\_yaw\_hardScale: 0.8 -> 0.6
  * Other viewkick stats equalized with R101 (so, iron sights are the only difference).

### SMGs

* Alternator

  * Near damage: 35 -> 40
  * Far damage 18 -> 28
  * Very far damage: 14 -> 18
  * Rate of fire: 10 -> 7
  * Default magazine: 20 -> 18
  * Extended magazine: 25 -> 22
  * Headshots disabled
  * viewkick\_scale\_firstshot\_hipfire: 0.3 -> 0.6
* CAR

  * Very far damage: 10 -> 9
* R97

  * Spread-in-air: 1.5 -> 1.0
* Volt

  * Far damage: 15 -> 17



# Univeral Changes:

### LMGs

* LSTAR

  * Near damage: 25 -> 30
  * Far damage: 18 -> 20
* Spitfire

  * Near damage: 35 -> 27
  * Very far damage: 20 -> 15

### Grenadiers

* SMR

  * Damage vs Titans: 115 -> 150
  * Projectile speed: 3300 -> 3600

### Anti-Titan Weapons

* Charge Rifle

  * Damage vs pilots: 300 -> 100

### Ordnance

* Frag Grenades

  * Explosion damage: 200 -> 20
  * Impulse force: 500 -> 17500
  * Explosion impulse: 50000 -> 65000
  * Grenades now explode when within proximity of enemies
* Gravity Star

  * Duration: 2 -> 1.5
* Electric Smoke

  * Pull-out time: 0.3 -> 0.25
  * Projectile launch speed: 1100 -> 1200
  * Lifetime: 6 seconds
  * Damage delay: 1s -> 0.8s
* Satchels

  * Explosion damage to pilots: 125 -> 100

### Tactical Abilities

* Grapple

  * Max length: 1100 -> 900
  * Air accel: 650 -> 350
  * detachSpeedLossMin: 460 -> 500
* Phase Shift

  * Holster, deploy, lower, raise, and toss times: 0.1 -> 0.01667
  * Health regen timer paused during Phase
* Pulse Blade

  * Completely replaced with a short-range teleport

### Titans

* Ion

  * Laser Shot

    * Distance: 4000 -> 3200
* Tone

  * Sonar Pulse

    * Duration vs Pilots: 5s -> 1s

## Additional Info

* View height: 60 -> 54 (to counter headglitching).
* Pilot melee damage: 100 -> 0.
* Intended for use with the Competitive CTF game mode at 1.2 pilot health multipler.

