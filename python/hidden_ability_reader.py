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

# code.interact(local=dict(globals(), **locals()))

######################### FILE SPECIFIC CONSTANTS #############################

def set_global_vars(rom_name):
	global ROM_NAME, ABILITIES
	

	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

	ABILITIES = open(f'texts/abilities.txt', mode="r").read().splitlines()



#################################################################
## TODO: create universal read_narc_data function that takes name of narc, and to_readable() function as args

def output_hidden_abilities_json(narc, rom_name):
	set_global_vars(rom_name)

	data_name = "hidden_abilities"
	read_narc_data(narc.files[7], data_name)


def read_narc_data(data, file_name):
	stream = io.BytesIO(data)
	abilities = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for n in range(0, len(data) // 2): 
		ability = read_bytes(stream, 2)


		abilities["raw"][n] = ability

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	abilities["readable"] = to_readable(abilities["raw"], file_name, len(data) // 2)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/abilities'):
		os.makedirs(f'{ROM_NAME}/json/abilities')

	with open(f'{ROM_NAME}/json/abilities/{file_name}.json', "w") as outfile:  
		json.dump(abilities, outfile) 

def to_readable(raw, file_name, file_count):
	readable = copy.deepcopy(raw)
	readable['index'] = file_name

	for n in range(0, file_count): 
		readable[n] = ABILITIES[raw[n]]
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	
