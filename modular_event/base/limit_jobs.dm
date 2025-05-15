/datum/job/New()
	. = ..()
	if (type != /datum/job/assistant && type != /datum/job/cyborg)
		job_flags &= ~JOB_NEW_PLAYER_JOINABLE

/datum/controller/subsystem/job/give_random_job(mob/dead/new_player/player)
	return assign_role(player, new /datum/job/assistant)
