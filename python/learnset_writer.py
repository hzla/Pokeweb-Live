import ndspy
import ndspy.rom
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


	
NARC_FILE_ID = 260
with open(f'session_settings.json', "r") as outfile:  
	settings = json.load(outfile) 
	NARC_FILE_ID = settings["learnsets"]
	ROM_NAME = settings['rom_name']

MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

for i,move in enumerate(MOVES):
	MOVES[i] = re.sub(r'[^A-Za-z0-9 \-]+', '', move)

LEARNSET_NARC_FORMAT = []

for n in range(20):
	LEARNSET_NARC_FORMAT.append([2, f'move_id_{n}'])
	LEARNSET_NARC_FORMAT.append([2, f'lvl_learned_{n}'])

#################################################################

## TODO instead of opening and editing the entire narc repeatedly, edit a variable 
## and edit the narc just once

def output_narc(narc_name="learnsets"):
	json_files = os.listdir(f'{ROM_NAME}/json/learnsets')
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, LEARNSET_NARC_FORMAT, narc)

	old_narc = open(narcfile_path, "wb")
	old_narc.write(narc.save()) 

	print("narc saved")

def write_bytes(stream, n, data):
	stream += (data.to_bytes(n, 'little'))		
	return stream

def write_narc_data(file_name, narc_format, narc, narc_name="learnsets"):
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
	
def write_readable_to_raw(file_name, narc_name="learnsets"):
	data = {}
	json_file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'

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

	for n in range(20):
		if f'move_id_{n}' in readable:
			
			if readable[f'move_id_{n}'] == "-":
				continue

			raw[f'move_id_{n}'] = MOVES.index(readable[f'move_id_{n}'])

			#update index info for readable since ruby side only updates the name, not id
			readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']

		if f'lvl_learned_{n}' in readable:
			raw[f'lvl_learned_{n}'] = readable[f'lvl_learned_{n}']
	
	return raw



def write_bytes(stream, n, data):
	stream += (data.to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
	
# output_narc()

