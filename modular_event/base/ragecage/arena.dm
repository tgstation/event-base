/// Plant these for first and second fighters or groups, 3 of each should be present
/obj/effect/landmark/ragecage
	name = "ragecage first fighter spawn"
	var/index = ARENA_FIRST_FIGHTER

/obj/effect/landmark/ragecage/second
	name = "ragecage second fighter spawn"
	index = ARENA_SECOND_FIGHTER

/// Landmark to which participants will be teleported after finishing the fight, at least 6 should be present
/obj/effect/landmark/ragecage_exit
	name = "ragecage exit"

/obj/machinery/computer/ragecage_signup
	name = "arena signup console"
	desc = "A console that lets you sign up to participate in rage cage fights. Supports duels and three on threes."
	icon_screen = "tram"
	icon_keyboard = "atmos_key"
	light_color = LIGHT_COLOR_CYAN
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// List of participants signed up for duels, once we have a spot the first two participants are taken from the list and sent to fight
	var/list/datum/duel_group/duels = list()
	/// List of trio participant groups
	var/list/datum/duel_group/trios = list()
	/// Currently active duel datum
	var/datum/arena_duel/active_duel = null
	/// All arena types that can be selected by players
	var/static/list/arena_types = list(
		"standard" = "Standard Arena",
		"electrified" = "Electrified Arena",
		"_random" = "Random Arena"
	)
	/// Cached arena templates
	var/static/list/arena_templates = null
	/// Bottom left corner of the loading room, used for placing
	var/turf/bottom_left
	/// What area type this arena console loads into. Linked turns into the nearest instance of this area
	var/area/mapped_start_area = /area/centcom/tdome/arena/ragecage
	/// The area that this console loads templates into
	var/area/linked
	/// List of all atoms spawned by the arena
	var/list/spawned = list()
	/// List of active holodeck effects
	var/list/effects = list()
	/// Special locs that can mess with derez'ing holo spawned objects
	var/static/list/special_locs = list(
		/obj/item/mob_holder,
	)

/obj/machinery/computer/ragecage_signup/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	linked = GLOB.areas_by_type[mapped_start_area]
	if(!linked)
		log_mapping("[src] at [AREACOORD(src)] has no matching holodeck area.")
		qdel(src)
		return

	bottom_left = locate(linked.x, linked.y, src.z)
	if(!bottom_left)
		log_mapping("[src] at [AREACOORD(src)] has an invalid holodeck area.")
		qdel(src)
		return

	if (arena_templates)
		return

	arena_templates = list()
	for(var/datum/map_template/arena/arena_type as anything in subtypesof(/datum/map_template/arena))
		if(!(initial(arena_type.mappath)))
			continue
		arena_type = new arena_type()
		arena_templates[arena_type.template_id] = arena_type

/obj/machinery/computer/ragecage_signup/Destroy(force)
	. = ..()
	reset_to_default()
	QDEL_LIST(duels)
	QDEL_LIST(trios)
	QDEL_LIST(spawned)
	QDEL_LIST(effects)
	linked = null
	if (active_duel)
		active_duel.end_fight()
		QDEL_NULL(active_duel)

/obj/machinery/computer/ragecage_signup/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RagecageConsole", name)
		ui.open()

/obj/machinery/computer/ragecage_signup/ui_data(mob/user)
	var/list/data = list("duelSigned" = FALSE, "trioSigned" = FALSE)
	var/list/active_data = list()

	var/list/duel_data = list()
	for (var/datum/duel_group/group as anything in duels)
		var/list/group_members = list()
		for (var/datum/duel_member/member as anything in group.members)
			group_members += list(list(
				"name" = member.owner.real_name,
				"dead" = member.owner.stat == DEAD,
				"owner" = group.owner == member.owner,
			))

			if (user == member.owner)
				data["duelSigned"] = TRUE

		var/list/duel_group = list("members" = group_members, "canJoin" = FALSE, "arenaType" = arena_types[group.arena_type])
		duel_data += list(duel_group)
		if (active_duel?.first_group == group)
			active_data["firstTeam"] = duel_group
		else if (active_duel?.second_group == group)
			active_data["secondTeam"] = duel_group

	data["duelTeams"] = duel_data

	var/list/trio_data = list()
	for (var/datum/duel_group/group as anything in trios)
		var/list/group_members = list()
		for (var/datum/duel_member/member as anything in group.members)
			group_members += list(list(
				"name" = member.owner.real_name,
				"dead" = member.owner.stat == DEAD,
				"owner" = group.owner == member.owner,
			))

			if (user == member.owner)
				data["trioSigned"] = TRUE

		var/list/duel_group = list("members" = group_members, "group" = REF(group), "canJoin" = (length(group_members) < 3 && group.owner != user && !group.active_duel), "arenaType" = arena_types[group.arena_type])
		trio_data += list(duel_group)
		if (active_duel?.first_group == group)
			active_data["firstTeam"] = duel_group
		else if (active_duel?.second_group == group)
			active_data["secondTeam"] = duel_group

	data["trioTeams"] = trio_data
	data["joinRequestCooldown"] = TIMER_COOLDOWN_RUNNING(user, COOLDOWN_ARENA_SIGNUP_REQUEST)

	var/list/valid_types = list()
	for (var/key in arena_types)
		valid_types += arena_types[key]
	data["arenaTypes"] = valid_types

	if (length(active_data))
		data["activeDuel"] = active_data
	return data

/obj/machinery/computer/ragecage_signup/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/living/carbon/human/user = ui.user
	if (!istype(user))
		return

	var/datum/duel_group/duel = null
	var/datum/duel_group/trio = null

	for (var/datum/duel_group/group as anything in duels)
		for (var/datum/duel_member/member as anything in group.members)
			if (member.owner == user)
				duel = group
				break
		if (duel)
			break

	for (var/datum/duel_group/group as anything in trios)
		for (var/datum/duel_member/member as anything in group.members)
			if (member.owner == user)
				trio = group
				break
		if (trio)
			break

	switch(action)
		if ("duel_signup")
			if (duel)
				to_chat(user, span_alert("You've already signed up for a duel!"))
				return

			var/arena_type = params["arena_type"]
			var/arena_key = "_random"
			for (var/key in arena_types)
				if (arena_types[key] == arena_type)
					arena_key = key
					break

			duels += new /datum/duel_group(user, src, FALSE, arena_key)
			check_matches()

		if ("trio_signup")
			if (trio)
				to_chat(user, span_alert("You've already signed up for a three on three fight!"))
				return

			var/arena_type = params["arena_type"]
			var/arena_key = "_random"
			for (var/key in arena_types)
				if (arena_types[key] == arena_type)
					arena_key = key
					break

			trios += new /datum/duel_group(user, src, !!params["join_random"], arena_key)
			check_matches()

		if ("duel_drop")
			if (!duel)
				to_chat(user, span_alert("You're not signed up for a duel!"))
				return

			if (duel.active_duel)
				to_chat(user, span_alert("You can't drop out mid-fight!"))
			else
				qdel(duel)

		if ("trio_drop")
			if (!trio)
				to_chat(user, span_alert("You're not signed up for a three on three fight!"))
				return

			if (trio.active_duel)
				to_chat(user, span_alert("You can't drop out mid-fight!"))
			else
				qdel(trio)

		if ("request_join")
			if (trio)
				to_chat(user, span_alert("You cannot join another team while already signed up!"))
				return

			var/datum/duel_group/group = locate(params["ref"]) in trios
			if (!group || TIMER_COOLDOWN_RUNNING(user, COOLDOWN_ARENA_SIGNUP_REQUEST) || length(group.members) >= 3 || group.active_duel)
				return

			TIMER_COOLDOWN_START(user, COOLDOWN_ARENA_SIGNUP_REQUEST, 60 SECONDS)
			tgui_alert(user, "Awaiting [group.owner.real_name]'s response to your request", "Team Join Request")
			var/choice = tgui_alert(user, "[user.real_name] is requesting to join your arena team. Do you accept their request?", "Team Join Request", list("Yes", "No"), timeout = 60 SECONDS)

			if (QDELETED(user))
				return

			if (choice != "Yes" || QDELETED(group) || QDELETED(group.owner))
				to_chat(user, span_alert("Your request to join [group.owner.real_name]'s team was rejected."))
				return

			for (var/datum/duel_group/trio_group as anything in trios)
				for (var/datum/duel_member/member as anything in trio_group.members)
					if (member.owner == user)
						trio = trio_group
						break
				if (trio)
					break

			if (TIMER_COOLDOWN_RUNNING(user, COOLDOWN_ARENA_SIGNUP_REQUEST) || length(group.members) >= 3 || group.active_duel || trio)
				to_chat(user, span_alert("You can no longer join [group.owner.real_name]'s team."))
				return

			to_chat(user, span_notice("You've been added to [group.owner.real_name]'s team."))
			group.members += new /datum/duel_member(user, group)
			check_matches()

/obj/machinery/computer/ragecage_signup/proc/reset_to_default()
	// yeah thats pretty much it
	INVOKE_ASYNC(src, PROC_REF(load_arena), arena_types[1])

/obj/machinery/computer/ragecage_signup/proc/load_arena(map_id)
	clear_arena()
	var/datum/map_template/template = arena_templates["arena_[map_id]"]
	template.load(bottom_left)
	spawned = template.created_atoms
	for(var/atom/holo_atom as anything in spawned)
		if(QDELETED(holo_atom))
			spawned -= holo_atom
			continue
		finalize_spawned(holo_atom)

/obj/machinery/computer/ragecage_signup/proc/finalize_spawned(atom/holo_atom)
	RegisterSignal(holo_atom, COMSIG_QDELETING, PROC_REF(remove_from_holo_lists))
	holo_atom.flags_1 |= HOLOGRAM_1

	if(isholoeffect(holo_atom)) //activates holo effects and transfers them from the spawned list into the effects list
		var/obj/effect/holodeck_effect/holo_effect = holo_atom
		effects += holo_effect
		spawned -= holo_effect
		var/atom/holo_effect_product = holo_effect.activate(src)//change name
		if(istype(holo_effect_product))
			spawned += holo_effect_product // we want mobs or objects spawned via holoeffects to be tracked as objects
			RegisterSignal(holo_effect_product, COMSIG_QDELETING, PROC_REF(remove_from_holo_lists))
		if(islist(holo_effect_product))
			for(var/atom/atom_product as anything in holo_effect_product)
				spawned += atom_product
				RegisterSignal(atom_product, COMSIG_QDELETING, PROC_REF(remove_from_holo_lists))
		return

	if(!isobj(holo_atom))
		return

	var/obj/holo_object = holo_atom
	holo_object.resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	if(isstructure(holo_object))
		holo_object.obj_flags |= NO_DEBRIS_AFTER_DECONSTRUCTION
		if(istype(holo_object, /obj/structure/closet))
			RegisterSignal(holo_object, COMSIG_CLOSET_CONTENTS_INITIALIZED, PROC_REF(register_contents))
		return

	if(ismachinery(holo_object))
		var/obj/machinery/holo_machine = holo_object
		holo_machine.obj_flags |= NO_DEBRIS_AFTER_DECONSTRUCTION
		holo_machine.power_change()

		if(istype(holo_machine, /obj/machinery/button))
			var/obj/machinery/button/holo_button = holo_machine
			holo_button.setup_device()

/obj/machinery/computer/ragecage_signup/proc/remove_from_holo_lists(datum/to_remove, _forced)
	SIGNAL_HANDLER
	spawned -= to_remove
	UnregisterSignal(to_remove, COMSIG_QDELETING)

/obj/machinery/computer/ragecage_signup/proc/register_contents(obj/structure/closet/storage)
	SIGNAL_HANDLER

	for(var/atom/movable/item as anything in storage.get_all_contents_type(/atom/movable))
		if(item == storage)
			continue
		spawned |= item
		finalize_spawned(item)

/obj/machinery/computer/ragecage_signup/proc/clear_arena()
	// Clear the items from the previous program
	for(var/atom/holo_atom as anything in spawned)
		derez(holo_atom)

	for(var/obj/effect/holodeck_effect/holo_effect as anything in effects)
		effects -= holo_effect
		holo_effect.deactivate(src)

	//makes sure that any time a holoturf is inside a baseturf list (e.g. if someone put a wall over it) its set to the OFFLINE turf
	//so that you cant bring turfs from previous programs into other ones (like putting the plasma burn turf into lounge for example)
	for(var/turf/closed/holo_turf in linked)
		holo_turf.replace_baseturf(/turf/open/floor/holofloor, /turf/open/floor/holofloor/plating)

// Do not rename this, otherwise mobspawners break. I'm too lazy to modularly edit mobspawners and this works so fuck it
// and its not worth the pain making this a holodeck subtype
/obj/machinery/computer/ragecage_signup/proc/derez(atom/movable/holo_atom, silent = TRUE, forced = FALSE)
	spawned -= holo_atom
	if(!holo_atom)
		return
	UnregisterSignal(holo_atom, COMSIG_QDELETING)
	var/turf/target_turf = get_turf(holo_atom)
	for(var/atom/movable/atom_contents as anything in holo_atom) //make sure that things inside of a holoitem are moved outside before destroying it
		if(atom_contents.flags_1 & HOLOGRAM_1) //hologram in hologram is fine
			continue
		atom_contents.forceMove(target_turf)

	if(istype(holo_atom, /obj/item/clothing/under))
		var/obj/item/clothing/under/holo_clothing = holo_atom
		holo_clothing.dump_attachments()

	if(istype(holo_atom, /obj/item/organ))
		var/obj/item/organ/holo_organ = holo_atom
		if(holo_organ.owner) // a mob has the holo organ inside them... oh dear
			to_chat(holo_organ.owner, span_warning("\The [holo_organ] inside of you fades away!"))
	if(!silent)
		visible_message(span_notice("[holo_atom] fades away!"))

	if(is_type_in_list(holo_atom.loc, special_locs))
		qdel(holo_atom.loc)
	qdel(holo_atom)

/obj/machinery/computer/ragecage_signup/proc/check_matches()
	if (prob(50))
		if (!check_duel())
			check_trio()
	else if (!check_trio())
		check_duel()

/obj/machinery/computer/ragecage_signup/proc/check_duel()
	if (length(duels) < 2)
		return FALSE

	new /datum/arena_duel(src, duels[1], duels[2])
	duels.Cut(1, 3)
	return TRUE

/obj/machinery/computer/ragecage_signup/proc/check_trio()
	var/datum/duel_group/first_best = null
	var/datum/duel_group/second_best = null
	for (var/datum/duel_group/group as anything in trios)
		if (length(group.members) > length(first_best?.members) || (length(group.members) == length(first_best?.members) && !first_best.join_random && group.join_random))
			second_best = first_best
			first_best = group
		else if (length(group.members) > length(second_best?.members) || (length(group.members) == length(second_best?.members) && !second_best.join_random && group.join_random))
			second_best = group

	if (!first_best || !second_best)
		return FALSE

	if (length(first_best.members) == 3 && length(second_best.members) == 3)
		new /datum/arena_duel(src, first_best, second_best)
		return TRUE

	if (length(first_best.members) < 3 && !first_best.join_random)
		first_best = null
		for (var/datum/duel_group/group as anything in (trios - second_best))
			if (length(group.members) > length(first_best?.members) && group.join_random)
				first_best = group

	if (length(second_best.members) < 3 && !second_best.join_random)
		second_best = null
		for (var/datum/duel_group/group as anything in (trios - first_best))
			if (length(group.members) > length(second_best?.members) && group.join_random)
				second_best = group

	if (!first_best || !second_best)
		return FALSE

	var/list/datum/duel_group/first_merge = list()
	var/list/datum/duel_group/second_merge = list()
	var/first_miss = 3 - length(first_best.members)
	var/second_miss = 3 - length(second_best.members)

	for (var/datum/duel_group/group as anything in (trios - first_best - second_best))
		if (!group.join_random)
			continue

		if (length(group.members) <= first_miss)
			first_merge += group
			first_miss -= length(group.members)
		else if (length(group.members) <= second_miss)
			second_merge += group
			second_miss -= length(group.members)

	if (first_miss || second_miss)
		return FALSE

	for (var/datum/duel_group/group as anything in first_merge)
		first_best.members += group.members
		group.members.Cut()
		qdel(group)

	for (var/datum/duel_group/group as anything in second_merge)
		second_best.members += group.members
		group.members.Cut()
		qdel(group)

	new /datum/arena_duel(src, first_best, second_best)
	duels -= first_best
	duels -= second_best
	return TRUE

