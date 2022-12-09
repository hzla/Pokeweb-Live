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


	LOCATIONS = open(f'{ROM_NAME}/texts/locations.txt', mode="r" ,encoding='utf-8').read().splitlines()


	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()

	ENCOUNTER_NARC_FORMAT = []

	seasons = ["spring", "summer", "fall", "winter"]

	for season in seasons:
		s_encounters = [[1,f'{season}_grass_rate'],
		[1, f'{season}_grass_doubles_rate'],
		[1, f'{season}_grass_special_rate'],
		[1, f'{season}_surf_rate'],
		[1, f'{season}_surf_special_rate'],
		[1, f'{season}_super_rod_rate'],
		[1, f'{season}_super_rod_special_rate'],
		[1, f'{season}_blank']]

		for enc_type in ["grass", "grass_doubles", "grass_special"]:
			for n in range(0,12):
				s_encounters.append([2, f'{season}_{enc_type}_slot_{n}'])
				s_encounters.append([1, f'{season}_{enc_type}_slot_{n}_min_level'])
				s_encounters.append([1, f'{season}_{enc_type}_slot_{n}_max_level'])

		for wat_enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
			for n in range(0,5):
				s_encounters.append([2, f'{season}_{wat_enc_type}_slot_{n}'])
				s_encounters.append([1, f'{season}_{wat_enc_type}_slot_{n}_min_level'])
				s_encounters.append([1, f'{season}_{wat_enc_type}_slot_{n}_max_level'])

		for entry in s_encounters:
			ENCOUNTER_NARC_FORMAT.append(entry)


def output_encounters_json(narc):
	set_global_vars()
	data_index = 0
	# code.interact(local=dict(globals(), **locals()))

	# while len(narc.files) < 160:
	# 	narc.files.append(narc.files[89])
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

		#copy data from spring section if not present in current season
		if file["raw"][entry[1]] == 0 and "spring" not in entry[1]:
			spring_data = "spring_" + "_".join(entry[1].split("_")[1:])
			file["raw"][entry[1]] = file["raw"][spring_data]

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)
	
	for season in ["spring", "summer", "fall", "winter"]:

		for enc_type in ["grass", "grass_doubles", "grass_special"]:
			for n in range(0,12):
				index = raw[f'{season}_{enc_type}_slot_{n}']
				
				if index >= 2048:
					readable[f'{season}_{enc_type}_slot_{n}_form'] = floor(index / 2048)
					index = index % 2048

				readable[f'{season}_{enc_type}_slot_{n}'] = POKEDEX[index]
				if index == 0:
					readable[f'{season}_{enc_type}_slot_{n}'] = ""

		for wat_enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
			for n in range(0,5):
				index = raw[f'{season}_{wat_enc_type}_slot_{n}']		
				if index >= 2048:
					readable[f'{season}_{wat_enc_type}_slot_{n}_form'] = floor(index / 2048)
					index = index % 2048

				readable[f'{season}_{wat_enc_type}_slot_{n}'] = POKEDEX[index]

				if index == 0:
					readable[f'{season}_{wat_enc_type}_slot_{n}'] = ""

	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

