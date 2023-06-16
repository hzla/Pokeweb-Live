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

def set_global_vars(rom_name):
	global ROM_NAME
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']




#################################################################


def output_maps_json(narc ,rom_name):
	set_global_vars(rom_name)
	data_index = 0


	for data in narc.files:
		data_name = data_index
		read_narc_data(data, "maps", data_index)
		data_index += 1

def read_narc_data(data, narc_name, file_name):
	stream = io.BytesIO(data)
	map_data = {}



	stream.seek(8)
	map_data["per_offset"] = read_bytes(stream, 4)

	stream.seek(map_data["per_offset"])
	map_data["width"] = read_bytes(stream, 2)
	map_data["height"] = read_bytes(stream, 2)




	for m in range(0,8):
		map_data[f'layer_{m}'] = []

	for n in range(0, map_data["width"] * map_data["height"]):
		for m in range(0,4):		
			tile = read_bytes(stream, 2)
			if m == 2 or m == 3:
				map_data[f'layer_{m}'].append(tile)

	# try:
	# 	for n in range(0, map_data["width"] * map_data["height"]):
	# 		for m in range(4,8):		
	# 			map_data[f'layer_{m}'].append(read_bytes(stream, 2))
	# except:
	# 	print("no layer 2")







	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(map_data, outfile) 

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	