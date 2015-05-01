#define FIRE			2

/obj/item/device/spacepod_equipment/weaponry/proc/fire_weapons()
	if(my_atom.next_firetime > world.time)
		usr << "<span class='warning'>Your weapons are recharging.</span>"
		return
	var/turf/firstloc
	var/turf/secondloc
	if(!my_atom.equipment_system || !my_atom.equipment_system.weapon_system)
		usr << "<span class='warning'>Missing equipment or weapons.</span>"
		my_atom.verbs -= text2path("[type]/proc/fire_weapons")
		return
	if( my_atom.equipment_system.battery )
		if( my_atom.equipment_system.battery.use(shot_cost) )
			usr << "There's not enough charge left!"
	else
		usr << "There's no battery in the system!"

	var/olddir
	for(var/i = 0; i < shots_per; i++)
		if(olddir != my_atom.dir)
			switch(my_atom.dir)
				if(NORTH)
					firstloc = get_step(my_atom, NORTH)
					firstloc = get_step(firstloc, NORTH)
					secondloc = get_step(firstloc,EAST)
				if(SOUTH)
					firstloc = get_step(my_atom, SOUTH)
					secondloc = get_step(firstloc,EAST)
				if(EAST)
					firstloc = get_step(my_atom, EAST)
					firstloc = get_step(firstloc, EAST)
					secondloc = get_step(firstloc,NORTH)
				if(WEST)
					firstloc = get_step(my_atom, WEST)
					secondloc = get_step(firstloc,NORTH)
		olddir = dir
		var/proj_type = text2path(projectile_type)
		var/obj/item/projectile/projone = new proj_type(firstloc)
		var/obj/item/projectile/projtwo = new proj_type(secondloc)
		projone.starting = get_turf(my_atom)
		projone.shot_from = src
		projone.firer = usr
		projone.def_zone = "chest"
		projtwo.starting = get_turf(my_atom)
		projtwo.shot_from = src
		projtwo.firer = usr
		projtwo.def_zone = "chest"
		spawn()
			playsound(src, fire_sound, 50, 1)
			projone.dumbfire(my_atom.dir)
			projtwo.dumbfire(my_atom.dir)
		sleep(2)
	my_atom.next_firetime = world.time + fire_delay

/datum/spacepod/equipment
	var/obj/spacepod/my_atom
	var/list/spacepod_equipment = list()
	var/max_size = 5

	// Various systems for fast retrieval
	var/obj/item/device/spacepod_equipment/weaponry/weapon_system  // weapons system
	var/obj/item/device/spacepod_equipment/misc/misc_system // misc system
	var/obj/item/device/spacepod_equipment/engine/engine_system // engine system
	var/obj/item/device/spacepod_equipment/shield/shield_system // shielding system
	var/obj/item/weapon/cell/battery // the battery, durh

/datum/spacepod/equipment/New(var/obj/spacepod/SP, max_size)
	..()
	if(istype(SP))
		my_atom = SP

/datum/spacepod/equipment/proc/equip(var/obj/item/equipment, var/mob/user = null)
	if( spacepod_equipment.len < max_size )
		if( assign_system( equipment )) // Adding the special systems
			spacepod_equipment.Add( equipment )
			if( user )
				user << "<span class='notice'>You insert \the [equipment] into the equipment system.</span>"
				user.drop_item(equipment)
			equipment.loc = src
			return 1
		else
			if( user )
				user << "\red That's not valid equipment!"
			return 0
	else
		if( user )
			user << "\red There's no space left for the [equipment]!"
		return 0

/datum/spacepod/equipment/proc/dequip(var/obj/item/equipment, var/mob/user)
	if( user.put_in_any_hand_if_possible(equipment))
		user << "<span class='notice'>You remove \the [equipment] from the space pod</span>"
		deassign_system( equipment )
		spacepod_equipment.Remove( equipment )
		return 1
	else
		user << "<span class='notice'>You can't remove the [equipment]!</span>"

	return 0

// Assigns proper systems
/datum/spacepod/equipment/proc/assign_system(var/obj/item/equipment)
	if(istype( equipment, /obj/item/device/spacepod_equipment/weaponry )) // Assigning the weapon system
		weapon_system = equipment
	else if(istype( equipment, /obj/item/device/spacepod_equipment/misc )) // Assigning misc systems
		misc_system = equipment
	else if(istype( equipment, /obj/item/device/spacepod_equipment/engine )) // Assigning the engine system
		engine_system = equipment
	else if(istype( equipment, /obj/item/device/spacepod_equipment/shield )) // Assigning the shield system
		shield_system = equipment
	else if(istype( equipment, /obj/item/weapon/cell )) // Assigning the battery
		battery = equipment
	else if(!istype( equipment, /obj/item/device/spacepod_equipment ))  // If it wasn't any of those systems, and isn't spacepod_equipment, we don't want what you're selling
		return 0

	if( istype( equipment, /obj/item/device/spacepod_equipment ))
		var/obj/item/device/spacepod_equipment/equipped = equipment
		equipped.my_atom = my_atom

	return 1

// Deassigns proper system
/datum/spacepod/equipment/proc/deassign_system(var/obj/item/equipment)
	if( equipment == weapon_system ) // Assigning the weapon system
		weapon_system = null
	else if( equipment == misc_system ) // Assigning misc systems
		misc_system = null
	else if( equipment == engine_system ) // Assigning the engine system
		engine_system = null
	else if( equipment == shield_system ) // Assigning the shield system
		shield_system = null
	else if( equipment == battery ) // Assigning the battery
		battery = null
	else if(!istype( equipment, /obj/item/device/spacepod_equipment ))  // If it wasn't any of those systems, and isn't spacepod_equipment, we don't want what you're selling
		world << "MAH EMULSION: Tried to remove an impossible object from the spacepod, yell at Kwask."
		return 0

	if( istype( equipment, /obj/item/device/spacepod_equipment ))
		var/obj/item/device/spacepod_equipment/equipped = equipment
		equipped.my_atom = null

	return 1

/obj/item/device/spacepod_equipment
	name = "equipment"
	icon = 'icons/pods/pod_parts.dmi'
	var/obj/spacepod/my_atom
	var/manufacturer = "NanoTrasen" // purely a fluff detail

/obj/item/device/spacepod_equipment/proc/check() // checks the status of a piece of equipment
	return 1

/obj/item/device/spacepod_equipment/weaponry
	name = "pod weapon"
	desc = "You shouldn't be seeing this"
	icon_state = "blank"
	var/projectile_type
	var/shot_cost = 0
	var/shots_per = 1
	var/fire_sound
	var/fire_delay = 20

/obj/item/device/spacepod_equipment/weaponry/taser
	name = "\improper taser system"
	desc = "A weak taser system for space pods, fires electrodes that shock upon impact."
	icon_state = "pod_taser"
	projectile_type = "/obj/item/projectile/beam/disabler"
	shot_cost = 250
	fire_sound = "sound/weapons/Taser.ogg"

/obj/item/device/spacepod_equipment/weaponry/burst_taser
	name = "\improper burst taser system"
	desc = "A weak taser system for space pods, this one fires 3 at a time."
	icon_state = "pod_b_taser"
	projectile_type = "/obj/item/projectile/beam/disabler"
	shot_cost = 350
	shots_per = 3
	fire_sound = "sound/weapons/Taser.ogg"
	fire_delay = 40

/obj/item/device/spacepod_equipment/weaponry/laser
	name = "\improper laser system"
	desc = "A weak laser system for space pods, fires concentrated bursts of energy"
	icon_state = "pod_w_laser"
	projectile_type = "/obj/item/projectile/beam"
	shot_cost = 300
	fire_sound = 'sound/weapons/Laser.ogg'
	fire_delay = 30

//base item for spacepod misc equipment (tracker)
/obj/item/device/spacepod_equipment/misc
	name = "pod misc"
	desc = "You shouldn't be seeing this"
	icon_state = "blank"
	var/enabled

/obj/item/device/spacepod_equipment/misc/tracker
	name = "\improper spacepod tracking system"
	desc = "A tracking device for spacepods."
	icon_state = "pod_locator"
	enabled = 0

/obj/item/device/spacepod_equipment/misc/tracker/check()
	return enabled

/obj/item/device/spacepod_equipment/misc/tracker/attackby(obj/item/I as obj, mob/user as mob, params)
	if(isscrewdriver(I))
		if(check())
			enabled = 0
			user.show_message("<span class='notice'>You disable \the [src]'s power.")
			return
		enabled = 1
		user.show_message("<span class='notice'>You enable \the [src]'s power.</span>")
	else
		..()

/obj/item/device/spacepod_equipment/engine
	name = "\improper spacepod engine"
	desc = "Vroom vroom."
	icon_state = "engine"
	var/tank_volume = 0.000 // how full the tank is
	var/tank_max_volume = 112.000 // 112 mols, or 4 full tanks of phoron
	var/burn_rate = 0.100 // 0.1 mols per meter
	var/heat_level = 0
	var/heat_rate = 10 // how much heat is gained per meter moved
	var/heat_rad_rate = 10 // how much heat is radiated per tick
	var/max_heat_level = 1000 // how hot this baby can get before bad things happen
	var/charge_rate = 10 // how much energy is generated every time fuel is used
	var/use_fuel = 1 // whether this engine runs on fuel or a nice hot cup of tea

/obj/item/device/spacepod_equipment/engine/New()
	..()

	processing_objects.Add( src )

/obj/item/device/spacepod_equipment/engine/Del()
	processing_objects.Remove( src )

	..()

/obj/item/device/spacepod_equipment/engine/process()
	if( my_atom.is_on_fire() ) // Being on fire kinda sucks
		heat_level += 20

	heat_level -= heat_rad_rate

	if( heat_level >= max_heat_level ) // hurt em a bit for running it too hot
		my_atom.deal_damage( (heat_level/(4*max_heat_level))*heat_rate )

/obj/item/device/spacepod_equipment/engine/check()
	if( tank_volume > 0 )
		return 1
	else
		return 0

// Runs a single cycle of the engine
/obj/item/device/spacepod_equipment/engine/proc/cycle()
	if( use_fuel )
		if( tank_volume > 0 )
			tank_volume -= burn_rate
			heat_level += heat_rate

			if( my_atom.equipment_system.battery )
				my_atom.equipment_system.battery.give( charge_rate )

			if( tank_volume < 0 )
				tank_volume = 0
		else
			return 0

	return 1

/obj/item/device/spacepod_equipment/shield
	name = "\improper spacepod shield system"
	desc = "For particularily rainy days."
	icon_state = "shield"

#undef FIRE