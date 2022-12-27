import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import json
import copy
import sys
import re

# code.interact(local=dict(globals(), **locals()))

######################### CONSTANTS #############################
def set_global_vars(rom_name):
	global NARC_FILE_ID, ROM_NAME, BASE_ROM, HEADER_NARC_FORMAT, LOCATIONS, HEADER_LENGTH

	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["headers"] if "headers" in settings else None
		BASE_ROM = settings["base_rom"]

	LOCATIONS = open(f'{ROM_NAME}/texts/locations.txt', mode="r").read().splitlines()

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
	[2, "overworlds_id"],
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
		[2, "overworlds_id"],
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

## TODO instead of opening and editing the entire narc repeatedly, edit a variable 
## and edit the narc just once

def output_narc(rom, rom_name):	
	set_global_vars(rom_name)
	narc = ndspy.narc.NARC(rom.files[NARC_FILE_ID])
	updated_narc = write_narc_data(HEADER_NARC_FORMAT, "headers", rom_name)
	narc.files[0] = updated_narc
	rom.files[NARC_FILE_ID] = narc.save()

	print("narc saved")

	return rom

def write_narc_data(narc_format, narc_name, rom_name):
	file_path = f'{rom_name}/json/{narc_name}/headers.json'
	
	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		all_json_data = json.load(outfile)
		file_count = int(all_json_data["count"])

		for n in range(1, file_count + 1):
			for entry in narc_format:
				byte = write_bytes(stream, entry[0], all_json_data[str(n)][entry[1]])

	return stream


#slightly changed function for modifying a json file with all narc entries
def write_readable_to_raw(file_name, rom_name):
	data = {}
	json_file_path = f'{rom_name}/json/headers/headers.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		all_json_data = json.load(outfile)
		to_modify = all_json_data[str(file_name)]	
			
		if to_modify is None:
			return

		modified = to_raw(to_modify)
		all_json_data[str(file_name)] = modified

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(all_json_data, outfile)


def to_raw(readable):
	raw = copy.deepcopy(readable)
	raw["location_name_id"] = LOCATIONS.index(readable["location_name"])
	return raw
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



# ############### If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name), sys.argv[3])
	