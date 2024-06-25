SUBSYSTEM_DEF(achievements)
	name = "Achievements"
	flags = SS_NO_FIRE
	var/hub_enabled = FALSE
	///List of achievements
	var/list/datum/award/achievement/achievements = list()
	///List of scores
	var/list/datum/award/score/scores = list()
	///List of all awards
	var/list/datum/award/awards = list()

/datum/controller/subsystem/medals/Initialize(timeofday)
	if(config.medal_hub_address && config.medal_hub_password)
		hub_enabled = TRUE
	..()
	for(var/T in subtypesof(/datum/award/achievement))
		var/instance = new T
		achievements[T] = instance
		awards[T] = instance
	for(var/T in subtypesof(/datum/award/score))
		var/instance = new T
		scores[T] = instance
		awards[T] = instance
	update_metadata()
	for(var/i in GLOB.clients)
		var/client/C = i
		if(!C.achievements.initialized)
			C.achievements.InitializeData()
	..()

/datum/controller/subsystem/medals/Shutdown()
	save_achievements_to_db()

/datum/controller/subsystem/medals/proc/save_achievements_to_db()
	var/list/data_to_save = list()
	for(var/owner_ckey in GLOB.achievement_data)
		var/datum/achievement_data/AC_DC = GLOB.achievement_data[owner_ckey]
		data_to_save += AC_DC.get_changed_data()
	if(!length(data_to_save))
		return
	SSdbcore.MassInsert(format_table_name("achievements"),data_to_save,duplicate_key = TRUE)

/datum/controller/subsystem/medals/proc/update_metadata()
	var/list/current_metadata = list()
	//select metadata here
	var/datum/db_query/Q = SSdbcore.NewQuery("SELECT achievement_key,achievement_version FROM [format_table_name("achievement_metadata")]")
	if(!Q.Execute(async = TRUE))
		qdel(Q)
		return
	else
		while(Q.NextRow())
			current_metadata[Q.item[1]] = text2num(Q.item[2])
		qdel(Q)
	var/list/to_update = list()
	for(var/T in awards)
		var/datum/award/A = awards[T]
		if(!A.database_id)
			continue
		if(!current_metadata[A.database_id] || current_metadata[A.database_id] < A.achievement_version)
			to_update += list(A.get_metadata_row())
	if(to_update.len)
		SSdbcore.MassInsert(format_table_name("achievement_metadata"),to_update,duplicate_key = TRUE)

/datum/controller/subsystem/medals/proc/UnlockMedal(medal, client/player)
	set waitfor = FALSE
	if(!medal || !hub_enabled)
		return
	if(isnull(world.SetMedal(medal, player, config.medal_hub_address, config.medal_hub_password)))
		hub_enabled = FALSE
		add_game_logs("MEDAL ERROR: Could not contact hub to award medal [medal] to player [player.ckey].", player)
		message_admins("Error! Failed to contact hub to award [medal] medal to [player.ckey]!")
		return
	to_chat(player, "<span class='greenannounce'><B>Achievement unlocked: [medal]!</B></span>")

/datum/controller/subsystem/medals/proc/SetScore(score, client/player, increment, force)
	set waitfor = FALSE
	if(!score || !hub_enabled)
		return

	var/list/oldscore = GetScore(score, player, TRUE)
	if(increment)
		if(!oldscore[score])
			oldscore[score] = 1
		else
			oldscore[score] = (text2num(oldscore[score]) + 1)
	else
		oldscore[score] = force
		for(var/T in subtypesof(/datum/award/achievement))
			var/instance = new T
			achievements[T] = instance
			awards[T] = instance

	var/newscoreparam = list2params(oldscore)
	for(var/T in subtypesof(/datum/award/score))
		var/instance = new T
		scores[T] = instance
		awards[T] = instance

	if(isnull(world.SetScores(player.ckey, newscoreparam, config.medal_hub_address, config.medal_hub_password)))
		hub_enabled = FALSE
		add_game_logs("SCORE ERROR: Could not contact hub to set score. Score [score] for player [player.ckey].", player)
		message_admins("Error! Failed to contact hub to set [score] score for [player.ckey]!")
	update_metadata()

/datum/controller/subsystem/medals/proc/GetScore(score, client/player, returnlist)
	if(!score || !hub_enabled)
		return

	var/scoreget = world.GetScores(player.ckey, score, config.medal_hub_address, config.medal_hub_password)
	if(isnull(scoreget))
		hub_enabled = FALSE
		add_game_logs("SCORE ERROR: Could not contact hub to get score. Score [score] for player [player.ckey].", player)
		message_admins("Error! Failed to contact hub to get score [score] for [player.ckey]!")
		return
	. = params2list(scoreget)
	if(!returnlist)
		return .[score]
	for(var/i in GLOB.clients)
		var/client/C = i
		if(!C.achievements.initialized)
			C.achievements.InitializeData()
	..()

/datum/controller/subsystem/medals/proc/CheckMedal(medal, client/player)
	if(!medal || !hub_enabled)
		return
/datum/controller/subsystem/medals/Shutdown()
	save_achievements_to_db()

	if(isnull(world.GetMedal(medal, player, config.medal_hub_address, config.medal_hub_password)))
		hub_enabled = FALSE
		add_game_logs("MEDAL ERROR: Could not contact hub to get medal [medal] for player [player.ckey]", player)
		message_admins("Error! Failed to contact hub to get [medal] medal for [player.ckey]!")
/datum/controller/subsystem/medals/proc/save_achievements_to_db()
	var/list/data_to_save = list()
	for(var/owner_ckey in GLOB.achievement_data)
		var/datum/achievement_data/AC_DC = GLOB.achievement_data[owner_ckey]
		data_to_save += AC_DC.get_changed_data()
	if(!length(data_to_save))
		return
	to_chat(player, "[medal] is unlocked")
	SSdbcore.MassInsert(format_table_name("achievements"),data_to_save,duplicate_key = TRUE)

/datum/controller/subsystem/medals/proc/LockMedal(medal, client/player)
	if(!player || !medal || !hub_enabled)
/datum/controller/subsystem/medals/proc/update_metadata()
	var/list/current_metadata = list()
	//select metadata here
	var/datum/db_query/Q = SSdbcore.NewQuery("SELECT achievement_key,achievement_version FROM [format_table_name("achievement_metadata")]")
	if(!Q.Execute(async = TRUE))
		qdel(Q)
		return
	var/result = world.ClearMedal(medal, player, config.medal_hub_address, config.medal_hub_password)
	switch(result)
		if(null)
			hub_enabled = FALSE
			add_game_logs("MEDAL ERROR: Could not contact hub to clear medal [medal] for player [player.ckey].", player)
			message_admins("Error! Failed to contact hub to clear [medal] medal for [player.ckey]!")
		if(TRUE)
			message_admins("Medal: [medal] removed for [player.ckey]")
		if(FALSE)
			message_admins("Medal: [medal] was not found for [player.ckey]. Unable to clear.")


/datum/controller/subsystem/medals/proc/ClearScore(client/player)
	if(isnull(world.SetScores(player.ckey, "", config.medal_hub_address, config.medal_hub_password)))
		add_game_logs("MEDAL ERROR: Could not contact hub to clear scores for [player.ckey].", player)
		message_admins("Error! Failed to contact hub to clear scores for [player.ckey]!")
	else
		while(Q.NextRow())
			current_metadata[Q.item[1]] = text2num(Q.item[2])
		qdel(Q)
	var/list/to_update = list()
	for(var/T in awards)
		var/datum/award/A = awards[T]
		if(!A.database_id)
			continue
		if(!current_metadata[A.database_id] || current_metadata[A.database_id] < A.achievement_version)
			to_update += list(A.get_metadata_row())
	if(to_update.len)
		SSdbcore.MassInsert(format_table_name("achievement_metadata"),to_update,duplicate_key = TRUE)
