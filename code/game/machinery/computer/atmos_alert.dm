/obj/machinery/computer/atmos_alert
	name = "atmospheric alert computer"
	desc = "Used to access the station's atmospheric sensors."
	circuit = /obj/item/circuitboard/atmos_alert
	var/ui_x = 350
	var/ui_y = 300
	icon_keyboard = "atmos_key"
	icon_screen = "alert:0"
	light_color = LIGHT_COLOR_CYAN
	var/list/priority_alarms = list()
	var/list/minor_alarms = list()
	var/receive_frequency = ATMOS_FIRE_FREQ

/obj/machinery/computer/atmos_alert/Initialize(mapload)
	. = ..()
	set_frequency(receive_frequency)

/obj/machinery/computer/atmos_alert/Destroy()
	SSradio.remove_object(src, receive_frequency)
	return ..()

/obj/machinery/computer/atmos_alert/attack_hand(mob/user)
	if(..())
		return TRUE

	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/atmos_alert/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosAlertConsole", name)
		ui.open()

/obj/machinery/computer/atmos_alert/ui_data(mob/user)
	var/list/data = list()

	data["priority"] = list()
	for(var/zone in priority_alarms)
		data["priority"] |= zone
	data["minor"] = list()
	for(var/zone in minor_alarms)
		data["minor"] |= zone

	return data

/obj/machinery/computer/atmos_alert/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("clear")
			var/zone = params["zone"]
			if(zone in priority_alarms)
				to_chat(usr, span_notice("Priority alarm for [zone] cleared."))
				priority_alarms -= zone
				. = TRUE
			if(zone in minor_alarms)
				to_chat(usr, span_notice("Minor alarm for [zone] cleared."))
				minor_alarms -= zone
				. = TRUE
	update_icon()

/obj/machinery/computer/atmos_alert/set_frequency(new_frequency)
	SSradio.remove_object(src, receive_frequency)
	receive_frequency = new_frequency
	radio_connection = SSradio.add_object(src, receive_frequency, RADIO_ATMOSIA)

/obj/machinery/computer/atmos_alert/receive_signal(datum/signal/signal)
	if(!signal)
		return

	var/zone = signal.data["zone"]
	var/severity = signal.data["alert"]

	if(!zone || !severity)
		return

	minor_alarms -= zone
	priority_alarms -= zone
	if(severity == "severe")
		priority_alarms += zone
	else if(severity == "minor")
		minor_alarms += zone
	update_icon()


/obj/machinery/computer/atmos_alert/update_icon_state()
	if(length(priority_alarms))
		icon_screen = "alert:2"
	else if(length(minor_alarms))
		icon_screen = "alert:1"
	else
		icon_screen = "alert:0"

/obj/machinery/computer/atmos_alert/old_frame
	icon = 'icons/obj/machines/computer3.dmi'
	icon_state = "frame-eng"
	icon_keyboard = "kb4"
