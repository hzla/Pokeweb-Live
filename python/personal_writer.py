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

# code.interact(local=dict(globals(), **locals()))

######################### CONSTANTS #############################


NARC_FILE_ID = 258
with open(f'session_settings.json', "r") as outfile:  
	settings = json.load(outfile) 
	NARC_FILE_ID = settings["personal"]
	ROM_NAME = settings['rom_name']

TYPES = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark","Fairy"]
EGG_GROUPS = ["~","Monster","Water 1","Bug","Flying","Field","Fairy","Grass","Human-Like","Water 3","Mineral","Amorphous","Water 2","Ditto","Dragon","Undiscovered"];
GROWTHS = ["Medium Fast","Erratic","Fluctuating","Medium Slow","Fast","Slow","Medium Fast","Medium Fast"]
ABILITIES = open(f'{ROM_NAME}/texts/abilities.txt', "r").read().splitlines() 
ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()
POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()

PERSONAL_NARC_FORMAT = [[1, "base_hp"],
[1,	"base_atk"],
[1,	"base_def"],
[1,	"base_speed"],
[1,	"base_spatk"],
[1,	"base_spdef"],
[1,	"type_1"],
[1,	"type_2"],
[1,	"catchrate"],
[1,	"stage"],
[2,	"evs"],
[2,	"item_1"],
[2,	"item_2"],
[2,	"item_3"],
[1,	"gender"],
[1,	"hatch_cycle"],
[1,	"base_happy"],
[1,	"exp_rate"],
[1,	"egg_group_1"],
[1,	"egg_group_2"],
[1,	"ability_1"],
[1,	"ability_2"],
[1,	"ability_3"],
[1,	"flee"],
[2,	"form_id"],
[2,	"form"],
[1,	"num_forms"],
[1,	"color"],
[2,	"base_exp"],
[2,	"height"],
[2,	"weight"],
[4, "tm_1-32"],
[4, "tm_33-64"],
[4, "tm_65-95+hm_1"],
[4, "hm_2-6"],
[1, "tutors"]]

#################################################################

## TODO instead of opening and editing the entire narc repeatedly, edit a variable 
## and edit the narc just once

def output_narc():
	json_files = os.listdir(f'{ROM_NAME}/json/personal')
	narcfile_path = f'{ROM_NAME}/narcs/personal-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	personal_narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, PERSONAL_NARC_FORMAT, personal_narc)

	old_personal_narc = open(narcfile_path, "wb")
	old_personal_narc.write(personal_narc.save()) 

	print("personal narc saved")

def write_bytes(stream, n, data):
	stream += (data.to_bytes(n, 'little'))		
	return stream

def write_narc_data(file_name, narc_format, personal_narc):
	file_path = f'{ROM_NAME}/json/personal/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/personal-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		personal_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in narc_format: 
			data = personal_data["raw"][entry[1]]
			write_bytes(stream, entry[0], data)

	if file_name >= len(personal_narc.files):
		narc_entry_data = bytearray()
		narc_entry_data[0:len(stream)] = stream
		personal_narc.files.append(narc_entry_data)
	else:
		narc_entry_data = bytearray(personal_narc.files[file_name])
		narc_entry_data[0:len(stream)] = stream
		personal_narc.files[file_name] = narc_entry_data
		
def write_readable_to_raw(file_name):
	personal_data = {}
	with open(f'{ROM_NAME}/json/personal/{file_name}.json', "r", encoding='ISO8859-1') as outfile:  	
		personal_data = json.load(outfile)	
		
		
		if personal_data["readable"] is None:
			return

		new_raw_data = to_raw(personal_data["readable"])
		personal_data["raw"] = new_raw_data

		if personal_data["raw"]["form_sprites"] != "Default":
			sprite_writer.write_sprite_to_index(personal_data["raw"]["form_sprites"], personal_data["raw"]["form"])

	with open(f'{ROM_NAME}/json/personal/{file_name}.json', "w", encoding='ISO8859-1') as outfile: 
		json.dump(personal_data, outfile)



def to_raw(readable):
	raw = copy.deepcopy(readable)

	## input validation is done on the client side with javascript 
	
	raw["type_1"] = TYPES.index(readable["type_1"])
	raw["type_2"] = TYPES.index(readable["type_2"])

	item_1 = readable["item_1"].encode("latin_1").decode("utf_8")
	item_2 = readable["item_2"].encode("latin_1").decode("utf_8")
	item_3 = readable["item_3"].encode("latin_1").decode("utf_8")

	readable["item_1"] = item_1
	readable["item_2"] = item_2
	readable["item_3"] = item_3

	raw["item_1"] = ITEMS.index(item_1)
	raw["item_2"] = ITEMS.index(item_2)
	raw["item_3"] = ITEMS.index(item_3)

	raw["exp_rate"] = GROWTHS.index(raw["exp_rate"])

	raw["egg_group_1"] = EGG_GROUPS.index(raw["egg_group_1"])
	raw["egg_group_2"] = EGG_GROUPS.index(raw["egg_group_2"])

	# abilities are stored uppercase in text bank
	raw["ability_1"] = ABILITIES.index(raw["ability_1"].upper())
	raw["ability_2"] = ABILITIES.index(raw["ability_2"].upper())
	raw["ability_3"] = ABILITIES.index(raw["ability_3"].upper())

	bin_ev = "0000"

	ev_yields = ["hp_yield", "atk_yield", "def_yield", "speed_yield", "spatk_yield", "spdef_yield"]
	ev_yields.reverse()

	for ev in ev_yields:
		bin_ev += bin(readable[ev])[2:].zfill(2)

	raw["evs"] = int(bin_ev, 2)
	
	#TODO CHECK FOR DIGLET DUGTRIO FOR 13TH BIT
	return raw


################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
	
# output_narc()

