from multiprocessing import Pool
import os
import ndspy.narc
import json
import rom_data

from personal_reader import output_personal_json
from learnset_reader import output_learnsets_json
from move_reader import output_moves_json
from arm9_reader import output_tms_json
from grotto_odds_reader import output_grotto_odds_json
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
	if narc != "grotto_odds":
		file_name = f'{rom_name}/narcs/{narc}-{narc_info[narc]}.narc'
		narc_data = ndspy.narc.NARC.fromFile(file_name)
		os.remove(file_name)
	else:		
		narc_data = open(f'{rom_name}/grotto_odds.bin','rb')
		# narc_data.close()

	eval(f'output_{narc}_json')(narc_data)
	print(narc)


	return narc


narc_info = {} ##store narc names and file id pairs
with open(f'session_settings.json', "r") as outfile:  
	narc_info = json.load(outfile) 

narcs_to_output = ["trdata", "personal", "learnsets", "moves", "encounters", "items", "evolutions", "overworlds", "maps", "matrix"]
# narcs_to_output = ["overworlds"]
if narc_info["base_rom"] == "BW2":
	narcs_to_output += ["grottos", "marts", "grotto_odds"]


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

