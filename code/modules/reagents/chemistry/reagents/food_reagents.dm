///////////////////////////////////////////////////////////////////
					//Food Reagents
//////////////////////////////////////////////////////////////////


// Part of the food code. Also is where all the food
// 	condiments, additives, and such go.


/datum/reagent/consumable
	name = "Consumable"
	taste_description = "generic food"
	taste_mult = 4
	var/nutriment_factor = 1 * REAGENTS_METABOLISM
	var/quality = 0	//affects mood, typically higher for mixed drinks with more complex recipes

/datum/reagent/consumable/on_mob_life(mob/living/carbon/M)
	current_cycle++
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!(HAS_TRAIT(H, TRAIT_NOHUNGER) || HAS_TRAIT(H, TRAIT_POWERHUNGRY)))
			H.adjust_nutrition(nutriment_factor)
	holder?.remove_reagent(type, metabolization_rate)

/datum/reagent/consumable/reaction_mob(mob/living/M, methods = TOUCH, reac_volume, show_message = 1, permeability = 1)
	if(methods & INGEST)
		if (quality && !HAS_TRAIT(M, TRAIT_AGEUSIA))
			switch(quality)
				if (DRINK_NICE)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "quality_drink", /datum/mood_event/quality_nice)
				if (DRINK_GOOD)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "quality_drink", /datum/mood_event/quality_good)
				if (DRINK_VERYGOOD)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "quality_drink", /datum/mood_event/quality_verygood)
				if (DRINK_FANTASTIC)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "quality_drink", /datum/mood_event/quality_fantastic)
				if (FOOD_AMAZING)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "quality_food", /datum/mood_event/amazingtaste)
	return ..()

/datum/reagent/consumable/nutriment
	name = "Nutriment"
	description = "All the vitamins, minerals, and carbohydrates the body needs in pure form."
	reagent_state = SOLID
	nutriment_factor = 15 * REAGENTS_METABOLISM
	color = "#664330" // rgb: 102, 67, 48

	var/brute_heal = 0.5
	var/burn_heal = 0

/datum/reagent/consumable/nutriment/on_mob_life(mob/living/carbon/M)
	if(prob(50))
		M.heal_bodypart_damage(brute_heal,burn_heal, 0)
		. = 1
	..()

/datum/reagent/consumable/nutriment/on_new(list/supplied_data)
	// taste data can sometimes be ("salt" = 3, "chips" = 1)
	// and we want it to be in the form ("salt" = 0.75, "chips" = 0.25)
	// which is called "normalizing"
	if(!supplied_data)
		supplied_data = data

	// if data isn't an associative list, this has some WEIRD side effects
	// TODO probably check for assoc list?

	data = counterlist_normalise(supplied_data)

/datum/reagent/consumable/nutriment/on_merge(list/newdata, newvolume)
	if(!islist(newdata) || !newdata.len)
		return

	// data for nutriment is one or more (flavour -> ratio)
	// where all the ratio values adds up to 1

	var/list/taste_amounts = list()
	if(data)
		taste_amounts = data.Copy()

	counterlist_scale(taste_amounts, volume)

	var/list/other_taste_amounts = newdata.Copy()
	counterlist_scale(other_taste_amounts, newvolume)

	counterlist_combine(taste_amounts, other_taste_amounts)

	counterlist_normalise(taste_amounts)

	data = taste_amounts

/datum/reagent/consumable/nutriment/vitamin
	name = "Vitamin"
	description = "All the best vitamins, minerals, and carbohydrates the body needs in pure form."

	brute_heal = 1.5
	burn_heal = 1.5

/datum/reagent/consumable/nutriment/vitamin/on_mob_life(mob/living/carbon/M)
	if(M.satiety < 600)
		M.satiety += 30
	. = ..()

/datum/reagent/consumable/nutriment/protein
	name = "Protein"
	description = "A natural polyamide made up of amino acids. An essential constituent of mosts known forms of life."
	brute_heal = 0.8 //Rewards the player for eating a balanced diet.
	nutriment_factor = 9 * REAGENTS_METABOLISM //45% as calorie dense as corn oil.

/datum/reagent/consumable/cooking_oil
	name = "Cooking Oil"
	description = "A variety of cooking oil derived from fat or plants. Used in food preparation and frying."
	color = "#EADD6B" //RGB: 234, 221, 107 (based off of canola oil)
	taste_mult = 0.8
	taste_description = "oil"
	nutriment_factor = 1 * REAGENTS_METABOLISM //Not very healthy on its own
	metabolization_rate = 10 * REAGENTS_METABOLISM
	var/fry_temperature = 450 //Around ~350 F (117 C) which deep fryers operate around in the real world

/datum/reagent/consumable/cooking_oil/reaction_obj(obj/O, reac_volume)
	if(holder && holder.chem_temp >= fry_temperature && isitem(O))
		var/obj/item/I = O
		if(I.fryable)
			I.loc.visible_message(span_warning("[I] rapidly fries as it's splashed with hot oil! Somehow."))
			var/obj/item/reagent_containers/food/snacks/deepfryholder/F = new(I.drop_location(), O)
			F.fry(volume)
			F.reagents.add_reagent(/datum/reagent/consumable/cooking_oil, reac_volume)

/datum/reagent/consumable/cooking_oil/reaction_mob(mob/living/M, methods = TOUCH, reac_volume, show_message = 1, permeability = 1)
	if(!istype(M))
		return
	var/boiling = FALSE
	if(holder && holder.chem_temp >= fry_temperature)
		boiling = TRUE
	if(!(methods & (TOUCH|VAPOR))) //Directly coats the mob, and doesn't go into their bloodstream
		return ..()
	if(!boiling)
		return TRUE
	var/oil_damage = ((holder.chem_temp / fry_temperature) * 0.33) //Damage taken per unit
	if(methods & TOUCH)
		oil_damage *= M.get_permeability()
	var/FryLoss = round(min(38, oil_damage * reac_volume))
	if(!HAS_TRAIT(M, TRAIT_OIL_FRIED))
		M.visible_message(span_warning("The boiling oil sizzles as it covers [M]!"), \
		span_userdanger("You're covered in boiling oil!"))
		if(FryLoss)
			M.emote("scream")
		playsound(M, 'sound/machines/fryer/deep_fryer_emerge.ogg', 25, TRUE)
		ADD_TRAIT(M, TRAIT_OIL_FRIED, "cooking_oil_react")
		addtimer(CALLBACK(M, TYPE_PROC_REF(/mob/living, unfry_mob)), 3)
	if(FryLoss)
		M.adjustFireLoss(FryLoss)
	return TRUE

/datum/reagent/consumable/cooking_oil/reaction_turf(turf/open/T, reac_volume)
	if(!istype(T) || isgroundlessturf(T))
		return
	if(reac_volume >= 5)
		T.MakeSlippery(TURF_WET_LUBE, min_wet_time = 10 SECONDS, wet_time_to_add = reac_volume * 1.5 SECONDS)
		T.name = "deep-fried [initial(T.name)]"
		T.add_atom_colour(color, TEMPORARY_COLOUR_PRIORITY)

/datum/reagent/consumable/cooking_oil/fish
	name = "Fish Oil"
	description = "A pungent oil derived from fish."
	color = "#eab36b"
	taste_mult = 3.0 //VERY strong flavor
	taste_description = "fishy oil"
	nutriment_factor = 2 * REAGENTS_METABOLISM //just barely healthier than oil on its own
	metabolization_rate = 10 * REAGENTS_METABOLISM
	fry_temperature = 380 //Around ~350 F (117 C) which deep fryers operate around in the real world

/datum/reagent/consumable/sugar
	name = "Sugar"
	description = "The organic compound commonly known as table sugar and sometimes called saccharose. This white, odorless, crystalline powder has a pleasing, sweet taste."
	reagent_state = SOLID
	color = "#FFFFFF" // rgb: 255, 255, 255
	taste_mult = 1.5 // stop sugar drowning out other flavours
	nutriment_factor = 2 * REAGENTS_METABOLISM
	metabolization_rate = 2 * REAGENTS_METABOLISM
	overdose_threshold = 100 // Hyperglycaemic shock
	taste_description = "sweetness"
	default_container = /obj/item/reagent_containers/food/condiment/sugar

/datum/reagent/consumable/sugar/overdose_start(mob/living/M)
	if(HAS_TRAIT(M, TRAIT_BOTTOMLESS_STOMACH))
		return
	to_chat(M, span_userdanger("You go into hyperglycaemic shock! Lay off the twinkies!"))
	M.AdjustSleeping(600, FALSE)
	. = 1

/datum/reagent/consumable/sugar/overdose_process(mob/living/M)
	if(HAS_TRAIT(M, TRAIT_BOTTOMLESS_STOMACH))
		return
	M.AdjustSleeping(40, FALSE)
	..()
	. = 1

/datum/reagent/consumable/virus_food
	name = "Virus Food"
	description = "A mixture of water and milk. Virus cells can use this mixture to reproduce."
	nutriment_factor = 2 * REAGENTS_METABOLISM
	color = "#899613" // rgb: 137, 150, 19
	taste_description = "watery milk"

/datum/reagent/consumable/soysauce
	name = "Soysauce"
	description = "A salty sauce made from the soy plant."
	nutriment_factor = 2 * REAGENTS_METABOLISM
	color = "#792300" // rgb: 121, 35, 0
	taste_description = "umami"
	default_container = /obj/item/reagent_containers/food/condiment/soysauce

/datum/reagent/consumable/ketchup
	name = "Ketchup"
	description = "Ketchup, catsup, whatever. It's tomato paste."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#731008" // rgb: 115, 16, 8
	taste_description = "ketchup"
	default_container = /obj/item/reagent_containers/food/condiment/pack/ketchup

/datum/reagent/consumable/capsaicin
	name = "Capsaicin Oil"
	description = "This is what makes chilis hot."
	color = "#B31008" // rgb: 179, 16, 8
	taste_description = "hot peppers"
	taste_mult = 1.5
	default_container = /obj/item/reagent_containers/food/condiment/pack/hotsauce

/datum/reagent/consumable/capsaicin/on_mob_life(mob/living/carbon/M)
	var/heating = 0
	switch(current_cycle)
		if(1 to 15)
			heating = 5 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(holder.has_reagent(/datum/reagent/cryostylane))
				holder.remove_reagent(/datum/reagent/cryostylane, 5)
			if(isslime(M))
				heating = rand(5,20)
		if(15 to 25)
			heating = 10 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				heating = rand(10,20)
		if(25 to 35)
			heating = 15 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				heating = rand(15,20)
		if(35 to INFINITY)
			heating = 20 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				heating = rand(20,25)
	M.adjust_bodytemperature(heating)
	..()

/datum/reagent/consumable/frostoil
	name = "Frost Oil"
	description = "A special oil that noticably chills the body. Extracted from Icepeppers and slimes."
	color = "#8BA6E9" // rgb: 139, 166, 233
	taste_description = "mint"

/datum/reagent/consumable/frostoil/on_mob_life(mob/living/carbon/M)
	var/cooling = 0
	switch(current_cycle)
		if(1 to 15)
			cooling = -10 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(holder.has_reagent(/datum/reagent/consumable/capsaicin))
				holder.remove_reagent(/datum/reagent/consumable/capsaicin, 5)
			if(isslime(M))
				cooling = -rand(5,20)
		if(15 to 25)
			cooling = -20 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				cooling = -rand(10,20)
		if(25 to 35)
			cooling = -30 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(prob(1) && !HAS_TRAIT(M, TRAIT_RESISTCOLD))
				M.emote("shiver")
			if(isslime(M))
				cooling = -rand(15,20)
		if(35 to INFINITY)
			cooling = -40 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(prob(5) && !HAS_TRAIT(M, TRAIT_RESISTCOLD))
				M.emote("shiver")
			if(isslime(M))
				cooling = -rand(20,25)
	M.adjust_bodytemperature(cooling, 50)
	..()

/datum/reagent/consumable/frostoil/reaction_turf(turf/T, reac_volume)
	if(reac_volume >= 5)
		for(var/mob/living/simple_animal/slime/M in T)
			M.adjustToxLoss(rand(15,30))
	if(reac_volume >= 1) // Make Freezy Foam and anti-fire grenades!
		if(isopenturf(T))
			var/turf/open/OT = T
			OT.MakeSlippery(wet_setting=TURF_WET_ICE, min_wet_time=100, wet_time_to_add=reac_volume SECONDS) // Is less effective in high pressure/high heat capacity environments. More effective in low pressure.
			OT.air.set_temperature(OT.air.return_temperature() - MOLES_CELLSTANDARD*100*reac_volume/OT.air.heat_capacity()) // reduces environment temperature by 5K per unit.

/datum/reagent/consumable/condensedcapsaicin
	name = "Condensed Capsaicin"
	description = "A chemical agent used for self-defense and in police work."
	color = "#B31008" // rgb: 179, 16, 8
	taste_description = "scorching agony"
	metabolization_rate = 6 * REAGENTS_METABOLISM

/datum/reagent/consumable/condensedcapsaicin/reaction_mob(mob/living/M, methods=TOUCH, reac_volume)
	if(!ishuman(M) && !ismonkey(M))
		return

	var/mob/living/carbon/victim = M
	if(methods & (TOUCH|VAPOR))
		//check for protection
		var/mouth_covered = victim.is_mouth_covered()
		var/eyes_covered = victim.is_eyes_covered()

		//actually handle the pepperspray effects
		if ( eyes_covered && mouth_covered )
			return
		else if ( mouth_covered )	// Reduced effects if partially protected
			if(prob(50))
				victim.emote("scream")
			victim.blur_eyes(14)
			victim.blind_eyes(10)
			victim.set_confusion_if_lower(10 SECONDS)
			victim.damageoverlaytemp = 75
			victim.Paralyze(10 SECONDS)
			M.adjustStaminaLoss(3)
			return
		else if ( eyes_covered ) // Eye cover is better than mouth cover
			if(prob(20))
				victim.emote("cough")
			victim.blur_eyes(4)
			victim.set_confusion_if_lower(5 SECONDS)
			victim.damageoverlaytemp = 50
			M.adjustStaminaLoss(3)
			return
		else // Oh dear :D
			if(prob(60))
				victim.emote("scream")
			victim.blur_eyes(14)
			victim.blind_eyes(10)
			victim.set_confusion_if_lower(12 SECONDS)
			victim.damageoverlaytemp = 100
			victim.Paralyze(14 SECONDS)
			M.adjustStaminaLoss(5)
		victim.update_damage_hud()

/datum/reagent/consumable/condensedcapsaicin/on_mob_life(mob/living/carbon/M)
	if(prob(15))
		M.visible_message(span_warning("[M] [pick("dry heaves!","splutters!")]"))
	if(prob(20))
		M.emote("cough")

	M.adjustStaminaLoss(3)
	M.clear_stamina_regen()
	..()

/datum/reagent/consumable/sodiumchloride
	name = "Table Salt"
	description = "A salt made of sodium chloride. Commonly used to season food."
	reagent_state = SOLID
	color = "#FFFFFF" // rgb: 255,255,255
	taste_description = "salt"
	default_container = /obj/item/reagent_containers/food/condiment/saltshaker

/datum/reagent/consumable/sodiumchloride/reaction_turf(turf/T, reac_volume) //Creates an umbra-blocking salt pile
	if(!istype(T))
		return
	if(reac_volume < 1)
		return
	new/obj/effect/decal/cleanable/food/salt(T)

/datum/reagent/consumable/blackpepper
	name = "Black Pepper"
	description = "A powder ground from peppercorns. *AAAACHOOO*"
	reagent_state = SOLID
	// no color (ie, black)
	taste_description = "pepper"
	default_container = /obj/item/reagent_containers/food/condiment/peppermill

/datum/reagent/consumable/coco
	name = "Coco Powder"
	description = "A fatty, bitter paste made from coco beans."
	reagent_state = SOLID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "bitterness"

/datum/reagent/consumable/hot_coco
	name = "Hot Chocolate"
	description = "Made with love! And coco beans."
	nutriment_factor = 3 * REAGENTS_METABOLISM
	color = "#403010" // rgb: 64, 48, 16
	taste_description = "creamy chocolate"
	glass_icon_state  = "chocolateglass"
	glass_name = "glass of chocolate"
	glass_desc = "Tasty."

/datum/reagent/consumable/hot_coco/on_mob_life(mob/living/carbon/M)
	M.adjust_bodytemperature(5 * TEMPERATURE_DAMAGE_COEFFICIENT, 0, BODYTEMP_NORMAL)
	..()

/datum/reagent/drug/mushroomhallucinogen
	name = "Mushroom Hallucinogen"
	description = "A strong hallucinogenic drug derived from certain species of mushroom."
	color = "#E700E7" // rgb: 231, 0, 231
	metabolization_rate = 0.2 * REAGENTS_METABOLISM
	taste_description = "mushroom"

/datum/reagent/drug/mushroomhallucinogen/on_mob_life(mob/living/carbon/M)
	M.set_slurring_if_lower(1 SECONDS)
	switch(current_cycle)
		if(1 to 5)
			M.set_dizzy_if_lower(5 SECONDS)
			M.set_drugginess_if_lower(30 SECONDS)
			if(prob(10))
				M.emote(pick("twitch","giggle"))

		if(6 to 10)
			M.set_jitter_if_lower(20 SECONDS)
			M.set_dizzy_if_lower(10 SECONDS)
			M.set_drugginess_if_lower(35 SECONDS)
			if(prob(20))
				M.emote(pick("twitch","giggle"))

		if (11 to INFINITY)
			M.set_jitter_if_lower(40 SECONDS)
			M.set_dizzy_if_lower(20 SECONDS)
			M.set_drugginess_if_lower(40 SECONDS)
			if(prob(30))
				M.emote(pick("twitch","giggle"))
	..()

/datum/reagent/consumable/garlic //NOTE: having garlic in your blood stops vampires from biting you.
	name = "Garlic Juice"
	description = "Crushed garlic. Chefs love it, but it can make you smell bad."
	color = "#FEFEFE"
	taste_description = "garlic"
	metabolization_rate = 0.15 * REAGENTS_METABOLISM

/datum/reagent/consumable/garlic/on_mob_life(mob/living/carbon/M)
	if(isvampire(M)) //incapacitating but not lethal. Unfortunately, vampires cannot vomit.
		if(prob(min(25,current_cycle)))
			to_chat(M, span_danger("You can't get the scent of garlic out of your nose! You can barely think..."))
			M.Paralyze(10)
			M.adjust_jitter(10 SECONDS)
	else if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.job == "Cook")
			if(prob(20)) //stays in the system much longer than sprinkles/banana juice, so heals slower to partially compensate
				H.heal_bodypart_damage(1,1, 0)
				. = 1
	..()

/datum/reagent/consumable/sprinkles
	name = "Sprinkles"
	description = "Multi-colored little bits of sugar, commonly found on donuts. Loved by cops."
	color = "#FF00FF" // rgb: 255, 0, 255
	taste_description = "childhood whimsy"

/datum/reagent/consumable/sprinkles/on_mob_life(mob/living/carbon/M)
	if(HAS_TRAIT(M.mind, TRAIT_LAW_ENFORCEMENT_METABOLISM))
		M.heal_bodypart_damage(1,1, 0)
		. = 1
	..()

/datum/reagent/consumable/cornoil
	name = "Corn Oil"
	description = "An oil derived from various types of corn."
	nutriment_factor = 15 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "slime"

/datum/reagent/consumable/cornoil/reaction_turf(turf/open/T, reac_volume)
	if (!istype(T))
		return
	T.MakeSlippery(TURF_WET_LUBE, min_wet_time = 10 SECONDS, wet_time_to_add = reac_volume*2 SECONDS)
	var/obj/effect/hotspot/hotspot = (locate(/obj/effect/hotspot) in T)
	if(hotspot)
		var/datum/gas_mixture/lowertemp = T.return_air()
		lowertemp.set_temperature(max( min(lowertemp.return_temperature()-2000,lowertemp.return_temperature() / 2) ,TCMB))
		lowertemp.react(src)
		qdel(hotspot)

/datum/reagent/consumable/enzyme
	name = "Universal Enzyme"
	description = "A universal enzyme used in the preperation of certain chemicals and foods."
	color = "#365E30" // rgb: 54, 94, 48
	taste_description = "sweetness"

/datum/reagent/consumable/dry_ramen
	name = "Dry Ramen"
	description = "Space age food, since August 25, 1958. Contains dried noodles, vegetables, and chemicals that boil in contact with water."
	reagent_state = SOLID
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "dry and cheap noodles"

/datum/reagent/consumable/hot_ramen
	name = "Hot Ramen"
	description = "The noodles are boiled, the flavors are artificial, just like being back in school."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "wet and cheap noodles"

/datum/reagent/consumable/hot_ramen/on_mob_life(mob/living/carbon/M)
	M.adjust_bodytemperature(10 * TEMPERATURE_DAMAGE_COEFFICIENT, 0, BODYTEMP_NORMAL)
	..()

/datum/reagent/consumable/hell_ramen
	name = "Hell Ramen"
	description = "The noodles are boiled, the flavors are artificial, just like being back in school."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "wet and cheap noodles on fire"

/datum/reagent/consumable/hell_ramen/on_mob_life(mob/living/carbon/M)
	M.adjust_bodytemperature(10 * TEMPERATURE_DAMAGE_COEFFICIENT)
	..()

/datum/reagent/consumable/flour
	name = "Flour"
	description = "This is what you rub all over yourself to pretend to be a ghost."
	reagent_state = SOLID
	color = "#FFFFFF" // rgb: 0, 0, 0
	taste_description = "chalky wheat"
	default_container = /obj/item/reagent_containers/food/condiment/flour

/datum/reagent/consumable/flour/reaction_turf(turf/T, reac_volume)
	if(!isspaceturf(T))
		var/obj/effect/decal/cleanable/food/flour/reagentdecal = new(T)
		reagentdecal = locate() in T //Might have merged with flour already there.
		if(reagentdecal)
			reagentdecal.reagents.add_reagent(/datum/reagent/consumable/flour, reac_volume)

/datum/reagent/consumable/batter
	name = "Batter"
	description = "This is what you dip things in to get them extra crunchy when fried."
	color = "#fdffdb"
	taste_description = "damp flour and beer"

/datum/reagent/consumable/cherryjelly
	name = "Cherry Jelly"
	description = "Totally the best. Only to be spread on foods with excellent lateral symmetry."
	color = "#801E28" // rgb: 128, 30, 40
	taste_description = "cherry"

/datum/reagent/consumable/bluecherryjelly
	name = "Blue Cherry Jelly"
	description = "Blue and tastier kind of cherry jelly."
	color = "#00F0FF"
	taste_description = "blue cherry"

/datum/reagent/consumable/rice
	name = "Rice"
	description = "tiny nutritious grains"
	reagent_state = SOLID
	nutriment_factor = 3 * REAGENTS_METABOLISM
	color = "#FFFFFF" // rgb: 0, 0, 0
	taste_description = "rice"

/datum/reagent/consumable/vanilla
	name = "Vanilla Powder"
	description = "A fatty, bitter paste made from vanilla pods."
	reagent_state = SOLID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#FFFACD"
	taste_description = "vanilla"

/datum/reagent/consumable/eggyolk
	name = "Egg Yolk"
	description = "It's full of protein."
	nutriment_factor = 3 * REAGENTS_METABOLISM
	color = "#FFB500"
	taste_description = "egg"

/datum/reagent/consumable/corn_starch
	name = "Corn Starch"
	description = "A slippery solution."
	color = "#C8A5DC"
	taste_description = "slime"

/datum/reagent/consumable/corn_syrup
	name = "Corn Syrup"
	description = "Decays into sugar."
	color = "#C8A5DC"
	metabolization_rate = 3 * REAGENTS_METABOLISM
	taste_description = "sweet slime"

/datum/reagent/consumable/corn_syrup/on_mob_life(mob/living/carbon/M)
	holder.add_reagent(/datum/reagent/consumable/sugar, 3)
	..()

/datum/reagent/consumable/honey
	name = "Honey"
	description = "Sweet sweet honey that decays into sugar. Has antibacterial and natural healing properties."
	color = "#d3a308"
	nutriment_factor = 15 * REAGENTS_METABOLISM
	metabolization_rate = 1 * REAGENTS_METABOLISM
	taste_description = "sweetness"

/datum/reagent/consumable/honey/on_mob_life(mob/living/carbon/M)
	M.reagents.add_reagent(/datum/reagent/consumable/sugar,3)
	if(prob(55))
		M.adjustBruteLoss(-1*REM, 0)
		M.adjustFireLoss(-1*REM, 0)
		M.adjustOxyLoss(-1*REM, 0)
		M.adjustToxLoss(-1*REM, 0)
	..()

/datum/reagent/consumable/honey/reaction_mob(mob/living/M, methods=TOUCH, reac_volume)
  if(iscarbon(M) && (methods & (TOUCH|VAPOR|PATCH)))
    var/mob/living/carbon/C = M
    for(var/s in C.surgeries)
      var/datum/surgery/S = s
      S.success_multiplier = max(0.6, S.success_multiplier) // +60% success probability on each step, compared to bacchus' blessing's ~46%
  ..()

/datum/reagent/consumable/mayonnaise
	name = "Mayonnaise"
	description = "An white and oily mixture of mixed egg yolks."
	color = "#DFDFDF"
	taste_description = "mayonnaise"

/datum/reagent/consumable/tearjuice
	name = "Tear Juice"
	description = "A blinding substance extracted from certain onions."
	color = "#c0c9a0"
	taste_description = "bitterness"

/datum/reagent/consumable/tearjuice/reaction_mob(mob/living/M, methods = TOUCH, reac_volume, show_message = 1, permeability = 1)
	if(!istype(M))
		return
	if(!permeability)
		return ..()
	if((methods & INGEST) || ((methods & (TOUCH|PATCH|VAPOR)) && !M.is_mouth_covered() && !M.is_eyes_covered()))
		if(!M.getorganslot(ORGAN_SLOT_EYES))	//can't blind somebody with no eyes
			to_chat(M, "<span class = 'notice'>Your eye sockets feel wet.</span>")
		else
			if(!M.eye_blurry)
				to_chat(M, "<span class = 'warning'>Tears well up in your eyes!</span>")
			M.blind_eyes(2)
			M.blur_eyes(5)
	return ..()

/datum/reagent/consumable/tearjuice/on_mob_life(mob/living/carbon/M)
	..()
	if(M.eye_blurry)	//Don't worsen vision if it was otherwise fine
		M.blur_eyes(4)
		if(prob(10))
			to_chat(M, "<span class = 'warning'>Your eyes sting!</span>")
			M.blind_eyes(2)


/datum/reagent/consumable/nutriment/stabilized
	name = "Stabilized Nutriment"
	description = "A bioengineered protien-nutrient structure designed to decompose in high saturation. In layman's terms, it won't get you fat."
	reagent_state = SOLID
	nutriment_factor = 15 * REAGENTS_METABOLISM
	color = "#664330" // rgb: 102, 67, 48

/datum/reagent/consumable/nutriment/stabilized/on_mob_life(mob/living/carbon/M)
	if(M.nutrition > NUTRITION_LEVEL_FULL - 25)
		M.adjust_nutrition(-3*nutriment_factor)
	..()

////Lavaland Flora Reagents////


/datum/reagent/consumable/entpoly
	name = "Entropic Polypnium"
	description = "An ichor, derived from a certain mushroom, makes for a bad time."
	color = "#1d043d"
	taste_description = "bitter mushroom"

/datum/reagent/consumable/entpoly/on_mob_life(mob/living/carbon/M)
	if(current_cycle >= 10)
		M.Unconscious(40, 0)
		. = 1
	if(prob(20))
		M.losebreath += 4
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2*REM, 150)
		M.adjustToxLoss(3*REM,0)
		M.adjustStaminaLoss(10*REM,0)
		M.blur_eyes(5)
		. = TRUE
	..()

/datum/reagent/consumable/tinlux
	name = "Tinea Luxor"
	description = "A stimulating ichor which causes luminescent fungi to grow on the skin. "
	color = "#b5a213"
	taste_description = "tingling mushroom"
		//Lazy list of mobs affected by the luminosity of this reagent.
	var/list/mobs_affected

/datum/reagent/consumable/tinlux/reaction_mob(mob/living/M)
	add_reagent_light(M)

/datum/reagent/consumable/tinlux/on_mob_end_metabolize(mob/living/M)
	remove_reagent_light(M)

/datum/reagent/consumable/tinlux/proc/on_living_holder_deletion(mob/living/source)
	remove_reagent_light(source)

/datum/reagent/consumable/tinlux/proc/add_reagent_light(mob/living/living_holder)
	var/obj/effect/dummy/lighting_obj/moblight/mob_light_obj = living_holder.mob_light(2)
	mob_light_obj.set_light_color("#b5a213")
	LAZYSET(mobs_affected, living_holder, mob_light_obj)
	RegisterSignal(living_holder, COMSIG_PARENT_QDELETING, PROC_REF(on_living_holder_deletion))

/datum/reagent/consumable/tinlux/proc/remove_reagent_light(mob/living/living_holder)
	UnregisterSignal(living_holder, COMSIG_PARENT_QDELETING)
	var/obj/effect/dummy/lighting_obj/moblight/mob_light_obj = LAZYACCESS(mobs_affected, living_holder)
	LAZYREMOVE(mobs_affected, living_holder)
	if(mob_light_obj)
		qdel(mob_light_obj)

/datum/reagent/consumable/vitfro
	name = "Vitrium Froth"
	description = "A bubbly paste that heals wounds of the skin."
	color = "#d3a308"
	taste_description = "fruity mushroom"

/datum/reagent/consumable/vitfro/on_mob_life(mob/living/carbon/M)
	if(prob(60))
		M.adjustBruteLoss(-1*REM, 0)
		M.adjustFireLoss(-1*REM, 0)
		. = TRUE
	..()

/datum/reagent/consumable/ashresin
	name = "Ash Resin"
	description = "A sticky and in large quantities toxic substance found in lavaland flora that helps retain water and keep out pests."
	color = "#ad8604"
	taste_description = "sticky ash"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/consumable/ashresin/on_mob_life(mob/living/carbon/M) //nothing to worry about when eaten sparsely
	if(prob(90))
		M.adjustOrganLoss(ORGAN_SLOT_STOMACH, 1)
		. = 1
	..()

/datum/reagent/consumable/clownstears
	name = "Clown's Tears"
	description = "The sorrow and melancholy of a thousand bereaved clowns, forever denied their Honkmechs."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#eef442" // rgb: 238, 244, 66
	taste_description = "mournful honking"


/datum/reagent/consumable/liquidelectricity
	name = "Liquid Electricity"
	description = "The blood of Ethereals, and the stuff that keeps them going. Great for them, horrid for anyone else."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#97ee63"
	taste_description = "pure electricity"
	compatible_biotypes = ALL_BIOTYPES

/datum/reagent/consumable/liquidelectricity/reaction_turf(turf/T, reac_volume)//splash the electric "blood" all over the place
	if(!istype(T))
		return
	if(reac_volume < 3)
		return

	var/obj/effect/decal/cleanable/whiteblood/ethereal/B = locate() in T //find some blood here
	if(!B)
		B = new(T)

/datum/reagent/consumable/liquidelectricity/on_mob_life(mob/living/carbon/M)
	if(HAS_TRAIT(M, TRAIT_POWERHUNGRY))
		M.adjust_nutrition(nutriment_factor)
	else if(prob(25))
		M.electrocute_act(rand(10,15), "Liquid Electricity in their body", 1) //lmao at the newbs who eat energy bars
		playsound(M, "sparks", 50, 1)
	return ..()

/datum/reagent/consumable/astrotame
	name = "Astrotame"
	description = "A space age artifical sweetener."
	nutriment_factor = 0
	metabolization_rate = 2 * REAGENTS_METABOLISM
	reagent_state = SOLID
	color = "#FFFFFF" // rgb: 255, 255, 255
	taste_mult = 8
	taste_description = "sweetness"
	overdose_threshold = 17

/datum/reagent/consumable/astrotame/overdose_process(mob/living/carbon/M)
	if(M.disgust < 80)
		M.adjust_disgust(10)
	..()
	. = 1

/datum/reagent/consumable/secretsauce
	name = "Secret Sauce"
	description = "What could it be."
	nutriment_factor = 2 * REAGENTS_METABOLISM
	color = "#792300"
	taste_description = "indescribable"
	quality = FOOD_AMAZING
	taste_mult = 100
	can_synth = FALSE

/datum/reagent/consumable/nutriment/peptides
	name = "Peptides"
	color = "#BBD4D9"
	taste_description = "mint frosting"
	description = "These restorative peptides not only speed up wound healing, but are nutritious as well!"
	nutriment_factor = 10 * REAGENTS_METABOLISM // 33% less than nutriment to reduce weight gain
	brute_heal = 3
	burn_heal = 1

/datum/reagent/consumable/caramel
	name = "Caramel"
	description = "Who would have guessed that heating sugar is so delicious?"
	nutriment_factor = 10 * REAGENTS_METABOLISM
	color = "#C65A00"
	taste_mult = 2
	taste_description = "bitter sweetness"
	reagent_state = SOLID

/datum/reagent/consumable/mesophilicculture
	name = "mesophilic culture"
	description = "A mixture of mesophilic bacteria used to make most cheese."
	color = "#F3CE3A" // rgb: 243, 206, 58
	taste_description = "bitterness"

/datum/reagent/consumable/thermophilicculture
	name = "thermophilic culture"
	description = "A mixture of thermophilic bacteria used to make some cheese."
	color = "#FFE682" // rgb: 255, 230, 130
	taste_description = "bitterness"

/datum/reagent/consumable/penicilliumcandidum
	name = "penicillium candidum"
	description = "A special bacterium used to make brie."
	color = "#E9ECD5" // rgb: 233, 236, 213
	taste_description = "bitterness"

/datum/reagent/consumable/penicilliumroqueforti
	name = "penicillium roqueforti"
	description = "A special bacterium used to make blue cheese."
	color = "#829BB3" // rgb: 130, 155, 179
	taste_description = "bitterness"

/datum/reagent/consumable/parmesan_delight
	name = "Parmesan Delight"
	description = "The time spent cultivating parmesan has produced this magical liquid."
	color = "#FFD700" // rgb: 255, 140, 255
	quality = DRINK_VERYGOOD
	taste_description = "salty goodness"

/datum/reagent/consumable/parmesan_delight/on_mob_life(mob/living/carbon/M)
	M.adjustBruteLoss(-0.5, 0)
	M.adjustFireLoss(-0.5, 0)
	M.adjustToxLoss(-0.5, 0)
	M.adjustOxyLoss(-0.5, 0)
	M.heal_bodypart_damage(1,1, 0)
	..()

/datum/reagent/consumable/drippings
	name = "meat drippings"
	description = "Full of fat and flavor. Mix it with water and flour to make gravy."
	nutriment_factor = 3 * REAGENTS_METABOLISM
	color = "#85482c"
	taste_mult = 2
	taste_description = "meat"

/datum/reagent/consumable/gravy
	name = "gravy"
	description = "Delicious brown sauce, thickened with flour."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#75553a"
	taste_mult = 1.5
	taste_description = "gravy"

/datum/reagent/consumable/char
	name = "Char"
	description = "Essence of the grill. Has strange properties when overdosed."
	reagent_state = LIQUID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#C8C8C8"
	taste_mult = 1 //has to be a bit low so it doesn't overtake literally everything when INTENSE GRILLING takes place
	taste_description = "smoke"
	overdose_threshold = 25

/datum/reagent/consumable/char/overdose_process(mob/living/carbon/M)
	if(prob(10))
		M.say(pick("I hate my wife.", "I just want to grill for God's sake.", "I wish I could just go on my lawnmower and cut the grass.", "Yep, Quake. That was a good game...", "Yeah, my PDA has wi-fi. A wife I hate."), forced = /datum/reagent/consumable/char)
	..()

/datum/reagent/consumable/laughsyrup
	name = "Laughin' Syrup"
	description = "The product of juicing Laughin' Peas. Fizzy, and seems to change flavour based on what it's used with!"
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#803280"
	taste_mult = 2
	taste_description = "fizzy sweetness"

/datum/reagent/consumable/ute_flour
	name = "Ute Flour"
	description = "A coarsely ground, peppery flour made from ute nut shells."
	taste_description = "earthy heat"
	color = "#EEC39A"

/datum/reagent/consumable/ute_milk
	name = "Ute Milk"
	description = "A milky liquid made by crushing the centre of a ute nut."
	taste_description = "sugary milk"
	color = "#FFFFFF"

/datum/reagent/consumable/ute_nectar
	name = "Ute Nectar"
	description = "A sweet, sugary syrup made from crushed sweet ute nuts."
	color = "#d3a308"
	nutriment_factor = 5 * REAGENTS_METABOLISM
	metabolization_rate = 1 * REAGENTS_METABOLISM
	taste_description = "peppery sweetness"

/datum/reagent/consumable/mintextract
	name = "Mint Extract"
	description = "Useful for dealing with undesirable customers."
	color = "#CF3600" // rgb: 207, 54, 0
	taste_description = "mint"

/datum/reagent/consumable/mintextract/on_mob_life(mob/living/carbon/affected_mob, delta_time, times_fired)
	if(HAS_TRAIT(affected_mob, TRAIT_FAT))
		affected_mob.gib()
	return ..()

/datum/reagent/consumable/bbqsauce
	name = "BBQ Sauce"
	description = "Sweet, smokey, savory, and gets everywhere. Perfect for grilling."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#78280A" // rgb: 120, 40, 10
	taste_mult = 2.5 //sugar's 1.5, capsacin's 1.5, so a good middle ground.
	taste_description = "smokey sweetness"

/datum/reagent/consumable/peanut_butter
	name = "Peanut Butter"
	description = "A creamy paste made from ground peanuts."
	nutriment_factor = 15 * REAGENTS_METABOLISM
	color = "#D9A066" // rgb: 217, 160, 102
	taste_description = "peanuts"
