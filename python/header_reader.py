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

import text_reader

# code.interact(local=dict(globals(), **locals()))

######################### FILE SPECIFIC CONSTANTS #############################

def set_global_vars():
	global LOCATIONS, ROM_NAME, HEADER_NARC_FORMAT, HEADER_LENGTH, BASE_ROM
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']

	LOCATIONS = open(f'{ROM_NAME}/texts/locations.txt', mode="r" ,encoding='utf-8').read().splitlines()

	HEADER_LENGTH = 48

	HEADER_NARC_FORMAT = [[1, "map_type"],
	[1, "unknown_1"],
	[2, "texture_id"],
	[2, "matrix_id"],
	[2, "script_id"],
	[2, "level_script_id"],
	[2, "text_bank_id"],
	[2, "music_spring_id"],
	[2, "music_summer_id"],
	[2, "music_fall_id"],
	[2, "music_winter_id"],
	[2, "encounter_id"],
	[2, "map_id"],
	[2, "parent_map_id"],
	[1, "location_name_id"],
	[1, "name_style_id" ],
	[1, "weather_id"],
	[1, "camera_id"],
	[1, "unknown_2"],
	[1, "flags"],
	[2, "unknown_3"],
	[2, "name_icon"],
	[4, "fly_x"],
	[4, "fly_y"],
	[4, "fly_z"]]

	if BASE_ROM == 'BW2':
		HEADER_NARC_FORMAT = [[1, "map_type"],
		[1, "unknown_1"],
		[2, "texture_id"],
		[2, "matrix_id"],
		[2, "script_id"],
		[2, "level_script_id"],
		[2, "text_bank_id"],
		[2, "music_spring_id"],
		[2, "music_summer_id"],
		[2, "music_fall_id"],
		[2, "music_winter_id"],
		[1, "encounter_id"],
		[1, 'unknown_4'],
		[2, "map_id"],
		[2, "parent_map_id"],
		[1, "location_name_id"],
		[1, "name_style_id" ],
		[1, "weather_id"],
		[1, "camera_id"],
		[1, "unknown_2"],
		[1, "flags"],
		[2, "unknown_3"],
		[2, "name_icon"],
		[4, "fly_x"],
		[4, "fly_y"],
		[4, "fly_z"]]



#################################################################


def output_headers_json(headers):
	set_global_vars()
	headers = headers.files[0]
	header_count = int(len(headers) / HEADER_LENGTH)

	read_narc_data(headers, HEADER_NARC_FORMAT, header_count )

def read_narc_data(data, narc_format, file_count):
	stream = io.BytesIO(data)
	headers = { }
	headers["count"] = file_count

	#USE THE FORMAT LIST TO PARSE BYTES
	for n in range(1, file_count + 1):
		headers[n] = {}
		for entry in narc_format:
			byte = read_bytes(stream, entry[0])
			headers[n][entry[1]] = byte

		
		try:
			headers[n]["location_name"] = LOCATIONS[headers[n]["location_name_id"]]
		except:
			headers[n]["location_name"] = "Unknown Location"
			print(n)

	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/headers'):
		os.makedirs(f'{ROM_NAME}/json/headers')

	with open(f'{ROM_NAME}/json/headers/headers.json', "w") as outfile:  
		json.dump(headers, outfile) 

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	