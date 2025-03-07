/obj/item/organ/brain
	name = "brain"
	desc = "A piece of juicy meat found in a person's head."
	icon_state = "brain"
	visual = TRUE
	throw_speed = 3
	throw_range = 5
	layer = ABOVE_MOB_LAYER
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_BRAIN
	organ_flags = ORGAN_VITAL
	attack_verb = list("attacked", "slapped", "whacked")
	///The brain's organ variables are significantly more different than the other organs, with half the decay rate for balance reasons, and twice the maxHealth
	decay_factor = STANDARD_ORGAN_DECAY	* 0.5			//30 minutes of decaying to result in a fully damaged brain, since a fast decay rate would be unfun gameplay-wise
	maxHealth = BRAIN_DAMAGE_DEATH
	low_threshold = 45
	high_threshold = 120
	var/suicided = FALSE
	var/mob/living/brain/brainmob = null
	var/brain_death = FALSE //if the brainmob was intentionally killed by attacking the brain after removal, or by severe braindamage
	var/decoy_override = FALSE	//if it's a fake brain with no brainmob assigned. Feedback messages will be faked as if it does have a brainmob. See changelings & dullahans.
	//two variables necessary for calculating whether we get a brain trauma or not
	var/damage_delta = 0
	/// Times how long the brain has been decaying for, used for memory loss
	var/decay_progress = 0
	/// Times how many times process has been run, used for stasis calculations
	var/process_count = 0

	var/list/datum/brain_trauma/traumas = list()

/obj/item/organ/brain/Insert(mob/living/carbon/C, special = 0,no_id_transfer = FALSE)
	..()

	name = initial(name)

	if(C.mind && C.mind.has_antag_datum(/datum/antagonist/changeling) && !no_id_transfer)	//congrats, you're trapped in a body you don't control
		if(brainmob && !(C.stat == DEAD || (HAS_TRAIT(C, TRAIT_DEATHCOMA))))
			to_chat(brainmob, "<span class = danger>You can't feel your body! You're still just a brain!</span>")
		forceMove(C)
		C.update_hair()
		return

	if(brainmob)
		if(C.key)
			C.ghostize()

		if(brainmob.mind)
			brainmob.mind.transfer_to(C)
		else
			C.key = brainmob.key

		QDEL_NULL(brainmob)

	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		BT.owner = owner
		BT.on_gain()

	/// Re-add the mindslave datum because we "lost" it when we got decapitated
	for(var/obj/item/implant/mindslave/ms_implant in C.implants)
		ms_implant.slave_mob(C)

	//Update the body's icon so it doesnt appear debrained anymore
	C.update_hair()

/obj/item/organ/brain/Remove(mob/living/carbon/C, special = FALSE, no_id_transfer = FALSE)
	..()
	if(!special)
		if(C.has_horror_inside())
			var/mob/living/simple_animal/horror/B = C.has_horror_inside()
			B.leave_victim()
		if(C.mind && C.mind.has_antag_datum(/datum/antagonist/changeling))
			var/datum/antagonist/changeling/bruh = C.mind.has_antag_datum(/datum/antagonist/changeling)
			for(var/d in bruh.purchasedpowers)
				if(istype(d, /datum/action/changeling/fakedeath))
					var/datum/action/changeling/fakedeath/ack = d
					ack.sting_action(C)

	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		BT.on_lose(TRUE)
		BT.owner = null

	if((!gc_destroyed || (owner && !owner.gc_destroyed)) && !no_id_transfer)
		transfer_identity(C)
	C.update_hair()

/obj/item/organ/brain/prepare_eat(mob/living/carbon/human/H)
	if(iszombie(H))//braaaaaains... otherwise, too important to eat.
		..()

/obj/item/organ/brain/proc/transfer_identity(mob/living/L)
	name = "[L.name]'s brain"
	if(brainmob || decoy_override)
		return
	if(!L.mind)
		return
	brainmob = new(src)
	brainmob.name = L.real_name
	brainmob.real_name = L.real_name
	brainmob.timeofhostdeath = L.timeofdeath
	brainmob.suiciding = suicided
	if(L.has_dna())
		var/mob/living/carbon/C = L
		if(!brainmob.stored_dna)
			brainmob.stored_dna = new /datum/dna/stored(brainmob)
		C.dna.copy_dna(brainmob.stored_dna)
		if(HAS_TRAIT(L, TRAIT_BADDNA))
			brainmob.status_traits[TRAIT_BADDNA] = L.status_traits[TRAIT_BADDNA]
		if(HAS_TRAIT(L, TRAIT_NOCLONE)) // YOU CAN'T ESCAPE
			brainmob.status_traits[TRAIT_NOCLONE] = L.status_traits[TRAIT_NOCLONE]
		var/obj/item/organ/zombie_infection/ZI = L.getorganslot(ORGAN_SLOT_ZOMBIE)
		if(ZI)
			brainmob.set_species(ZI.old_species)	//For if the brain is cloned
	if(L.mind && L.mind.current)
		L.mind.transfer_to(brainmob)
	to_chat(brainmob, span_notice("You feel slightly disoriented. That's normal when you're just a brain."))

/obj/item/organ/brain/attackby(obj/item/O, mob/user, params)
	user.changeNext_move(CLICK_CD_MELEE)

	if(istype(O, /obj/item/organ_storage))
		return //Borg organ bags shouldn't be killing brains

	if((organ_flags & ORGAN_FAILING) && O.is_drainable() && O.reagents.has_reagent(/datum/reagent/medicine/mannitol)) //attempt to heal the brain
		. = TRUE //don't do attack animation.
		if(brain_death || brainmob?.health <= HEALTH_THRESHOLD_DEAD) //if the brain is fucked anyway, do nothing
			to_chat(user, span_warning("[src] is far too damaged, there's nothing else we can do for it!"))
			return

		if(!O.reagents.has_reagent(/datum/reagent/medicine/mannitol, 10))
			to_chat(user, span_warning("There's not enough mannitol in [O] to restore [src]!"))
			return

		user.visible_message("[user] starts to pour the contents of [O] onto [src].", span_notice("You start to slowly pour the contents of [O] onto [src]."))
		if(!do_after(user, 6 SECONDS, src))
			to_chat(user, span_warning("You failed to pour [O] onto [src]!"))
			return

		user.visible_message("[user] pours the contents of [O] onto [src], causing it to reform its original shape and turn a slightly brighter shade of pink.", span_notice("You pour the contents of [O] onto [src], causing it to reform its original shape and turn a slightly brighter shade of pink."))
		setOrganDamage(damage - (0.05 * maxHealth))	//heals a small amount, and by using "setorgandamage", we clear the failing variable if that was up

		O.reagents.clear_reagents()
		return

	if(brainmob) //if we aren't trying to heal the brain, pass the attack onto the brainmob.
		O.attack(brainmob, user) //Oh noooeeeee

	if(O.force != 0 && !(O.item_flags & NOBLUDGEON))
		setOrganDamage(maxHealth) //fails the brain as the brain was attacked, they're pretty fragile.

/obj/item/organ/brain/examine(mob/user)
	. = ..()

	if(suicided)
		. += span_info("It's started turning slightly grey. They must not have been able to handle the stress of it all.")
	else if(brainmob)
		if(brainmob.get_ghost(FALSE, TRUE))
			if(brain_death || brainmob.health <= HEALTH_THRESHOLD_DEAD)
				. += span_info("It's lifeless and severely damaged.")
			else if(organ_flags & ORGAN_FAILING)
				. += span_info("It seems to still have a bit of energy within it, but it's rather damaged... You may be able to restore it with some <b>mannitol</b>.")
			else
				. += span_info("You can feel the small spark of life still left in this one.")
		else if(organ_flags & ORGAN_FAILING)
			. += span_info("It seems particularly lifeless and is rather damaged... You may be able to restore it with some <b>mannitol</b> incase it becomes functional again later.")
		else
			. += span_info("This one seems particularly lifeless. Perhaps it will regain some of its luster later.")
	else
		if(decoy_override)
			if(organ_flags & ORGAN_FAILING)
				. += span_info("It seems particularly lifeless and is rather damaged... You may be able to restore it with some <b>mannitol</b> incase it becomes functional again later.")
			else
				. += span_info("This one seems particularly lifeless. Perhaps it will regain some of its luster later.")
		else
			. += span_info("This one is completely devoid of life.")

/obj/item/organ/brain/attack(mob/living/carbon/C, mob/user)
	if(!istype(C))
		return ..()

	add_fingerprint(user)

	if(user.zone_selected != zone)
		return ..()

	var/target_has_brain = C.getorgan(/obj/item/organ/brain)

	if(target_has_brain)
		to_chat(user, span_warning("This being already has a brain!"))
		return

	// This should be a better check but this covers 99.9% of cases
	if(!(compatible_biotypes & C.mob_biotypes))
		to_chat(user, span_warner("This brain is incompatiable with this beings biology!"))
		return

	if(!target_has_brain && C.is_eyes_covered() && user.zone_selected == BODY_ZONE_HEAD)
		to_chat(user, span_warning("You're going to need to remove [C.p_their()] head cover first!"))
		return

//since these people will be dead M != usr

	if(!C.get_bodypart(zone) || !user.temporarilyRemoveItemFromInventory(src))
		return
	var/msg = "[C] has [src] inserted into [C.p_them()] by [user]."
	if(C == user)
		msg = "[user] inserts [src] into [user.p_them()]!"

	C.visible_message(span_danger(msg), span_userdanger(msg))

	if(C != user)
		to_chat(C, span_notice("[user] inserts [src] into you."))
		to_chat(user, span_notice("You insert [src] into [C]."))
	else
		to_chat(user, span_notice("You insert [src] into yourself."))

	Insert(C)

/obj/item/organ/brain/Destroy() //copypasted from MMIs.
	if(brainmob)
		QDEL_NULL(brainmob)
	QDEL_LIST(traumas)
	return ..()

/obj/item/organ/brain/on_life()
	if(damage >= BRAIN_DAMAGE_DEATH) //rip
		to_chat(owner, span_userdanger("The last spark of life in your brain fizzles out..."))
		owner.death()
		brain_death = TRUE

/obj/item/organ/brain/process(delta_time)	//needs to run in life AND death
	..()
	// Intentionally not using delta_time, stasis will skip every n ticks, not caring about how long they took
	// Technically subject to timing inconsistencies when the tick rate is changed, but unless the timing is changed dramatically
	// the effect is within tolerance
	process_count += 1
	if(!((organ_flags & ORGAN_SYNTHETIC) || (owner && (owner.stat < DEAD || HAS_TRAIT(owner, TRAIT_PRESERVED_ORGANS) || !SHOULD_LIFETICK(owner, process_count)))))
		decay_progress += (delta_time SECONDS) // delta_time is in seconds
	//if we're not more injured than before, return without gambling for a trauma
	if(damage <= prev_damage)
		prev_damage = damage
		return
	damage_delta = damage - prev_damage
	if(damage > BRAIN_DAMAGE_MILD)
		if(prob(damage_delta * (1 + max(0, (damage - BRAIN_DAMAGE_MILD)/100)))) //Base chance is the hit damage; for every point of damage past the threshold the chance is increased by 1% //learn how to do your bloody math properly goddamnit
			gain_trauma_type(BRAIN_TRAUMA_MILD)
	if(damage > BRAIN_DAMAGE_SEVERE)
		if(prob(damage_delta * (1 + max(0, (damage - BRAIN_DAMAGE_SEVERE)/100)))) //Base chance is the hit damage; for every point of damage past the threshold the chance is increased by 1%
			if(prob(20))
				gain_trauma_type(BRAIN_TRAUMA_SPECIAL)
			else
				gain_trauma_type(BRAIN_TRAUMA_SEVERE)

	if(owner)
		if(owner.stat < UNCONSCIOUS) //conscious or soft-crit
			if(prev_damage < BRAIN_DAMAGE_MILD && damage >= BRAIN_DAMAGE_MILD)
				to_chat(owner, span_warning("You feel lightheaded."))
			else if(prev_damage < BRAIN_DAMAGE_SEVERE && damage >= BRAIN_DAMAGE_SEVERE)
				to_chat(owner, span_danger("You feel less in control of your thoughts."))
			else if(prev_damage < (BRAIN_DAMAGE_DEATH - 20) && damage >= (BRAIN_DAMAGE_DEATH - 20))
				to_chat(owner, span_userdanger("You can feel your mind flickering on and off..."))
	//update our previous damage holder after we've checked our boundaries
	prev_damage = damage
	return

/obj/item/organ/brain/alien
	name = "alien brain"
	desc = "We barely understand the brains of terrestial animals. Who knows what we may find in the brain of such an advanced species?"
	icon_state = "brain-x"

/obj/item/organ/brain/positron
	name = "positronic brain"
	slot = "brain"
	zone = BODY_ZONE_CHEST
	status = ORGAN_ROBOTIC
	desc = "A cube of shining metal, four inches to a side and covered in shallow grooves. It has an IPC serial number engraved on the top. In order for this posibrain to be used as a newly built Positronic Brain, it must be coupled with an MMI."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain-ipc"
	organ_flags = ORGAN_SYNTHETIC
	compatible_biotypes = MOB_ROBOTIC

/obj/item/organ/brain/positron/emp_act(severity)
	if(prob(25))
		return

	var/obj/item/clothing/head/hat = owner.get_item_by_slot(ITEM_SLOT_HEAD)
	if(hat && istype(hat, /obj/item/clothing/head/foilhat))
		return
	to_chat(owner, span_warning("Alert: Posibrain [severity > EMP_LIGHT ? "severely " : ""]damaged."))
	owner.adjust_drugginess(5 * severity)
	if(severity > EMP_LIGHT)
		owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, (2 * (severity - EMP_LIGHT)) * (maxHealth - damage) / maxHealth) // don't give traumas from weak EMPs

////////////////////////////////////TRAUMAS////////////////////////////////////////

/obj/item/organ/brain/proc/has_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience = TRAUMA_RESILIENCE_ABSOLUTE)
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		if(istype(BT, brain_trauma_type) && (BT.resilience <= resilience))
			return BT

/obj/item/organ/brain/proc/get_traumas_type(brain_trauma_type = /datum/brain_trauma, resilience = TRAUMA_RESILIENCE_ABSOLUTE)
	. = list()
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		if(istype(BT, brain_trauma_type) && (BT.resilience <= resilience))
			. += BT

/obj/item/organ/brain/proc/can_gain_trauma(datum/brain_trauma/trauma, resilience)
	if(!owner || owner.stat == DEAD)
		return FALSE
	if(!ispath(trauma))
		trauma = trauma.type
	if(!initial(trauma.can_gain))
		return FALSE
	if(!resilience)
		resilience = initial(trauma.resilience)

	var/resilience_tier_count = 0
	for(var/X in traumas)
		if(istype(X, trauma))
			return FALSE
		var/datum/brain_trauma/T = X
		if(resilience == T.resilience)
			resilience_tier_count++

	var/max_traumas
	switch(resilience)
		if(TRAUMA_RESILIENCE_BASIC)
			max_traumas = TRAUMA_LIMIT_BASIC
		if(TRAUMA_RESILIENCE_SURGERY)
			max_traumas = TRAUMA_LIMIT_SURGERY
		if(TRAUMA_RESILIENCE_WOUND)
			max_traumas = TRAUMA_LIMIT_WOUND
		if(TRAUMA_RESILIENCE_LOBOTOMY)
			max_traumas = TRAUMA_LIMIT_LOBOTOMY
		if(TRAUMA_RESILIENCE_MAGIC)
			max_traumas = TRAUMA_LIMIT_MAGIC
		if(TRAUMA_RESILIENCE_ABSOLUTE)
			max_traumas = TRAUMA_LIMIT_ABSOLUTE

	if(resilience_tier_count >= max_traumas)
		return FALSE
	return TRUE

//Proc to use when directly adding a trauma to the brain, so extra args can be given
/obj/item/organ/brain/proc/gain_trauma(datum/brain_trauma/trauma, resilience, ...)
	var/list/arguments = list()
	if(args.len > 2)
		arguments = args.Copy(3)
	. = brain_gain_trauma(trauma, resilience, arguments)

//Direct trauma gaining proc. Necessary to assign a trauma to its brain. Avoid using directly.
/obj/item/organ/brain/proc/brain_gain_trauma(datum/brain_trauma/trauma, resilience, list/arguments)
	if(!can_gain_trauma(trauma, resilience))
		return

	var/datum/brain_trauma/actual_trauma
	if(ispath(trauma))
		if(!LAZYLEN(arguments))
			actual_trauma = new trauma() //arglist with an empty list runtimes for some reason
		else
			actual_trauma = new trauma(arglist(arguments))
	else
		actual_trauma = trauma

	if(actual_trauma.brain) //we don't accept used traumas here
		WARNING("gain_trauma was given an already active trauma.")
		return

	traumas += actual_trauma
	actual_trauma.brain = src
	if(owner)
		actual_trauma.owner = owner
		actual_trauma.on_gain()
	if(resilience)
		actual_trauma.resilience = resilience
	. = actual_trauma
	SSblackbox.record_feedback("tally", "traumas", 1, actual_trauma.type)

//Add a random trauma of a certain subtype
/obj/item/organ/brain/proc/gain_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience)
	var/list/datum/brain_trauma/possible_traumas = list()
	for(var/T in subtypesof(brain_trauma_type))
		var/datum/brain_trauma/BT = T
		if(can_gain_trauma(BT, resilience) && initial(BT.random_gain))
			possible_traumas += BT

	if(!LAZYLEN(possible_traumas))
		return

	var/trauma_type = pick(possible_traumas)
	return gain_trauma(trauma_type, resilience)

//Cure a random trauma of a certain resilience level
/obj/item/organ/brain/proc/cure_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience = TRAUMA_RESILIENCE_BASIC)
	var/list/traumas = get_traumas_type(brain_trauma_type, resilience)
	if(LAZYLEN(traumas))
		qdel(pick(traumas))

/obj/item/organ/brain/proc/cure_all_traumas(resilience = TRAUMA_RESILIENCE_BASIC)
	var/list/traumas = get_traumas_type(resilience = resilience)
	for(var/X in traumas)
		qdel(X)
