/mob/living/simple_animal/hostile/construct
	name = "Construct"
	real_name = "Construct"
	desc = ""
	gender = NEUTER
	mob_biotypes = MOB_INORGANIC
	speak_emote = list("hisses")
	response_help  = "thinks better of touching"
	response_disarm = "flails at"
	response_harm   = "punches"
	speak_chance = 1
	icon = 'icons/mob/nonhuman-player/cult.dmi'
	speed = 0
	spacewalk = TRUE
	a_intent = INTENT_HARM
	stop_automated_movement = 1
	status_flags = CANPUSH
	attack_sound = 'sound/weapons/punch1.ogg'
	see_in_dark = 7
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	healable = 0
	faction = list("cult")
	movement_type = FLYING
	pressure_resistance = 100
	unique_name = 1
	AIStatus = AI_OFF //normal constructs don't have AI
	loot = list(/obj/item/ectoplasm)
	del_on_death = TRUE
	initial_language_holder = /datum/language_holder/construct
	deathmessage = "collapses in a shattered heap."
	hud_type = /datum/hud/constructs
	var/list/construct_spells = list()
	var/playstyle_string = "<span class='big bold'>You are a generic construct!</span><b> Your job is to not exist, and you should probably adminhelp this.</b>"
	var/master = null
	var/seeking = FALSE
	var/can_repair_constructs = FALSE
	var/can_repair_self = FALSE
	/// Theme controls color. THEME_CULT is red THEME_WIZARD is purple and THEME_HOLY is blue
	var/theme = THEME_CULT

/mob/living/simple_animal/hostile/construct/Initialize(mapload)
	. = ..()
	update_health_hud()
	for(var/spell in construct_spells)
		var/datum/action/new_spell = new spell(src)
		new_spell.Grant(src)

	var/spellnum = 1
	for(var/datum/action/spell as anything in actions)
		if(!(type in construct_spells))
			continue

		var/pos = 2 + spellnum * 31
		if(construct_spells.len >= 4)
			pos -= 31 * (construct_spells.len - 4)
		spell.default_button_position = "6:[pos],4:-2" // Set the default position to this random position
		spellnum++
		update_action_buttons()

	if(icon_state)
		add_overlay("glow_[icon_state]_[theme]")

/mob/living/simple_animal/hostile/construct/Login()
	..()
	to_chat(src, playstyle_string)

/mob/living/simple_animal/hostile/construct/examine(mob/user)
	var/t_He = p_they(TRUE)
	var/t_s = p_s()
	var/text_span
	switch(theme)
		if(THEME_CULT)
			text_span = "cult"
		if(THEME_WIZARD)
			text_span = "purple"
		if(THEME_HOLY)
			text_span = "blue"
	. = list("<span class='[text_span]'>This is [icon2html(src, user)] \a <b>[src]</b>!\n[desc]")
	if(health < maxHealth)
		if(health >= maxHealth/2)
			. += span_warning("[t_He] look[t_s] slightly dented.")
		else
			. += span_warning("<b>[t_He] look[t_s] severely dented!</b>")
	. += "</span>"

/mob/living/simple_animal/hostile/construct/attack_animal(mob/living/simple_animal/M)
	if(isconstruct(M)) //is it a construct?
		var/mob/living/simple_animal/hostile/construct/C = M
		if(!C.can_repair_constructs || (C == src && !C.can_repair_self))
			return
		if(health < maxHealth)
			adjustHealth(-5)
			if(src != M)
				Beam(M,icon_state="sendbeam",time=4)
				M.visible_message(span_danger("[M] repairs some of \the <b>[src]'s</b> dents."), \
						   span_cult("You repair some of <b>[src]'s</b> dents, leaving <b>[src]</b> at <b>[health]/[maxHealth]</b> health."))
			else
				M.visible_message(span_danger("[M] repairs some of [p_their()] own dents."), \
						   span_cult("You repair some of your own dents, leaving you at <b>[M.health]/[M.maxHealth]</b> health."))
		else
			if(src != M)
				to_chat(M, span_cult("You cannot repair <b>[src]'s</b> dents, as [p_they()] [p_have()] none!"))
			else
				to_chat(M, span_cult("You cannot repair your own dents, as you have none!"))
	else if(src != M)
		return ..()

/mob/living/simple_animal/hostile/construct/narsie_act()
	return

/mob/living/simple_animal/hostile/construct/electrocute_act(shock_damage, obj/source, siemens_coeff = 1, zone = null, override = FALSE, tesla_shock = FALSE, illusion = FALSE, stun = TRUE, gib = FALSE)
	return 0

/mob/living/simple_animal/hostile/construct/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(updating_health)
		update_health_hud()

mob/living/simple_animal/hostile/construct/attackby(obj/item/W, mob/living/user, params)
	. = ..()
	if(istype(W, /obj/item/nullrod))
		visible_message(span_warning("[src] recoils from the blow!"), \
						span_cult("As \the [W] hits you, you feel holy power blast through your form, tearing it apart!"))
		adjustBruteLoss(45)

/////////////////Juggernaut///////////////
/mob/living/simple_animal/hostile/construct/armored
	name = "Juggernaut"
	real_name = "Juggernaut"
	desc = "A massive, armored construct built to spearhead attacks and soak up enemy fire."
	icon_state = "juggernaut"
	icon_living = "juggernaut"
	maxHealth = 150
	health = 150
	response_harm = "harmlessly punches"
	harm_intent_damage = 0
	obj_damage = 90
	melee_damage_lower = 25
	melee_damage_upper = 25
	attacktext = "smashes their armored gauntlet into"
	speed = 2.5
	environment_smash = ENVIRONMENT_SMASH_WALLS
	attack_sound = 'sound/weapons/punch3.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	force_threshold = 10
	construct_spells = list(
		/datum/action/cooldown/spell/forcewall/cult,
		/datum/action/cooldown/spell/basic_projectile/juggernaut,
		/datum/action/innate/cult/create_rune/wall,
	)
	playstyle_string = "<b>You are a Juggernaut. Though slow, your shell can withstand heavy punishment, \
						create shield walls, rip apart enemies and walls alike, and even deflect energy weapons.</b>"

/mob/living/simple_animal/hostile/construct/armored/hostile //actually hostile, will move around, hit things
	AIStatus = AI_ON
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //only token destruction, don't smash the cult wall NO STOP

/mob/living/simple_animal/hostile/construct/armored/bullet_act(obj/projectile/P)
	if(istype(P, /obj/projectile/energy) || istype(P, /obj/projectile/beam))
		var/reflectchance = 40 - round(P.damage/3)
		if(prob(reflectchance))
			apply_damage(P.damage * 0.5, P.damage_type)
			visible_message(span_danger("The [P.name] is reflected by [src]'s armored shell!"), \
							span_userdanger("The [P.name] is reflected by your armored shell!"))

			// Find a turf near or on the original location to bounce to
			if(P.starting)
				var/new_x = P.starting.x + pick(0, 0, -1, 1, -2, 2, -2, 2, -2, 2, -3, 3, -3, 3)
				var/new_y = P.starting.y + pick(0, 0, -1, 1, -2, 2, -2, 2, -2, 2, -3, 3, -3, 3)
				var/turf/curloc = get_turf(src)

				// redirect the projectile
				P.original = locate(new_x, new_y, P.z)
				P.starting = curloc
				P.firer = src
				P.yo = new_y - curloc.y
				P.xo = new_x - curloc.x
				var/new_angle_s = P.Angle + rand(120,240)
				while(new_angle_s > 180)	// Translate to regular projectile degrees
					new_angle_s -= 360
				P.setAngle(new_angle_s)

			return BULLET_ACT_FORCE_PIERCE // complete projectile permutation

	return ..()

//////////////////////////Angelic-Juggernaut////////////////////////////
/mob/living/simple_animal/hostile/construct/armored/angelic
	theme = THEME_HOLY
	loot = list(/obj/item/ectoplasm/angelic)

/mob/living/simple_animal/hostile/construct/armored/noncult

////////////////////////Wraith/////////////////////////////////////////////
/mob/living/simple_animal/hostile/construct/wraith
	name = "Wraith"
	real_name = "Wraith"
	desc = "A wicked, clawed shell constructed to assassinate enemies and sow chaos behind enemy lines."
	icon_state = "wraith"
	icon_living = "wraith"
	maxHealth = 65
	health = 65
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_vis_effect = ATTACK_EFFECT_SLASH
	retreat_distance = 2 //AI wraiths will move in and out of combat
	attacktext = "slashes"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	construct_spells = list(
		/datum/action/cooldown/spell/jaunt/ethereal_jaunt/shift,
		/datum/action/innate/cult/create_rune/tele,
	)
	playstyle_string = "<b>You are a Wraith. Though relatively fragile, you are fast, deadly, \
		can phase through walls, and your attacks will lower the cooldown on phasing.</b>"

	// Accomplishing various things gives you a refund on jaunt, to jump in and out.
	/// The seconds refunded per attack
	var/attack_refund = 1 SECONDS
	/// The seconds refunded when putting a target into critical
	var/crit_refund = 5 SECONDS

/mob/living/simple_animal/hostile/construct/wraith/AttackingTarget() //refund jaunt cooldown when attacking living targets
	var/prev_stat
	var/mob/living/living_target = target
	if(isliving(target) && !iscultist(target))
		var/mob/living/L = target
		prev_stat = L.stat

	. = ..()

	if(. && isnum(prev_stat))
		var/datum/action/cooldown/spell/jaunt/ethereal_jaunt/shift/jaunt = locate() in actions
		if(!jaunt)
			return

		var/total_refund = 0 SECONDS
		// they're dead, and you killed them - full refund
		if(QDELETED(living_target) || (living_target.stat == DEAD && prev_stat != DEAD))
			total_refund += jaunt.cooldown_time
		// you knocked them into critical
		else if(living_target.stat == UNCONSCIOUS && prev_stat == CONSCIOUS)
			total_refund += crit_refund

		if(living_target.stat != DEAD && prev_stat != DEAD)
			total_refund += attack_refund

		jaunt.next_use_time -= total_refund
		jaunt.build_all_button_icons()

/mob/living/simple_animal/hostile/construct/wraith/hostile //actually hostile, will move around, hit things
	AIStatus = AI_ON

//////////////////////////Angelic-Wraith////////////////////////////
/mob/living/simple_animal/hostile/construct/wraith/angelic
	theme = THEME_HOLY
	loot = list(/obj/item/ectoplasm/angelic)
	construct_spells = list(
		/datum/action/cooldown/spell/jaunt/ethereal_jaunt/shift/angelic,
		/datum/action/innate/cult/create_rune/tele,
	)

/mob/living/simple_animal/hostile/construct/wraith/noncult

/////////////////////////////Artificer/////////////////////////
/mob/living/simple_animal/hostile/construct/builder
	name = "Artificer"
	real_name = "Artificer"
	desc = "A bulbous construct dedicated to building and maintaining the Cult of Nar'sie's armies."
	icon_state = "artificer"
	icon_living = "artificer"
	maxHealth = 50
	health = 50
	response_harm = "viciously beats"
	harm_intent_damage = 5
	obj_damage = 60
	melee_damage_lower = 5
	melee_damage_upper = 5
	retreat_distance = 10
	minimum_distance = 10 //AI artificers will flee like fuck
	attacktext = "rams"
	environment_smash = ENVIRONMENT_SMASH_WALLS
	attack_sound = 'sound/weapons/punch2.ogg'
	construct_spells = list(
		/datum/action/cooldown/spell/conjure/cult_floor,
		/datum/action/cooldown/spell/conjure/cult_wall,
		/datum/action/cooldown/spell/conjure/soulstone,
		/datum/action/cooldown/spell/conjure/construct/lesser,
		/datum/action/cooldown/spell/aoe/magic_missile/lesser,
		/datum/action/innate/cult/create_rune/revive,
	)
	playstyle_string = "<b>You are an Artificer. You are incredibly weak and fragile, \
		but you are able to construct fortifications, use magic missile, and repair allied constructs, shades, \
		and yourself (by clicking on them). Additionally, <i>and most important of all,</i> you can create new constructs \
		by producing soulstones to capture souls, and shells to place those soulstones into.</b>"
	can_repair_constructs = TRUE
	can_repair_self = TRUE

/mob/living/simple_animal/hostile/construct/builder/Found(atom/A) //what have we found here?
	if(isconstruct(A)) //is it a construct?
		var/mob/living/simple_animal/hostile/construct/C = A
		if(C.health < C.maxHealth) //is it hurt? let's go heal it if it is
			return 1
		else
			return 0
	else
		return 0

/mob/living/simple_animal/hostile/construct/builder/CanAttack(atom/the_target)
	if(see_invisible < the_target.invisibility)//Target's invisible to us, forget it
		return 0
	if(Found(the_target) || ..()) //If we Found it or Can_Attack it normally, we Can_Attack it as long as it wasn't invisible
		return 1 //as a note this shouldn't be added to base hostile mobs because it'll mess up retaliate hostile mobs

/mob/living/simple_animal/hostile/construct/builder/MoveToTarget(list/possible_targets)
	..()
	if(isliving(target))
		var/mob/living/L = target
		if(isconstruct(L) && L.health >= L.maxHealth) //is this target an unhurt construct? stop trying to heal it
			LoseTarget()
			return 0
		if(L.health <= melee_damage_lower+melee_damage_upper) //ey bucko you're hurt as fuck let's go hit you
			retreat_distance = null
			minimum_distance = 1

/mob/living/simple_animal/hostile/construct/builder/Aggro()
	..()
	if(isconstruct(target)) //oh the target is a construct no need to flee
		retreat_distance = null
		minimum_distance = 1

/mob/living/simple_animal/hostile/construct/builder/LoseAggro()
	..()
	retreat_distance = initial(retreat_distance)
	minimum_distance = initial(minimum_distance)

/mob/living/simple_animal/hostile/construct/builder/hostile //actually hostile, will move around, hit things, heal other constructs
	AIStatus = AI_ON
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //only token destruction, don't smash the cult wall NO STOP

/////////////////////////////Angelic Artificer/////////////////////////
/mob/living/simple_animal/hostile/construct/builder/angelic
	theme = THEME_HOLY
	loot = list(/obj/item/ectoplasm/angelic)
	construct_spells = list(
		/datum/action/cooldown/spell/conjure/soulstone/purified,
		/datum/action/cooldown/spell/conjure/construct/lesser,
		/datum/action/cooldown/spell/aoe/magic_missile/lesser,
		/datum/action/innate/cult/create_rune/revive,
	)

/mob/living/simple_animal/hostile/construct/builder/noncult
	construct_spells = list(
		/datum/action/cooldown/spell/conjure/cult_floor,
		/datum/action/cooldown/spell/conjure/cult_wall,
		/datum/action/cooldown/spell/conjure/soulstone/noncult,
		/datum/action/cooldown/spell/conjure/construct/lesser,
		/datum/action/cooldown/spell/aoe/magic_missile/lesser,
		/datum/action/innate/cult/create_rune/revive,
	)

/////////////////////////////Harvester/////////////////////////
/mob/living/simple_animal/hostile/construct/harvester
	name = "Harvester"
	real_name = "Harvester"
	desc = "A long, thin construct built to herald Nar'sie's rise. It'll be all over soon."
	icon_state = "harvester"
	icon_living = "harvester"
	maxHealth = 40
	health = 40
	sight = SEE_MOBS
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_vis_effect = ATTACK_EFFECT_SLASH
	attacktext = "butchers"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	construct_spells = list(
		/datum/action/cooldown/spell/aoe/area_conversion,
		/datum/action/cooldown/spell/forcewall/cult,
		/datum/action/cooldown/spell/jaunt/ethereal_jaunt/shift,
	)
	playstyle_string = "<B>You are a Harvester. You are incapable of directly killing humans, but your attacks will remove their limbs: \
						Bring those who still cling to this world of illusion back to the Geometer so they may know Truth. Your form and any you are pulling can pass through runed walls effortlessly.</B>"
	can_repair_constructs = TRUE


/mob/living/simple_animal/hostile/construct/harvester/Bump(atom/AM)
	. = ..()
	if(istype(AM, /turf/closed/wall/mineral/cult) && AM != loc) //we can go through cult walls
		var/atom/movable/stored_pulling = pulling
		if(stored_pulling)
			stored_pulling.setDir(get_dir(stored_pulling.loc, loc))
			stored_pulling.forceMove(loc)
		forceMove(AM)
		if(stored_pulling)
			start_pulling(stored_pulling, supress_message = TRUE) //drag anything we're pulling through the wall with us by magic

/mob/living/simple_animal/hostile/construct/harvester/AttackingTarget()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(HAS_TRAIT(C, TRAIT_NODISMEMBER))
			return ..()		//ATTACK!
		var/list/parts = list()
		var/undismembermerable_limbs = 0
		for(var/X in C.bodyparts)
			var/obj/item/bodypart/BP = X
			if(BP.body_part != HEAD && BP.body_part != CHEST)
				if(BP.dismemberable)
					parts += BP
				else
					undismembermerable_limbs++
		if(!LAZYLEN(parts))
			if(undismembermerable_limbs) //they have limbs we can't remove, and no parts we can, attack!
				return ..()
			C.Paralyze(60)
			visible_message(span_danger("[src] knocks [C] down!"))
			to_chat(src, span_cultlarge("\"Bring [C.p_them()] to me.\""))
			return FALSE
		do_attack_animation(C)
		var/obj/item/bodypart/BP = pick(parts)
		BP.dismember()
		return FALSE
	. = ..()

/mob/living/simple_animal/hostile/construct/harvester/Initialize(mapload)
	. = ..()
	var/datum/action/innate/seek_prey/seek = new()
	seek.Grant(src)
	seek.Activate()

///////////////////////Master-Tracker///////////////////////

/datum/action/innate/seek_master
	name = "Seek your Master"
	desc = "You and your master share a soul-link that informs you of their location"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"

	buttontooltipstyle = "cult"
	button_icon = "icons/mob/actions/actions_cult.dmi"
	button_icon_state = "cult_mark"
	var/tracking = FALSE
	var/mob/living/simple_animal/hostile/construct/the_construct


/datum/action/innate/seek_master/Grant(mob/living/C)
	the_construct = C
	..()

/datum/action/innate/seek_master/Activate()
	var/datum/antagonist/cult/C = owner.mind.has_antag_datum(/datum/antagonist/cult)
	if(!C)
		return
	var/datum/objective/eldergod/summon_objective = locate() in C.cult_team.objectives

	if(summon_objective.check_completion())
		the_construct.master = C.cult_team.blood_target

	if(!the_construct.master)
		to_chat(the_construct, "<span class='cult italic'>You have no master to seek!</span>")
		the_construct.seeking = FALSE
		return
	if(tracking)
		tracking = FALSE
		the_construct.seeking = FALSE
		to_chat(the_construct, "<span class='cult italic'>You are no longer tracking your master.</span>")
		return
	else
		tracking = TRUE
		the_construct.seeking = TRUE
		to_chat(the_construct, "<span class='cult italic'>You are now tracking your master.</span>")


/datum/action/innate/seek_prey
	name = "Seek the Harvest"
	desc = "None can hide from Nar'sie, activate to track a survivor attempting to flee the red harvest!"
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"

	buttontooltipstyle = "cult"
	button_icon_state = "cult_mark"
	var/mob/living/simple_animal/hostile/construct/harvester/the_construct

/datum/action/innate/seek_prey/Grant(mob/living/C)
	the_construct = C
	..()

/datum/action/innate/seek_prey/Activate()
	if(GLOB.cult_narsie == null)
		return
	if(the_construct.seeking)
		desc = "None can hide from Nar'sie, activate to track a survivor attempting to flee the red harvest!"
		button_icon_state = "cult_mark"
		the_construct.seeking = FALSE
		to_chat(the_construct, "<span class='cult italic'>You are now tracking Nar'sie, return to reap the harvest!</span>")
		return
	else
		if(LAZYLEN(GLOB.cult_narsie.souls_needed))
			the_construct.master = pick(GLOB.cult_narsie.souls_needed)
			var/mob/living/real_target = the_construct.master //We can typecast this way because Nar'sie only allows /mob/living into the souls list
			to_chat(the_construct, "<span class='cult italic'>You are now tracking your prey, [real_target.real_name] - harvest [real_target.p_them()]!</span>")
		else
			to_chat(the_construct, "<span class='cult italic'>Nar'sie has completed her harvest!</span>")
			return
		desc = "Activate to track Nar'sie!"
		button_icon_state = "sintouch"
		the_construct.seeking = TRUE


/////////////////////////////ui stuff/////////////////////////////

/mob/living/simple_animal/hostile/construct/update_health_hud()
	if(hud_used)
		if(health >= maxHealth)
			hud_used.healths.icon_state = "[icon_state]_health0"
		else if(health > maxHealth*0.8)
			hud_used.healths.icon_state = "[icon_state]_health2"
		else if(health > maxHealth*0.6)
			hud_used.healths.icon_state = "[icon_state]_health3"
		else if(health > maxHealth*0.4)
			hud_used.healths.icon_state = "[icon_state]_health4"
		else if(health > maxHealth*0.2)
			hud_used.healths.icon_state = "[icon_state]_health5"
		else
			hud_used.healths.icon_state = "[icon_state]_health6"
