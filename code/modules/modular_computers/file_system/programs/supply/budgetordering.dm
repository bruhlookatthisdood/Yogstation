/datum/computer_file/program/budgetorders
	filename = "orderapp"
	filedesc = "NT IRN"
	category = PROGRAM_CATEGORY_SUPL
	program_icon_state = "bountyboard"
	extended_desc = "Nanotrasen Internal Requisition Network interface for supply purchasing using a department budget account."
	requires_ntnet = TRUE
	usage_flags = PROGRAM_CONSOLE | PROGRAM_LAPTOP | PROGRAM_TABLET | PROGRAM_PHONE | PROGRAM_TELESCREEN | PROGRAM_PDA
	size = 12
	tgui_id = "NtosCargo"
	program_icon = "store"
	///Are you actually placing orders with it?
	var/requestonly = TRUE
	///Can the tablet see or buy illegal stuff?
	var/contraband = FALSE
	///Is it being bought from a personal account, or is it being done via a budget/cargo?
	var/self_paid = FALSE
	///Can this console approve purchase requests?
	var/can_approve_requests = FALSE
	///Can this console see contraband items?
	var/emagged = FALSE
	///What do we say when the shuttle moves with living beings on it.
	var/safety_warning = "For safety reasons, the automated supply shuttle \
		cannot transport live organisms, human remains, classified nuclear weaponry, \
		homing beacons or machinery housing any form of artificial intelligence."
	///If you're being raided by pirates, what do you tell the crew?
	var/blockade_warning = "Bluespace instability detected. Shuttle movement impossible."
	/// Can send the shuttle **AWAY** from the station
	var/can_send = FALSE
	///Is it being bought from a departmental budget?
	var/budget_order = FALSE
	///If this is true, unlock the ability to order through budgets
	var/unlock_budget = TRUE

/datum/computer_file/program/budgetorders/proc/get_export_categories()
	. = EXPORT_CARGO

/datum/computer_file/program/budgetorders/proc/is_visible_pack(mob/user, paccess_to_check, list/access, contraband)
	if(issilicon(user)) //Borgs can't buy things.
		return FALSE
	if(emagged)
		return TRUE
	else if(contraband) //Hide contrband when non-emagged.
		return FALSE
	if(!paccess_to_check) // No required_access, allow it.
		return TRUE

	//Aquire access from the inserted ID card.
	if(!length(access))
		var/obj/item/card/id/D
		var/obj/item/computer_hardware/card_slot/card_slot
		if(computer)
			card_slot = computer.all_components[MC_CARD]
			D = card_slot?.GetID()
		if(!D)
			return FALSE
		access = D.GetAccess()

	if(paccess_to_check in access)
		return TRUE

	return FALSE

/datum/computer_file/program/budgetorders/run_emag()
	if(emagged)
		return FALSE
	emagged = TRUE
	return TRUE

/datum/computer_file/program/budgetorders/ui_data()
	. = ..()
	var/list/data = get_header_data()
	data["location"] = SSshuttle.supply.getStatusText()
	var/datum/bank_account/buyer = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	var/obj/item/card/id/id_card = card_slot?.GetID()
	if(id_card?.registered_account)
		unlock_budget = TRUE
		if(id_card?.registered_account?.account_job?.paycheck_department == ACCOUNT_CAR)
			unlock_budget = FALSE //cargo tech is already using the same budget.
		if(id_card?.registered_account?.account_job?.paycheck_department && budget_order)
			buyer = SSeconomy.get_dep_account(id_card.registered_account.account_job.paycheck_department)
		if((ACCESS_HEADS in id_card.access) || (ACCESS_QM in id_card.access) || (ACCESS_CARGO in id_card.access))
			requestonly = FALSE
			can_approve_requests = TRUE
			can_send = TRUE
		else
			requestonly = TRUE
			can_approve_requests = FALSE
			can_send = FALSE
	else
		requestonly = TRUE
		unlock_budget = FALSE //none registered account shouldnt be using budget order
	if(buyer)
		data["points"] = buyer.account_balance

//Otherwise static data, that is being applied in ui_data as the crates visible and buyable are not static, and are determined by inserted ID.
	data["requestonly"] = requestonly
	data["supplies"] = list()
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]
		if(!is_visible_pack(usr, P.access_view , null, P.contraband) || P.hidden)
			continue
		if(!data["supplies"][P.group])
			data["supplies"][P.group] = list(
				"name" = P.group,
				"packs" = list()
			)
		if((P.hidden && (P.contraband && !contraband) || (P.special && !P.special_enabled) || P.DropPodOnly))
			continue
		data["supplies"][P.group]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.get_cost(),
			"id" = pack,
			"desc" = P.desc || P.name, // If there is a description, use it. Otherwise use the pack's name.
			"access" = P.access
		))

//Data regarding the User's capability to buy things.
	data["away"] = SSshuttle.supply.getDockedId() == "supply_away"
	data["self_paid"] = self_paid
	data["unlock_budget"] = unlock_budget
	data["budget_order"] = budget_order
	data["docked"] = SSshuttle.supply.mode == SHUTTLE_IDLE
	data["loan"] = !!SSshuttle.shuttle_loan
	data["loan_dispatched"] = SSshuttle.shuttle_loan && SSshuttle.shuttle_loan.dispatched
	data["can_approve_requests"] = can_approve_requests
	data["can_send"] = can_send
	data["app_cost"] = TRUE
	var/message = "Remember to stamp and send back the supply manifests."
	if(SSshuttle.centcom_message)
		message = SSshuttle.centcom_message
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	data["message"] = message
	data["cart"] = list()
	for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
		data["cart"] += list(list(
			"object" = SO.pack.name,
			"cost" = SO.pack.get_cost(),
			"id" = SO.id,
			"orderer" = SO.orderer,
			"paid" = !isnull(SO.paying_account), //paid by requester
			"budget" = SO.budget
		))

	data["requests"] = list()
	for(var/datum/supply_order/SO in SSshuttle.requestlist)
		data["requests"] += list(list(
			"object" = SO.pack.name,
			"cost" = SO.pack.get_cost(),
			"orderer" = SO.orderer,
			"reason" = SO.reason,
			"id" = SO.id,
			"budget" = SO.budget
		))

	return data

/datum/computer_file/program/budgetorders/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	var/obj/item/computer_hardware/card_slot/card_slot = computer.all_components[MC_CARD]
	switch(action)
		if("send")
			if(!SSshuttle.supply.canMove())
				computer.say(safety_warning)
				return
			if(SSshuttle.supplyBlocked)
				computer.say(blockade_warning)
				return
			if(SSshuttle.supply.getDockedId() == "supply_home")
				SSshuttle.supply.export_categories = get_export_categories()
				SSshuttle.moveShuttle("supply", "supply_away", TRUE)
				computer.say("The supply shuttle is departing.")
				computer.investigate_log("[key_name(usr)] sent the supply shuttle away.", INVESTIGATE_CARGO)
			else
				computer.investigate_log("[key_name(usr)] called the supply shuttle.", INVESTIGATE_CARGO)
				computer.say("The supply shuttle has been called and will arrive in [SSshuttle.supply.timeLeft(600)] minutes.")
				SSshuttle.moveShuttle("supply", "supply_home", TRUE)
			. = TRUE
		if("loan")
			if(!SSshuttle.shuttle_loan)
				return
			if(SSshuttle.supplyBlocked)
				computer.say(blockade_warning)
				return
			else if(SSshuttle.supply.mode != SHUTTLE_IDLE)
				return
			else if(SSshuttle.supply.getDockedId() != "supply_away")
				return
			else
				SSshuttle.shuttle_loan.loan_shuttle()
				computer.say("The supply shuttle has been loaned to CentCom.")
				computer.investigate_log("[key_name(usr)] accepted a shuttle loan event.", INVESTIGATE_CARGO)
				log_game("[key_name(usr)] accepted a shuttle loan event.")
				. = TRUE
		if("add")
			var/id = text2path(params["id"])
			var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
			if(!istype(pack))
				return
			if((pack.hidden && (pack.contraband && !contraband) || pack.DropPodOnly))
				return

			var/name = "*None Provided*"
			var/rank = "*None Provided*"
			var/ckey = usr.ckey
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				name = H.get_authentification_name()
				rank = H.get_assignment(hand_first = TRUE)
			else if(issilicon(usr))
				name = usr.real_name
				rank = "Silicon"
			
			var/datum/bank_account/account
			if(self_paid && ishuman(usr))
				var/mob/living/carbon/human/H = usr
				var/obj/item/card/id/id_card = H.get_idcard(TRUE)
				if(!istype(id_card))
					computer.say("No ID card detected.")
					return
				if(istype(id_card, /obj/item/card/id/departmental_budget))
					computer.say("The [src] rejects [id_card].")
					return
				account = id_card.registered_account
				if(!istype(account))
					computer.say("Invalid bank account.")
					return

			var/reason = ""
			if((requestonly && !self_paid) || !(card_slot?.GetID()))
				reason = stripped_input("Reason:", name, "")
				if(isnull(reason) || ..())
					return

			if(!self_paid && ishuman(usr) && !account)
				var/obj/item/card/id/id_card = card_slot?.GetID()
				if(budget_order)
					account = SSeconomy.get_dep_account(id_card?.registered_account?.account_job.paycheck_department)
					name = account.account_holder
					rank = "*None Provided*"

			var/turf/T = get_turf(computer)
			var/datum/supply_order/SO = new(pack, name, rank, ckey, reason, account, account?.account_holder)
			SO.generateRequisition(T)
			if((requestonly && !self_paid) || !(card_slot?.GetID()))
				SSshuttle.requestlist += SO
			else
				SSshuttle.shoppinglist += SO
				if(self_paid || budget_order)
					computer.say("Order processed. The price will be charged to [account.account_holder]'s bank account on delivery.")
			. = TRUE
		if("remove")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
				if(SO.id == id)
					SSshuttle.shoppinglist -= SO
					. = TRUE
					break
		if("clear")
			SSshuttle.shoppinglist.Cut()
			. = TRUE
		if("approve")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.requestlist)
				if(SO.id == id)
					SSshuttle.requestlist -= SO
					SSshuttle.shoppinglist += SO
					. = TRUE
					break
		if("deny")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSshuttle.requestlist)
				if(SO.id == id)
					SSshuttle.requestlist -= SO
					. = TRUE
					break
		if("denyall")
			SSshuttle.requestlist.Cut()
			. = TRUE
		if("toggleprivate")
			self_paid = !self_paid
			if(budget_order)
				budget_order = FALSE //incase something fucked
			. = TRUE
		if("togglebudget")
			budget_order = !budget_order
			if(self_paid)
				self_paid = FALSE //incase something fucked
			. = TRUE
	if(.)
		post_signal("supply")

/datum/computer_file/program/budgetorders/proc/post_signal(command)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = command))
	frequency.post_signal(src, status_signal)
