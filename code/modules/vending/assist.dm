/obj/machinery/vending/assist
	products = list(/obj/item/assembly/prox_sensor = 5,
					/obj/item/assembly/igniter = 3,
					/obj/item/assembly/signaler = 4,
					/obj/item/assembly/signaler/button = 2,
					/obj/item/wirecutters = 1,
					/obj/item/cartridge/signal = 4)
	premium = list(/obj/item/laserlevel = 1)
	contraband = list(/obj/item/assembly/timer = 2,
					  /obj/item/assembly/voice = 2,
					  /obj/item/assembly/health = 2)
	refill_canister = /obj/item/vending_refill/assist
	product_ads = "Only the finest!;Have some tools.;The most robust equipment.;The finest gear in space!"
	default_price = 10
	extra_price = 50
	payment_department = NO_FREEBIES

/obj/item/vending_refill/assist
	machine_name = "Vendomat"
	icon_state = "refill_engi"
