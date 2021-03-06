//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/*
Destructive Analyzer

It is used to destroy hand-held objects and advance technological research. Controls are in the linked R&D console.

Note: Must be placed within 3 tiles of the R&D Console
*/
/obj/machinery/r_n_d/destructive_analyzer
	name = "destructive analyzer"
	icon_state = "d_analyzer"
	var/obj/item/weapon/loaded_item = null
	var/decon_mod = 1

	use_power = 1
	idle_power_usage = 30
	active_power_usage = 2500

/obj/machinery/r_n_d/destructive_analyzer/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/destructive_analyzer(src)
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(src)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(src)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(src)
	RefreshParts()

/obj/machinery/r_n_d/destructive_analyzer/RefreshParts()
	var/T = 0
	for(var/obj/item/weapon/stock_parts/S in src)
		T += S.rating * 0.1
	T = between (0, T, 1)
	decon_mod = T

/obj/machinery/r_n_d/destructive_analyzer/proc/ConvertReqString2List(var/list/source_list)
	var/list/temp_list = params2list(source_list)
	for(var/O in temp_list)
		temp_list[O] = text2num(temp_list[O])
	return temp_list


/obj/machinery/r_n_d/destructive_analyzer/attackby(var/obj/O as obj, var/mob/user as mob)
	if (shocked)
		shock(user,50)
	if (istype(O, /obj/item/weapon/screwdriver))
		if (!opened)
			opened = 1
			if(linked_console)
				linked_console.linked_destroy = null
				linked_console = null
			icon_state = "d_analyzer_t"
			user << "You open the maintenance hatch of [src]."
		else
			opened = 0
			icon_state = "d_analyzer"
			user << "You close the maintenance hatch of [src]."
		return
	if (opened)
		if(istype(O, /obj/item/weapon/crowbar))
			playsound(src.loc, 'sound/items/Crowbar.ogg', 50, 1)
			var/obj/machinery/constructable_frame/machine_frame/M = new /obj/machinery/constructable_frame/machine_frame(src.loc)
			M.state = 2
			M.icon_state = "box_1"
			for(var/obj/I in component_parts)
				I.loc = src.loc
			qdel(src)
			return 1
		else
			user << "<span class='alert'> You can't load the [src.name] while it's opened.</span>"
			return 1
	if (disabled)
		return
	if (!linked_console)
		user << "<span class='alert'> The destructive analyzer must be linked to an R&D console first!</span>"
		return
	if (busy)
		user << "<span class='alert'> The destructive analyzer is busy right now.</span>"
		return
	if (istype(O, /obj/item) && !loaded_item)
		if(isrobot(user)) //Don't put your module items in there!
			return
		if(!O.origin_tech)
			user << "<span class='alert'> This doesn't seem to have a tech origin!</span>"
			return
		var/list/temp_tech = ConvertReqString2List(O.origin_tech)
		if (temp_tech.len == 0)
			user << "<span class='alert'> You cannot deconstruct this item!</span>"
			return
		if(O.reliability < 90 && O.crit_fail == 0)
			usr << "<span class='alert'> Item is neither reliable enough nor broken enough to learn from.</span>"
			return
		busy = 1
		loaded_item = O
		user.drop_item()
		O.loc = src
		user << "<span class='notice'> You add the [O.name] to the machine!</span>"
		flick("d_analyzer_la", src)
		spawn(10)
			icon_state = "d_analyzer_l"
			busy = 0
		return 1
	return
