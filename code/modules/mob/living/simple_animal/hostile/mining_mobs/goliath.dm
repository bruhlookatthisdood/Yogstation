//A slow but strong beast that tries to stun using its tentacles
/mob/living/simple_animal/hostile/asteroid/goliath
	name = "goliath"
	desc = "A massive beast that uses long tentacles to ensnare its prey, threatening them is not advised under any conditions."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Goliath"
	icon_living = "Goliath"
	icon_aggro = "Goliath_alert"
	icon_dead = "Goliath_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	move_to_delay = 40
	ranged = 1
	ranged_cooldown_time = 120
	friendly = "wails at"
	speak_emote = list("bellows")
	vision_range = 4
	speed = 3
	maxHealth = 300
	health = 300
	harm_intent_damage = 0
	obj_damage = 100
	melee_damage_lower = 25
	melee_damage_upper = 25
	attacktext = "pulverizes"
	attack_sound = 'sound/weapons/punch1.ogg'
	throw_message = "does nothing to the rocky hide of the"
	vision_range = 5
	aggro_vision_range = 9
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	loot = list(/obj/item/stack/sheet/animalhide/goliath_hide)
	footstep_type = FOOTSTEP_MOB_HEAVY
	var/pre_attack = 0
	var/pre_attack_icon = "Goliath_preattack"

/mob/living/simple_animal/hostile/asteroid/goliath/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	handle_preattack()

/mob/living/simple_animal/hostile/asteroid/goliath/proc/handle_preattack()
	if(ranged_cooldown <= world.time + ranged_cooldown_time*0.25 && !pre_attack)
		pre_attack++
	if(!pre_attack || stat || AIStatus == AI_IDLE)
		return
	icon_state = pre_attack_icon

/mob/living/simple_animal/hostile/asteroid/goliath/revive(full_heal = 0, admin_revive = 0)
	if(..())
		anchored = TRUE
		. = 1

/mob/living/simple_animal/hostile/asteroid/goliath/death(gibbed)
	move_force = MOVE_FORCE_DEFAULT
	move_resist = MOVE_RESIST_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	..(gibbed)

/mob/living/simple_animal/hostile/asteroid/goliath/OpenFire()
	var/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	if(get_dist(src, target) <= 7)//Screen range check, so you can't get tentacle'd offscreen
		visible_message(span_warning("[src] digs its tentacles under [target]!"))
		new /obj/effect/temp_visual/goliath_tentacle/original(tturf, src)
		ranged_cooldown = world.time + ranged_cooldown_time
		icon_state = icon_aggro
		pre_attack = 0

/mob/living/simple_animal/hostile/asteroid/goliath/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	ranged_cooldown -= 10
	handle_preattack()
	. = ..()

/mob/living/simple_animal/hostile/asteroid/goliath/Aggro()
	vision_range = aggro_vision_range
	handle_preattack()
	if(icon_state != icon_aggro)
		icon_state = icon_aggro

//Lavaland Goliath
/mob/living/simple_animal/hostile/asteroid/goliath/beast
	name = "goliath"
	desc = "A hulking, armor-plated beast with long tendrils arching from its back."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "goliath"
	icon_living = "goliath"
	icon_aggro = "goliath"
	icon_dead = "goliath_dead"
	throw_message = "does nothing to the tough hide of the"
	pre_attack_icon = "goliath2"
	crusher_loot = /obj/item/crusher_trophy/goliath_tentacle
	crusher_drop_mod = 10
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/goliath = 2, /obj/item/stack/sheet/bone = 2)
	guaranteed_butcher_results = list(/obj/item/stack/sheet/animalhide/goliath_hide = 1)
	loot = list()
	stat_attack = UNCONSCIOUS
	robust_searching = 1

/mob/living/simple_animal/hostile/asteroid/goliath/beast/random/Initialize(mapload)
	. = ..()
	if(prob(1))
		new /mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient(loc)
		return INITIALIZE_HINT_QDEL

/mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient
	name = "ancient goliath"
	desc = "Goliaths are biologically immortal, and rare specimens have survived for centuries. This one is clearly ancient, and its tentacles constantly churn the earth around it."
	icon_state = "Goliath"
	icon_living = "Goliath"
	icon_aggro = "Goliath_alert"
	icon_dead = "Goliath_dead"
	maxHealth = 400
	health = 400
	speed = 4
	pre_attack_icon = "Goliath_preattack"
	throw_message = "does nothing to the rocky hide of the"
	loot = list(/obj/item/stack/sheet/animalhide/goliath_hide) //A throwback to the asteroid days
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/goliath = 2, /obj/item/stack/sheet/bone = 2)
	guaranteed_butcher_results = list()
	crusher_drop_mod = 30
	wander = FALSE
	var/list/cached_tentacle_turfs
	var/turf/last_location
	var/tentacle_recheck_cooldown = 100

/mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!.) // dead
		return
	if(isturf(loc))
		if(!LAZYLEN(cached_tentacle_turfs) || loc != last_location || tentacle_recheck_cooldown <= world.time)
			LAZYCLEARLIST(cached_tentacle_turfs)
			last_location = loc
			tentacle_recheck_cooldown = world.time + initial(tentacle_recheck_cooldown)
			for(var/turf/open/T in orange(4, loc))
				LAZYADD(cached_tentacle_turfs, T)
		for(var/t in cached_tentacle_turfs)
			if(isopenturf(t))
				if(prob(10))
					new /obj/effect/temp_visual/goliath_tentacle(t, src)
			else
				cached_tentacle_turfs -= t

/mob/living/simple_animal/hostile/asteroid/goliath/beast/tendril
	fromtendril = TRUE

/mob/living/simple_animal/hostile/asteroid/goliath/beast/joe
	name = "Joe"
	desc = "The mining team's pet goliath! Usually found hard at work at the coin press."
	response_help = "pets"
	crusher_loot = null
	guaranteed_butcher_results = list() //no plates from joe
	move_force = MOVE_FORCE_DEFAULT
	move_resist = MOVE_RESIST_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	faction = list("neutral")
	environment_smash = ENVIRONMENT_SMASH_NONE

//tentacles
/obj/effect/temp_visual/goliath_tentacle
	name = "goliath tentacle"
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Goliath_tentacle_spawn"
	layer = BELOW_MOB_LAYER
	var/mob/living/spawner

/obj/effect/temp_visual/goliath_tentacle/Initialize(mapload, mob/living/new_spawner)
	. = ..()
	for(var/obj/effect/temp_visual/goliath_tentacle/T in loc)
		if(T != src)
			return INITIALIZE_HINT_QDEL
	if(!QDELETED(new_spawner))
		spawner = new_spawner
	if(ismineralturf(loc))
		var/turf/closed/mineral/M = loc
		M.attempt_drill()
	deltimer(timerid)
	timerid = addtimer(CALLBACK(src, PROC_REF(tripanim)), 7, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/original/Initialize(mapload, new_spawner)
	. = ..()
	var/list/turf/turfs = circle_range_turfs(get_turf(src), 2)
	for(var/i in 1 to rand(4, 10))
		var/turf/T = pick_n_take(turfs)
		new /obj/effect/temp_visual/goliath_tentacle(T, spawner)

/obj/effect/temp_visual/goliath_tentacle/proc/tripanim()
	icon_state = "Goliath_tentacle_wiggle"
	deltimer(timerid)
	timerid = addtimer(CALLBACK(src, PROC_REF(trip)), 3, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/proc/trip()
	var/latched = FALSE
	for(var/mob/living/L in loc)
		if((!QDELETED(spawner) && spawner.faction_check_mob(L)) || L.stat == DEAD)
			continue
		visible_message(span_danger("[src] grabs hold of [L]!"))
		if(!L.IsStun())
			L.Stun(100)
		else
			L.AdjustStun(20)
		L.adjustBruteLoss(rand(10,15))
		latched = TRUE
	if(!latched)
		retract()
	else
		deltimer(timerid)
		timerid = addtimer(CALLBACK(src, PROC_REF(retract)), 10, TIMER_STOPPABLE)

/obj/effect/temp_visual/goliath_tentacle/proc/retract()
	icon_state = "Goliath_tentacle_retract"
	deltimer(timerid)
	timerid = QDEL_IN(src, 7)
