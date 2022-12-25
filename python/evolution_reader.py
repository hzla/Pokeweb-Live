import code 
import copy
import tools
import rom_data

def output_evolutions_json(narc, rom_name):
	tools.output_json(narc, "evolutions", to_readable, rom_name)

def to_readable(raw, file_name, base=5):
	readable = copy.deepcopy(raw)

	for n in range(0, 7):
		readable[f'method_{n}'] = rom_data.METHODS[raw[f'method_{n}']]


		if raw[f'target_{n}'] == 0:
			readable[f'target_{n}'] = ""


		if (raw[f'target_{n}']) > 2048:
			# print(file_name)
			# print(raw)
			form = raw[f'target_{n}'] // 2048 
			base_form_id = raw[f'target_{n}'] - (2048 * form )
			readable[f'target_{n}'] = rom_data.POKEDEX[base_form_id]
			readable[f'target_form_{n}'] = form + 1
		else:
			readable[f'target_{n}'] = rom_data.POKEDEX[(raw[f'target_{n}'])]
			readable[f'target_form_{n}'] = 1


		if base == 5:
			if raw[f'method_{n}'] in [6,8,17,18,19,20]:
				readable[f'param_{n}'] = rom_data.ITEMS[raw[f'param_{n}']]
			elif raw[f'method_{n}'] == 21:

				readable[f'param_{n}'] = rom_data.MOVES[raw[f'param_{n}']]
			elif raw[f'method_{n}'] == 22:
				readable[f'param_{n}'] = rom_data.POKEDEX[raw[f'param_{n}']]
			else:
				readable
		else:
			
			if raw[f'method_{n}'] in [6,8,16,17,18,19]:
				readable[f'param_{n}'] = rom_data.ITEMS[raw[f'param_{n}']]
			elif raw[f'method_{n}'] == 20:
				readable[f'param_{n}'] = rom_data.MOVES[raw[f'param_{n}']]
			elif raw[f'method_{n}'] == 21:
				readable[f'param_{n}'] = rom_data.POKEDEX[raw[f'param_{n}']]
			else:
				readable

	return readable



def get_form(species_id):
	if species_id < 2048:
		return [1, species_id]
	else:
		form = species_id // 2048
		base_form_id = raw[f'target_{n}'] - (2048 * form)
		return [form + 1, base_form_id]




