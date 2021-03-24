import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import json
import copy
import sys
import re

# code.interact(local=dict(globals(), **locals()))

######################### CONSTANTS #############################
NARC_FILE_ID = 263
with open(f'session_settings.json', "r") as outfile:  
	settings = json.load(outfile) 
	ROM_NAME = settings['rom_name']
	NARC_FILE_ID = settings["moves"]

TYPES = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark","Fairy"]

CATEGORIES = ["Status","Physical","Special"]

EFFECT_CATEGORIES = ["No Special Effect", "Status Inflicting","Target Stat Changing","Healing","Chance to Inflict Status","Raising Target's Stat along Attack", "Lowering Target's Stat along Attack","Raise user stats","Lifesteal","OHKO","Weather","Safeguard", "Force Switch Out", "Unique Effect"]

EFFECTS = open(f'Reference_Files/effects.txt', "r").read().splitlines() 

STATUSES = ["None","Visible","Temporary","Infatuation", "Trapped"]

TARGETS = ["Any adjacent","Random (User/ Adjacent ally)","Random adjacent ally","Any adjacent opponent","All excluding user","All adjacent opponents","User's party","User","Entire Field","Random adjacent opponent","Field Itself","Opponent's side of field","User's side of field","User (Selects target automatically)"]

STATS = ["None", "Attack", "Defense", "Special Attack", "Special Defense", "Speed", "Accuracy", "Evasion", "All" ]

PROPERTIES = ["contact","requires_charge","recharge_turn","blocked_by_protect","reflected_by_magic_coat","stolen_by_snatch","copied_by_mirror_move","punch_move","sound_move","grounded_by_gravity","defrosts_targets","hits_non-adjacent_opponents","healing_move","hits_through_substitute"]

MOVE_NAMES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

for i,move in enumerate(MOVE_NAMES):
	MOVE_NAMES[i] = re.sub(r'[^A-Za-z0-9 \-]+', '', move)

RESULT_EFFECTS = open(f'Reference_Files/result_effects.txt', "r").read().splitlines()

MOVES_NARC_FORMAT = [[1, "type"],
[1,	"effect_category"],
[1,	"category"],
[1,	"power"],
[1,	"accuracy"],
[1,	"pp"],
[1,	"priority"],
[1,	"hits"],
[2,	"result_effect"],
[1,	"effect_chance"],
[1,	"status"],
[1,	"min_turns"],
[1,	"max_turns"],
[1,	"crit"],
[1,	"flinch"],
[2,	"effect"],
[1,	"recoil"],
[1,	"healing"],
[1,	"target"],
[1,	"stat_1"],
[1,	"stat_2"],
[1,	"stat_3"],
[1,	"magnitude_1"],
[1,	"magnitude_2"],
[1,	"magnitude_3"],
[1,	"stat_chance_1"],
[1,	"stat_chance_2"],
[1,	"stat_chance_3"],
[2,	"flag"], ## Flag is always 53 53
[2,	"properties"]]

#################################################################

## TODO instead of opening and editing the entire narc repeatedly, edit a variable 
## and edit the narc just once

def output_narc(narc_name="moves"):
	json_files = os.listdir(f'{ROM_NAME}/json/moves')
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, MOVES_NARC_FORMAT, narc)

	old_narc = open(narcfile_path, "wb")
	old_narc.write(narc.save()) 

	print("narc saved")

def write_narc_data(file_name, narc_format, narc, narc_name="moves"):
	file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in narc_format: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)
	
	narc_entry_data = bytearray(narc.files[file_name])
	narc_entry_data[0:len(stream)] = stream
	narc.files[file_name] = narc_entry_data
	
def write_readable_to_raw(file_name, narc_name="moves"):
	data = {}
	json_file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	
			
		if json_data["readable"] is None:
			return
		new_raw_data = to_raw(json_data["readable"])
		json_data["raw"] = new_raw_data

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(json_data, outfile)

def to_raw(readable):
	raw = copy.deepcopy(readable)

	raw["type"] = TYPES.index(readable["type"])

	raw["effect_category"] = EFFECT_CATEGORIES.index(readable["effect_category"])
	
	raw["category"] = CATEGORIES.index(readable["category"])

	#special case for tri attack
	if readable["result_effect"] == "Chance of either Paralyzing; Burning; or Freezing target":
		raw["result_effect"] = 65535
	else:
		raw["result_effect"] = RESULT_EFFECTS.index(raw["result_effect"])

	raw["effect"] = EFFECTS.index(raw["effect"])

	raw["status"] = STATUSES.index(raw["status"])

	if readable["recoil"] > 0:
		raw["recoil"] = 256 - readable["recoil"]

	raw["target"] = TARGETS.index(raw["target"])

	raw["stat_1"] = STATS.index(readable["stat_1"])
	raw["stat_2"] = STATS.index(readable["stat_2"])
	raw["stat_3"] = STATS.index(readable["stat_3"])

	if readable["magnitude_1"] < 0:
		raw["magnitude_1"] = readable["magnitude_1"] + 256

	if readable["magnitude_2"] < 0:
		raw["magnitude_2"] = readable["magnitude_2"] + 256

	if readable["magnitude_3"] < 0:
		raw["magnitude_3"] = readable["magnitude_3"] + 256

	binary_hits = ""
	hits = ["max_hits", "min_hits"]
	for hit in hits:
		binary_hits += bin(readable[hit])[2:].zfill(4)
	raw["hits"] = int(binary_hits, 2)

	binary_props = ""
	PROPERTIES.reverse()
	
	for prop in PROPERTIES:
		binary_props += bin(readable[prop])[2:].zfill(1)
	raw["properties"] = int(binary_props, 2)


	return raw
	

def write_bytes(stream, n, data):
	stream += (data.to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
	
# output_narc()

# write_readable_to_raw(1)