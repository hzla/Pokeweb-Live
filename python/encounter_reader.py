import code 
import copy
from math import floor
import rom_data
import tools


def output_encounters_json(narc, rom_name):
	tools.output_json(narc, "encounters", to_readable, rom_name)

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)
	
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

	return readable


	

