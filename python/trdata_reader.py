import ndspy
import ndspy.rom
import code 
import io
import os
import os.path
from os import path
import json
import copy
import ndspy.narc
from trpok_reader import output_trpok_json


def set_global_vars():
	global ROM_NAME, NARC_FORMAT, TRAINER_CLASSES, ITEMS, BATTLE_TYPES, TRAINER_NAMES, AIS, TEMPLATE_FLAGS, BASE_ROM, TRPOK_INFO
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']


	TEMPLATE_FLAGS =["has_moves", "has_items"]

	TRAINER_CLASSES = open(f'{ROM_NAME}/texts/tr_classes.txt', "r").read().splitlines()

	if BASE_ROM == 'BW':
		TRAINER_NAMES = open(f'Reference_Files/trainer_names.txt', "r").read().splitlines()
	else:
		TRAINER_NAMES = open(f'Reference_Files/trainer_names_2.txt', "r").read().splitlines()




	customTnames = f'Reference_Files/trainer_names_{ROM_NAME.split("/")[-1]}.txt'
	customTclasses = f'Reference_Files/trainer_classes_{ROM_NAME.split("/")[-1]}.txt'

	print("searching for the following custom trainer names/classes files")
	print(customTclasses)
	print(customTnames)


	if os.path.isfile(customTnames) and os.path.isfile(customTclasses):
		print("custom detected")
		TRAINER_CLASSES = open(customTclasses, "r").read().splitlines()
		TRAINER_NAMES = open(customTnames, "r").read().splitlines()
	else:
		print("no custom names/classes found")



	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()

	BATTLE_TYPES = ["Singles", "Doubles", "Triples", "Rotation"]

	TRPOK_INFO = []

	AIS = ["Prioritize Effectiveness",
	"Evaluate Attacks",
	"Expert",
	"Prioritize Status",
	"Risky Attacks",
	"Prioritize Damage",
	"Partner",
	"Double Battle",
	"Prioritize Healing",
	"Utilize Weather",
	"Harassment",
	"Roaming Pokemon",
	"Safari Zone",
	"Catching Demo"]

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
	# while len(narc.files) < 850:
	# 	narc.files.append(narc.files[0])

	for data in narc.files:
		data_name = data_index
		read_narc_data(data, NARC_FORMAT, data_name, "trdata")
		data_index += 1

	output_trpok_json(TRPOK_INFO)

def read_narc_data(data, narc_format, file_name, narc_name):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		file["raw"][entry[1]] = read_bytes(stream, entry[0])


	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name)
	TRPOK_INFO.append([file["raw"]["template"], file["raw"]["num_pokemon"]])
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{narc_name}'):
		os.makedirs(f'{ROM_NAME}/json/{narc_name}')

	with open(f'{ROM_NAME}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)
	
	readable["class"] = TRAINER_CLASSES[raw["class"]] 
	readable["class_id"] = raw["class"]
	

	if file_name < len(TRAINER_NAMES):
		readable["name"] = TRAINER_NAMES[file_name]

	readable["reward_item"] = ITEMS[raw["reward_item"]]
	readable["battle_type_1"] = BATTLE_TYPES[raw["battle_type_1"]]

	for n in range(1, 5):
		readable[f'item_{n}'] = ITEMS[raw[f'item_{n}']]


	index = 2
	props = bin(raw["template"])[2:].zfill(index) 
	
	for prop in TEMPLATE_FLAGS:
		amount = int(props[index - 1])
		readable[prop] = amount
		index -= 1


	index = 14
	props = bin(raw["ai"])[2:].zfill(index) 
	
	for prop in AIS:
		amount = int(props[index - 1])
		readable[prop] = amount
		index -= 1

	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	

