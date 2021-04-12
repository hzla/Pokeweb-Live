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
import math


def set_global_vars():
	global ROM_NAME, NARC_FORMATS, POKEDEX, ITEMS, TRDATA, MOVES, GENDERS, NARC_PATH
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings['trpok']
		NARC_PATH = f'{ROM_NAME}/narcs/trpok-{NARC_FILE_ID}.narc'


	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()
	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()

	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	GENDERS = ['Default', "Male", "Female"]

	NARC_FORMAT_0 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"]]

	NARC_FORMAT_1 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"],
	[2, "move_1"],
	[2, "move_2"],
	[2, "move_3"],
	[2, "move_4"]]

	NARC_FORMAT_2 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"],
	[2, "item_id"]]

	NARC_FORMAT_3 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"],
	[2, "item_id"],
	[2, "move_1"],
	[2, "move_2"],
	[2, "move_3"],
	[2, "move_4"]]

	NARC_FORMATS = [NARC_FORMAT_0,NARC_FORMAT_1,NARC_FORMAT_2,NARC_FORMAT_3]


def output_trpok_json(trpok_info):
	set_global_vars()
	data_index = 0
	narc = ndspy.narc.NARC.fromFile(NARC_PATH)

	while len(narc.files) < 850:
		narc.files.append(narc.files[0])

	for data in narc.files:	
		data_name = data_index
		template = trpok_info[data_index][0]
		num_pokemon = trpok_info[data_index][1]
		narc_format = NARC_FORMATS[template]

		read_narc_data(data, narc_format, data_name, "trpok", template, num_pokemon)
		data_index += 1

	print("trpok")

def read_narc_data(data, narc_format, file_name, narc_name, template, num_pokemon):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	
	for n in range(0, num_pokemon):
		for entry in narc_format: 
			file["raw"][f'{entry[1]}_{n}'] = read_bytes(stream, entry[0])

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name, template, num_pokemon)
	file["readable"]["template"] = template
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 

def to_readable(raw, file_name, template, num_pokemon):
	readable = copy.deepcopy(raw)

	readable["count"] = num_pokemon

	for n in range(0, num_pokemon):
		

		readable[f'species_id_{n}'] = POKEDEX[raw[f'species_id_{n}']]


		if raw[f'ability_{n}'] == 255:
			raw[f'ability_{n}'] = 0

		readable[f'ability_{n}'] = math.floor(raw[f'ability_{n}'] / 16)

		
		readable[f'gender_{n}'] = GENDERS[raw[f'ability_{n}'] % 16]

		if template == 1 or template == 3:
			for m in range(1,5):
				readable[f'move_{m}_{n}'] = MOVES[raw[f'move_{m}_{n}']]

		if template > 1:
			readable[f'item_id_{n}'] = ITEMS[raw[f'item_id_{n}']]

	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

