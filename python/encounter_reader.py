import code 
import copy
from math import floor
import rom_data
import tools


def output_encounters_json(narc, rom_name):
	tools.output_json(narc, "encounters", to_readable, rom_name)

def to_readable(raw, file_name, gen=5):
	readable = copy.deepcopy(raw)
	
	if gen == 5:
		for season in ["spring", "summer", "fall", "winter"]:

			for enc_type in ["grass", "grass_doubles", "grass_special"]:
				for n in range(0,12):
					index = raw[f'{season}_{enc_type}_slot_{n}']
					
					if index >= 2048:
						readable[f'{season}_{enc_type}_slot_{n}_form'] = floor(index / 2048)
						index = index % 2048

					readable[f'{season}_{enc_type}_slot_{n}'] = rom_data.POKEDEX[index]
					if index == 0:
						readable[f'{season}_{enc_type}_slot_{n}'] = ""

			for wat_enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
				for n in range(0,5):
					index = raw[f'{season}_{wat_enc_type}_slot_{n}']		
					if index >= 2048:
						readable[f'{season}_{wat_enc_type}_slot_{n}_form'] = floor(index / 2048)
						index = index % 2048

					readable[f'{season}_{wat_enc_type}_slot_{n}'] = rom_data.POKEDEX[index]

					if index == 0:
						readable[f'{season}_{wat_enc_type}_slot_{n}'] = ""

	if gen == 4:
		for time in ["morning", "day", "night"]:
			for n in range(0,12):
				mondata = get_form(raw[f'{time}_{n}_species_id'])
				readable[f'{time}_{n}_species_id'] = rom_data.POKEDEX[mondata[1]]
				readable[f'{time}_{n}_species_form'] = mondata[0]


		for region in ["hoenn", "sinnoh"]:
			for n in range(0,2):
				mondata = get_form(raw[f'{region}_{n}_species_id'])
				readable[f'{region}_{n}_species_id'] = rom_data.POKEDEX[mondata[1]]
				readable[f'{region}_{n}_species_form'] = mondata[0]

		method_counts = [5,2,5,5,5]
		for idx, method in enumerate(["surf", "rock_smash", "old_rod", "good_rod", "super_rod"]):
			for n in range(0, method_counts[idx]):
				mondata = get_form(raw[f'{method}_{n}_species_id'])
				readable[f'{method}_{n}_species_id'] = rom_data.POKEDEX[mondata[1]]
				readable[f'{method}_{n}_species_form'] = mondata[0]

	return readable

def get_form(species_id):
	if species_id < 2048:
		return [1, species_id]
	else:
		form = species_id // 2048
		base_form_id = raw[f'target_{n}'] - (2048 * form)
		return [form + 1, base_form_id]



	

