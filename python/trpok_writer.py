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
def set_global_vars(rom_name):
	global ROM_NAME, NARC_FORMATS, NARC_FILE_ID, POKEDEX, ITEMS, MOVES, GENDERS
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["trpok"]


	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()
	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()

	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()

	GENDERS = ['Default', "Male", "Female"]

	NARC_FORMAT_0 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"]]

	NARC_FORMAT_1 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"],
	[2, "move_1"],
	[2, "move_2"],
	[2, "move_3"],
	[2, "move_4"]]

	NARC_FORMAT_2 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"],
	[2, "item_id"]]

	NARC_FORMAT_3 = [[1, "ivs"],
	[1, "ability"],
	[1, "level"],
	[1, "padding"],
	[2, "species_id"],
	[2, "form"],
	[2, "item_id"],
	[2, "move_1"],
	[2, "move_2"],
	[2, "move_3"],
	[2, "move_4"]]

	NARC_FORMATS = [NARC_FORMAT_0,NARC_FORMAT_1,NARC_FORMAT_2,NARC_FORMAT_3]

#################################################################


def output_narc(rom, rom_name):
	set_global_vars(rom_name)
	json_files = os.listdir(f'{ROM_NAME}/json/trpok')
	narcfile_path = f'{ROM_NAME}/narcs/trpok-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])
		write_narc_data(file_name, NARC_FORMATS, narc, rom_name)

	rom.files[NARC_FILE_ID] = narc.save()
	print("trpok narc saved")

	return rom

def write_narc_data(file_name, narc_format, narc, rom_name):
	file_path = f'{ROM_NAME}/json/trpok/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/trpok-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		tr_data = json.load(open(f'{ROM_NAME}/json/trdata/{file_name}.json', "r"))
		template = tr_data["raw"]["template"]
		# print(json_data)
		num_pokemon = json_data["readable"]["count"]

		
		narc_format = narc_format[template]

		#USE THE FORMAT LIST TO PARSE BYTES
		for n in range(0, num_pokemon):
			
			for entry in narc_format: 
				if f'{entry[1]}_{n}' in json_data["raw"]:
					data = json_data["raw"][f'{entry[1]}_{n}']
					write_bytes(stream, entry[0], data)

	if file_name >= len(narc.files):
		# narc_entry_data = bytearray()
		# narc_entry_data[0:len(stream)] = stream
		narc.files.append(stream)
	else:
		# narc_entry_data = bytearray(narc.files[file_name])
		# narc_entry_data[0:len(stream)] = stream
		narc.files[file_name] = stream
	
def write_readable_to_raw(file_name, rom_name):
	data = {}
	json_file_path = f'{rom_name}/json/trpok/{file_name}.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	
			
		if json_data["readable"] is None:
			return

		tr_data = json.load(open(f'{rom_name}/json/trdata/{file_name}.json', "r"))
		template = tr_data["raw"]["template"]




		new_raw_data = to_raw(json_data["readable"], template)
		json_data["raw"] = new_raw_data


		tr_data["raw"]["num_pokemon"] = json_data["readable"]["count"]
		tr_data["readable"]["num_pokemon"] = json_data["readable"]["count"]

	with open(f'{ROM_NAME}/json/trdata/{file_name}.json', "w") as outfile:
		json.dump(tr_data, outfile)

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(json_data, outfile)

def to_raw(readable, template):
	raw = copy.deepcopy(readable)

	n = 0
	while n < readable["count"]:
		if f'species_id_{n}' in raw:	

			
			if readable[f'species_id_{n}'].strip() == "-":
				raw[f'species_id_{n}'] = 0
			else:
				raw[f'species_id_{n}'] = POKEDEX.index(readable[f'species_id_{n}'])



			raw[f'ability_{n}'] = int(readable[f'ability_{n}']) * 16

			raw[f'ability_{n}'] += GENDERS.index(readable[f'gender_{n}'])



			for m in range(1,5):
				if f'move_{m}_{n}' in readable:
					raw[f'move_{m}_{n}'] = MOVES.index(readable[f'move_{m}_{n}'])
				else: 
					raw[f'move_{m}_{n}'] = 0


			if f'item_id_{n}' in readable:
				raw[f'item_id_{n}'] = ITEMS.index(readable[f'item_id_{n}'].replace("Ã\x83Â©","é").replace('Ã©', 'é'))
			else:
				raw[f'item_id_{n}'] = 0

		n += 1

	return raw
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream

################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	set_global_vars(sys.argv[3])

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name), sys.argv[3])

if len(sys.argv) > 2 and sys.argv[1] == "validate":
	
	set_global_vars(sys.argv[2])
	file_count = len(os.listdir(f'{sys.argv[2]}/json/trpok'))
	for file_name in range(0,file_count):

		write_readable_to_raw(int(file_name), sys.argv[2])
	