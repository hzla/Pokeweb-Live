import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import json
import copy
import sys
import sprite_writer
import rom_data
import tools

# code.interact(local=dict(globals(), **locals()))


def output_narc(rom, narc_name="personal"):
	return tools.output_narc("personal", rom)

def write_readable_to_raw(file_name):
	personal_data = {}
	with open(f'{rom_data.ROM_NAME}/json/personal/{file_name}.json', "r", encoding='ISO8859-1') as outfile:  	
		personal_data = json.load(outfile)	
		
		
		if personal_data["readable"] is None:
			return

		new_raw_data = to_raw(personal_data["readable"])
		personal_data["raw"] = new_raw_data

		if personal_data["raw"]["form_sprites"] != "Default" and personal_data["raw"]["form"] != 0:
			print("updating sprites")
			sprite_writer.write_sprite_to_index(personal_data["raw"]["form_sprites"], personal_data["raw"]["form"])

	with open(f'{rom_data.ROM_NAME}/json/personal/{file_name}.json', "w", encoding='ISO8859-1') as outfile: 
		json.dump(personal_data, outfile)


def to_raw(readable):
	raw = copy.deepcopy(readable)

	## input validation is done on the client side with javascript 
	
	raw["type_1"] = rom_data.TYPES.index(readable["type_1"])
	raw["type_2"] = rom_data.TYPES.index(readable["type_2"])

	item_1 = readable["item_1"].encode("latin_1").decode("utf_8").replace("Ã\x83Â©","é").replace('Ã©', 'é')
	item_2 = readable["item_2"].encode("latin_1").decode("utf_8").replace("Ã\x83Â©","é").replace('Ã©', 'é')
	item_3 = readable["item_3"].encode("latin_1").decode("utf_8").replace("Ã\x83Â©","é").replace('Ã©', 'é')

	readable["item_1"] = item_1
	readable["item_2"] = item_2
	readable["item_3"] = item_3

	raw["item_1"] = rom_data.ITEMS.index(item_1)
	raw["item_2"] = rom_data.ITEMS.index(item_2)
	raw["item_3"] = rom_data.ITEMS.index(item_3)

	raw["exp_rate"] = rom_data.GROWTHS.index(raw["exp_rate"])

	raw["egg_group_1"] = rom_data.EGG_GROUPS.index(raw["egg_group_1"])
	raw["egg_group_2"] = rom_data.EGG_GROUPS.index(raw["egg_group_2"])

	# abilities are stored uppercase in text bank
	raw["ability_1"] = rom_data.ABILITIES.index(raw["ability_1"].upper())
	raw["ability_2"] = rom_data.ABILITIES.index(raw["ability_2"].upper())
	raw["ability_3"] = rom_data.ABILITIES.index(raw["ability_3"].upper())

	bin_ev = "0000"

	ev_yields = ["hp_yield", "atk_yield", "def_yield", "speed_yield", "spatk_yield", "spdef_yield"]
	ev_yields.reverse()

	for ev in ev_yields:
		bin_ev += bin(int(readable[ev]))[2:].zfill(2)

	raw["evs"] = int(bin_ev, 2)
	
	#TODO CHECK FOR DIGLET DUGTRIO FOR 13TH BIT
	return raw


################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars()
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	

