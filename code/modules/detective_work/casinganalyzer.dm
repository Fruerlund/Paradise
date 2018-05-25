/obj/machinery/cartridgeanalyzer
	name = "\improper Cartridge Analyzer"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "juicer1"
	desc = "Used for comparing bullet casings."
	layer = 2.9
	anchored = 1
	use_power = 1
	idle_power_usage = 5
	active_power_usage = 100
	pass_flags = PASSTABLE

	var/operating = 0
	var/list/allowed_list = list(/obj/item/ammo_casing)

/obj/machinery/cartridgeanalyzer/New()
	..()

/obj/machinery/cartridgeanalyzer/Destroy()

	if(contents.len)

		for(var/obj/item/P in contents)
			P.loc = get_turf(src)

	return..()

/obj/machinery/cartridgeanalyzer/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/cartridgeanalyzer/attack_ghost(mob/user)
	ui_interact(user)

/obj/machinery/cartridgeanalyzer/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "cartridgeanalyzer.tmpl", "Cartridge Analyzer UI", 540, 450)
		ui.open()

/obj/machinery/cartridgeanalyzer/ui_data(mob/user, ui_key = "main", datum/topic_state/state = default_state)

	var/data[0]

	if(operating)
		data["operating"] = "Scanning"
	else
		data["operating"] = "Analyze"

/obj/machinery/cartridgeanalyzer/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["scan"])

		analyzecasings()

	if(href_list["eject"])

		eject()

/obj/machinery/cartridgeanalyzer/attackby(obj/item/P, mob/user)

	if(istype(P, /obj/item/wrench))
		playsound(src, P.usesound, 50, 1)
		if(anchored)
			anchored = 0
			to_chat(user, "<span class='alert'>\The [src] can now be moved.</span>")
			return
		else if(!anchored)
			anchored = 1
			to_chat(user, "<span class='alert'>\The [src] is now secured.</span>")
			return

	var/allowed = is_type_in_list(P, allowed_list)

	if(allowed)

		if(contents && contents.len < 3)

			var/obj/item/ammo_casing/A = P
			to_chat(usr, "You add [A] to the analyzer.")
			user.drop_item()
			A.forceMove(src)
			contents += A
			return TRUE

		to_chat(user, "<span class='alert'>\The [src] cannot hold more catridges.</span>")
		return FALSE

	to_chat(user, "<span class='alert'>\The [src] cannot hold [P].</span>")
	return FALSE



/obj/machinery/cartridgeanalyzer/verb/eject()

	set category = "Object"
	set name = "Empty Analyzer"
	set src in oview(1)

	add_fingerprint(usr)

	if(!(contents.len))
		return FALSE

	for(var/obj/item/O in contents)
		contents -= O
		O.loc = loc

/obj/machinery/cartridgeanalyzer/verb/analyzecasings()

	set category = "Object"
	set name = "Analyze Casings"
	set src in oview(1)

	add_fingerprint(usr)

	if(!(contents.len))
		to_chat(usr, "<span class='alert'>\The [src] does not contain anything to scan.</span>")
		return FALSE

	if(contents.len == 1)
		to_chat(usr, "<span class='alert'>\The [src] does not contain a second catridge.</span>")
		return TRUE


	if(operating)
		to_chat(usr, "<span class='alert'>\The [src] is already scanning.</span>")
		return FALSE

	operating = 1
	to_chat(usr, "\The [src] starts scanning.")
	spawn(50)

	check_list()

/obj/machinery/cartridgeanalyzer/proc/check_list()

	var/list/compare_list = list()

	for(var/obj/item/P in contents)

		if(istype(P, /obj/item/ammo_casing))

			var/obj/item/ammo_casing/A = P
			compare_list += A.casingid

	var/result = "<b>Item A:	</b> [compare_list[1]]"
	result += "<b>Item B:	</b>[compare_list[2]]"

	if(compare_list[1] == compare_list[2])

		playsound(src.loc, 'sound/machines/ping.ogg', 50, 1)
		result += "<b>Match Percentage:	</b>: 100 % "

	else

		playsound(src.loc, 'sound/machines/buzz-two.ogg', 50, 1)
		result += "<b>Match Percentage:	</b>: 0 % "

	eject()
	print_report(result)

/obj/machinery/cartridgeanalyzer/proc/print_report(var/datatoprint)

	usr.visible_message("<span class='warning'>[src] rattles and prints out a sheet of paper.</span>")
	playsound(loc, 'sound/goonstation/machines/printer_thermal.ogg', 50, 1)

	var/obj/item/paper/P = new(get_turf(src))
	P.name = "paper - Cartridge Analyzer Report: [station_time_timestamp()]"
	P.info = "<large><center><b>Catridge Analyzerbr>Scan Analysis:</center><hr>"
	P.info += "<b>Scan Conducted at:	 [station_time_timestamp()]</b><br>"
	P.info += "<b>Scan by:</b>	 [usr]<br>"
	P.info += datatoprint
	P.info += "<hr><b>Notes:</b>"

	operating = FALSE
	return TRUE