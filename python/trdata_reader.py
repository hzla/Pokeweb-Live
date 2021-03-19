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
	global ROM_NAME, NARC_FORMAT, TRAINER_CLASSES, ITEMS, BATTLE_TYPES, TRAINER_NAMES
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']


	TRAINER_CLASSES = open(f'{ROM_NAME}/texts/tr_classes.txt', "r").read().splitlines()
	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()

	BATTLE_TYPES = ["Singles", "Doubles", "Triples", "Rotation"]

	NARC_FORMAT = [[1, "template"],
	[1, "class"],
	[1, "battle_type_1"],
	[1, "num_pokemon"],
	[2, "item_1"],
	[2, "item_2"],
	[2, "item_3"],
	[2, "item_4"],
	[4, "ai"],
	[1, "heal"],
	[1, "money"],
	[2, "reward_item"]]

	
def output_trdata_json(narc):
	set_global_vars()
	data_index = 0
	# code.interact(local=dict(globals(), **locals()))
	while len(narc.files) < 1000:
		narc.files.append(narc.files[0])

	for data in narc.files:
		data_name = data_index
		read_narc_data(data, NARC_FORMAT, data_name, "trdata")
		data_index += 1

def read_narc_data(data, narc_format, file_name, narc_name):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		file["raw"][entry[1]] = read_bytes(stream, entry[0])

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)
	
	readable["class"] = TRAINER_CLASSES[raw["class"]]
	readable["class_id"] = raw["class"]


	readable["reward_item"] = ITEMS[raw["reward_item"]]
	readable["battle_type_1"] = BATTLE_TYPES[raw["battle_type_1"]]

	for n in range(1, 5):
		readable[f'item_{n}'] = ITEMS[raw[f'item_{n}']]

	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

