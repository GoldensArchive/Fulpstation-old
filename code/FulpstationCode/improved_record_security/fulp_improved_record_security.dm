#define SEC_RECORD_BAD_CLEARANCE "ACCESS DENIED: User ID has inadequate clearance."

#define SEC_RECORD_BOT_COOLDOWN 60 SECONDS


/mob/living/simple_animal/bot/secbot/proc/arrest_security_record(mob/living/carbon/C, arrest_type, threat, location)

	if(!C) //Sanity
		return

	if(arrest_cooldown.Find(C)) //Don't arrest people whose names are in the cooldown list
		return

	for(var/obj/machinery/computer/secure_data/sec_comp in GLOB.machines)
		if(sec_comp)
			sec_comp.secbot_entry(C, src, arrest_type, threat, location)
			arrest_cooldown += C
			addtimer(CALLBACK(src, /mob/living/simple_animal/bot/secbot.proc/sec_record_bot_cooldown_end,C), SEC_RECORD_BOT_COOLDOWN)
			return

/mob/living/simple_animal/bot/secbot/proc/sec_record_bot_cooldown_end(mob/living/carbon/C)
	arrest_cooldown -= C //Remove from the cooldown list


/obj/machinery/computer/secure_data/proc/secbot_entry(mob/living/carbon/C, mob/living/simple_animal/bot/secbot/S, arrest_type, threat, location)
	var/bot_authenticated = "[S.name]"
	var/bot_rank = "Security Robot"
	var/t1 = "[bot_authenticated] [arrest_type ? "Detained" : "Arrested"] [C] at [location]. Threat level: [threat]"

	for(var/datum/data/record/R in GLOB.data_core.security)
		if(!R) //Sanity
			return

		if(R.fields["name"] == "[C.name]")
			active2 = R //We found the record we want
			break

	var/counter = 1
	while(active2.fields[text("com_[]", counter)])
		counter++
	active2.fields[text("com_[]", counter)] = text("<b>Made by [] ([]) on [] [], []</b><BR>[]", bot_authenticated, bot_rank, station_time_timestamp(), time2text(world.realtime, "MMM DD"), GLOB.year_integer+540, t1)


/obj/machinery/computer/secure_data/proc/check_input_clearance(mob/M, delete = FALSE)
	if(!issilicon(M) && !IsAdminGhost(M)) //Silicons and AdminGhosts ignore access checks.
		var/obj/item/card/id/I = M.get_idcard(TRUE)
		if(!I)
			return FALSE
		req_access = list(ACCESS_SECURITY, ACCESS_ARMORY)
		if(delete) //Wardens can modify security record entries, but cannot delete them; only HoS, Silicons and Captain can do that.
			req_access = list(ACCESS_SECURITY, ACCESS_ARMORY, ACCESS_KEYCARD_AUTH)
		if(!check_access(I))
			req_access = null
			return FALSE
		req_access = null
	return TRUE

/obj/machinery/computer/secure_data/proc/delete_allrecords_feedback()
	temp = ""
	if(check_input_clearance(usr, TRUE))
		temp += "<h5><b>Are you sure you wish to delete all Security records?</b></h5><br>"
		temp += "<a href='?src=[REF(src)];choice=Purge All Records'>Yes</a><br>"
		temp += "<a href='?src=[REF(src)];choice=Clear Screen'>No</a>"
	else
		temp += "<a href='?src=[REF(src)];choice=Clear Screen'><b>[SEC_RECORD_BAD_CLEARANCE]</b></a>"
	return temp


/obj/machinery/computer/secure_data/proc/delete_record_feedback(type = "Security Portion Only")
	temp = ""
	if(check_input_clearance(usr, TRUE))
		temp = "<h5><b>Are you sure you wish to delete the record ([type])?</b></h5><br>"
		temp += "<a href='?src=[REF(src)];choice=Delete Record ([type]) Execute'>Yes</a><br>"
		temp += "<a href='?src=[REF(src)];choice=Clear Screen'>No</a>"
	else
		temp += "<a href='?src=[REF(src)];choice=Clear Screen'><b>[SEC_RECORD_BAD_CLEARANCE]</b></a>"

	return temp