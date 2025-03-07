//Boxes of ammo
/obj/item/ammo_box
	name = "ammo box (null_reference_exception)"
	desc = "A box of ammo."
	icon = 'icons/obj/ammo.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	item_state = "syringe_kit"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	materials = list(/datum/material/iron = 30000)
	throwforce = 2
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	///list containing the actual ammo within the magazine
	var/list/stored_ammo = list()
	///type that the magazine will be searching for, rejects if not a subtype of
	var/ammo_type = /obj/item/ammo_casing
	///maximum amount of ammo in the magazine
	var/max_ammo = 7
	///Controls how sprites are updated for the ammo box; see defines in combat.dm: AMMO_BOX_ONE_SPRITE; AMMO_BOX_PER_BULLET; AMMO_BOX_FULL_EMPTY
	var/multiple_sprites = AMMO_BOX_ONE_SPRITE
	///String, used for checking if ammo of different types but still fits can fit inside it; generally used for magazines
	var/caliber
	///Allows multiple bullets to be loaded in from one click of another box/magazine
	var/multiload = TRUE
	///Whether the magazine should start with nothing in it
	var/start_empty = FALSE
	///cost of all the bullets in the magazine/box
	var/list/bullet_cost
	///cost of the materials in the magazine/box itself
	var/list/base_cost
	//Whether the magazine should utilize a unique sprite or not if the magazine has multi-stage sprites
	var/sprite_designation

/obj/item/ammo_box/Initialize(mapload)
	. = ..()
	calc_mats()
	if(!start_empty)
		top_off(starting=TRUE)
	update_appearance(UPDATE_ICON|UPDATE_DESC)

/**
  * top_off is used to refill the magazine to max, in case you want to increase the size of a magazine with VV then refill it at once
  *
  * Arguments:
  * * load_type - if you want to specify a specific ammo casing type to load, enter the path here, otherwise it'll use the basic [/obj/item/ammo_box/var/ammo_type]. Must be a compatible round
  * * starting - Relevant for revolver cylinders, if FALSE then we mind the nulls that represent the empty cylinders (since those nulls don't exist yet if we haven't initialized when this is TRUE)
  */
/obj/item/ammo_box/proc/top_off(load_type, starting=FALSE)
	if(!load_type) //this check comes first so not defining an argument means we just go with default ammo
		load_type = ammo_type

	var/obj/item/ammo_casing/round_check = load_type
	if(!starting && (caliber && initial(round_check.caliber) != caliber) || (!caliber && load_type != ammo_type))
		stack_trace("Tried loading unsupported ammocasing type [load_type] into ammo box [type].")
		return

	for(var/i = max(1, stored_ammo.len), i <= max_ammo, i++)
		stored_ammo += new round_check(src)
	update_appearance(UPDATE_ICON|UPDATE_DESC)

/obj/item/ammo_box/proc/calc_mats(force = FALSE)
	if (force || !bullet_cost)
		for (var/material in materials)
			var/material_amount = materials[material]
			LAZYSET(base_cost, material, (material_amount * 0.10))

			material_amount *= 0.90 // 10% for the container
			material_amount /= max_ammo
			LAZYSET(bullet_cost, material, material_amount)

/obj/item/ammo_box/autolathe_crafted()
	calc_mats(force = TRUE)

///gets a round from the magazine, if keep is TRUE the round will stay in the gun
/obj/item/ammo_box/proc/get_round(keep = FALSE)
	if (!stored_ammo.len)
		return null
	else
		var/b = stored_ammo[stored_ammo.len]
		stored_ammo -= b
		if (keep)
			stored_ammo.Insert(1,b)
		return b

///puts a round into the magazine
/obj/item/ammo_box/proc/give_round(obj/item/ammo_casing/R, replace_spent = 0)
	// If we fail to find a caliber, then we fall back to ammo_type.
	if(!R || (caliber && R.caliber != caliber) || (!caliber && R.type != ammo_type))
		return FALSE

	if (stored_ammo.len < max_ammo)
		stored_ammo += R
		R.forceMove(src)
		return TRUE

	//for accessibles magazines (e.g internal ones) when full, start replacing spent ammo
	else if(replace_spent)
		for(var/obj/item/ammo_casing/AC in stored_ammo)
			if(!AC.BB)//found a spent ammo
				stored_ammo -= AC
				AC.forceMove(get_turf(src.loc))

				stored_ammo += R
				R.forceMove(src)
				return TRUE
	return FALSE

///Whether or not the box can be loaded, used in overrides
/obj/item/ammo_box/proc/can_load(mob/user)
	return TRUE

/obj/item/ammo_box/attackby(obj/item/A, mob/user, params, silent = FALSE, replace_spent = 0)
	attempt_load(A, user, silent, replace_spent)

/obj/item/ammo_box/proc/attempt_load(obj/item/A, mob/user, silent = FALSE, replace_spent = 0) //user attempts to put a into this box
	var/num_loaded = 0
	if(!can_load(user))
		return
	if(istype(A, /obj/item/ammo_box))
		var/obj/item/ammo_box/AM = A
		for(var/obj/item/ammo_casing/AC in AM.stored_ammo)
			var/did_load = give_round(AC, replace_spent)
			if(did_load)
				AM.stored_ammo -= AC
				num_loaded++
			if(!did_load || !multiload)
				break
	if(istype(A, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/AC = A
		if(give_round(AC, replace_spent))
			user.transferItemToLoc(AC, src, TRUE)
			num_loaded++

	if(num_loaded)
		if(!silent)
			to_chat(user, span_notice("You load [num_loaded] round\s into \the [src]!"))
			playsound(src, 'sound/weapons/bulletinsert.ogg', 60, TRUE)
		A.update_appearance(UPDATE_ICON)
		update_appearance(UPDATE_ICON|UPDATE_DESC)
	return num_loaded

/obj/item/ammo_box/attack_self(mob/user)
	var/obj/item/ammo_casing/A = get_round()
	if(A)
		A.forceMove(drop_location())
		if(!user.is_holding(src) || !user.put_in_hands(A))	//incase they're using TK
			A.bounce_away(FALSE, NONE)
		playsound(src, 'sound/weapons/bulletinsert.ogg', 60, TRUE)
		to_chat(user, span_notice("You remove a round from [src]!"))
		update_appearance(UPDATE_ICON|UPDATE_DESC)

/obj/item/ammo_box/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, TRUE))
		return
	var/obj/item/held_item = user.get_active_held_item()
	if(held_item && held_item != src)
		attempt_load(held_item, user)
	else
		var/obj/item/ammo_casing/A = get_round()
		if(A)
			if(!user.put_in_hands(A))
				A.forceMove(drop_location())
				A.bounce_away(FALSE, NONE)
			playsound(src, 'sound/weapons/bulletinsert.ogg', 60, TRUE)
			to_chat(user, span_notice("You remove a round from [src]!"))
			update_appearance(UPDATE_ICON|UPDATE_DESC)

/obj/item/ammo_box/update_icon(updates=ALL)
	. = ..()
	for(var/material in bullet_cost)
		var/material_amount = bullet_cost[material]
		material_amount = (material_amount*stored_ammo.len) + base_cost[material]
		materials[material] = material_amount

/obj/item/ammo_box/update_icon_state()
	. = ..()
	var/rounds_left = stored_ammo.len
	switch(multiple_sprites)
		if(AMMO_BOX_PER_BULLET)
			icon_state = "[initial(icon_state)]-[rounds_left]"
		if(AMMO_BOX_FULL_EMPTY)
			icon_state = "[initial(icon_state)]-[rounds_left ? "[max_ammo]" : "0"]"

/obj/item/ammo_box/update_desc(updates=ALL)
	. = ..()
	var/rounds_left = stored_ammo.len
	desc = "[initial(desc)] There [(rounds_left == 1) ? "is" : "are"] [rounds_left] round\s left!"

///Count of number of bullets in the magazine
/obj/item/ammo_box/magazine/proc/ammo_count(countempties = TRUE)
	var/boolets = 0
	for(var/obj/item/ammo_casing/bullet in stored_ammo)
		if(bullet && (bullet.BB || countempties))
			boolets++
	return boolets

///list of every bullet in the magazine
/obj/item/ammo_box/magazine/proc/ammo_list(drop_list = FALSE)
	var/list/L = stored_ammo.Copy()
	if(drop_list)
		stored_ammo.Cut()
	return L

///drops the entire contents of the magazine on the floor
/obj/item/ammo_box/magazine/proc/empty_magazine()
	var/turf_mag = get_turf(src)
	for(var/obj/item/ammo in stored_ammo)
		ammo.forceMove(turf_mag)
		stored_ammo -= ammo

/obj/item/ammo_box/magazine/handle_atom_del(atom/A)
	stored_ammo -= A
	update_appearance(UPDATE_ICON|UPDATE_DESC)
