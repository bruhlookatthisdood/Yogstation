//Space bears!
/mob/living/simple_animal/hostile/bear
	name = "space bear"
	desc = "You don't need to be faster than a space bear, you just need to outrun your crewmates."
	icon_state = "bear"
	icon_living = "bear"
	icon_dead = "bear_dead"
	icon_gib = "bear_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("RAWR!","Rawr!","GRR!","Growl!")
	speak_emote = list("growls", "roars")
	emote_hear = list("rawrs.","grumbles.","grawls.")
	emote_taunt = list("stares ferociously", "stomps")
	speak_chance = 1
	taunt_chance = 25
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/bear = 5, /obj/item/clothing/head/bearpelt = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "hits"
	maxHealth = 60
	health = 60
	spacewalk = TRUE
	var/armored = FALSE

	obj_damage = 60
	melee_damage_lower = 15 // i know it's like half what it used to be, but bears cause bleeding like crazy now so it works out
	melee_damage_upper = 15
	attack_vis_effect = ATTACK_EFFECT_CLAW
	wound_bonus = -5
	bare_wound_bonus = 10 // BEAR wound bonus am i right
	sharpness = SHARP_EDGED
	attacktext = "claws"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	friendly = "bear hugs"

	//Space bears aren't affected by cold.
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500

	faction = list("russian")
	gold_core_spawnable = HOSTILE_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW

/mob/living/simple_animal/hostile/bear/loan
	faction = list("hostile")

//SPACE BEARS! SQUEEEEEEEE~     OW! FUCK! IT BIT MY HAND OFF!!
/mob/living/simple_animal/hostile/bear/Hudson
	name = "Hudson"
	gender = MALE
	desc = "Feared outlaw, this guy is one bad news bear." //I'm sorry...

/mob/living/simple_animal/hostile/bear/snow
	name = "space polar bear"
	icon_state = "snowbear"
	icon_living = "snowbear"
	icon_dead = "snowbear_dead"
	desc = "It's a polar bear, in space, but not actually in space."
	weather_immunities = list(WEATHER_SNOW)

/mob/living/simple_animal/hostile/bear/russian
	name = "combat bear"
	desc = "A ferocious brown bear decked out in armor plating, a red star with yellow outlining details the shoulder plating."
	icon_state = "combatbear"
	icon_living = "combatbear"
	icon_dead = "combatbear_dead"
	faction = list("russian")
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/bear = 5, /obj/item/clothing/head/bearpelt = 1, /obj/item/bear_armor = 1)
	melee_damage_lower = 18
	melee_damage_upper = 20
	wound_bonus = 0
	armour_penetration = 20
	health = 120
	maxHealth = 120
	armored = TRUE

/mob/living/simple_animal/hostile/bear/russian/sentience_act()
	faction -= "russian"

/mob/living/simple_animal/hostile/bear/update_icons()
	..()
	if(armored)
		add_overlay("armor_bear")

/obj/item/bear_armor
	name = "pile of bear armor"
	desc = "A scattered pile of various shaped armor pieces fitted for a bear, some duct tape, and a nail filer. Crude instructions \
		are written on the back of one of the plates in russian. This seems like an awful idea."
	icon_state = "bear_armor_upgrade"

/obj/item/bear_armor/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(istype(target, /mob/living/simple_animal/hostile/bear) && proximity_flag)
		var/mob/living/simple_animal/hostile/bear/A = target
		if(A.armored)
			to_chat(user, span_warning("[A] has already been armored up!"))
			return
		A.armored = TRUE
		A.maxHealth += 60
		A.health += 60
		A.armour_penetration += 20
		A.melee_damage_lower += 3
		A.melee_damage_upper += 5
		A.wound_bonus += 5
		A.update_icons()
		to_chat(user, span_info("You strap the armor plating to [A] and sharpen [A.p_their()] claws with the nail filer. This was a great idea."))
		qdel(src)
























