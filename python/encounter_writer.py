import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import json
import copy
import sys


# code.interact(local=dict(globals(), **locals()))

######################### CONSTANTS #############################
def set_global_vars():
	global LOCATIONS, ROM_NAME, NARC_FORMAT, POKEDEX, NARC_FILE_ID
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["encounters"]

	LOCATIONS = open(f'{ROM_NAME}/texts/locations.txt', mode="r" ,encoding='utf-8').read().splitlines()

	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()

	NARC_FORMAT = []

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
			NARC_FORMAT.append(entry)

set_global_vars()
#################################################################

## TODO instead of opening and editing the entire narc repeatedly, edit a variable 
## and edit the narc just once

def output_narc(narc_name="encounters"):
	json_files = os.listdir(f'{ROM_NAME}/json/{narc_name}')
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, NARC_FORMAT, narc, "encounters")

	old_narc = open(narcfile_path, "wb")
	old_narc.write(narc.save()) 

	print("narc saved")

def write_narc_data(file_name, narc_format, narc, narc_name="moves"):
	file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in narc_format: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)
	
	if file_name >= len(narc.files):
		narc_entry_data = bytearray()
		narc_entry_data[0:len(stream)] = stream
		narc.files.append(narc_entry_data)
	else:
		narc_entry_data = bytearray(narc.files[file_name])
		narc_entry_data[0:len(stream)] = stream
		narc.files[file_name] = narc_entry_data
	
def write_readable_to_raw(file_name, narc_name="encounters"):
	data = {}
	json_file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	
			
		if json_data["readable"] is None:
			return
		new_raw_data = to_raw(json_data["readable"])
		json_data["raw"] = new_raw_data

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(json_data, outfile)

def to_raw(readable):
	raw = copy.deepcopy(readable)

	for season in ["spring", "summer", "fall", "winter"]:

		for enc_type in ["grass", "grass_doubles", "grass_special"]:
			for n in range(0,12):
				index = POKEDEX.index(readable[f'{season}_{enc_type}_slot_{n}'])
				
				raw[f'{season}_{enc_type}_slot_{n}'] = index

				alt_form = f'{season}_{enc_type}_slot_{n}_form' in readable
				if alt_form:
					raw[f'{season}_{enc_type}_slot_{n}'] += (int(readable[f'{season}_{enc_type}_slot_{n}_form']) * 2048)
		
		for enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
			for n in range(0,5):
				index = POKEDEX.index(readable[f'{season}_{enc_type}_slot_{n}'])
				
				raw[f'{season}_{enc_type}_slot_{n}'] = index
				
				alt_form = f'{season}_{enc_type}_slot_{n}_form' in readable
				if alt_form:
					raw[f'{season}_{enc_type}_slot_{n}'] += (int(readable[f'{season}_{enc_type}_slot_{n}_form']) * 2048)

	return raw
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
# output_narc()

# write_readable_to_raw(1)