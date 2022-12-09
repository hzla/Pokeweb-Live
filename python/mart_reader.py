import code 
import json
import copy
import rom_data
import tools

def output_marts_json(narc):
	tools.output_json(narc, "marts", to_readable)

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	try:
		readable["name"] = rom_data.MART_LOCATIONS[file_name]
	except IndexError:
		readable["name"] = "-"

	for n in range(0,20):
		readable[f'item_{n}'] = rom_data.ITEMS[raw[f'item_{n}']]

	return readable


	

