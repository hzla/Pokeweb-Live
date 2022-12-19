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
	global ROM_NAME, NARC_FORMAT, MOVEMENTS, HEADER_FORMAT, FURNITURE_FORMAT, NPC_FORMAT, WARP_FORMAT, TRIGGER_FORMAT, DIRECTIONS, NARC_FILE_ID
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["overworlds"]

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

set_global_vars()
#################################################################


def output_narc(rom, narc_name="overworlds"):
	json_files = os.listdir(f'{ROM_NAME}/json/{narc_name}')
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC(rom.files[NARC_FILE_ID])

	for f in json_files:
		file_name = int(f.split(".")[0])
		write_narc_data(file_name, NARC_FORMAT, narc, narc_name)

	rom.files[NARC_FILE_ID] = narc.save()
	return rom

def write_narc_data(file_name, narc_format, narc, narc_name="trpok"):
	file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		
		for entry in HEADER_FORMAT: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)

		for overworld in ['furniture', 'npc', 'warp', 'trigger']:
			for n in range(json_data['raw'][f'{overworld}_count']):
				for entry in NARC_FORMAT[overworld]:
					data = json_data["raw"][f'{overworld}_{n}_{entry[1]}']
					write_bytes(stream, entry[0], data)

		write_bytes(stream, json_data["raw"]["footer_length"], json_data["raw"]["footer"])



	if file_name >= len(narc.files):
		# narc_entry_data = bytearray()
		# narc_entry_data[0:len(stream)] = stream
		narc.files.append(stream)
	else:
		# narc_entry_data = bytearray(narc.files[file_name])
		# narc_entry_data[0:len(stream)] = stream
		narc.files[file_name] = stream
	
def write_readable_to_raw(file_name, narc_name="trpok"):
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

def to_raw(readable, template):
	raw = copy.deepcopy(readable)



	return raw
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream

################ If run with arguments #############
