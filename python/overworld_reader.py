import ndspy
import ndspy.rom
import code 
import io
import os
import os.path
from os import path
import json
import copy


def set_global_vars():
	global ROM_NAME, NARC_FORMAT, MOVEMENTS, HEADER_FORMAT, FURNITURE_FORMAT, NPC_FORMAT, WARP_FORMAT, TRIGGER_FORMAT, DIRECTIONS
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']

	MOVEMENTS = open(f'Reference_Files/movements.txt', mode="r").read().splitlines()

	DIRECTIONS = ['Up', 'Down', 'Left', 'Right' ]

	NARC_FORMAT = {}

	HEADER_FORMAT = [[4, 'file_length'],
	[1, 'furniture_count'],
	[1, 'npc_count'],
	[1, 'warp_count'],
	[1, 'trigger_count']]

	FURNITURE_FORMAT = [[2, 'script_id'],
	[2, 'unknown_1' ],
	[2, 'unknown_2'],
	[2, 'unknown_3'],
	[2, 'x_cord'],
	[2, 'x_cord_padding'],
	[2, 'y_cord'],
	[2, 'y_cord_padding'],
	[4, 'z_cord']]

	NPC_FORMAT = [[2, 'overworld_id'],
	[2, 'overworld_sprite'],
	[2, 'movement_permissions'],
	[2, 'movement_permissions_2'],
	[2, 'overworld_flag'],
	[2, 'script_id'],
	[2, 'direction'],
	[2, 'sight'],
	[2, 'unknown_1'],
	[2, 'unknown_2'],
	[2, 'horizontal_leash'],
	[2, 'vertical_leash'],
	[2, 'unknown_3'],
	[2, 'unknown_4'],
	[2, 'x_cord'],
	[2, 'y_cord'],
	[2, 'unknown_5'],
	[2, 'z_cord']]

	WARP_FORMAT = [[2, 'map_id'],
	[2, 'use_warp_cords'],
	[1, 'contact_direction'],
	[1, 'transition_type'],
	[4, 'exit_x'],
	# [2, 'exit_x_padding'],
	[4, 'exit_y'],
	# [2, 'exit_y_padding'],
	[2, 'x_extension'],
	[2, 'y_extension'],
	[2, 'directionality']]

	TRIGGER_FORMAT = [[2, 'entity_id'],
	[2, 'to_trigger_value'],
	[2, 'to_check_value'],
	[2, 'unknown_1'],
	[2, 'unknown_2'],
	[2, 'x_cord'],
	[2, 'y_cord'],
	[2, 'z_cord'],
	[2, 'unknown_3'],
	[2, 'unknown_4'],
	[2, 'unknown_5']]

	NARC_FORMAT["furniture"] = FURNITURE_FORMAT
	NARC_FORMAT["npc"] = NPC_FORMAT
	NARC_FORMAT["warp"] = WARP_FORMAT
	NARC_FORMAT["trigger"] = TRIGGER_FORMAT




def output_overworlds_json(narc):
	set_global_vars()
	data_index = 0


	for data in narc.files:
		data_name = data_index
		read_narc_data(data, data_name, "overworlds")
		data_index += 1

def read_narc_data(data, file_name, narc_name):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in HEADER_FORMAT: 
		file["raw"][entry[1]] = read_bytes(stream, entry[0])

	for overworld in ['furniture', 'npc', 'warp', 'trigger']:
		for n in range(file['raw'][f'{overworld}_count']):
			for entry in NARC_FORMAT[overworld]:
				file["raw"][f'{overworld}_{n}_{entry[1]}'] = read_bytes(stream, entry[0])


	# code.interact(local=dict(globals(), **locals()))
	file["raw"]["footer"] = int.from_bytes(data[stream.tell():], "little")
	file["raw"]["footer_length"] = len(data[stream.tell():])

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile, indent=4) 

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	for n in range(raw[f'npc_count']):
		try:
			readable[f'npc_{n}_movement_permissions'] = MOVEMENTS[raw[f'npc_{n}_movement_permissions']] 
		except:
			readable[f'npc_{n}_movement_permissions'] = ""

	# CONVERT FIELDS HERE
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

