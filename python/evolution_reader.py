import code 
import copy
import tools
import rom_data

def output_evolutions_json(narc, rom_name):
	tools.output_json(narc, "evolutions", to_readable, rom_name)

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	for n in range(0,7):
		readable[f'method_{n}'] = rom_data.METHODS[raw[f'method_{n}']]
		readable[f'target_{n}'] = rom_data.POKEDEX[raw[f'target_{n}']]

		if raw[f'target_{n}'] == 0:
			readable[f'target_{n}'] = ""


		if raw[f'method_{n}'] in [6,8,17,18,19,20]:
			readable[f'param_{n}'] = rom_data.ITEMS[raw[f'param_{n}']]
		elif raw[f'method_{n}'] == 21:

			readable[f'param_{n}'] = rom_data.MOVES[raw[f'param_{n}']]
		elif raw[f'method_{n}'] == 22:
			readable[f'param_{n}'] = rom_data.POKEDEX[raw[f'param_{n}']]
		else:
			readable

	return readable



