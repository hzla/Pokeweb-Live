import ndspy
import ndspy.rom, ndspy.bmg, ndspy.codeCompression
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

def remove_accents(input_str):
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    only_ascii = nfkd_form.encode('ASCII', 'ignore')
    return str(only_ascii)[2:]


ROM_NAME = ""
BASE_ROM = ""
BASE_VERSION = ""

def set_global_vars(rom_name):
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
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


def output_arm9(rom_name):
	set_global_vars(rom_name)
	json_file_path = f'{rom_name}/json/arm9/tms.json'
	
	# ndspy copy of narcfile to edit
	arm9_file_path = f'{rom_name}/arm9.bin'
	old_arm9 = open(arm9_file_path, "rb")
	
	to_edit_arm9 = bytearray(old_arm9.read())
		
	stream = bytearray() 

	with open(json_file_path, "r") as outfile:  	
		json_data = json.load(outfile)	
		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in TM_FORMAT: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)

	to_edit_arm9[TM_OFFSET:TM_OFFSET + len(stream)] = stream
	open(arm9_file_path, "wb").write(to_edit_arm9) 

	print("arm9 saved")

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream


def write_readable_to_raw(rom_name):
	data = {}
	json_file_path = f'{rom_name}/json/arm9/tms.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		narc_data = json.load(outfile)	
			
		if narc_data["readable"] is None:
			return
		new_raw_data = to_raw(narc_data["readable"])
		narc_data["raw"] = new_raw_data

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(narc_data, outfile)

def to_raw(readable):
	raw = copy.deepcopy(readable)
	# print(MOVES)
	for n in range(1, 93):
		raw[f'tm_{n}'] = MOVES.index(readable[f'tm_{n}'])
	for n in range(1, 7):
		raw[f'hm_{n}'] = MOVES.index(readable[f'hm_{n}'])
	for n in range(93, 96):
		raw[f'tm_{n}'] = MOVES.index(readable[f'tm_{n}'])	
	return raw

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	write_readable_to_raw(sys.argv[3])
	

