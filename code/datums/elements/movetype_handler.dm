/**
 * An element that enables and disables movetype bitflags whenever the relative traits are added or removed.
 * It also handles the +2/-2 pixel y anim loop typical of mobs possessing the FLYING or FLOATING movetypes.
 * This element is necessary for the TRAIT_MOVE_ traits to work correctly, so make sure to attach this element
 * before adding them to non-living movables.
 */
/datum/element/movetype_handler
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY

	var/list/attached_atoms = list()
	var/list/paused_floating_anim_atoms = list()


/datum/element/movetype_handler/Attach(datum/target)
	. = ..()
	if(!ismovable(target))
		return ELEMENT_INCOMPATIBLE
	if(attached_atoms[target]) //Already attached.
		return

	var/atom/movable/movable_target = target
	RegisterSignal(movable_target, GLOB.movement_type_addtrait_signals, PROC_REF(on_movement_type_trait_gain))
	RegisterSignal(movable_target, GLOB.movement_type_removetrait_signals, PROC_REF(on_movement_type_trait_loss))
	RegisterSignal(movable_target, SIGNAL_ADDTRAIT(TRAIT_NO_FLOATING_ANIM), PROC_REF(on_no_floating_anim_trait_gain))
	RegisterSignal(movable_target, SIGNAL_REMOVETRAIT(TRAIT_NO_FLOATING_ANIM), PROC_REF(on_no_floating_anim_trait_loss))
	RegisterSignal(movable_target, COMSIG_PAUSE_FLOATING_ANIM, PROC_REF(pause_floating_anim))
	attached_atoms[movable_target] = TRUE

	if(movable_target.movement_type & (FLOATING|FLYING) && !HAS_TRAIT(movable_target, TRAIT_NO_FLOATING_ANIM))
		DO_FLOATING_ANIM(movable_target)


/datum/element/movetype_handler/Detach(datum/source)
	var/list/signals_to_remove = list(
		SIGNAL_ADDTRAIT(TRAIT_NO_FLOATING_ANIM),
		SIGNAL_REMOVETRAIT(TRAIT_NO_FLOATING_ANIM),
		COMSIG_PAUSE_FLOATING_ANIM
	)
	signals_to_remove += GLOB.movement_type_addtrait_signals
	signals_to_remove += GLOB.movement_type_removetrait_signals
	UnregisterSignal(source, signals_to_remove)

	attached_atoms -= source
	paused_floating_anim_atoms -= source
	STOP_FLOATING_ANIM(source)
	return ..()


/// Called when a movement type trait is added to the movable. Enables the relative bitflag.
/datum/element/movetype_handler/proc/on_movement_type_trait_gain(atom/movable/source, trait)
	SIGNAL_HANDLER
	var/flag = GLOB.movement_type_trait_to_flag[trait]
	if(source.movement_type & flag)
		return
	var/old_state = source.movement_type
	source.movement_type |= flag
	if(!(old_state & (FLOATING|FLYING)) && (source.movement_type & (FLOATING|FLYING)) && !paused_floating_anim_atoms[source] && !HAS_TRAIT(source, TRAIT_NO_FLOATING_ANIM))
		DO_FLOATING_ANIM(source)
	SEND_SIGNAL(source, COMSIG_MOVETYPE_FLAG_ENABLED, flag, old_state)


/// Called when a movement type trait is removed from the movable. Disables the relative bitflag if it wasn't there in the compile-time bitfield.
/datum/element/movetype_handler/proc/on_movement_type_trait_loss(atom/movable/source, trait)
	SIGNAL_HANDLER
	var/flag = GLOB.movement_type_trait_to_flag[trait]
	if(initial(source.movement_type) & flag)
		return
	var/old_state = source.movement_type
	source.movement_type &= ~flag
	if((old_state & (FLOATING|FLYING)) && !(source.movement_type & (FLOATING|FLYING)))
		STOP_FLOATING_ANIM(source)
		var/turf/pitfall = source.loc //Things that don't fly fall in open space.
		if(istype(pitfall))
			pitfall.zFall(source)
	SEND_SIGNAL(source, COMSIG_MOVETYPE_FLAG_DISABLED, flag, old_state)


/// Called when the TRAIT_NO_FLOATING_ANIM trait is added to the movable. Stops it from bobbing up and down.
/datum/element/movetype_handler/proc/on_no_floating_anim_trait_gain(atom/movable/source, trait)
	SIGNAL_HANDLER
	STOP_FLOATING_ANIM(source)


/// Called when the TRAIT_NO_FLOATING_ANIM trait is removed from the mob. Restarts the bobbing animation.
/datum/element/movetype_handler/proc/on_no_floating_anim_trait_loss(atom/movable/source, trait)
	SIGNAL_HANDLER
	if(source.movement_type & (FLOATING|FLYING) && !paused_floating_anim_atoms[source])
		DO_FLOATING_ANIM(source)


///Pauses the floating animation for the duration of the timer... plus [tickrate - (world.time + timer) % tickrate] to be precise.
/datum/element/movetype_handler/proc/pause_floating_anim(atom/movable/source, timer)
	SIGNAL_HANDLER
	if(paused_floating_anim_atoms[source] < world.time + timer)
		STOP_FLOATING_ANIM(source)
		if(!length(paused_floating_anim_atoms))
			START_PROCESSING(SSdcs, src) //1 second tickrate.
		paused_floating_anim_atoms[source] = world.time + timer


/datum/element/movetype_handler/process()
	for(var/_paused in paused_floating_anim_atoms)
		var/atom/movable/paused = _paused
		if(paused_floating_anim_atoms[paused] < world.time)
			if(paused.movement_type & (FLOATING|FLYING) && !HAS_TRAIT(paused, TRAIT_NO_FLOATING_ANIM))
				DO_FLOATING_ANIM(paused)
			paused_floating_anim_atoms -= paused
	if(!length(paused_floating_anim_atoms))
		STOP_PROCESSING(SSdcs, src)

