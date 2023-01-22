import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc
import code 
import io
import os
import os.path
from os import path
import json
import copy
import re
import rom_data
# code.interact(local=dict(globals(), **locals()))

######################### FILE SPECIFIC CONSTANTS #############################

def set_global_vars(rom_name):
	global ROM_NAME, NARC_FORMAT, BASE_ROM, MOVES
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']

	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	NARC_FORMAT = []

	for n in range(258):
		NARC_FORMAT.append([4, f'move_id_{n}'])
		NARC_FORMAT.append([4, f'address_{n}'])



#################################################################
## TODO: create universal read_data function that takes name of narc, and to_readable() function as args

def output_move_effects_table_json(move_effects_table, rom_name):
	set_global_vars(rom_name)
	data_name = "move_effects_table"
	folder_name = "arm9"

	read_data(move_effects_table, NARC_FORMAT, data_name, folder_name)


def read_data(data, narc_format, file_name, folder_name):
	stream = data
	json_data = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		byte = read_bytes(stream, entry[0])
		json_data["raw"][entry[1]] = byte

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	json_data["readable"] = to_readable(json_data["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{folder_name}'):
		os.makedirs(f'{ROM_NAME}/json/{folder_name}')

	with open(f'{ROM_NAME}/json/{folder_name}/{file_name}.json', "w") as outfile:  
		json.dump(json_data, outfile) 

	effect_mappings = {}

	for n in range(258):
		effect_mappings[json_data["readable"][f"move_id_{n}"]] = json_data["readable"][f"address_{n}"]

	with open(f'{ROM_NAME}/json/{folder_name}/effect_mappings.json', "w") as outfile:  
		json.dump(effect_mappings, outfile) 


def to_readable(raw, file_name=""):
	readable = copy.deepcopy(raw)

	for n in range(258):
		readable[f'move_id_{n}'] = MOVES[raw[f'move_id_{n}']] 

	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')


