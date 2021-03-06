///////////////ANTIBODY SCANNER///////////////

/obj/item/device/antibody_scanner
	name = "\improper Antibody Scanner"
	desc = "Scans living beings for antibodies in their blood."
	icon_state = "health"
	w_class = 2.0
	item_state = "electronic"
	flags = CONDUCT

/obj/item/device/antibody_scanner/attack(mob/M as mob, mob/user as mob)
	if(!istype(M,/mob/living/carbon/))
		report("Scan aborted: Incompatible target.", user)
		return

	var/mob/living/carbon/C = M
	if (istype(C,/mob/living/carbon/human/))
		var/mob/living/carbon/human/H = C
		if(H.species && H.species.flags & NO_BLOOD)
			report("Scan aborted: The target does not have blood.", user)
			return

	if(!C.antibodies)
		report("Scan Complete: No antibodies detected.", user)
		return

	if (CLUMSY in user.mutations && prob(50))
		// I was tempted to be really evil and rot13 the output.
		report("Antibodies detected: [reverse_text(antigens2string(C.antibodies))]", user)
	else
		report("Antibodies detected: [antigens2string(C.antibodies)]", user)

/obj/item/device/antibody_scanner/proc/report(var/text, mob/user as mob)
	user << "<span class='notice'> \icon[src] \The [src] beeps, \"[text]\</span>"

///////////////VIRUS DISH///////////////

/obj/item/weapon/virusdish
	var/base_name = "virus sample"
	name = "virus sample"
	icon = 'icons/obj/items.dmi'
	icon_state = "implantcase-b"
	var/datum/disease2/disease/virus2 = null
	var/growth = 0
	var/info = 0
	var/analysed = 0
	var/label_text = ""
	
	proc/update_name_label()
		if(src.label_text == "")
			src.name = src.base_name
		else
			src.name = "[src.base_name] ([src.label_text])"

/obj/item/weapon/virusdish/random
	name = "virus sample"

/obj/item/weapon/virusdish/random/New()
	..()
	src.virus2 = new /datum/disease2/disease
	src.virus2.makerandom()
	growth = rand(5, 50)

/obj/item/weapon/virusdish/attackby(var/obj/item/weapon/W as obj,var/mob/living/carbon/user as mob)
	if(istype(W, /obj/item/weapon/pen) || istype(W, /obj/item/device/flashlight/pen))
		var/tmp_label = sanitize(copytext(input(user, "Enter a label for [src.name]","Label",src.label_text), 1, MAX_NAME_LEN))
		if(length(tmp_label) > 14)
			user << "<span class='alert'> The label can be at most 14 characters long.</span>"
			return
		else
			user << "<span class='notice'> You set the label to \"[tmp_label]\".</span>"
			src.label_text = tmp_label
			src.update_name_label()
			return
	else if(istype(W,/obj/item/weapon/reagent_containers/syringe) || istype(W, /obj/item/weapon/hand_labeler))
		return
	..()
	if(prob(50))
		user << "<span class='danger'>\The [src] shatters!</span>"
		if(virus2.infectionchance > 0)
			for(var/mob/living/carbon/target in view(1, get_turf(src)))
				if(airborne_can_reach(get_turf(src), get_turf(target)))
					infect_virus2(target, src.virus2)
		del src

/obj/item/weapon/virusdish/examine(mob/user)
	user << "This is a virus containment dish."
	if(src.info)
		user << "It has the following information about its contents:"
		user << src.info

/obj/item/weapon/ruinedvirusdish
	name = "ruined virus sample"
	icon = 'icons/obj/items.dmi'
	icon_state = "implantcase-b"
	desc = "The bacteria in the dish are completely dead."

/obj/item/weapon/ruinedvirusdish/attackby(var/obj/item/weapon/W as obj,var/mob/living/carbon/user as mob)
	if(istype(W,/obj/item/weapon/hand_labeler) || istype(W,/obj/item/weapon/reagent_containers/syringe))
		return ..()

	if(prob(50))
		user << "\The [src] shatters!"
		del src

///////////////GNA DISK///////////////

/obj/item/weapon/diseasedisk
	name = "blank GNA disk"
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk0"
	w_class = 1
	var/datum/disease2/effectholder/effect = null
	var/list/species = null
	var/stage = 1
	var/analysed = 1

/obj/item/weapon/diseasedisk/premade/New()
	name = "blank GNA disk (stage: [stage])"
	effect = new /datum/disease2/effectholder
	effect.effect = new /datum/disease2/effect/invisible
	effect.stage = stage
