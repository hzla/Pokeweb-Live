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
import math


def set_global_vars(rom_name):
	global ROM_NAME, NARC_FORMAT, POKEDEX, ITEMS, TRDATA, MOVES, GENDERS, NARC_PATH, ABILITIES, NATURES, STATUSES, FLAGS, EXTRA_FLAGS, TYPES 
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings['trpok']
		NARC_PATH = f'{ROM_NAME}/narcs/trpok-{NARC_FILE_ID}.narc'

	TYPES = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel","Mystery", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark"]
	POKEDEX = open(f'texts/pokedex.txt', "r").read().splitlines()
	ITEMS = open(f'texts/items.txt', mode="r").read().splitlines()
	NATURES = open(f'texts/natures.txt', mode="r").read().splitlines()
	MOVES = open(f'texts/moves.txt', mode="r").read().splitlines()
	ABILITIES = open(f'texts/abilities.txt', mode="r").read().splitlines()
	GENDERS = ['Default', "Male", "Female"]
	FLAGS = ['status', 'hp', 'atk', 'def', 'spd', 'spatk', 'spdef', 'types', 'pp_counts', 'nickname']
	EXTRA_FLAGS = ['status', 'hp', 'atk', 'def', 'spd', 'spatk', 'spdef', 'type_1', 'type_2', 'move_1_pp','move_2_pp','move_3_pp','move_4_pp', 'nickname']


	NARC_FORMAT = [[1, "ivs"],
	[1, "ability"],
	[2, "level"],
	[2, "species_id"],
	[2, "item_id"],
	[2, "move_1"],
	[2, "move_2"],
	[2, "move_3"],
	[2, "move_4"],
	[2, "custom_ability"],
	[2, "ball"],
	[1, "hp_iv"],
	[1, "atk_iv"],
	[1, "def_iv"],
	[1, "spd_iv"],
	[1, "spatk_iv"],
	[1, "spdef_iv"],
	[1, "hp_ev"],
	[1, "atk_ev"],
	[1, "def_ev"],
	[1, "spd_ev"],
	[1, "spatk_ev"],
	[1, "spdef_ev"],
	[1, "nature"],
	[1, "shiny_lock"],
	[4, "additional_flags"],
	[4, "status"],
	[2, "hp"],
	[2, "atk"],
	[2, "def"],
	[2, "spd"],
	[2, "spatk"],
	[2, "spdef"],
	[1, "type_1"],
	[1, "type_2"],
	[1, "move_1_pp"],
	[1, "move_2_pp"],
	[1, "move_3_pp"],
	[1, "move_4_pp"]]

	# for n in range(0,11):
	# 	NARC_FORMAT.append([2, f'nickname_{n}'])

	NARC_FORMAT.append([2, 'ballseal'])



def output_trpok_json(trpok_info, rom_name):
	set_global_vars(rom_name)
	data_index = 0
	narc = ndspy.narc.NARC.fromFile(NARC_PATH)

	for data in narc.files:	
		data_name = data_index
		template = trpok_info[data_index][0]
		num_pokemon = trpok_info[data_index][1]
		narc_format = copy.deepcopy(NARC_FORMAT)
		trdata = trpok_info[data_index][2]


		if trdata["has_moves"] != 1:
			for n in range(1,5):
				narc_format.remove([2, f"move_{n}"])

		if trdata["has_items"] != 1:
			narc_format.remove([2, "item_id"])

		if trdata["set_abilities"] != 1:
			narc_format.remove([2, "custom_ability"])

		if trdata["set_ball"] != 1:
			narc_format.remove([2, "ball"])

		if trdata["set_iv_ev"] != 1:
			for value_type in ["iv", "ev"]:
				for stat in ["hp", "atk", "def", "spd", "spatk", "spdef"]:
					narc_format.remove([1, f'{stat}_{value_type}'])	
		

		if trdata["set_nature"] != 1:			
			narc_format.remove([1, "nature"])

		if trdata["shiny_lock"] != 1:			
			narc_format.remove([1, "shiny_lock"])
		
		additional_flags = {}
		
		if trdata["additional_flags"] != 1:			
			narc_format.remove([4, "additional_flags"])

		# print(trdata)
		# print("NARC FORMAT ###############")
		# print(narc_format)

		read_narc_data(data, narc_format, data_name, "trpok", template, num_pokemon, trdata)
		data_index += 1

	print("trpok")

def read_narc_data(data, narc_format, file_name, narc_name, template, num_pokemon, trdata):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }

	# print(file_name)
	# print(narc_format)

	# print(file_name)
	# print("###############")
	#USE THE FORMAT LIST TO PARSE BYTES
	
	for n in range(0, num_pokemon):
		skip_entry = False
		additional_flags = {}
		for entry in narc_format: 
			skip_entry = False
			flags_set = False
			# remove unused additional fields if additional flags are used
			if additional_flags != {}:
				
				for flag in FLAGS[0:7]:
					# print(additional_flags[flag])
					# print(entry[1])
					if additional_flags[flag] != 1:
						if entry[1] == flag:
							skip_entry = True

				if additional_flags["types"] != 1:
					if entry[1] == "type_1" or entry[1] == "type_2":
						skip_entry = True

				if additional_flags["pp_counts"] != 1:
					if entry[1] == "move_1_pp" or entry[1] == "move_2_pp" or entry[1] == "move_3_pp" or entry[1] == "move_4_pp":
						skip_entry = True
			else:
				# don't read additional flag data if no additional flags
				if (entry[1] in EXTRA_FLAGS):
					skip_entry = True


			if not skip_entry:
				entry_data = copy.deepcopy(read_bytes(stream, entry[0]))
				# print(f'{entry[1]}_{n}')
				# print(entry_data)
				file["raw"][f'{entry[1]}_{n}'] = entry_data

			# set additional flag data after reading additional flags

			if entry[1] == "additional_flags":
				# print(file["raw"][f'{entry[1]}_{n}'])
				index = 10
				props = bin(entry_data)[2:].zfill(index) 
				
				for prop in FLAGS:
					amount = int(props[index - 1])
					additional_flags[prop] = amount
					index -= 1



			# print(additional_flags)


	

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name, template, num_pokemon)
	file["readable"]["template"] = template
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 


def to_readable(raw, file_name, template, num_pokemon):
	readable = copy.deepcopy(raw)
	# print(raw)
	readable["count"] = num_pokemon
	for n in range(0, num_pokemon):
		
		#change to 2048 for hg-engine
		if (raw[f'species_id_{n}']) > 1024:
			
			form = raw[f'species_id_{n}'] // 1024
			base_form_id = raw[f'species_id_{n}'] - (1024 * form)


			print(base_form_id)
			print(raw[f'species_id_{n}'])
			print(file_name)
			print("%%%%%%%%%%%%%%%%")
			readable[f'species_id_{n}'] = POKEDEX[base_form_id]

			readable[f'form_{n}'] = form + 1
		else:
			if (raw[f'species_id_{n}'] > 1024):
				raw[f'species_id_{n}'] -= 1024
				print(raw[f'species_id_{n}'])
			readable[f'species_id_{n}'] = POKEDEX[(raw[f'species_id_{n}'])]
			readable[f'form_{n}'] = 1
		

		if (f'custom_ability_{n}') in raw:
			readable[f'custom_ability_{n}'] = ABILITIES[raw[f'custom_ability_{n}']]
		
		if (f'nature_{n}') in raw:
			readable[f'nature_{n}'] = NATURES[(raw[f'nature_{n}'])]


		if (f'move_{1}_{0}') in raw:
			for m in range(1,5):
				try:
					readable[f'move_{m}_{n}'] = MOVES[raw[f'move_{m}_{n}']]
				except:
					print(f'trpok file {file_name}: pokemon {n}: move {m}: value: {raw[f'move_{m}_{n}']}')
					readable[f'move_{m}_{n}'] = MOVES[0]

		if (f'item_id_{n}') in raw:
			readable[f'item_id_{n}'] = ITEMS[raw[f'item_id_{n}']]

		for i in range(1,3):
			if f"type_{i}" in raw:			
				readable[f'type_{i}_{n}'] = TYPES[raw[f'type_{i}_{n}']]

		
		if (f"additional_flags_{n}") in raw:
			index = 10
			props = bin(raw[f"additional_flags_{n}"])[2:].zfill(index) 
			
			for prop in FLAGS:
				amount = int(props[index - 1])
				readable[prop] = amount
				index -= 1

	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')



	

