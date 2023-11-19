/datum/action/cooldown/bloodsucker/vassal_blood
	name = "Help Vassal"
	desc = "Bring an ex-Vassal back into the fold."
	button_icon_state = "power_torpor"
	power_explanation = "Help Vassal:\n\
		Use this power while you have an ex-Vassal grabbed to bring them back into the fold. \
		Right-Click will show the status of all Vassals."
	power_flags = NONE
	check_flags = NONE
	purchase_flags = NONE
	bloodcost = 10
	cooldown_time = 10 SECONDS

	///Bloodbag we have in our hands.
	var/obj/item/reagent_containers/blood/bloodbag
	///Weakref to a target we're bringing into the fold.
	var/datum/weakref/target_ref
	///If we are analyze or helping
	var/analyzing

/datum/action/cooldown/bloodsucker/vassal_blood/CanUse(mob/living/carbon/user)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/vassal/revenge/revenge_vassal = owner.mind.has_antag_datum(/datum/antagonist/ex_vassal)
	if(revenge_vassal)
		return FALSE

	if(tgui_alert(owner, "What would you like to do?", "Lost and Found", list("Analyze", "Help")) == "Analyze")
		if(!revenge_vassal.ex_vassals.len)
			owner.balloon_alert(owner, "no vassals!")
			return FALSE
		analyzing = TRUE
		return TRUE

	if(owner.pulling && isliving(owner.pulling))
		var/mob/living/pulled_target = owner.pulling
		var/datum/antagonist/ex_vassal/former_vassal = pulled_target.mind.has_antag_datum(/datum/antagonist/ex_vassal)
		if(!former_vassal)
			owner.balloon_alert(owner, "not a former vassal!")
			return FALSE
		target_ref = WEAKREF(owner.pulling)
		return TRUE

	var/blood_bag = locate(/obj/item/reagent_containers/blood) in user.held_items
	if(!blood_bag)
		owner.balloon_alert(owner, "blood bag needed!")
		return FALSE
	if(istype(blood_bag, /obj/item/reagent_containers/blood/o_minus/bloodsucker))
		owner.balloon_alert(owner, "already bloodsucker blood!")

	bloodbag = blood_bag
	return TRUE

/datum/action/cooldown/bloodsucker/vassal_blood/ActivatePower()
	. = ..()
	var/datum/antagonist/vassal/revenge/revenge_vassal = owner.mind.has_antag_datum(/datum/antagonist/vassal/revenge)
	if(analyzing)
		for(var/datum/antagonist/ex_vassal/former_vassals as anything in revenge_vassal.ex_vassals)
			var/information = "[former_vassals.owner.current]"
			information += " - has [round(COOLDOWN_TIMELEFT(former_vassals, blood_timer) / 600)] minutes left of Blood"
			var/turf/open/floor/target_area = get_area(owner)
			if(target_area)
				information += " - currently at [target_area]."
			if(former_vassals.owner.current.stat >= DEAD)
				information += " - DEAD."

			to_chat(owner, "[information]")

		DeactivatePower()
		return

	if(target_ref)
		var/mob/living/target = target_ref.resolve()
		var/datum/antagonist/ex_vassal/former_vassal = target.mind.has_antag_datum(/datum/antagonist/ex_vassal)
		if(!former_vassal || former_vassal.revenge_vassal)
			target_ref = null
			return
		if(do_after(owner, 5 SECONDS, target))
			former_vassal.return_to_fold(revenge_vassal)
		target_ref = null
		DeactivatePower()
		return

	if(bloodbag)
		var/mob/living/living_owner = owner
		living_owner.blood_volume -= 150
		QDEL_NULL(bloodbag)
		var/obj/item/reagent_containers/blood/o_minus/bloodsucker/new_bag = new(owner.loc)
		owner.put_in_active_hand(new_bag)
		DeactivatePower()
