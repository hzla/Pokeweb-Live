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

# import text_reader

# code.interact(local=dict(globals(), **locals()))

######################### FILE SPECIFIC CONSTANTS #############################

def set_global_vars():
	global LOCATIONS, ROM_NAME, HEADER_NARC_FORMAT, HEADER_LENGTH, BASE_ROM, HEADER_OFFSET, HEADER_COUNT
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']

	LOCATIONS = open(f'texts/locations.txt', mode="r" ,encoding='utf-8').read().splitlines()

	HEADER_LENGTH = 24
	HEADER_COUNT = 540

	HEADER_OFFSET = 0xF6BE2

	HEADER_NARC_FORMAT = [[1, "texture_1"],
	[1, "texture_2"],
	[2, "matrix"],
	[2, "script"],
	[2, "level_script"],
	[2, "text_bank"],
	[2, "music_day"],
	[2, "music_night"],
	[2, "event"],
	[1, "location_name_id"],
	[1, "name_style"],
	[1, "weather"],
	[1, "camera"],
	[1, "follow_mode"],
	[1, "flags"],
	[1, "encounter"],
	[1, "unknown"]]




#################################################################


def output_headers_json(arm9):
	set_global_vars()


	header_data = arm9[HEADER_OFFSET:(HEADER_OFFSET + HEADER_LENGTH * HEADER_COUNT)]
	read_narc_data(header_data, HEADER_NARC_FORMAT, HEADER_COUNT )

def read_narc_data(data, narc_format, file_count):
	stream = io.BytesIO(data)
	headers = {}
	headers["count"] = file_count

	#USE THE FORMAT LIST TO PARSE BYTES
	for n in range(0, file_count ):
		headers[n] = {}
		for entry in narc_format:
			byte = read_bytes(stream, entry[0])
			headers[n][entry[1]] = byte

		try:
			headers[n]["location_name"] = LOCATIONS[headers[n]["location_name_id"] + 1]
		except:
			headers[n]["location_name"] = "Unknown Location"


	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/headers'):
		os.makedirs(f'{ROM_NAME}/json/headers')

	with open(f'{ROM_NAME}/json/headers/headers.json', "w") as outfile:  
		json.dump(headers, outfile) 

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	