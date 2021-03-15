import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import os.path
from os import path
import json
import copy
import re

# code.interact(local=dict(globals(), **locals()))

######################### FILE SPECIFIC CONSTANTS #############################

def set_global_vars():
	global ROM_NAME, TYPES, CATEGORIES, EFFECT_CATEGORIES, EFFECTS, STATUSES, TARGETS, STATS, PROPERTIES, MOVE_NAMES, MOVES_NARC_FORMAT, RESULT_EFFECTS
	

	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

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

def output_moves_json(narc):
	set_global_vars()
	data_index = 0
	for data in narc.files:
		data_name = data_index
		read_narc_data(data, MOVES_NARC_FORMAT, data_name)
		data_index += 1


def read_narc_data(data, narc_format, file_name):
	stream = io.BytesIO(data)
	move = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		move["raw"][entry[1]] = read_bytes(stream, entry[0])

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	move["readable"] = to_readable(move["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/moves'):
		os.makedirs(f'{ROM_NAME}/json/moves')

	with open(f'{ROM_NAME}/json/moves/{file_name}.json', "w") as outfile:  
		json.dump(move, outfile) 


def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)



	readable["index"] = file_name
	readable["name"]  = MOVE_NAMES[file_name]
	
	readable["type"] = TYPES[raw["type"]]

	readable["effect_category"] = EFFECT_CATEGORIES[raw["effect_category"]]
	
	readable["category"] = CATEGORIES[raw["category"]]

	#special case for tri attack
	if raw["result_effect"] == 65535:
		readable["result_effect"] = EFFECTS[36]
	else:
		readable["result_effect"] = RESULT_EFFECTS[raw["result_effect"]]

	readable["effect"] = EFFECTS[raw["effect"]]

	readable["status"] = STATUSES[raw["status"]]

	if raw["recoil"] > 0:
		readable["recoil"] = 256 - raw["recoil"]

	readable["target"] = TARGETS[raw["target"]]

	readable["stat_1"] = STATS[raw["stat_1"]]
	readable["stat_2"] = STATS[raw["stat_2"]]
	readable["stat_3"] = STATS[raw["stat_3"]]

	if raw["magnitude_1"] > 6:
		readable["magnitude_1"] = raw["magnitude_1"] - 256

	if raw["magnitude_2"] > 6:
		readable["magnitude_2"] = raw["magnitude_2"] - 256

	if raw["magnitude_3"] > 6:
		readable["magnitude_3"] = raw["magnitude_3"] - 256

	index = 8
	binary_hits = bin(raw["hits"])[2:].zfill(index)

	hits = ["min_hits", "max_hits"]
	for hit in hits:
		amount = int(binary_hits[index-4:index],2)
		readable[hit] = amount
		index -= 4

	index = 14
	binary_props = bin(raw["properties"])[2:].zfill(index) 
	
	for prop in PROPERTIES:
		amount = int(binary_props[index - 1])
		readable[prop] = amount
		index -= 1


	return readable

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	
