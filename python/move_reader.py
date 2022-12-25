import code 
import json
import copy
import rom_data
import tools
# code.interact(local=dict(globals(), **locals()))

def output_moves_json(narc, rom_name):
	tools.output_json(narc, "moves", to_readable, rom_name)

def to_readable(raw, file_name, base=5):
	readable = copy.deepcopy(raw)

	readable["index"] = file_name
	readable["animation"] = file_name
	if file_name >= len(rom_data.MOVES):
		readable["name"] = f'EXPANDED MOVE {file_name}'
		file_name = 0
		
	else:
		readable["name"]  = rom_data.MOVES[file_name] 


	if file_name >= 673:
		readable["animation"] = 0


	if base == 5:
		readable["effect_category"] = rom_data.EFFECT_CATEGORIES[raw["effect_category"]]
		#special case for tri attack
		if raw["result_effect"] == 65535:
			readable["result_effect"] = rom_data.EFFECTS[36]
		else:
			readable["result_effect"] = rom_data.RESULT_EFFECTS[raw["result_effect"]]

		if raw["recoil"] > 0:
			readable["recoil"] = 256 - raw["recoil"]

		readable["stat_1"] = rom_data.STATS[raw["stat_1"]]
		readable["stat_2"] = rom_data.STATS[raw["stat_2"]]
		readable["stat_3"] = rom_data.STATS[raw["stat_3"]]

		if raw["magnitude_1"] > 6:
			readable["magnitude_1"] = raw["magnitude_1"] - 256

		if raw["magnitude_2"] > 6:
			readable["magnitude_2"] = raw["magnitude_2"] - 256

		if raw["magnitude_3"] > 6:
			readable["magnitude_3"] = raw["magnitude_3"] - 256

		index = 8
		binary_hits = bin(raw["hits"])[2:].zfill(index)

		hits = ["min_hits", "max_hits"]
		for hit in hits:
			amount = int(binary_hits[index-4:index],2)
			readable[hit] = amount
			index -= 4



	readable["type"] = rom_data.TYPES[raw["type"]]
	readable["category"] = rom_data.CATEGORIES[raw["category"]]

	readable["effect"] = rom_data.EFFECTS[raw["effect"]]
	readable["status"] = rom_data.STATUSES[raw["status"]]
	readable["target"] = rom_data.TARGETS[raw["target"]]

	
	if base == 4:
		index = 8
	else:
		index = 14

	binary_props = bin(raw["properties"])[2:].zfill(index) 
	
	for prop in rom_data.PROPERTIES:
		amount = int(binary_props[index - 1])
		readable[prop] = amount
		index -= 1

	return readable


	
