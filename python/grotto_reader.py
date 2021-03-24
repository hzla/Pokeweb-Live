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
	global ROM_NAME, NARC_FORMAT, GROTTO_NAMES, POKEDEX, ITEMS
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()
	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()
	GROTTO_NAMES = open('Reference_Files/grotto_locations.txt', mode="r").read().splitlines()

	NARC_FORMAT = []

	for version in ["white", "black"]:
		for rarity in ["rare", "uncommon", "common"]:
			for n in range(0,4):
				NARC_FORMAT.append([2, f'{version}_{rarity}_pok_{n}'])
			for n in range(0,4):
				NARC_FORMAT.append([1, f'{version}_{rarity}_max_lvl_{n}'])
			for n in range(0,4):
				NARC_FORMAT.append([1, f'{version}_{rarity}_min_lvl_{n}'])
			for n in range(0,4):
				NARC_FORMAT.append([1, f'{version}_{rarity}_gender_{n}'])
			for n in range(0,4):
				NARC_FORMAT.append([1, f'{version}_{rarity}_form_{n}'])

			NARC_FORMAT.append([2, f'{version}_{rarity}_padding'])

	for item_type in ["normal", "hidden"]:
		for rarity in ["superrare", "rare", "uncommon", "common"]:
			for n in range(0,4):
				NARC_FORMAT.append([2, f'{item_type}_{rarity}_item_{n}'])


def output_grottos_json(narc):
	set_global_vars()
	data_index = 0

	for data in narc.files:
		data_name = data_index
		read_narc_data(data, NARC_FORMAT, data_name, "grottos")
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

	readable["name"] = GROTTO_NAMES[file_name]

	for version in ["black", "white"]:
		for rarity in ["rare", "uncommon", "common"]:
			for n in range(0,4):
				readable[f'{version}_{rarity}_pok_{n}'] = POKEDEX[raw[f'{version}_{rarity}_pok_{n}']]
		

	for item_type in ["normal", "hidden"]:
		for rarity in ["superrare", "rare", "uncommon", "common"]:
			for n in range(0,4):
				readable[f'{item_type}_{rarity}_item_{n}'] = ITEMS[raw[f'{item_type}_{rarity}_item_{n}']]


	# CONVERT FIELDS HERE
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

