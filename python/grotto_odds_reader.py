import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc
import code 
import io
import os
import os.path
from os import path
import json
import copy
import re
# code.interact(local=dict(globals(), **locals()))

######################### FILE SPECIFIC CONSTANTS #############################

def set_global_vars():
	global ROM_NAME, NARC_FORMAT, BASE_ROM
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']


	NARC_FORMAT = []

	for n in range(0, 20):

		for rarity in ["rare", "uncommon", "common"]:
			NARC_FORMAT.append([1, f'{rarity}_pok_odds_{n}'])


		for item_type in ["normal", "hidden"]:
			for rarity in ["superrare", "rare", "uncommon", "common"]:
				if item_type == "hidden" and rarity == "common":
					continue
				NARC_FORMAT.append([1, f'{rarity}_{item_type}_item_odds_{n}'])


#################################################################
## TODO: create universal read_data function that takes name of narc, and to_readable() function as args

def output_grotto_odds_json(grotto_odds):
	set_global_vars()
	data_index = 0
	data_name = "grotto_odds"
	folder_name = "arm9"

	read_data(grotto_odds, NARC_FORMAT, data_name, folder_name)
	data_index += 1

def read_data(data, narc_format, file_name, folder_name):
	stream = data
	json_data = {"raw": {}, "readable": {} }
	
	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		byte = read_bytes(stream, entry[0])
		json_data["raw"][entry[1]] = byte

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	json_data["readable"] = to_readable(json_data["raw"], file_name)
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{ROM_NAME}/json/{folder_name}'):
		os.makedirs(f'{ROM_NAME}/json/{folder_name}')

	with open(f'{ROM_NAME}/json/{folder_name}/{file_name}.json', "w") as outfile:  
		json.dump(json_data, outfile) 


def to_readable(raw, file_name=""):
	readable = copy.deepcopy(raw)
	return readable


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')


