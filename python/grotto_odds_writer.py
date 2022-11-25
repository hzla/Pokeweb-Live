import ndspy
import ndspy.rom, ndspy.bmg, ndspy.codeCompression
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


def output_grotto_odds():
	json_file_path = f'{ROM_NAME}/json/arm9/grotto_odds.json'
	
	# ndspy copy of narcfile to edit
	grotto_odds_file_path = f'{ROM_NAME}/grotto_odds.bin'		
	stream = bytearray() 

	with open(json_file_path, "r") as outfile:  	
		json_data = json.load(outfile)	
		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in NARC_FORMAT: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)

	stream
	open(grotto_odds_file_path, "wb").write(stream) 

	print("grotto_odds")

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream


def write_readable_to_raw():
	data = {}
	json_file_path = f'{ROM_NAME}/json/arm9/grotto_odds.json'

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
	return raw

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	write_readable_to_raw()
	output_grotto_odds()
	

