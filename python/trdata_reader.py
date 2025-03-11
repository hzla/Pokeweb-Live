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

import rom_data
import tools

def output_trdata_json(narc, rom_name):
	tools.output_json(narc, "trdata", to_readable, rom_name)

def to_readable(raw, file_name, base=5):
	readable = copy.deepcopy(raw)
	
	readable["class"] = rom_data.TRAINER_CLASSES[raw["class"]] 
	readable["class_id"] = raw["class"]
	

	if file_name < len(rom_data.TRAINER_NAMES):
		readable["name"] = rom_data.TRAINER_NAMES[file_name]

	if base == 5:
		readable["reward_item"] = rom_data.ITEMS[raw["reward_item"]]
		readable["battle_type_1"] = rom_data.BATTLE_TYPES[raw["battle_type_1"]]
	else:
		readable["battle_type"] = rom_data.BATTLE_TYPES[raw["battle_type"]]

	for n in range(1, 5):
		try:
			readable[f'item_{n}'] = rom_data.ITEMS[raw[f'item_{n}']]
		except:
			print(f'trdata {file_name}: item {raw[f'item_{n}']}')


	if base == 4:
		index = 8 
	else:
		index = 2

	props = bin(raw["template"])[2:].zfill(index) 
	
	for prop in rom_data.TEMPLATE_FLAGS:
		amount = int(props[index - 1])
		readable[prop] = amount
		index -= 1


	index = 14
	props = bin(raw["ai"])[2:].zfill(index) 
	
	for prop in rom_data.AIS:
		amount = int(props[index - 1])
		readable[prop] = amount
		index -= 1

	return readable


	

