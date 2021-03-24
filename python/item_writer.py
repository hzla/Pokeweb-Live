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
	global ROM_NAME, NARC_FORMAT, NARC_FILE_ID
	
	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["items"]

	

	NARC_FORMAT = [[2, "market_value"],
				[1, "battle_flags"],
				[1, "gain_values"],
				[1, "berry_flags"],
				[1, "held_flags"],
				[1, "unknown_flag_1"],
				[1, "nature_gift_power"],
				[2, "type_attribute"],
				[1, "item_group"],
				[1, "battle_item_group"],
				[1, "usability_flag"],
				[1, "item_type"],
				[1, "consumable_flag"],
				[1, "name_order_id"],
				[1, "status_removal_flag"], #also used as ball_id
				[1, "hp_atk_boost"],
				[1, "def_spatk_boost"],
				[1, "spd_spdef_boost"],
				[1, "acc_crit_pp_boost"],
				[2, "pp_flags"],
				[1, "hp_ev_gain"],
				[1, "atk_ev_gain"],
				[1, "def_ev_gain"],
				[1, "spd_ev_gain"],
				[1, "spatk_ev_gain"],
				[1, "spdef_ev_gain"],
				[1, "hp_gain"],
				[1, "pp_gain"],
				[1, "battle_happiness"],
				[1, "ow_happiness"],
				[1, "hold_happiness"],
				[2, "padding"]]

set_global_vars()
#################################################################


def output_narc(narc_name="items"):
	json_files = os.listdir(f'{ROM_NAME}/json/{narc_name}')
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC.fromFile(narcfile_path)

	for f in json_files:
		file_name = int(f.split(".")[0])

		write_narc_data(file_name, NARC_FORMAT, narc, narc_name)

	old_narc = open(narcfile_path, "wb")
	old_narc.write(narc.save()) 

	print("narc saved")

def write_narc_data(file_name, narc_format, narc, narc_name="items"):
	file_path = f'{ROM_NAME}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		#USE THE FORMAT LIST TO PARSE BYTES
		for entry in narc_format: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)
	
	if file_name >= len(narc.files):
		narc_entry_data = bytearray()
		narc_entry_data[0:len(stream)] = stream
		narc.files.append(narc_entry_data)
	else:
		narc_entry_data = bytearray(narc.files[file_name])
		narc_entry_data[0:len(stream)] = stream
		narc.files[file_name] = narc_entry_data
	
def write_readable_to_raw(file_name, narc_name="items"):
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

	

	return raw
	

def write_bytes(stream, n, data):
	stream += (data.to_bytes(n, 'little'))		
	return stream



################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":

	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
# output_narc()

# write_readable_to_raw(1)