import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import json
import copy
import sys
import rom_data
import tools


# code.interact(local=dict(globals(), **locals()))

def output_narc(narc_name="encounters"):
	tools.output_narc("encounters")

def write_readable_to_raw(file_name, narc_name="encounters"):
	data = {}
	json_file_path = f'{rom_data.ROM_NAME}/json/{narc_name}/{file_name}.json'

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
				
				if readable[f'{season}_{enc_type}_slot_{n}'] == "":
					index = 0
				else:
					index = rom_data.POKEDEX.index(readable[f'{season}_{enc_type}_slot_{n}'])
				
				raw[f'{season}_{enc_type}_slot_{n}'] = index

				alt_form = f'{season}_{enc_type}_slot_{n}_form' in readable
				if alt_form:
					raw[f'{season}_{enc_type}_slot_{n}'] += (int(readable[f'{season}_{enc_type}_slot_{n}_form']) * 2048)
		
		for enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
			for n in range(0,5):
				index = rom_data.POKEDEX.index(readable[f'{season}_{enc_type}_slot_{n}'])
				
				raw[f'{season}_{enc_type}_slot_{n}'] = index
				
				alt_form = f'{season}_{enc_type}_slot_{n}_form' in readable
				if alt_form:
					raw[f'{season}_{enc_type}_slot_{n}'] += (int(readable[f'{season}_{enc_type}_slot_{n}_form']) * 2048)

	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars()
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
