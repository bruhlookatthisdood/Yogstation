// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/light)

#define LIGHT_EMERGENCY_POWER_USE 0.2 //How much power emergency lights will consume per tick
// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3

#define BROKEN_SPARKS_MIN (3 MINUTES)
#define BROKEN_SPARKS_MAX (9 MINUTES)

#define LIGHT_ON_DELAY_UPPER 3 SECONDS
#define LIGHT_ON_DELAY_LOWER 1 SECONDS

/obj/item/wallframe/light_fixture
	name = "light fixture frame"
	desc = "Used for building lights."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-item"
	result_path = /obj/structure/light_construct
	inverse = TRUE

/obj/item/wallframe/light_fixture/small
	name = "small light fixture frame"
	icon_state = "bulb-construct-item"
	result_path = /obj/structure/light_construct/small
	materials = list(/datum/material/iron=MINERAL_MATERIAL_AMOUNT)

/obj/item/wallframe/light_fixture/try_build(turf/on_wall, user)
	if(!..())
		return
	var/area/A = get_area(user)
	if(!IS_DYNAMIC_LIGHTING(A))
		to_chat(user, span_warning("You cannot place [src] in this area!"))
		return
	return TRUE


/obj/structure/light_construct
	name = "light fixture frame"
	desc = "A light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-stage1"
	anchored = TRUE
	layer = WALL_OBJ_LAYER
	max_integrity = 200
	armor = list(MELEE = 50, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 50)

	var/stage = 1
	var/fixture_type = "tube"
	var/sheets_refunded = 2
	var/obj/machinery/light/newlight = null
	var/obj/item/stock_parts/cell/cell

	var/cell_connectors = TRUE

/obj/structure/light_construct/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)

/obj/structure/light_construct/Destroy()
	QDEL_NULL(cell)
	return ..()

/obj/structure/light_construct/get_cell()
	return cell

/obj/structure/light_construct/examine(mob/user)
	. = ..()
	switch(stage)
		if(1)
			. += "It's an empty frame."
		if(2)
			. += "It's wired."
		if(3)
			. += "The casing is closed."
	if(cell_connectors)
		if(cell)
			. += "You see [cell] inside the casing."
		else
			. += "The casing has no power cell for backup power."
	else
		. += span_danger("This casing doesn't support power cells for backup power.")

/obj/structure/light_construct/attack_hand(mob/user)
	if(cell)
		user.visible_message("[user] removes [cell] from [src]!",span_notice("You remove [cell]."))
		user.put_in_hands(cell)
		cell.update_appearance(UPDATE_ICON)
		cell = null
		add_fingerprint(user)

/obj/structure/light_construct/attack_tk(mob/user)
	if(cell)
		to_chat(user, span_notice("You telekinetically remove [cell]."))
		cell.forceMove(drop_location())
		cell.attack_tk(user)
		cell = null

/obj/structure/light_construct/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if(istype(W, /obj/item/stock_parts/cell))
		if(!cell_connectors)
			to_chat(user, span_warning("This [name] can't support a power cell!"))
			return
		if(HAS_TRAIT(W, TRAIT_NODROP))
			to_chat(user, span_warning("[W] is stuck to your hand!"))
			return
		if(cell)
			to_chat(user, span_warning("There is a power cell already installed!"))
		else if(user.temporarilyRemoveItemFromInventory(W))
			user.visible_message(span_notice("[user] hooks up [W] to [src]."), \
			span_notice("You add [W] to [src]."))
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			W.forceMove(src)
			cell = W
			add_fingerprint(user)
		return
	else if (istype(W, /obj/item/light))
		to_chat(user, span_warning("This [name] isn't finished being setup!"))
		return

	switch(stage)
		if(1)
			if(W.tool_behaviour == TOOL_WRENCH)
				if(cell)
					to_chat(user, span_warning("You have to remove the cell first!"))
					return
				else
					to_chat(user, span_notice("You begin deconstructing [src]..."))
					if (W.use_tool(src, user, 30, volume=50))
						new /obj/item/stack/sheet/metal(drop_location(), sheets_refunded)
						user.visible_message("[user.name] deconstructs [src].", \
							span_notice("You deconstruct [src]."), span_italics("You hear a ratchet."))
						playsound(src, 'sound/items/deconstruct.ogg', 75, 1)
						qdel(src)
					return

			if(istype(W, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/coil = W
				if(coil.use(1))
					icon_state = "[fixture_type]-construct-stage2"
					stage = 2
					user.visible_message("[user.name] adds wires to [src].", \
						span_notice("You add wires to [src]."))
				else
					to_chat(user, span_warning("You need one length of cable to wire [src]!"))
				return
		if(2)
			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(usr, span_warning("You have to remove the wires first!"))
				return

			if(W.tool_behaviour == TOOL_WIRECUTTER)
				stage = 1
				icon_state = "[fixture_type]-construct-stage1"
				new /obj/item/stack/cable_coil(drop_location(), 1, "red")
				user.visible_message("[user.name] removes the wiring from [src].", \
					span_notice("You remove the wiring from [src]."), span_italics("You hear clicking."))
				W.play_tool_sound(src, 100)
				return

			if(W.tool_behaviour == TOOL_SCREWDRIVER)
				user.visible_message("[user.name] closes [src]'s casing.", \
					span_notice("You close [src]'s casing."), span_italics("You hear screwing."))
				W.play_tool_sound(src, 75)
				switch(fixture_type)
					if("tube")
						newlight = new /obj/machinery/light/built(loc)
					if("bulb")
						newlight = new /obj/machinery/light/small/built(loc)
					if("floor")
						newlight = new /obj/machinery/light/floor/built(loc)
				newlight.setDir(dir)
				transfer_fingerprints_to(newlight)
				if(cell)
					newlight.cell = cell
					cell.forceMove(newlight)
					cell = null
				qdel(src)
				return
	return ..()

/obj/structure/light_construct/blob_act(obj/structure/blob/B)
	if(B && B.loc == loc)
		qdel(src)


/obj/structure/light_construct/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, sheets_refunded)
	qdel(src)

/obj/structure/light_construct/small
	name = "small light fixture frame"
	icon_state = "bulb-construct-stage1"
	fixture_type = "bulb"
	sheets_refunded = 1

/obj/structure/light_construct/floor
	name = "floor light fixture frame"
	icon_state = "floor-construct-stage1"
	fixture_type = "floor"
	sheets_refunded = 1
	layer = LOW_OBJ_LAYER

// the standard tube light fixture
/obj/machinery/light
	name = "light fixture"
	icon = 'icons/obj/lighting.dmi'
	var/overlayicon = 'icons/obj/lighting_overlay.dmi'
	var/base_state = "tube"		// base description and icon_state
	icon_state = "tube"
	desc = "A lighting fixture."
	layer = WALL_OBJ_LAYER
	max_integrity = 100
	use_power = ACTIVE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 20
	power_channel = AREA_USAGE_LIGHT //Lights are calc'd via area so they dont need to be in the machine list
	var/on = FALSE					// 1 if on, 0 if off
	var/on_gs = FALSE
	var/forced_off = FALSE
	var/static_power_used = 0
	var/brightness = 8			// luminosity when on, also used in power calculation
	var/bulb_power = 1			// basically the alpha of the emitted light source
	var/bulb_colour = "#FFFFFF"	// befault colour of the light.
	var/status = LIGHT_OK		// LIGHT_OK, _EMPTY, _BURNED or _BROKEN
	var/flickering = FALSE
	var/light_type = /obj/item/light/tube		// the type of light item
	var/fitting = "tube"
	var/switchcount = 0			// count of number of times switched on/off
								// this is used to calc the probability the light burns out

	var/rigged = FALSE			// true if rigged to explode

	var/obj/item/stock_parts/cell/cell
	var/start_with_cell = TRUE	// if true, this fixture generates a very weak cell at roundstart

	var/nightshift_enabled = FALSE	//Currently in night shift mode?
	var/nightshift_allowed = TRUE	//Set to FALSE to never let this light get switched to night mode.
	var/nightshift_brightness = 8
	var/nightshift_light_power = 0.45
	var/nightshift_light_color = "#FFDDCC"

	var/emergency_mode = FALSE	// if true, the light is in emergency mode
	var/no_emergency = FALSE	// if true, this light cannot ever have an emergency mode
	var/bulb_emergency_brightness_mul = 0.25	// multiplier for this light's base brightness in emergency power mode
	var/bulb_emergency_colour = "#FF3232"	// determines the colour of the light while it's in emergency mode
	var/bulb_emergency_pow_mul = 0.75	// the multiplier for determining the light's power in emergency mode
	var/bulb_emergency_pow_min = 0.5	// the minimum value for the light's power in emergency mode

	var/bulb_vacuum_colour = "#4F82FF"	// colour of the light when air alarm is set to severe
	var/bulb_vacuum_brightness = 8

	///So we don't have a lot of stress on startup.
	var/maploaded = FALSE

	///More stress stuff.
	var/turning_on = FALSE

/obj/machinery/light/broken
	status = LIGHT_BROKEN
	icon_state = "tube-broken"

// the smaller bulb light fixture

/obj/machinery/light/small
	icon_state = "bulb"
	base_state = "bulb"
	fitting = "bulb"
	brightness = 4
	desc = "A small lighting fixture."
	light_type = /obj/item/light/bulb

/obj/machinery/light/small/broken
	status = LIGHT_BROKEN
	icon_state = "bulb-broken"

/obj/machinery/light/Move()
	if(status != LIGHT_BROKEN)
		break_light_tube(1)
	return ..()

/obj/machinery/light/built
	icon_state = "tube-empty"
	start_with_cell = FALSE

/obj/machinery/light/built/Initialize(mapload)
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/floor/built
	icon_state = "floor-empty"

/obj/machinery/light/floor/built/Initialize(mapload)
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/small/built
	icon_state = "bulb-empty"

/obj/machinery/light/small/built/Initialize(mapload)
	. = ..()
	status = LIGHT_EMPTY
	update(0)

// create a new lighting fixture
/obj/machinery/light/Initialize(mapload)
	. = ..()
	GLOB.lights += src

	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(clean_light))

	//Setup area colours -pb
	var/area/A = get_area(src)
	if(bulb_colour == initial(bulb_colour))
		if(istype(src, /obj/machinery/light/small))
			bulb_colour = A.lighting_colour_bulb
		else
			bulb_colour = A.lighting_colour_tube

	if(nightshift_light_color == initial(nightshift_light_color))
		nightshift_light_color = A.lighting_colour_night

	if(!mapload) //sync up nightshift lighting for player made lights
		var/obj/machinery/power/apc/temp_apc = A.get_apc()
		nightshift_enabled = temp_apc?.nightshift_lights
	else
		maploaded = TRUE

	if(start_with_cell && !no_emergency)
		cell = new/obj/item/stock_parts/cell/emergency_light(src)
	spawn(2)
		switch(fitting)
			if("tube")
				brightness = 8
				if(prob(2))
					break_light_tube(1)
			if("bulb")
				brightness = 4
				if(prob(5))
					break_light_tube(1)
			if("floor bulb")
				brightness = 4
				if(prob(5))
					break_light_tube(1)
		spawn(1)
			update(FALSE, TRUE, maploaded)

/obj/machinery/light/Destroy()
	GLOB.lights.Remove(src)
	var/area/A = get_area(src)
	if(A)
		on = FALSE && !forced_off
//		A.update_lights()
	QDEL_NULL(cell)
	return ..()

/obj/machinery/light/update_icon(updates=ALL)
	. = ..()
	if(on && turning_on)
		return

	cut_overlays()
	switch(status)		// set icon_states
		if(LIGHT_OK)
			if(forced_off)
				icon_state = "[base_state]"
				return
			var/area/A = get_area(src)
			if(emergency_mode || (A && (A.fire || A.delta_light)))
				icon_state = "[base_state]_emergency"
			else if (A && A.vacuum)
				icon_state = "[base_state]_vacuum"
			else
				icon_state = "[base_state]"
			if(on && !forced_off)
				var/glow_state = base_state
				if(emergency_mode || (A && A.fire))
					glow_state = "[base_state]_emergency"
				else if ((A && A.vacuum) || nightshift_enabled)
					glow_state = "[base_state]_nightshift"
				var/mutable_appearance/glowybit = mutable_appearance(overlayicon, glow_state, layer)
				//glowybit.alpha = clamp(light_power*250, 30, 200)
				add_overlay(glowybit)
		if(LIGHT_EMPTY)
			icon_state = "[base_state]-empty"
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
	return

/obj/machinery/light/proc/clean_light(O,strength)
	if(strength < CLEAN_TYPE_BLOOD)
		return
	var/area/A = get_area(src)
	if(istype(src, /obj/machinery/light/small))
		bulb_colour = A.lighting_colour_bulb
	else
		bulb_colour = A.lighting_colour_tube
	update()

// update the icon_state and luminosity of the light depending on its state
/obj/machinery/light/proc/update(trigger = TRUE, quiet = FALSE, instant = FALSE)
	switch(status)
		if(LIGHT_BROKEN,LIGHT_BURNED,LIGHT_EMPTY)
			on = FALSE
	emergency_mode = FALSE
	if(on)
		if(instant)
			turn_on(trigger, quiet)
		else if(maploaded)
			turn_on(trigger, TRUE)
			maploaded = FALSE
		else if(!turning_on)
			turning_on = TRUE
			addtimer(CALLBACK(src, PROC_REF(turn_on), trigger, quiet), rand(LIGHT_ON_DELAY_LOWER, LIGHT_ON_DELAY_UPPER))
	else if(has_emergency_power(LIGHT_EMERGENCY_POWER_USE) && !turned_off())
		use_power = IDLE_POWER_USE
		emergency_mode = TRUE
		START_PROCESSING(SSmachines, src)
	else
		use_power = IDLE_POWER_USE
		set_light(0)
	update_appearance(UPDATE_ICON)

	active_power_usage = (brightness * 10)
	if(on != on_gs)
		on_gs = on
		if(on)
			static_power_used = brightness * 20 //20W per unit luminosity
			addStaticPower(static_power_used, AREA_USAGE_STATIC_LIGHT)
		else
			removeStaticPower(static_power_used, AREA_USAGE_STATIC_LIGHT)

	broken_sparks(start_only=TRUE)

/obj/machinery/light/proc/turn_on(trigger, quiet = FALSE)
	if(QDELETED(src))
		return FALSE
	turning_on = FALSE
	if(!on)
		return FALSE

	var/BR = brightness
	var/PO = bulb_power
	var/CO = bulb_colour
	if(color)
		CO = color
	var/area/A = get_area(src)
	if (A && (A.fire || A.delta_light))
		CO = bulb_emergency_colour
	else if (A && A.vacuum)
		CO = bulb_vacuum_colour
		BR = bulb_vacuum_brightness
	else if (nightshift_enabled)
		BR = nightshift_brightness
		PO = nightshift_light_power
		if(!color)
			CO = nightshift_light_color
	var/matching = light && BR == light.light_range && PO == light.light_power && CO == light.light_color
	if(!matching)
		switchcount++
		if(rigged)
			if(status == LIGHT_OK && trigger)
				explode()
		else if( prob( min(60, (switchcount^2)*0.01) ) )
			if(trigger)
				burn_out()
		else
			use_power = ACTIVE_POWER_USE
			set_light(BR, PO, CO)
			if(!quiet)
				playsound(src.loc, 'sound/effects/light_on.ogg', 50)
	update_icon()
	return TRUE

/obj/machinery/light/update_atom_colour()
	..()
	update()

/obj/machinery/light/proc/broken_sparks(start_only=FALSE)
	if(!QDELETED(src) && status == LIGHT_BROKEN && has_power() && Master.current_runlevel)
		if(!start_only)
			do_sparks(3, TRUE, src)
		var/delay = rand(BROKEN_SPARKS_MIN, BROKEN_SPARKS_MAX)
		addtimer(CALLBACK(src, PROC_REF(broken_sparks)), delay, TIMER_UNIQUE | TIMER_NO_HASH_WAIT)

/obj/machinery/light/process()
	if (!cell)
		return PROCESS_KILL
	if(has_power())
		if (cell.charge == cell.maxcharge)
			return PROCESS_KILL
		cell.charge = min(cell.maxcharge, cell.charge + LIGHT_EMERGENCY_POWER_USE) //Recharge emergency power automatically while not using it
	if(emergency_mode && !use_emergency_power(LIGHT_EMERGENCY_POWER_USE))
		update(FALSE) //Disables emergency mode and sets the color to normal

/obj/machinery/light/proc/burn_out()
	if(status == LIGHT_OK)
		status = LIGHT_BURNED
		icon_state = "[base_state]-burned"
		on = FALSE
		set_light(0)
		playsound(src.loc, 'sound/effects/burnout.ogg', 65)
		update_icon()

// attempt to set the light's on/off status
// will not switch on if broken/burned/empty
/obj/machinery/light/proc/seton(s)
	on = (s && status == LIGHT_OK && !forced_off)
	update(FALSE)

/obj/machinery/light/get_cell()
	return cell

// examine verb
/obj/machinery/light/examine(mob/user)
	. = ..()
	switch(status)
		if(LIGHT_OK)
			. += "It is turned [on? "on" : "off"]."
		if(LIGHT_EMPTY)
			. += "The [fitting] has been removed."
		if(LIGHT_BURNED)
			. += "The [fitting] is burnt out."
		if(LIGHT_BROKEN)
			. += "The [fitting] has been smashed."
	if(cell)
		. += "Its backup power charge meter reads [round((cell.charge / cell.maxcharge) * 100, 0.1)]%."



// attack with item - insert light (if right type), otherwise try to break the light

/obj/machinery/light/attackby(obj/item/W, mob/living/user, params)

	//Light replacer code
	if(istype(W, /obj/item/lightreplacer))
		var/obj/item/lightreplacer/LR = W
		LR.ReplaceLight(src, user)

	// attempt to insert light
	else if(istype(W, /obj/item/light))
		if(status == LIGHT_OK)
			to_chat(user, span_warning("There is a [fitting] already inserted!"))
		else
			src.add_fingerprint(user)
			var/obj/item/light/L = W
			if(istype(L, light_type))
				if(!user.temporarilyRemoveItemFromInventory(L))
					return

				src.add_fingerprint(user)
				if(status != LIGHT_EMPTY)
					drop_light_tube(user)
					to_chat(user, span_notice("You replace [L]."))
				else
					to_chat(user, span_notice("You insert [L]."))
				status = L.status
				switchcount = L.switchcount
				rigged = L.rigged
				brightness = L.brightness
				on = has_power() && !forced_off
				update()

				qdel(L)

				if(on && rigged)
					explode()
			else
				to_chat(user, span_warning("This type of light requires a [fitting]!"))
	// hit the light socket with umbral tendrils, instantly breaking the light as opposed to RNG //yogs
	else if(istype(W, /obj/item/umbral_tendrils))
		break_light_tube()
		..() //yogs end

	// attempt to stick weapon into light socket
	else if(status == LIGHT_EMPTY)
		if(W.tool_behaviour == TOOL_SCREWDRIVER) //If it's a screwdriver open it.
			W.play_tool_sound(src, 75)
			user.visible_message("[user.name] opens [src]'s casing.", \
				span_notice("You open [src]'s casing."), span_italics("You hear a noise."))
			deconstruct()
		else
			to_chat(user, span_userdanger("You stick \the [W] into the light socket!"))
			if(has_power() && (W.flags_1 & CONDUCT_1))
				do_sparks(3, TRUE, src)
				if (prob(75))
					electrocute_mob(user, get_area(src), src, rand(0.7,1.0), TRUE)
	//attempt to turn off light with multitool
	else if(W.tool_behaviour == TOOL_MULTITOOL)
		set_light(0)
		forced_off = !forced_off
		on = !on
		update_appearance(UPDATE_ICON)
		update()
	else
		return ..()

/obj/machinery/light/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/structure/light_construct/newlight = null
		var/cur_stage = 2
		if(!disassembled)
			cur_stage = 1
		switch(fitting)
			if("tube")
				newlight = new /obj/structure/light_construct(src.loc)
				newlight.icon_state = "tube-construct-stage[cur_stage]"

			if("bulb")
				newlight = new /obj/structure/light_construct/small(src.loc)
				newlight.icon_state = "bulb-construct-stage[cur_stage]"

			if("floor bulb")
				newlight = new /obj/structure/light_construct/floor(src.loc)
				newlight.icon_state = "floor-construct-stage[cur_stage]"
		newlight.setDir(src.dir)
		newlight.stage = cur_stage
		if(!disassembled)
			newlight.obj_integrity = newlight.max_integrity * 0.5
			if(status != LIGHT_BROKEN)
				break_light_tube()
			if(status != LIGHT_EMPTY)
				drop_light_tube()
			new /obj/item/stack/cable_coil(loc, 1, "red")
		transfer_fingerprints_to(newlight)
		if(cell)
			newlight.cell = cell
			cell.forceMove(newlight)
			cell = null
	qdel(src)

/obj/machinery/light/attacked_by(obj/item/I, mob/living/user)
	..()
	if(status == LIGHT_BROKEN || status == LIGHT_EMPTY)
		if(on && (I.flags_1 & CONDUCT_1) && !forced_off)
			if(prob(12))
				electrocute_mob(user, get_area(src), src, 0.3, TRUE)

/obj/machinery/light/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(. && !QDELETED(src))
		if(prob(damage_amount * 5))
			break_light_tube()




/obj/machinery/light/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			switch(status)
				if(LIGHT_EMPTY)
					playsound(loc, 'sound/weapons/smash.ogg', 50, 1)
				if(LIGHT_BROKEN)
					playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 90, 1)
				else
					playsound(loc, 'sound/effects/glasshit.ogg', 90, 1)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, 1)

// returns if the light has power /but/ is manually turned off
// if a light is turned off, it won't activate emergency power
/obj/machinery/light/proc/turned_off()
	var/area/A = get_area(src)
	return !A.lightswitch && A.power_light || flickering

// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/proc/has_power()
	var/area/A = get_area(src)
	return A.lightswitch && A.power_light

// returns whether this light has emergency power
// can also return if it has access to a certain amount of that power
/obj/machinery/light/proc/has_emergency_power(pwr)
	if(no_emergency || !cell)
		return FALSE
	if(pwr ? cell.charge >= pwr : cell.charge)
		return status == LIGHT_OK

// attempts to use power from the installed emergency cell, returns true if it does and false if it doesn't
/obj/machinery/light/proc/use_emergency_power(pwr = LIGHT_EMERGENCY_POWER_USE)
	if(!has_emergency_power(pwr))
		return FALSE
	if(cell.charge > 300) //it's meant to handle 120 W, ya doofus
		visible_message(span_warning("[src] short-circuits from too powerful of a power cell!"))
		burn_out()
		return FALSE
	cell.use(pwr)
	set_light(brightness * bulb_emergency_brightness_mul, max(bulb_emergency_pow_min, bulb_emergency_pow_mul * (cell.charge / cell.maxcharge)), bulb_emergency_colour)
	return TRUE


/obj/machinery/light/proc/flicker(amount = rand(10, 20))
	set waitfor = 0
	if(flickering)
		return
	flickering = 1
	if(on && status == LIGHT_OK)
		for(var/i = 0; i < amount; i++)
			if(status != LIGHT_OK)
				break
			on = !on
			update(0)
			sleep(rand(0.5, 1.5) SECONDS)
		on = (status == LIGHT_OK) && !forced_off
		update(0)
	flickering = 0

// ai attack - make lights flicker, because why not

/obj/machinery/light/attack_ai(mob/user)
	no_emergency = !no_emergency
	to_chat(user, span_notice("Emergency lights for this fixture have been [no_emergency ? "disabled" : "enabled"]."))
	update(FALSE)
	return

// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player

/obj/machinery/light/attack_hand(mob/living/carbon/human/user)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE)
	add_fingerprint(user)

	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	// make it burn hands unless you're wearing heat insulated gloves or have the RESISTHEAT/RESISTHEATHANDS traits
	if(on && status == LIGHT_OK)
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))
			if(isethereal(H))
				to_chat(H, span_notice("You start channeling some power through the [fitting] into your body."))
				if(do_after(user, 1 SECONDS, src))
					if(istype(H.getorganslot(ORGAN_SLOT_STOMACH), /obj/item/organ/stomach/cell))
						to_chat(H, span_notice("You receive some charge from the [fitting]."))
						H.adjust_nutrition(100)
					else
						to_chat(H, span_notice("You can't receive charge from the [fitting]."))
				return

			if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					prot = (G.max_heat_protection_temperature > 360)
		else
			prot = 1

		if(prot > 0 || HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
			to_chat(user, span_notice("You remove the light [fitting]."))
		else if(istype(user) && user.dna.check_mutation(TK))
			to_chat(user, span_notice("You telekinetically remove the light [fitting]."))
		else
			to_chat(user, span_warning("You try to remove the light [fitting], but you burn your hand on it!"))

			var/obj/item/bodypart/affecting = H.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
			if(affecting && affecting.receive_damage( 0, 5 ))		// 5 burn damage
				H.update_damage_overlays()
			return				// if burned, don't remove the light
	else
		to_chat(user, span_notice("You remove the light [fitting]."))
	// create a light tube/bulb item and put it in the user's hand
	drop_light_tube(user)

/obj/machinery/light/proc/drop_light_tube(mob/user)
	var/obj/item/light/L = new light_type()
	L.status = status
	L.rigged = rigged
	L.brightness = brightness

	// light item inherits the switchcount, then zero it
	L.switchcount = switchcount
	switchcount = 0

	L.update()
	L.forceMove(loc)

	if(user) //puts it in our active hand
		L.add_fingerprint(user)
		user.put_in_active_hand(L)

	status = LIGHT_EMPTY
	update()
	return L

/obj/machinery/light/attack_tk(mob/user)
	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	to_chat(user, span_notice("You telekinetically remove the light [fitting]."))
	// create a light tube/bulb item and put it in the user's hand
	var/obj/item/light/L = drop_light_tube()
	L.attack_tk(user)

/obj/machinery/light/attack_eminence(mob/camera/eminence/user, params)
	if(status == LIGHT_EMPTY || status == LIGHT_BROKEN)
		return
		
	to_chat(user, span_brass("You concentrate your power, trying to break [src]..."))
	if(!do_after(user, 2 SECONDS, src))
		return
	to_chat(user, span_brass("You sucessfully break [src]!"))
	break_light_tube(0)

// break the light and make sparks if was on

/obj/machinery/light/proc/break_light_tube(skip_sound_and_sparks = 0)
	if(status == LIGHT_EMPTY || status == LIGHT_BROKEN)
		return

	if(!skip_sound_and_sparks)
		if(status == LIGHT_OK || status == LIGHT_BURNED)
			playsound(src.loc, 'sound/effects/glasshit.ogg', 75, 1)
		if(on)
			do_sparks(3, TRUE, src)
	status = LIGHT_BROKEN
	update()

/obj/machinery/light/proc/fix()
	if(status == LIGHT_OK)
		return
	status = LIGHT_OK
	brightness = initial(brightness)
	on = TRUE && !forced_off
	update()

/obj/machinery/light/tesla_act(power, tesla_flags, shocked_targets, zap_gib = FALSE)
	if(tesla_flags & TESLA_MACHINE_EXPLOSIVE)
		explosion(src,0,0,0,flame_range = 5, adminlog = 0)
		qdel(src)
	else
		return ..()

// called when area power state changes
/obj/machinery/light/power_change()
	var/area/A = get_area(src)
	seton(A.lightswitch && A.power_light)

// called when on fire

/obj/machinery/light/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(prob(max(0, exposed_temperature - 673)))   //0% at <400C, 100% at >500C
		break_light_tube()

// explode the light

/obj/machinery/light/proc/explode()
	set waitfor = 0
	var/turf/T = get_turf(src.loc)
	break_light_tube()	// break it first to give a warning
	sleep(0.2 SECONDS)
	explosion(T, 0, 1, 2, 4)
	sleep(0.1 SECONDS)
	qdel(src)

// the light item
// can be tube or bulb subtypes
// will fit into empty /obj/machinery/light of the corresponding type

/obj/item/light
	icon = 'icons/obj/lighting.dmi'
	force = 2
	throwforce = 5
	w_class = WEIGHT_CLASS_TINY
	var/status = LIGHT_OK		// LIGHT_OK, LIGHT_BURNED or LIGHT_BROKEN
	var/base_state
	var/switchcount = 0	// number of times switched
	materials = list(/datum/material/glass=100)
	grind_results = list(/datum/reagent/silicon = 5, /datum/reagent/nitrogen = 10) //Nitrogen is used as a cheaper alternative to argon in incandescent lighbulbs
	var/rigged = FALSE		// true if rigged to explode
	var/brightness = 2 //how much light it gives off

/obj/item/light/suicide_act(mob/living/carbon/user)
	if (status == LIGHT_BROKEN)
		user.visible_message(span_suicide("[user] begins to stab [user.p_them()]self with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
		return BRUTELOSS
	else
		user.visible_message(span_suicide("[user] begins to eat \the [src]! It looks like [user.p_theyre()] not very bright!"))
		shatter()
		return BRUTELOSS

/obj/item/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "ltube"
	base_state = "ltube"
	item_state = "c_tube"
	brightness = 8

/obj/item/light/tube/broken
	status = LIGHT_BROKEN

/obj/item/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "lbulb"
	base_state = "lbulb"
	item_state = "contvapour"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	brightness = 4

/obj/item/light/bulb/broken
	status = LIGHT_BROKEN

/obj/item/light/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..()) //not caught by a mob
		shatter()

// update the icon state and description of the light

/obj/item/light/proc/update()
	switch(status)
		if(LIGHT_OK)
			icon_state = base_state
			desc = "A replacement [name]."
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			desc = "A burnt-out [name]."
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			desc = "A broken [name]."

/obj/item/light/Initialize(mapload)
	. = ..()
	update()
	AddComponent(/datum/component/caltrop, force)

/obj/item/light/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(istype(L) && !(L.is_flying() || L.buckled))
		playsound(src, 'sound/effects/glass_step.ogg', HAS_TRAIT(L, TRAIT_LIGHT_STEP) ? 30 : 50, TRUE)
		if(status == LIGHT_BURNED || status == LIGHT_OK)
			shatter()

// attack bulb/tube with object
// if a syringe, can inject plasma to make it explode
/obj/item/light/attackby(obj/item/I, mob/user, params)
	..()
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I

		to_chat(user, span_notice("You inject the solution into \the [src]."))

		if(S.reagents.has_reagent(/datum/reagent/toxin/plasma, 5))

			rigged = TRUE

		S.reagents.clear_reagents()
	else
		..()
	return

/obj/item/light/attack(mob/living/M, mob/living/user, def_zone)
	..()
	shatter()

/obj/item/light/attack_obj(obj/O, mob/living/user)
	..()
	shatter()

/obj/item/light/proc/shatter()
	if(status == LIGHT_OK || status == LIGHT_BURNED)
		visible_message(span_danger("[src] shatters."),span_italics("You hear a small glass object shatter."))
		status = LIGHT_BROKEN
		force = 5
		playsound(src.loc, 'sound/effects/glasshit.ogg', 75, 1)
		if(rigged)
			atmos_spawn_air("plasma=5") //5u of plasma are required to rig a light bulb/tube
		update()


/obj/machinery/light/floor
	name = "floor light"
	icon = 'icons/obj/lighting.dmi'
	base_state = "floor"		// base description and icon_state
	icon_state = "floor"
	brightness = 4
	layer = LOW_OBJ_LAYER
	light_type = /obj/item/light/bulb
	fitting = "floor bulb"

/obj/item/floor_light
	name = "floor light frame"
	desc = "Used for building lights."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "floor-construct-stage1"

/obj/item/floor_light/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Use in-hand to place a [src].\n"

/obj/item/floor_light/attack_self(mob/user)
	if(!isturf(user.loc))
		to_chat(user, span_warning("You need more space to place a [src] here."))
		return
	if((locate(/obj/machinery/light/floor) in user.loc) || (locate(/obj/structure/light_construct/floor) in user.loc))
		to_chat(user, span_warning("There is already a [src] here."))
		return
	to_chat(user, span_notice("You anchor the [src] in place."))
	playsound(user, 'sound/machines/click.ogg', 50, 1)
	var/obj/structure/light_construct/floor/M = new(user.loc)
	transfer_fingerprints_to(M)
	qdel(src)

/proc/flicker_all_lights()
	for(var/obj/machinery/light/L in GLOB.machines)
		if(is_station_level(L.z))
			addtimer(CALLBACK(L, TYPE_PROC_REF(/obj/machinery/light, flicker), rand(3, 6)), rand(0, 15))

#undef LIGHT_ON_DELAY_UPPER
#undef LIGHT_ON_DELAY_LOWER
