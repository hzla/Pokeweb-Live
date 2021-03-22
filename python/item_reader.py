import ndspy
import ndspy.rom
import code 
import io
import os
import os.path
from os import path
import json
import copy


def set_global_vars():
	global ROM_NAME, NARC_FORMAT, ITEMS
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()

	NARC_FORMAT = [[2, "market_value"],
				[1, "battle_flags"],
				[1, "gain_values"],
				[1, "berry_flags"],
				[1, "held_flags"],
				[1, "unknown_flag_1"],
				[1, "nature_gift_power"],
				[2, "type_attribute"],
				[1, "item_group"],
				[1, "battle_item_group"],
				[1, "usability_flag"],
				[1, "item_type"],
				[1, "consumable_flag"],
				[1, "name_order_id"],
				[1, "status_removal_flag"], #also used ball_id
				[1, "hp_atk_boost"],
				[1, "def_spatk_boost"],
				[1, "spd_spdef_boost"],
				[1, "acc_crit_pp_boost"],
				[2, "pp_flags"],
				[1, "hp_ev_gain"],
				[1, "atk_ev_gain"],
				[1, "def_ev_gain"],
				[1, "spd_ev_gain"],
				[1, "spatk_ev_gain"],
				[1, "spdef_ev_gain"],
				[1, "hp_gain"],
				[1, "pp_gain"],
				[1, "battle_happiness"],
				[1, "ow_happiness"],
				[1, "hold_happiness"],
				[2, "padding"]]

	
def output_items_json(narc):
	set_global_vars()
	data_index = 0

	for data in narc.files:
		data_name = data_index
		read_narc_data(data, NARC_FORMAT, data_name, "items")
		data_index += 1

def read_narc_data(data, narc_format, file_name, narc_name):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		file["raw"][entry[1]] = read_bytes(stream, entry[0])

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	readable["name"] = ITEMS[file_name]

	# CONVERT FIELDS HERE
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

