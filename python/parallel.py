from multiprocessing import Pool
import os
import ndspy.narc
import json
import rom_data
import sys 
import shutil

from personal_reader import output_personal_json
from learnset_reader import output_learnsets_json
from move_reader import output_moves_json
from arm9_reader import output_tms_json
from grotto_odds_reader import output_grotto_odds_json
from move_effects_table_reader import output_move_effects_table_json
from encounter_reader import output_encounters_json
from trdata_reader import output_trdata_json
from item_reader import output_items_json
from evolution_reader import output_evolutions_json
from grotto_reader import output_grottos_json
from mart_reader import output_marts_json
from overworld_reader import output_overworlds_json
from map_reader import output_maps_json
from matrix_reader import output_matrix_json


def output(narc):	
	narc_data = 0
	if narc != "grotto_odds" and narc != "move_effects_table":
		file_name = f'{rom_name}/narcs/{narc}-{narc_info[narc]}.narc'
		narc_data = ndspy.narc.NARC.fromFile(file_name)
		os.remove(file_name)
	else:		
		narc_data = open(f'{rom_name}/{narc}.bin','rb')
		# narc_data.close()

	eval(f'output_{narc}_json')(narc_data, rom_name)
	print(narc)


	return narc


narc_info = {} ##store narc names and file id pairs

rom_name = sys.argv[1]

with open(f'{rom_name}/session_settings.json', "r") as outfile:  
	narc_info = json.load(outfile) 

narcs_to_output = ["trdata", "personal", "learnsets", "moves", "encounters", "items", "evolutions", "overworlds", "maps", "matrix"]

with open(f'{rom_name}/session_settings.json', "r") as outfile:  
	settings = json.load(outfile) 
	narcs_to_output =  [item for item in narcs_to_output if item not in settings["blacklist"]]


if narc_info["base_rom"] == "BW2":
	narcs_to_output += ["grottos", "marts", "grotto_odds", "move_effects_table"]


for ctr_narc in settings["blacklist"]:
	# path to source directory
	src_dir = f"./templates/{settings["base_version"]}/json/{ctr_narc}"
	# path to destination directory
	dest_dir = f"./{rom_name}/json/{ctr_narc}" 
	# getting all the files in the source directory
	files = os.listdir(src_dir)
	shutil.copytree(src_dir, dest_dir)
	print(ctr_narc)


rom_name = narc_info["rom_name"]


if __name__ == '__main__':
	

	# file_name = f'{rom_name}/narcs/maps-{narc_info["maps"]}.narc'
	# narc_data = ndspy.narc.NARC.fromFile(file_name)
	# output_maps_json(narc_data)
	
	print("settings up processing pools")
	pool = Pool(processes=os.cpu_count())
	print("outputing narcs")
	pool.map(output, narcs_to_output)
	pool.close()

