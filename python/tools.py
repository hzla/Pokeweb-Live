import ndspy
import ndspy.rom
import code 
import io
import os
import os.path
from os import path
import json
import copy
from math import floor
import rom_data

from trpok_reader import output_trpok_json
import hgss_trpok_reader


################ STANDARD FUNCTIONS FOR MULTI FILE STATIC FORMAT NARCS ###################

def output_narc(narc_name, rom, rom_name):
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		NARC_FILE_ID = settings[narc_name]
		BASE_ROM = settings["base_rom"]

	if BASE_ROM == "HGSS":
		rom_data.set_hgss_global_vars(rom_name)
	else:
		rom_data.set_global_vars(rom_name)


	json_files = os.listdir(f'{rom_data.ROM_NAME}/json/{narc_name}')
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC(rom.files[NARC_FILE_ID])

	for f in json_files:
		file_name = int(f.split(".")[0])
		write_narc_data(file_name, rom_data.NARC_FORMATS[narc_name], narc, narc_name, NARC_FILE_ID)
	
	rom.files[NARC_FILE_ID] = narc.save()
	print("narc saved")

	return rom

def write_narc_data(file_name, narc_format, narc, narc_name, narc_file_id):
	file_path = f'{rom_data.ROM_NAME}/json/{narc_name}/{file_name}.json'

	stream = bytearray() 

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in narc_format: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)

		# add terminator bytes for learnsets
		if narc_name == "learnsets":
			write_bytes(stream, 2, 65535) 
			write_bytes(stream, 2, 65535) 
	
	if file_name >= len(narc.files):
		narc_entry_data = bytearray()
		narc_entry_data[0:len(stream)] = stream
		narc.files.append(narc_entry_data)
	else:
		narc_entry_data = bytearray(narc.files[file_name])
		narc_entry_data[0:len(stream)] = stream
		if narc_name != "learnsets":
			narc.files[file_name] = narc_entry_data
		else:
			narc.files[file_name] = stream

def write_readable_to_raw(file_name, narc_name, to_raw):
	data = {}
	json_file_path = f'{rom_data.ROM_NAME}/json/{narc_name}/{file_name}.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	
			
		if json_data["readable"] is None:
			return
		new_raw_data = to_raw(json_data["readable"])
		json_data["raw"] = new_raw_data

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(json_data, outfile)

def output_json(narc, narc_name, to_readable, rom_name, base=5):
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		BASE_ROM = settings["base_rom"]

	if BASE_ROM == "HGSS" or BASE_ROM == "PLAT":
		rom_data.set_hgss_global_vars(rom_name)
		base = 4
	else:
		rom_data.set_global_vars(rom_name)

	narc_format = rom_data.NARC_FORMATS[narc_name]
	data_index = 0

	global TRPOK_INFO
	TRPOK_INFO = []

	for data in narc.files:
		data_name = data_index
		read_narc_data(data, narc_format, data_name, narc_name, rom_data.ROM_NAME, to_readable, base)
		data_index += 1

	if narc_name == "trdata":
		if BASE_ROM == "HGSS" or BASE_ROM == "PLAT":
			hgss_trpok_reader.output_trpok_json(TRPOK_INFO, rom_name)
		else:
			output_trpok_json(TRPOK_INFO, rom_name)

def read_narc_data(data, narc_format, file_name, narc_name, rom_name, to_readable, base=5):
	stream = io.BytesIO(data)
	file = {"raw": {}, "readable": {} }
	


	#USE THE FORMAT LIST TO PARSE BYTES
	for entry in narc_format: 
		file["raw"][entry[1]] = read_bytes(stream, entry[0])
		
		if narc_name == "encounters" and base == 5:
			#copy data from spring section if not present in current season
			if file["raw"][entry[1]] == 0 and "spring" not in entry[1]:
				spring_data = "spring_" + "_".join(entry[1].split("_")[1:])
				file["raw"][entry[1]] = file["raw"][spring_data]
		elif narc_name == "learnsets":
			# stop reading learnsets after terminator byte
			if file["raw"][entry[1]] == 65535:
				file["raw"].pop(entry[1])
				break

			if rom_data.BASE_VERSION == "SS" or rom_data.BASE_VERSION == "PL":
				ls_id = int(entry[1].split("_")[2])
				file["raw"][f"lvl_learned_{ls_id}"] = (file["raw"][entry[1]] >> 9) & 0x7F
				file["raw"][entry[1]] = file["raw"][entry[1]] & 0x1FF 		
		else:
			"nothin"

	#CONVERT TO READABLE FORMAT USING CONSTANTS/TEXT BANKS
	file["readable"] = to_readable(file["raw"], file_name, base)

	# save trdata format for trpok reader
	if narc_name == "trdata":
		TRPOK_INFO.append([file["raw"]["template"], file["raw"]["num_pokemon"], file["readable"]])
	
	#OUTPUT TO JSON
	if not os.path.exists(f'{rom_name}/json/{narc_name}'):
		os.makedirs(f'{rom_name}/json/{narc_name}')

	with open(f'{rom_name}/json/{narc_name}/{file_name}.json', "w") as outfile:  
		json.dump(file, outfile) 


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream
