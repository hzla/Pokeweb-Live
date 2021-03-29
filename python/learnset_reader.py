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
	global ROM_NAME, TYPES, MOVES, LEARNSET_NARC_FORMAT
	

	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

	TYPES = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark","Fairy"]

	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	for i,move in enumerate(MOVES):
		MOVES[i] = re.sub(r'[^A-Za-z0-9 \-]+', '', move)

	LEARNSET_NARC_FORMAT = []

	for n in range(20):
		LEARNSET_NARC_FORMAT.append([2, f'move_id_{n}'])
		LEARNSET_NARC_FORMAT.append([2, f'lvl_learned_{n}'])


#################################################################
## TODO: create universal read_narc_data function that takes name of narc, and to_readable() function as args

def output_learnsets_json(narc):
	set_global_vars()
	data_index = 0
	for data in narc.files:
		data_name = data_index
		read_narc_data(data, LEARNSET_NARC_FORMAT, data_name)
		data_index += 1

def read_narc_data(data, narc_format, file_name):
	stream = io.BytesIO(data)
	learnset = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		learnset_byte = read_bytes(stream, entry[0])

		# stop reading when reaching ffff
		if learnset_byte == 65535:
			break

		learnset["raw"][entry[1]] = learnset_byte

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	learnset["readable"] = to_readable(learnset["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/learnsets'):
		os.makedirs(f'{ROM_NAME}/json/learnsets')

	with open(f'{ROM_NAME}/json/learnsets/{file_name}.json', "w") as outfile:  
		json.dump(learnset, outfile) 

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)
	readable['index'] = file_name

	for n in range(20):
		if f'move_id_{n}' in readable:
			readable[f'move_id_{n}'] = MOVES[raw[f'move_id_{n}']]
			readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	
