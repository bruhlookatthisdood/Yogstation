/area/yogs/infiltrator_base
	name = "Syndicate Infiltrator Base"
	icon = 'icons/turf/areas.dmi'
	icon_state = "red"
	blob_allowed = FALSE
	requires_power = FALSE
	has_gravity = TRUE
	noteleport = TRUE
	flags_1 = NONE
	ambience_index = AMBIENCE_DANGER
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED

/area/yogs/infiltrator_base/poweralert(state, obj/source)
	return

/area/yogs/infiltrator_base/atmosalert(danger_level, obj/source)
	return

/area/yogs/infiltrator_base/jail
	name = "Syndicate Infiltrator Base Brig"

//headcanon lore: this is some random snowy moon that the syndies use as a base
/area/yogs/infiltrator_base/outside
	name = "Syndicate Base X-77"
	icon_state = "yellow"
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/brazil
	name = "Location Unresolved"
	icon_state = "execution_room"
	blob_allowed = FALSE
	has_gravity = TRUE
	noteleport = TRUE
	flags_1 = NONE
	area_flags = NOTELEPORT
