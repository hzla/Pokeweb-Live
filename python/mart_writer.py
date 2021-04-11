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
def set_global_vars():
	global ROM_NAME, NARC_FORMAT, ITEMS, MART_LOCATIONS, NARC_FILE_ID, MART_COUNTS_NARC_FILE_ID
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings['marts']
		MART_COUNTS_NARC_FILE_ID = settings['mart_counts']

	with open(f'{ROM_NAME}/texts/items.txt', mode="r") as outfile: 
		ITEMS = outfile.read().splitlines()

	with open(f'Reference_Files/mart_locations.txt', mode="r") as outfile:
		MART_LOCATIONS =  outfile.read().splitlines()

	NARC_FORMAT = []

	for n in range(0,20):
		NARC_FORMAT.append([2, f'item_{n}'])

set_global_vars()
#################################################################


def output_narc(narc_name="marts"):
	json_files = os.listdir(f'{ROM_NAME}/json/{narc_name}')
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'
	counts_narcfile_path = f'{ROM_NAME}/narcs/mart_counts-{MART_COUNTS_NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)
	counts_narc = ndspy.narc.NARC.fromFile(counts_narcfile_path)
	counts = bytearray(counts_narc.files[0])

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, NARC_FORMAT, narc, counts, narc_name)

	print(counts)

	counts_narc.files[0] = counts

	with open(counts_narcfile_path, "wb") as outfile:
		outfile.write(counts_narc.save()) 

	with open(narcfile_path, "wb") as outfile:
		outfile.write(narc.save()) 

	print("narc saved")

def write_narc_data(file_name, narc_format, narc , counts, narc_name=""):
	file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		item_count = 0
		for entry in narc_format: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)
				if json_data["raw"][entry[1]] != 0:
					item_count += 1

	counts[file_name]= item_count
	narc_entry_data = bytearray(narc.files[file_name])
	narc_entry_data[0:len(stream)] = stream
	narc.files[file_name] = narc_entry_data
	
def write_readable_to_raw(file_name, narc_name="marts"):
	data = {}
	json_file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'

	with open(json_file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	
			
		if json_data["readable"] is None:
			return

		new_raw_data = to_raw(json_data["readable"])
		json_data["raw"] = new_raw_data

	with open(json_file_path, "w", encoding='ISO8859-1') as outfile: 
		json.dump(json_data, outfile)

def to_raw(readable):
	raw = copy.deepcopy(readable)

	for n in range(0,20):
		raw[f'item_{n}'] = ITEMS.index(readable[f'item_{n}'])


	return raw
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
# output_narc()

# write_readable_to_raw(1)