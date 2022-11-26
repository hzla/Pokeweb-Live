import ndspy
import ndspy.rom, ndspy.codeCompression
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

def set_global_vars():
	global ROM_NAME, MOVES, TM_FORMAT, TUTOR_FORMAT, TM_OFFSET, TUTOR_OFFSET, BASE_ROM
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']
		BASE_VERSION = settings['base_version']

	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	for i,move in enumerate(MOVES):
		MOVES[i] = re.sub(r'[^A-Za-z0-9 \-]+', '', move)

	TM_FORMAT = []

	TM_OFFSETS = {"B": 0x9aaa0, "W": 0x9aab8, "B2": 0x8cc84, "W2": 0x8ccb0 }

	TM_OFFSET = TM_OFFSETS[BASE_VERSION]

	for n in range(1, 93):
		TM_FORMAT.append([2, f'tm_{n}'])
	for n in range(1, 7):
		TM_FORMAT.append([2, f'hm_{n}'])
	for n in range(93, 96):
		TM_FORMAT.append([2, f'tm_{n}'])


#################################################################
## TODO: create universal read_data function that takes name of narc, and to_readable() function as args

def output_tms_json(arm9):
	set_global_vars()
	data_index = 0
	data_name = "tms"
	folder_name = "arm9"

	arm9 = arm9[TM_OFFSET:TM_OFFSET + 204]

	read_data(arm9, TM_FORMAT, data_name, folder_name)
	data_index += 1

def output_tutors_json(arm9):
	set_global_vars()
	data_index = 0
	data_name = "tutors"
	folder_name = "arm9"

	arm9 = arm9[TUTOR_OFFSET:TM_OFFSET + 1000]

	read_data(arm9, TM_FORMAT, data_name, folder_name)
	data_index += 1



def read_data(data, narc_format, file_name, folder_name):
	stream = io.BytesIO(data)
	json_data = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		byte = read_bytes(stream, entry[0])
		json_data["raw"][entry[1]] = byte

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	json_data["readable"] = to_readable(json_data["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{folder_name}'):
		os.makedirs(f'{ROM_NAME}/json/{folder_name}')

	with open(f'{ROM_NAME}/json/{folder_name}/{file_name}.json', "w") as outfile:  
		json.dump(json_data, outfile) 


def to_readable(raw, file_name=""):
	readable = copy.deepcopy(raw)

	for n in range(1, 93):
		readable[f'tm_{n}'] = MOVES[raw[f'tm_{n}']]
	for n in range(1, 7):
		readable[f'hm_{n}'] = MOVES[raw[f'hm_{n}']]
	for n in range(93, 96):
		readable[f'tm_{n}'] = MOVES[raw[f'tm_{n}']]
	
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')


