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

def set_global_vars(rom_name):
	global LOCATIONS, ROM_NAME, HEADER_NARC_FORMAT, HEADER_LENGTH, BASE_ROM, HEADER_OFFSET, HEADER_COUNT
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']

	LOCATIONS = open(f'texts/locations_hgss.txt', mode="r" ,encoding='utf-8').read().splitlines()

	HEADER_LENGTH = 24
	HEADER_COUNT = 540

	HEADER_OFFSET = 0xF6BE0

	HEADER_NARC_FORMAT = [[1, "encounter"],
	[1, "area_data"],
	[2, "map_info"],
	[2, "matrix_id"],
	[2, "script_id"],
	[2, "script_header_id"],
	[2, "text_bank"],
	[2, "music_day"],
	[2, "music_night"],
	[2, "events_id"],
	[1, "location_name_id"],
	[1, "map_name_textbox_id"],
	[1, "weather"],
	[1, "camera"],
	[1, "follow_mode"],
	[1, "permissions"]]


#################################################################


def output_headers_json(arm9, rom_name):
	set_global_vars(rom_name)


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
			headers[n]["location_name"] = LOCATIONS[headers[n]["location_name_id"]]
		except:
			headers[n]["location_name"] = "Unknown Location"


	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/headers'):
		os.makedirs(f'{ROM_NAME}/json/headers')

	with open(f'{ROM_NAME}/json/headers/headers.json', "w") as outfile:  
		json.dump(headers, outfile) 

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	