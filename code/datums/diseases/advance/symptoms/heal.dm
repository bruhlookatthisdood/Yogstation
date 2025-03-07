/datum/symptom/heal
	name = "Basic Healing (does nothing)" //warning for adminspawn viruses
	desc = "You should not be seeing this."
	stealth = 0
	resistance = 0
	stage_speed = 0
	transmittable = 0
	level = 0 //not obtainable
	base_message_chance = 20 //here used for the overlays
	symptom_delay_min = 1
	symptom_delay_max = 1
	var/passive_message = "" //random message to infected but not actively healing people
	threshold_descs = list(
		"Stage Speed 6" = "Doubles healing speed.",
		"Stealth 4" = "Healing will no longer be visible to onlookers.",
	)

/datum/symptom/heal/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 6) //stronger healing
		power = 2

/datum/symptom/heal/Activate(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(4, 5)
			var/effectiveness = CanHeal(A)
			if(!effectiveness)
				if(passive_message && prob(2) && passive_message_condition(M))
					to_chat(M, passive_message)
				return
			else
				Heal(M, A, effectiveness)
	return

/datum/symptom/heal/proc/CanHeal(datum/disease/advance/A)
	return power

/datum/symptom/heal/proc/Heal(mob/living/M, datum/disease/advance/A, actual_power)
	return TRUE

/datum/symptom/heal/proc/passive_message_condition(mob/living/M)
	return TRUE


/datum/symptom/heal/starlight
	name = "Starlight Condensation"
	icon = "symptom.starlight_condensation.gif"
	desc = "The virus reacts to direct starlight, producing regenerative chemicals."
	stealth = -1
	resistance = -2
	stage_speed = 0
	transmittable = 1
	level = 6
	passive_message = span_notice("You miss the feeling of starlight on your skin.")
	var/nearspace_penalty = 0.3
	threshold_descs = list(
		"Stage Speed 6" = "Increases healing speed.",
		"Transmission 6" = "Removes penalty for only being close to space.",
	)

/datum/symptom/heal/starlight/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalTransmittable() >= 6)
		nearspace_penalty = 1
	if(A.totalStageSpeed() >= 6)
		power = 2

/datum/symptom/heal/starlight/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	if(istype(get_turf(M), /turf/open/space))
		return power
	else
		for(var/turf/T in view(M, 2))
			if(istype(T, /turf/open/space))
				return power * nearspace_penalty

/datum/symptom/heal/starlight/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 2 * actual_power //active less than most healing viruses

	var/list/parts = M.get_damaged_bodyparts(1,1, null, BODYPART_ORGANIC)
	if(!parts.len)
		return

	if(prob(5))
		to_chat(M, span_notice("Your skin tingles as the starlight seems to heal you."))

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len, null, BODYPART_ORGANIC))
			M.update_damage_overlays()
	return 1

/datum/symptom/heal/starlight/passive_message_condition(mob/living/M)
	if(M.getBruteLoss() || M.getFireLoss() || M.getToxLoss())
		return TRUE
	return FALSE

/datum/symptom/heal/chem
	name = "Toxolysis"
	icon = "toxolysis"
	stealth = 0
	resistance = -2
	stage_speed = 2
	transmittable = -2
	level = 7
	var/food_conversion = FALSE
	desc = "The virus rapidly breaks down any foreign chemicals in the bloodstream. It also heals toxin damage."
	threshold_descs = list(
		"Resistance 7" = "Increases toxin healing speed.",
		"Stage Speed 6" = "Consumed chemicals feed the host.",
	)

/datum/symptom/heal/chem/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 6)
		food_conversion = TRUE
	if(A.totalResistance() >= 7)
		power = 2

/datum/symptom/heal/chem/Heal(mob/living/M, datum/disease/advance/A, actual_power)
	var/toxins_present = FALSE
	for(var/datum/reagent/R in M.reagents.reagent_list) //Not just toxins!
		M.reagents.remove_reagent(R.type, actual_power / power)//doesn't speed up using power
		if(istype(R, /datum/reagent/toxin))
			toxins_present = TRUE
		if(food_conversion)
			M.adjust_nutrition(0.3)
		if(prob(2))
			to_chat(M, span_notice("You feel a mild warmth as your blood purifies itself."))
	var/heal_amt = actual_power * (toxins_present ? 1 : 0.1)	//If there are toxins in you it heals at full power, otherwise it is very minor
	M.adjustToxLoss(-heal_amt)
	
	return 1



/datum/symptom/heal/metabolism
	name = "Metabolic Boost"
	icon = "metabolic_boost"
	stealth = -1
	resistance = -2
	stage_speed = 2
	transmittable = 1
	level = 7
	var/triple_metabolism = FALSE
	var/reduced_hunger = FALSE
	desc = "The virus causes the host's metabolism to accelerate rapidly, making them process chemicals twice as fast,\
	 but also causing increased hunger."
	threshold_descs = list(
		"Stealth 3" = "Reduces hunger rate.",
		"Stage Speed 10" = "Chemical metabolization is tripled instead of doubled.",
	)

/datum/symptom/heal/metabolism/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 10)
		triple_metabolism = TRUE
	if(A.totalStealth() >= 3)
		reduced_hunger = TRUE

/datum/symptom/heal/metabolism/Heal(mob/living/carbon/C, datum/disease/advance/A, actual_power)
	if(!istype(C))
		return
	C.reagents.metabolize(C, can_overdose=TRUE) //this works even without a liver; it's intentional since the virus is metabolizing by itself
	if(triple_metabolism)
		C.reagents.metabolize(C, can_overdose=TRUE)
	C.overeatduration = max(C.overeatduration - 2, 0)
	var/lost_nutrition = 9 - (reduced_hunger * 5)
	C.adjust_nutrition(-lost_nutrition * HUNGER_FACTOR) //Hunger depletes at 10x the normal speed
	if(prob(2))
		to_chat(C, span_notice("You feel an odd gurgle in your stomach, as if it was working much faster than normal."))
	return 1

/datum/symptom/heal/darkness
	name = "Nocturnal Regeneration"
	icon = "symptom.nocturnal_regeneration.gif"
	desc = "The virus is able to mend the host's flesh when in conditions of low light, repairing physical damage. More effective against brute damage."
	stealth = 2
	resistance = -1
	stage_speed = -2
	transmittable = -1
	level = 6
	passive_message = span_notice("You feel tingling on your skin as light passes over it.")
	threshold_descs = list(
		"Stage Speed 8" = "Doubles healing speed.",
	)

/datum/symptom/heal/darkness/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 8)
		power = 2

/datum/symptom/heal/darkness/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	var/light_amount = 0
	if(isturf(M.loc)) //else, there's considered to be no light
		var/turf/T = M.loc
		light_amount = min(1,T.get_lumcount()) - 0.5
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			return power

/datum/symptom/heal/darkness/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 1 * actual_power

	var/list/parts = M.get_damaged_bodyparts(1,1, null, BODYPART_ORGANIC)

	if(!parts.len)
		return

	if(prob(5))
		to_chat(M, span_notice("The darkness soothes and mends your wounds."))

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len * 0.5, null, BODYPART_ORGANIC)) //more effective on brute
			M.update_damage_overlays()
	return 1

/datum/symptom/heal/darkness/passive_message_condition(mob/living/M)
	if(M.getBruteLoss() || M.getFireLoss())
		return TRUE
	return FALSE

/datum/symptom/heal/coma
	name = "Regenerative Coma"
	icon = "symptom.regen_coma.gif"
	desc = "The virus causes the host to fall into a death-like coma when severely damaged, then rapidly fixes the damage."
	stealth = 0
	resistance = 2
	stage_speed = -3
	transmittable = -2
	level = 8
	passive_message = span_notice("The pain from your wounds makes you feel oddly sleepy...")
	var/deathgasp = FALSE
	var/active_coma = FALSE //to prevent multiple coma procs
	threshold_descs = list(
		"Stealth 2" = "Host appears to die when falling into a coma.",
		"Stage Speed 7" = "Increases healing speed.",
	)

/datum/symptom/heal/coma/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 7)
		power = 1.5
	if(A.totalStealth() >= 2)
		deathgasp = TRUE

/datum/symptom/heal/coma/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	if(HAS_TRAIT(M, TRAIT_DEATHCOMA))
		return power
	else if(M.IsUnconscious() || M.stat == UNCONSCIOUS)
		return power * 0.9
	else if(M.stat == SOFT_CRIT)
		return power * 0.5
	else if(M.IsSleeping())
		return power * 0.25
	else if(ispreternis(M) || isipc(M)) //ipc and preternis don't get round removed
		return 0
	else if(M.getBruteLoss() + M.getFireLoss() >= 90 && !active_coma)
		to_chat(M, span_warning("You feel yourself slip into a regenerative coma..."))
		active_coma = TRUE
		addtimer(CALLBACK(src, PROC_REF(coma), M), 60)

/datum/symptom/heal/coma/proc/coma(mob/living/M)
	M.fakedeath("regenerative_coma", !deathgasp)
	M.update_stat()
	M.update_mobility()
	addtimer(CALLBACK(src, PROC_REF(uncoma), M), 300)

/datum/symptom/heal/coma/proc/uncoma(mob/living/M)
	if(!active_coma)
		return
	active_coma = FALSE
	M.cure_fakedeath("regenerative_coma")
	M.update_stat()
	M.update_mobility()

/datum/symptom/heal/coma/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 6 * actual_power

	var/list/parts = M.get_damaged_bodyparts(1,1)

	if(!parts.len)
		return

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len, null, BODYPART_ORGANIC))
			M.update_damage_overlays()

	if(active_coma && M.getBruteLoss() + M.getFireLoss() == 0)
		uncoma(M)

	return 1

/datum/symptom/heal/coma/passive_message_condition(mob/living/M)
	if((M.getBruteLoss() + M.getFireLoss()) > 30)
		return TRUE
	return FALSE

/datum/symptom/heal/water
	name = "Tissue Hydration"
	icon = "symptom.tissue_hydration.gif"
	desc = "The virus uses excess water inside and outside the body to repair damaged tissue cells. More effective when using holy water and against burns."
	stealth = 0
	resistance = -1
	stage_speed = 0
	transmittable = 1
	level = 6
	passive_message = span_notice("Your skin feels oddly dry...")
	var/absorption_coeff = 1
	threshold_descs = list(
		"Resistance 5" = "Water is consumed at a much slower rate.",
		"Stage Speed 7" = "Increases healing speed.",
	)

/datum/symptom/heal/water/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 7)
		power = 2
	if(A.totalResistance() >= 5)
		absorption_coeff = 0.25

/datum/symptom/heal/water/CanHeal(datum/disease/advance/A)
	. = 0
	var/mob/living/M = A.affected_mob
	if(M.fire_stacks < 0)
		M.fire_stacks = min(M.fire_stacks + 1 * absorption_coeff, 0)
		. += power
	if(M.reagents.has_reagent(/datum/reagent/water/holywater, needs_metabolizing = FALSE))
		M.reagents.remove_reagent(/datum/reagent/water/holywater, 0.5 * absorption_coeff)
		. += power * 0.75
	else if(M.reagents.has_reagent(/datum/reagent/water, needs_metabolizing = FALSE))
		M.reagents.remove_reagent(/datum/reagent/water, 0.5 * absorption_coeff)
		. += power * 0.5

/datum/symptom/heal/water/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 2 * actual_power

	var/list/parts = M.get_damaged_bodyparts(1,1, null, BODYPART_ORGANIC) //more effective on burns

	if(!parts.len)
		return

	if(prob(5))
		to_chat(M, span_notice("You feel yourself absorbing the water around you to soothe your damaged skin."))

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len * 0.5, heal_amt/parts.len, null, BODYPART_ORGANIC))
			M.update_damage_overlays()

	return 1

/datum/symptom/heal/water/passive_message_condition(mob/living/M)
	if(M.getBruteLoss() || M.getFireLoss())
		return TRUE
	return FALSE

/datum/symptom/heal/plasma
	name = "Plasma Fixation"
	icon = "symptom.plasma_fixation.gif"
	desc = "The virus draws plasma from the atmosphere and from inside the body to heal and stabilize body temperature."
	stealth = 0
	resistance = 3
	stage_speed = -2
	transmittable = -2
	level = 8
	passive_message = span_notice("You feel an odd attraction to plasma.")
	var/temp_rate = 1
	threshold_descs = list(
		"Transmission 6" = "Increases temperature adjustment rate.",
		"Stage Speed 7" = "Increases healing speed.",
	)
	compatible_biotypes = ALL_BIOTYPES //only really for temp stabilize

/datum/symptom/heal/plasma/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 7)
		power = 2
	if(A.totalTransmittable() >= 6)
		temp_rate = 4

/datum/symptom/heal/plasma/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	var/datum/gas_mixture/environment

	. = 0

	if(M.loc)
		environment = M.return_air()
	if(environment)
		if(environment.get_moles(GAS_PLASMA) > GLOB.gas_data.visibility[GAS_PLASMA]) //if there's enough plasma in the air to see
			. += power * 0.625
	var/requires_metabolizing = !(A.process_dead && M.stat == DEAD) //don't require metabolizing if our host is dead and we have necrotic metabolsim
	if(M.reagents.has_reagent(/datum/reagent/toxin/plasma, needs_metabolizing = requires_metabolizing))
		. +=  power * 0.375

/datum/symptom/heal/plasma/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 4 * actual_power

	if(prob(5))
		to_chat(M, span_notice("You feel yourself absorbing plasma inside and around you..."))

	if(M.bodytemperature > BODYTEMP_NORMAL)
		M.adjust_bodytemperature(-20 * temp_rate * TEMPERATURE_DAMAGE_COEFFICIENT,BODYTEMP_NORMAL)
		if(prob(5))
			to_chat(M, span_notice("You feel less hot."))
	else if(M.bodytemperature < (BODYTEMP_NORMAL + 1))
		M.adjust_bodytemperature(20 * temp_rate * TEMPERATURE_DAMAGE_COEFFICIENT,0,BODYTEMP_NORMAL)
		if(prob(5))
			to_chat(M, span_notice("You feel warmer."))

	M.adjustToxLoss(-heal_amt * 2)

	var/list/parts = M.get_damaged_bodyparts(1,1, null, BODYPART_ORGANIC)
	if(!parts.len)
		return
	if(prob(5))
		to_chat(M, span_notice("The pain from your wounds fades rapidly."))
	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len, null, BODYPART_ORGANIC))
			M.update_damage_overlays()
	return 1


/datum/symptom/heal/radiation
	name = "Radioactive Resonance"
	icon = "radioactive_resonance"
	desc = "The virus uses radiation to fix damage through dna mutations."
	stealth = -1
	resistance = -2
	stage_speed = 2
	transmittable = -3
	level = 6
	symptom_delay_min = 1
	symptom_delay_max = 1
	passive_message = span_notice("Your skin glows faintly for a moment.")
	var/cellular_damage = FALSE
	threshold_descs = list(
		"Transmission 6" = "Additionally heals cellular damage.",
		"Resistance 7" = "Increases healing speed.",
	)

/datum/symptom/heal/radiation/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalResistance() >= 7)
		power = 2
	if(A.totalTransmittable() >= 6)
		cellular_damage = TRUE

/datum/symptom/heal/radiation/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	switch(M.radiation)
		if(0)
			return FALSE
		if(1 to RAD_MOB_SAFE)
			return 0.25
		if(RAD_MOB_SAFE to RAD_BURN_THRESHOLD)
			return 0.5
		if(RAD_BURN_THRESHOLD to RAD_MOB_MUTATE)
			return 0.75
		if(RAD_MOB_MUTATE to RAD_MOB_KNOCKDOWN)
			return 1
		else
			return 1.5

/datum/symptom/heal/radiation/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = actual_power

	if(cellular_damage)
		M.adjustCloneLoss(-heal_amt * 0.5)

	M.adjustToxLoss(-(2 * heal_amt))

	var/list/parts = M.get_damaged_bodyparts(1,1, null, BODYPART_ORGANIC)

	if(!parts.len)
		return

	if(prob(4))
		to_chat(M, span_notice("Your skin glows faintly, and you feel your wounds mending themselves."))

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len, null, BODYPART_ORGANIC))
			M.update_damage_overlays()
	return 1

#define SYMPTOM_SUPERFICIAL_LOWER_THRESHOLD 0.7
/datum/symptom/heal/surface
	name = "Superficial Healing"
	desc = "The virus accelerates the body's natural healing, causing the body to heal minor wounds quickly."
	stealth = -2
	resistance = -2
	stage_speed = -2
	transmittable = 1

	level = 3
	passive_message = span_notice("Your skin tingles")

	var/threshold = 0.9 // Percentual total health we check against. This is less than a toolbox hit, so probably wont save you in combat
	var/healing_power = 0.5 // 0.5 brute and fire, slightly better than the worst case starlight with its 0.3

	threshold_descs = list(
		"Stage Speed 8" = "Improves healing significantly.",
		"Resistance 10" = "Improves healing threshhold. This comes at the downside of exhausting the body more as heavier wounds heal",
	)

/datum/symptom/heal/surface/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.properties["stage_rate"] >= 8) //stronger healing
		healing_power = 1.5
	if(A.properties["resistance"] >= 10)
		threshold = SYMPTOM_SUPERFICIAL_LOWER_THRESHOLD

/datum/symptom/heal/surface/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	if(M.health == M.maxHealth)
		return FALSE
	return TRUE
	

/datum/symptom/heal/surface/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	if(M.health == M.maxHealth)
		return
	if(((M.health/M.maxHealth) > threshold))
		healing_power = healing_power * actual_power

		// We don't actually heal all damage types at once, but prioritise one over the other.
		// Since the virus focuses mainly on surface damage, it will firstly heal those
		// If it can't find any then it will consider healing some toxins (Not affected by healing power)
		if(M.getBruteLoss() || M.getFireLoss())
			M.heal_bodypart_damage(healing_power, healing_power) 				
		else if(M.getToxLoss())
			M.adjustToxLoss(-0.5)
		else
			return	// Still continues IF we healed something

		// A downside to the better threshold
		if(threshold == SYMPTOM_SUPERFICIAL_LOWER_THRESHOLD)
			// Interesting downside
			if(M.getStaminaLoss() < 65)
				M.adjustStaminaLoss(20)
		return TRUE
#undef SYMPTOM_SUPERFICIAL_LOWER_THRESHOLD


/datum/symptom/heal/symbiotic
	name = "Symbiotic Regeneration"
	desc = "The virus forms a symbiotic relationship with vital organs in the host's body, accelerating the host's natural healing processes while resting."
	stealth = -3
	resistance = -1
	stage_speed = 2
	transmittable = -4

	level = 3
	passive_message = span_notice("You feel calm.")

	/// When was the last time the affected mob moved?
	var/last_moved = 0
	/// How long do you need to stand still to start healing?
	var/heal_delay = 3 SECONDS

	compatible_biotypes = ALL_BIOTYPES // bungus
	threshold_descs = list(
		"Stage speed 9" = "Shorter delay until healing starts.",
		"Resistance 9" = "Increased rate of healing.",
	)

/datum/symptom/heal/symbiotic/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStealth() >= 5) //stronger healing
		heal_delay = 1 SECONDS
	if(A.totalResistance() >= 10) //no delay
		power = 3
	RegisterSignal(A.affected_mob, COMSIG_MOB_CLIENT_PRE_MOVE, PROC_REF(on_move))

/datum/symptom/heal/symbiotic/End(datum/disease/advance/A)
	UnregisterSignal(A.affected_mob, COMSIG_MOB_CLIENT_PRE_MOVE)
	return ..()

/datum/symptom/heal/symbiotic/proc/on_move(mob/living/mover, dir)
	last_moved = world.time

/datum/symptom/heal/symbiotic/CanHeal(datum/disease/advance/A)
	if(last_moved + heal_delay > world.time)
		return FALSE
	return power

/datum/symptom/heal/symbiotic/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	if(M.health == M.maxHealth)
		return
	if(last_moved + heal_delay > world.time)
		return

	if(M.getBruteLoss() || M.getFireLoss() || M.getToxLoss())
		var/heal_amount = actual_power * 0.5
		M.heal_bodypart_damage(heal_amount, heal_amount, required_status=((A.infectable_biotypes & MOB_ROBOTIC) ? BODYPART_ANY : BODYPART_ORGANIC))
		M.adjustToxLoss(-heal_amount)
		if(prob(1) && IS_ENGINEERING(M))
			M.adjust_wet_stacks(0.1) // there seems to be a danger of precipitation...
			to_chat(M, span_notice("You can smell rain."))
		return TRUE

	return FALSE // stop healing if there isn't any damage to heal
