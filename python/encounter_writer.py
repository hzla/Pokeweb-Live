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

def output_narc(rom, rom_name):
	return tools.output_narc("encounters", rom, rom_name)

def write_readable_to_raw(file_name, narc_name="encounters"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)

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
	
	rom_data.set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
