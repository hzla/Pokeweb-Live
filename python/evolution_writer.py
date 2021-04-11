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
	global ROM_NAME, NARC_FORMAT, NARC_FILE_ID, ITEMS, POKEDEX, MOVES, METHODS
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["evolutions"]

	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()
	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()
	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	METHODS = open(f'Reference_Files/evo_methods.txt', mode="r").read().splitlines()	

	NARC_FORMAT = []

	for n in range(0, 7):
		NARC_FORMAT.append([2, f'method_{n}'])
		NARC_FORMAT.append([2, f'param_{n}'])
		NARC_FORMAT.append([2, f'target_{n}'])

set_global_vars()
#################################################################


def output_narc(narc_name="evolutions"):
	json_files = os.listdir(f'{ROM_NAME}/json/{narc_name}')
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, NARC_FORMAT, narc, narc_name)

	old_narc = open(narcfile_path, "wb")
	old_narc.write(narc.save()) 

	print("narc saved")

def write_narc_data(file_name, narc_format, narc, narc_name="evolutions"):
	file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in narc_format: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)
	
	if file_name >= len(narc.files):
		narc_entry_data = bytearray()
		narc_entry_data[0:len(stream)] = stream
		narc.files.append(narc_entry_data)
	else:
		narc_entry_data = bytearray(narc.files[file_name])
		narc_entry_data[0:len(stream)] = stream
		narc.files[file_name] = narc_entry_data
	
def write_readable_to_raw(file_name, narc_name="evolutions"):
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

def to_raw(readable):
	raw = copy.deepcopy(readable)

	for n in range(0,7):
		
		raw[f'method_{n}'] = METHODS.index(readable[f'method_{n}'])
		raw[f'target_{n}'] = POKEDEX.index(readable[f'target_{n}'].upper())

		if raw[f'method_{n}'] in [6,8,16,17,18,19]:
			raw[f'param_{n}'] = ITEMS.index(raw[f'param_{n}'])
		elif raw[f'method_{n}'] == 20:
			raw[f'param_{n}'] = MOVES.index(readable[f'param_{n}'])
		elif raw[f'method_{n}'] == 21:
			raw[f'param_{n}'] = POKEDEX.index(readable[f'param_{n}'].upper())
		else:
			raw

	return raw
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
	
# output_narc()

# write_readable_to_raw(1)