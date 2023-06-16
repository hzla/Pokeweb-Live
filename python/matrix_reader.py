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


def output_matrix_json(narc, rom_name):
	set_global_vars(rom_name)
	data_index = 0


	for data in narc.files:
		data_name = data_index
		read_narc_data(data,"matrix", data_index)
		data_index += 1

def read_narc_data(data, narc_name, file_name):
	stream = io.BytesIO(data)
	matrix = {}
	matrix["maps"] = []
	matrix["headers"] = []

	stream.seek(4)
	matrix["width"] = read_bytes(stream, 2)
	matrix["height"] = read_bytes(stream, 2)

	for n in range(0, matrix["width"] * matrix["height"]):	
		matrix['maps'].append(read_bytes(stream, 4))

	
	try:
		for n in range(0, matrix["width"] * matrix["height"]):	
			matrix['headers'].append(read_bytes(stream, 4))
	except:
		print("no headers")

	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(matrix, outfile) 

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	