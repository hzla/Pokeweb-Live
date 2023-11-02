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


def set_global_vars(rom_name):
	global ROM_NAME, NARC_FORMAT, BASE_ROM, MOVES, EFFECT_TABLE_OFFSET, FAIRY
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']
		BASE_VERSION = settings["base_version"]
		FAIRY = settings["fairy"]

	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	NARC_FORMAT = []

	if FAIRY:
		B2_EFFECT_TABLE_OFFSET = 0X00040974
		W2_EFFECT_TABLE_OFFSET = 0X00040974
	else:
		B2_EFFECT_TABLE_OFFSET = 0X000407F4
		W2_EFFECT_TABLE_OFFSET = 0X000407F4

	if BASE_VERSION == "B2":
		EFFECT_TABLE_OFFSET = B2_EFFECT_TABLE_OFFSET
	else:
		EFFECT_TABLE_OFFSET = W2_EFFECT_TABLE_OFFSET

	for n in range(258):
		NARC_FORMAT.append([4, f'move_id_{n}'])
		NARC_FORMAT.append([4, f'address_{n}'])



#################################################################


def output_move_effects_table(rom_name):
	set_global_vars(rom_name)
	json_file_path = f'{rom_name}/json/arm9/move_effects_table.json'
	

	move_effects_table_file_path = f'{rom_name}/move_effects_table.bin'		
	stream = bytearray() 

	with open(json_file_path, "r") as outfile:  	
		json_data = json.load(outfile)	
		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in NARC_FORMAT: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)

	stream
	open(move_effects_table_file_path, "wb").write(stream) 

	overlay167_edited = bytearray(open(f'{rom_name}/overlay167.bin','rb').read())
	overlay167_edited[EFFECT_TABLE_OFFSET:EFFECT_TABLE_OFFSET + 2064] = stream

	open(f'{rom_name}/overlay167.bin', "wb").write(overlay167_edited) 





	print("move_effects_table")

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream


def write_readable_to_raw(rom_name):
	data = {}
	json_file_path = f'{rom_name}/json/arm9/move_effects_table.json'

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

	for n in range(258):
		raw[f'move_id_{n}'] = MOVES.index(readable[f'move_id_{n}'])
		

	return raw

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	set_global_vars(sys.argv[3])
	write_readable_to_raw(sys.argv[3])
	output_move_effects_table(sys.argv[3])
	

