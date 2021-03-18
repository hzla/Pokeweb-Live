import ndspy
import ndspy.rom
import code 
import io
import os
import os.path
from os import path
import json
import copy
from math import floor

def set_global_vars():
	global LOCATIONS, ROM_NAME, ENCOUNTER_NARC_FORMAT, POKEDEX
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

	LOCATIONS = open(f'{ROM_NAME}/texts/locations.txt', mode="r").read().splitlines()

	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()

	ENCOUNTER_NARC_FORMAT = [[1, "grass_rate"],
	[1, "grass_doubles_rate"],
	[1, "grass_special_rate"],
	[1, "surf_rate"],
	[1, "surf_special_rate"],
	[1, "super_rod_rate"],
	[1, "super_rod_special_rate"],
	[1, "blank"]]

	for enc_type in ["grass", "grass_doubles", "grass_special"]:
		for n in range(0,12):
			ENCOUNTER_NARC_FORMAT.append([2, f'{enc_type}_slot_{n}'])
			ENCOUNTER_NARC_FORMAT.append([1, f'{enc_type}_slot_{n}_min_level'])
			ENCOUNTER_NARC_FORMAT.append([1, f'{enc_type}_slot_{n}_max_level'])

	for wat_enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
		for n in range(0,5):
			ENCOUNTER_NARC_FORMAT.append([2, f'{wat_enc_type}_slot_{n}'])
			ENCOUNTER_NARC_FORMAT.append([1, f'{wat_enc_type}_slot_{n}_min_level'])
			ENCOUNTER_NARC_FORMAT.append([1, f'{wat_enc_type}_slot_{n}_max_level'])

def output_encounters_json(narc):
	set_global_vars()
	data_index = 0
	for data in narc.files:
		data_name = data_index
		read_narc_data(data, ENCOUNTER_NARC_FORMAT, data_name, "encounters")
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
	for enc_type in ["grass", "grass_doubles", "grass_special"]:
		for n in range(0,12):
			index = raw[f'{enc_type}_slot_{n}']
			
			if index >= 2048:
				readable[f'{enc_type}_slot_{n}_form'] = floor(index / 2048)
				index = index % 2048

			readable[f'{enc_type}_slot_{n}'] = POKEDEX[index]

	for wat_enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
		for n in range(0,5):
			index = raw[f'{wat_enc_type}_slot_{n}']		
			if index >= 2048:
				readable[f'{wat_enc_type}_slot_{n}_form'] = floor(index / 2048)
				index = index % 2048

			readable[f'{wat_enc_type}_slot_{n}'] = POKEDEX[index]


	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

